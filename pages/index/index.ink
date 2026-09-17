<script def>
{
  "navigationBarTitleText": "野外作業助手"
}
</script>

<script setup>
/* 野外作業 agent — 480x352 單色綠 HUD,跟官方 AIUI 設計規範
   資料全部係模擬(SIMULATION),冇接任何後端、冇 fetch */
const STEPS = [
  {
    key: 'idle',
    label: 'READY',
    title: '野外作業助手',
    say: '望住個沙井,講一句就得',
    rows: [
      ['提示', '粵語語音,唔使拎手機'],
      ['就緒', '資產資料已離線備妥']
    ],
    big: '', unit: ''
  },
  {
    key: 'identify',
    label: 'ASSET',
    title: '集水井 CP-2041',
    say: '喺你前方四十米,方向東北',
    rows: [
      ['方向', '東北'],
      ['系統', 'D300 排水管']
    ],
    big: '40', unit: '米'
  },
  {
    key: 'record',
    label: 'RECORD',
    title: '上次檢查紀錄',
    say: '上次檢查係十個月前,已經逾期',
    rows: [
      ['上次檢查', '10 個月前'],
      ['井深', '1.8 米'],
      ['井底高程', '41.32 米']
    ],
    big: '10', unit: '個月'
  },
  {
    key: 'checklist',
    label: 'SAFETY',
    title: '密閉空間檢查',
    say: '四項安全措施,全部已確認',
    rows: [
      ['氣體檢測', '已確認'],
      ['機械通風', '已確認'],
      ['安全帶', '已確認'],
      ['工作許可證', '已確認']
    ],
    big: '4/4', unit: '項'
  },
  {
    key: 'report',
    label: 'FILED',
    title: '報告已歸檔',
    say: '報告已經存好,返寫字樓唔使再入電腦',
    rows: [
      ['報告編號', 'RPT-0916-01'],
      ['現場相片', '3 張'],
      ['狀態', '已落載到案卷']
    ],
    big: '', unit: ''
  }
];

export default {
  data: {
    step: 0,
    steps: STEPS,
    live: false
  },
  current() {
    return this.data.steps[this.data.step];
  },
  setStep(i) {
    const n = Math.max(0, Math.min(this.data.steps.length - 1, i));
    this.setData({ step: n });
  },
  handleNext() {
    this.setStep(this.data.step + 1);
  },
  handleBack() {
    this.setStep(this.data.step - 1);
  },
  handleReset() {
    this.setStep(0);
  },
  /* 眼鏡:撳 temple / 講「下一個」都行 —— 兩個冗餘線索 */
  onKeyUp(event) {
    if (event.code === 'Enter' || event.code === 'GlobalHook') {
      this.data.step >= this.data.steps.length - 1 ? this.handleReset() : this.handleNext();
    }
  }
}
</script>

<page>
  <view class="hud">
    <!-- 頂線:狀態 label + 電量(兩個線索:字 + 位置) -->
    <view class="topbar">
      <text class="label">{{ steps[step].label }}</text>
      <text class="meta">離線可用 · 100%</text>
    </view>
    <view class="rule"></view>

    <!-- 主體 -->
    <view class="body">
      <view class="main">
        <text class="title">{{ steps[step].title }}</text>
        <text class="say">{{ steps[step].say }}</text>

        <view class="rows">
          <view class="row" a:for="{{ steps[step].rows }}">
            <text class="rowk">{{ item[0] }}</text>
            <text class="rowv">{{ item[1] }}</text>
          </view>
        </view>
      </view>

      <!-- 大數字:位置 + 尺寸,兩個線索 -->
      <view class="side" a:if="{{ steps[step].big }}">
        <text class="big">{{ steps[step].big }}</text>
        <text class="unit">{{ steps[step].unit }}</text>
      </view>
    </view>

    <view class="rule"></view>
    <!-- 底部:操作 + 模擬聲明 -->
    <view class="bottom">
      <button class="btn" bindtap="handleBack">上一步</button>
      <button class="btn primary" bindtap="handleNext">下一步</button>
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
  font-size: 12px;
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
  color: rgba(64, 255, 94, 0.88);
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
</style>
