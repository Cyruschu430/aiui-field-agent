# AIUI Field Agent — hands-free field-work assistant for Rokid AI Glasses

A field-work agent for **Rokid AI Glasses**, built as a personal R&D project. The
worker looks at an asset, speaks in Cantonese, and the agent identifies it, reads
the record, runs the safety checklist and files the report — without taking their
gloves off.

> **Status: simulated demo.** All data in this repository is fictional. Nothing
> here is connected to a live asset database, and the agent has not yet been
> validated on a device.

## What is here

| Path | What it is |
|---|---|
| `pages/index/index.ink` | The AIUI/Ink page — 5-step field workflow, designed to the official AIUI monochrome-green specification |
| `app.json` / `app.js` / `package.json` | Standard AIUI project scaffold |
| `preview/live.html` | Earlier browser HUD mockup (design reference, bilingual EN/TC, not the app) |
| `preview/hud-preview.png` | Rendered HUD preview |
| `LICENSES/` | SIL OFL 1.1 texts for the fonts embedded in the mockup |

## Run it in Craft (AIUI Web IDE)

1. Open <https://js.rokid.com/craft>
2. Choose **Import → GitHub subdirectory**
3. Paste this repository URL:
   `https://github.com/Cyruschu430/aiui-field-agent`
4. Click **Run Agent** — the IDE simulates wake-up → speech recognition → LLM → voice playback

Remote sources are treated as **read-only** in Craft; edits there are not written
back to GitHub.

## Test the agent (in Craft)

The page is driven by the agent, not by its own UI logic: `AGENTS.md` carries the system
prompts, and the LLM opens `pages/index` with a slot — `{ step: 'identify' | 'record' |
'checklist' | 'report' | 'idle' }`. The page accepts a step name or index and falls back to
`idle`, so a wrong slot can never blank the screen.

Say these in the Craft simulation and check the state it lands on:

| Utterance (Cantonese) | Expected step |
|---|---|
| 「集水井喺邊,幾遠?」 | `identify` — 40 米 · 東北 |
| 「上次幾時檢查?」 | `record` — 10 個月前 · 已逾期 |
| 「開始做檢查」 | `checklist` — 4/4 項已確認 |
| 「影相,存報告」 | `report` — RPT-0916-01 已歸檔 |

Then test the input paths the device actually has: temple press / Enter (advance), and the
back key (should step back inside the page, not exit the app — `event.preventDefault()`).

**What is not wired:** there is no speech recognition in the page, no network call, and no
record backend. If the LLM does not route to the page, the deterministic path (temple press)
still walks the same five states — that is the honest fallback, not a bug.

Run the repo's own check before pushing:

```bash
python3 scripts/check.py     # manifest JSON, page JS syntax, required hooks, ink: prefix, SIMULATION marker
```

## Design compliance

The page follows the published AIUI design specification rather than adapting a
phone layout to a display:

- 480 × 352 reference canvas, 16 / 12 safe inset
- Primary `#40ff5e`, brightness ladder 100 / 72 / 48 / 24 / 12
- Type ladder 22 / 16 / 14 / 13 / 11 px
- 1 px rules, 4 px control radius, 6 px panel radius
- No shadows for depth; large green fill kept under 12 % of the canvas
- **Two redundant cues per semantic** — text label plus position, not colour alone

## What is real, what is not

**Built:** the agent workflow, the HUD, the state machine, the interaction model
(temple press / Enter / tap), bilingual copy.

**Not built:** any connection to real asset records, offline queueing, Cantonese
speech recognition, and the report-filing backend. The asset IDs, dates and
readings in `pages/index/index.ink` are illustrative.

## Next

1. Validate on a device — daylight legibility, IPX4 on a wet site, two-hour wear
2. Replace the placeholder data with a record-layer adapter (the layer that
   decides whether an agent is adopted or merely trialled)
3. Cantonese voice front end, tested against Hong Kong place names
4. Submit to the AIUI Studio review flow

## Notes

Personal research and development, independent of my employment. No client data,
no personal data, and no third-party material is included.

Fonts embedded in `preview/live.html` — *Silkscreen* (Google Fonts) and
*Fusion Pixel Font* — are licensed under the SIL Open Font License 1.1; see
`LICENSES/`.

---

### 中文摘要

野外作業助手:師傅望住沙井講一句粵語,agent 就認資產、讀紀錄、跑密閉空間安全檢查、自動歸檔。
介面照官方 AIUI 單色綠規範做(480×352、#40ff5e、字級 22/16/14)。**全部資料係模擬**,
未上真機驗證。個人研究項目,唔涉及客戶資料。
