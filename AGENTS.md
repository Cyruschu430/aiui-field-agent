# AGENTS.md — aiui-field-agent

Project context for coding agents. Read this before editing.

## What this is

A public demo of a hands-free field-work agent for **Rokid AI Glasses**, built on
the **AIUI / Ink** runtime (mini-program model, *not* an Android APK). One AIUI
page carries the whole workflow: identify asset → read record → safety checklist →
file report.

Owner: Cyrus Chu (Hong Kong). Personal R&D; **not** affiliated with any employer,
and no employer product, brand or data may appear in this repository.

## Stack and runtime facts

- **AIUI / Ink SFC** = Single File Component: `<script def>` (page manifest) +
  `<script setup>` (export default with `data` / methods / `onKeyUp`) + `<page>`
  (markup, tags like `<view>` `<text>` `<button>`) + `<style>`.
- `app.json` declares `pages`; `app.js` holds app lifecycle.
- Interaction model: temple press arrives as `event.code === 'GlobalHook'`;
  keyboard/Enter also supported by `onKeyUp`.
- **Agent Workers cannot fetch.** No `fetch`, `window`, or media capture in worker
  scope. Assume the agent is offline-first; queue writes rather than blocking.
- Development/validation loop: **Craft** (`js.rokid.com/craft`) imports a GitHub
  subdirectory read-only and runs a web simulation; publication goes through
  **AIUI Studio**.
- Scaffold reference: `npm create @yodaos-pkg/aiui-agent@latest <name>`.
  Upstream repo is `yodaos-project/AIUI` (was `jsar-project/AIUI`).

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

- HUD copy: **Traditional Chinese, Cantonese register** for worker-facing text;
  English uppercase for micro labels. Keep it how a Hong Kong technician talks,
  not how a report reads.
- Every screen must be honest about being a simulation: keep the `SIMULATION`
  marker until real device validation exists.
- Never commit client data, personal data, real asset records, credentials, or
  third-party material without a licence file under `LICENSES/`.

## Commands

```bash
# validate the page loads / behaviour in the browser IDE
open https://js.rokid.com/craft      # Import → GitHub subdirectory → this repo → Run Agent

# refresh the preview render from the earlier web mockup (optional)
# preview/live.html is a design reference only — it is not the app
```

## Conventions

- Keep one page until there is a second real workflow; do not scaffold pages,
  widgets or agent workers speculatively.
- Data lives in a `STEPS` array at the top of `index.ink`; add a step by adding an
  object, not by branching in markup.
- Keep the diff small and readable; this repo is read by Rokid's developer
  relations team.
