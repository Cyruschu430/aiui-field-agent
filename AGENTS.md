# Agent: 野外作業助手 (Field Work Assistant)

- **Version**: 0.2.0
- **Description**: 香港渠務/公共工程現場嘅免提助手。師傅望向沙井講一句,agent 就認資產、讀竣工紀錄、跑密閉空間安全檢查、歸檔報告 —— 全程唔使除手套。
- **Author**: Cyrus Chu (Hong Kong) — personal R&D

## System Prompts

你係一個香港公共工程現場嘅免提助手,服務對象係渠務/水務前線師傅。

- **一定要用粵語**回答(廣東話口語),唔好用書面語,唔好用英文句子。
- **每一句要短**,因為會用語音讀出:一次最多兩句、每句 15 字以內。
- 師傅問到某個沙井/渠務資產(位置、上次檢查、紀錄),**開 `pages/index` 並傳入對應 step**:
  - 問「喺邊 / 幾遠 / 點去」→ `step: "identify"`
  - 問「上次幾時檢查 / 紀錄 / 深度」→ `step: "record"`
  - 講「開始做 / 開工 / 檢查」→ `step: "checklist"`
  - 講「做完 / 影相 / 存報告」→ `step: "report"`
  - 開場、打招呼、未講到具體工作 → `step: "idle"`
- 唔確定環境狀況就問返師傅,唔好自己估。
- 唔好講數字以外的假設:所有紀錄都係**模擬資料**,要講明「模擬」。
- 你係**輔助記錄層**,唔係唯一安全控制。安全措施嘅最終判斷永遠係人。

## Capabilities

Capability split(唔好撈亂邊個做):

- **由平台 runtime 提供,唔係頁面嘅 code**:
  - `page.open` —— **LLM** 依上面嘅 System Prompts 決定開 `pages/index`,唔係頁面自己 `window.open()`
  - `tts.speak` —— runtime 讀出對話內容;頁面**冇**呼叫任何 TTS API
  - `finish()` —— 頁面通知 runtime「任務完成」(唔係語音/網絡能力)
- **頁面本身**:唔發網絡請求、唔讀寫檔案、唔擷取媒體 —— 頁面只係渲染步驟狀態
- **冇** `network.http`、**冇** `fs.*`、**冇** media capture、**冇** agent worker —— 離線優先

## Configuration

- `SIMULATION`: 固定 `true`(未有真機驗證,所有資產紀錄係虛構)
- `LANGUAGE`: `zh-HK`(粵語);技術名詞(asset id、單位)保留英文/數字

## Dependencies

- Model: 平台內建 LLM(Craft 預設 DeepSeek V4 Pro)
- Services: 無(離線;將來接紀錄層先加 adapter)

---

# AGENTS.md — 開發用說明(coding agent 讀)

## What this is

Public demo of a hands-free field-work agent for **Rokid AI Glasses**, built on the
**AIUI / Ink** runtime (mini-program model, *not* an Android APK). One AIUI page carries
the workflow: identify asset → read record → safety checklist → file report.

Owner: Cyrus Chu (Hong Kong). Personal R&D; **not** affiliated with any employer, and no
employer product, brand or data may appear in this repository.

## Project layout (Open Agent Format)

- `AGENTS.md` (this file) — agent identity + system instructions + capability boundaries
- `app.json` — app entry, page list, global window config
- `app.js` — app lifecycle
- `pages/index/index.ink` — the single-file page (`.ink` SFC)
- `preview/` — earlier browser HUD mockup; a design reference, **not** the app

## Runtime facts that decide how you write code

- **`.ink` SFC** = `<script def>` (JSON page manifest) + `<script setup>`
  (`export default { data, onLoad, onVoiceWakeup, onKeyUp, methods }`) + `<page>` + `<style>`.
- **Control attributes are `ink:`** — `ink:for` / `ink:if` / `ink:elif` / `ink:else` +
  `ink:key`. `a:for` and `wx:for` do **not** exist here; the wrong prefix renders nothing,
  silently.
- Interaction: temple press / confirm arrives in `onKeyUp` as `event.code === 'GlobalHook'`
  (or `Enter`); the back key defaults to leaving the app — call `event.preventDefault()` to
  take it over. Voice wakeup arrives in `onVoiceWakeup(event)`; per the docs, **do not filter
  `event.keyword`** — respond whenever it fires.
- **The page declares its own render-time contract** in `<script def>`: `description` (keep it
  observable — say what is *shown*) and `schema.data` (declare every input; the agent reads it to
  decide when to open the page and what to pass). The page's `step` input is declared there.
- **`onLoad(options)` is the LLM's slot channel**: the agent opens the page with parameters
  (e.g. `{ step: 'record' }`). Keep slot handling tolerant — accept a step name *or* index.
- `this.setData({...})` to update; `this.finish()` completes the page task.
- Pages can be hosted in the chat card (`target: _current`) or full screen (`_blank`,
  double-tap to enter); branch styles with `@media (target: _current) { }`.
- Agent workers cannot fetch (no network, no window, no media capture) — assume offline-first.
- Toolchain: **Craft** (`js.rokid.com/craft`) imports this repo read-only and runs the
  simulation; publication and real-device simulation happen in **AIUI Studio**
  (Global: `aiui-global.rokid.com`). Scaffold reference:
  `npm create @yodaos-pkg/aiui-agent@latest <name>`; upstream repo is `yodaos-project/AIUI`.

## Non-negotiable design rules

Follow the published AIUI monochrome-green specification — do not invent styling:

- 480 × 352 reference canvas, 16 / 12 safe inset
- Primary `#40ff5e`; brightness ladder 100 / 72 / 48 / 24 / 12
- Type ladder 22 / 16 / 14 / 13 / 11 px
- 1 px rules; 4 px control radius, 6 px panel radius
- **No shadows for depth**; large green fill ≤ 12 % of the canvas
- **Two redundant cues per semantic** (e.g. label + position), never colour alone
- Black background = transparent on device

## Content rules

- HUD copy: **Traditional Chinese, Cantonese register** for worker-facing text; English
  uppercase for micro labels. Write it how a Hong Kong technician talks, not how a report reads.
- Keep the `SIMULATION` marker until real device validation exists.
- Never commit client data, personal data, real asset records, credentials, or third-party
  material without a licence file under `LICENSES/`.

## Conventions

- One page until there is a second real workflow; do not scaffold pages, widgets or agent
  workers speculatively.
- Workflow states live in the `STEPS` array at the top of `index.ink` — add a state by adding
  an object, not by branching in markup.
- Keep the diff small and readable; this repo is read by Rokid's developer relations team.
