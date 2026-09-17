<script def>
{
  "navigationBarTitleText": "野外作業助手",
  "description": "Shows one step of a Hong Kong field-work job on the glasses: where the asset is, its last inspection record, the confined-space safety checklist, or the filed report. Pass step as one of: idle, identify, record, checklist, report. Monochrome-green HUD; every record is simulated.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "step": { "type": "string" }
      }
    }
  }
}
</script>

<script setup>
/* 野外作業 agent — 480x352 單色綠 HUD,跟官方 AIUI 設計規範
   資料全部係模擬(SIMULATION),冇接後端、冇 fetch
   agent 行為靠 AGENTS.md 嘅 System Prompts + page description 決定:
   LLM 決定開呢一頁同傳入 step,page 只負責渲染 */
const STEPS = [
  {
    key: 'idle',
    label: 'READY',
    title: '野外作業助手',
    say: '望住個沙井,講一句就得',
    rows: [
      { k: '提示', v: '粵語語音,唔使拎手機' },
      { k: '就緒', v: '資產資料已離線備妥' }
    ],
    big: '', unit: ''
  },
  {
    key: 'identify',
    label: 'ASSET',
    title: '集水井 CP-2041',
    say: '喺你前方四十米,方向東北',
    rows: [
      { k: '方向', v: '東北' },
      { k: '系統', v: 'D300 排水管' }
    ],
    big: '40', unit: '米'
  },
  {
    key: 'record',
    label: 'RECORD',
    title: '上次檢查紀錄',
    say: '上次檢查係十個月前,已經逾期',
    rows: [
      { k: '上次檢查', v: '10 個月前' },
      { k: '井深', v: '1.8 米' },
      { k: '井底高程', v: '41.32 米' }
    ],
    big: '10', unit: '個月'
  },
  {
    key: 'checklist',
    label: 'SAFETY',
    title: '密閉空間檢查',
    say: '四項安全措施,全部已確認',
    rows: [
      { k: '氣體檢測', v: '已確認' },
      { k: '機械通風', v: '已確認' },
      { k: '安全帶', v: '已確認' },
      { k: '工作許可證', v: '已確認' }
    ],
    big: '4/4', unit: '項'
  },
  {
    key: 'report',
    label: 'FILED',
    title: '報告已歸檔',
    say: '報告已經存好,返寫字樓唔使再入電腦',
    rows: [
      { k: '報告編號', v: 'RPT-0916-01' },
      { k: '現場相片', v: '3 張' },
      { k: '狀態', v: '已落載到案卷' }
    ],
    big: '', unit: ''
  }
];

export default {
  data: {
    step: 0,
    steps: STEPS,
    listening: false,
    done: false
  },
  /* render-time input:LLM 依 <script def> 嘅 description + schema.data 傳 step 入嚟
     (官方要求:description 要 observable、每個 input 都要喺 schema.data 聲明)
     接受名字('record')或者索引(2);冇傳就由第一步開始 */
  onLoad(options) {
    const wanted = options && options.step;
    if (wanted === undefined || wanted === null || wanted === '') return;
    const byName = STEPS.findIndex(s => s.key === String(wanted));
    const byIndex = Number.isInteger(Number(wanted)) ? Number(wanted) : -1;
    const i = byName >= 0 ? byName : byIndex;
    if (i >= 0 && i < STEPS.length) this.setData({ step: i });
  },
  /* 喚醒:唔過濾 keyword(官方建議),一收到就入監聽狀態 */
  onVoiceWakeup(event) {
    this.setData({ listening: true, done: false });
    console.log('voice wakeup:', event && event.keyword);
    if (this._listenTimer) clearTimeout(this._listenTimer);   // 唔好疊住上一次
    this._listenTimer = setTimeout(() => {
      this.setData({ listening: false });
      this._listenTimer = null;
    }, 4000);
  },
  onHide() {
    if (this._listenTimer) {
      clearTimeout(this._listenTimer);
      this._listenTimer = null;
    }
  },
  setStep(i) {
    this.setData({
      step: Math.max(0, Math.min(STEPS.length - 1, i)),
      done: false
    });
  },
  handleNext() {
    if (this.data.step >= STEPS.length - 1) {
      this.setData({ done: true });
      this.finish();          // 最後一步確認 = 完成任務
      return;
    }
    this.setStep(this.data.step + 1);
  },
  handleBack() {
    this.setStep(this.data.step - 1);
  },
  handleReset() {
    this.setStep(0);
  },
  /* 撳 temple / Enter / 確認鍵 —— 兩個冗餘線索:按鍵 + 畫面反應 */
  onKeyUp(event) {
    const code = event && event.code;
    if (code === 'GlobalHook' || code === 'Enter' || code === 'Confirm') {
      this.handleNext();
      return;
    }
    if (code === 'Back' || code === 'Escape') {
      event.preventDefault();       // 接管返回鍵,唔好直接退出個 app
      this.handleBack();
    }
  }
}
</script>

<page>
  <view class="hud">
    <!-- 頂線:狀態 label + 電量(兩個線索:字 + 位置) -->
    <view class="topbar">
      <text class="label">{{ listening ? 'LISTENING' : steps[step].label }}</text>
      <text class="meta">{{ done ? '已完成 · 可以行開' : '離線可用 · 100%' }}</text>
    </view>
    <view class="rule"></view>

    <!-- 主體 -->
    <view class="body">
      <view class="main">
        <text class="title">{{ steps[step].title }}</text>
        <text class="say">{{ listening ? '講嘢啦,例如:上次幾時檢查' : steps[step].say }}</text>

        <view class="rows">
          <view class="row" ink:for="{{ steps[step].rows }}" ink:key="k">
            <text class="rowk">{{ item.k }}</text>
            <text class="rowv">{{ item.v }}</text>
          </view>
        </view>
      </view>

      <!-- 大數字:位置 + 尺寸,兩個線索 -->
      <view class="side" ink:if="{{ steps[step].big }}">
        <text class="big">{{ steps[step].big }}</text>
        <text class="unit">{{ steps[step].unit }}</text>
      </view>
    </view>

    <view class="rule"></view>
    <!-- 底部:操作 + 模擬聲明 -->
    <view class="bottom">
      <button class="btn" bindtap="handleBack">上一步</button>
      <button class="btn primary" bindtap="handleNext">{{ done ? '重新開始' : '下一步' }}</button>
      <text class="sim">SIMULATION</text>
    </view>
  </view>
</page>

<style>
/* 官方 AIUI 單色綠規範:black 底(眼鏡上 = 透明)、primary #40ff5e、
   亮度階 100/72/48/24/12、1px 線、radius 4/6px、唔用 shadow 做深度、
   大面積綠填 ≤12%、type ladder 22/16/14/13/11 */
.hud {
  width: 100vw;
  height: 100vh;
  background: #000;
  padding: 16px 12px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  font-family: system-ui, sans-serif;
}
.topbar {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}
.label {
  color: #40ff5e;
  font-size: 11px;
  letter-spacing: 1.5px;
}
.meta {
  color: rgba(64, 255, 94, 0.72);
  font-size: 11px;
}
.rule {
  height: 1px;
  background: rgba(64, 255, 94, 0.48);
  margin: 8px 0;
}
.body {
  display: flex;
  flex: 1;
  gap: 12px;
  min-height: 0;
}
.main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.title {
  color: #40ff5e;
  font-size: 22px;
  line-height: 1.2;
}
.say {
  color: rgba(64, 255, 94, 0.72);
  font-size: 16px;
  line-height: 1.35;
  margin-top: 4px;
}
.rows {
  margin-top: 10px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.row {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px solid rgba(64, 255, 94, 0.24);
  padding-bottom: 3px;
}
.rowk {
  color: rgba(64, 255, 94, 0.48);
  font-size: 11px;
  letter-spacing: 1px;
}
.rowv {
  color: rgba(64, 255, 94, 0.72);
  font-size: 13px;
  font-family: ui-monospace, monospace;
}
.side {
  width: 120px;
  border-left: 1px solid rgba(64, 255, 94, 0.24);
  padding-left: 10px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: flex-start;
}
.big {
  color: #40ff5e;
  font-size: 44px;
  line-height: 1;
}
.unit {
  color: rgba(64, 255, 94, 0.72);
  font-size: 14px;
  margin-top: 2px;
}
.bottom {
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn {
  background: transparent;
  color: rgba(64, 255, 94, 0.72);
  border: 1px solid rgba(64, 255, 94, 0.48);
  border-radius: 4px;
  font-size: 13px;
  padding: 3px 10px;
}
.btn.primary {
  color: #000;
  background: #40ff5e;
  border-color: #40ff5e;
}
.sim {
  margin-left: auto;
  color: rgba(64, 255, 94, 0.24);
  font-size: 11px;
  letter-spacing: 1.5px;
}
/* 同一個 page 兩個 hosting slot:對話卡(_current)壓縮,全屏(_blank)保持完整 */
@media (target: _current) {
  .hud { padding: 12px 10px; }
  .title { font-size: 18px; }
  .big { font-size: 30px; }
  .side { width: 88px; }
}
@media (target: _blank) {
  .hud { padding: 16px 12px; }
}
</style>
