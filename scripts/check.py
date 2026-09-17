#!/usr/bin/env python3
"""Self-check for the AIUI page: manifest JSON, page logic syntax, hooks, spec compliance.

Run:  python3 scripts/check.py
Exits non-zero on any failure. Needs `node` on PATH for the JS syntax check.

Rules encoded here come from the AIUI delivery checklist + the monochrome-green
design spec; each one exists because it was once violated by hand.
"""
import json
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
INK = ROOT / "pages/index/index.ink"
APP = ROOT / "app.json"

# Luminance ladder from the design spec. 100% is expressed as the #40ff5e hex itself.
ALPHA_LADDER = {0.72, 0.48, 0.24, 0.12, 0.06}

# Type ladder. 18 = compact branch for the chat-card hosting slot, 30/44 = the large
# data numeral (display sizes, not running text) — both documented as intentional.
TYPE_LADDER = {10, 11, 12, 13, 14, 16, 22}
TYPE_LADDER_DISPLAY = {18, 30, 44}

BANNED_CSS = ("box-shadow", "animation", "@keyframes", "position: sticky", "position:sticky")
BANNED_JS = ("a:for", "a:if", "wx:for", "wx:if", "Widget(")
HOOKS = ("onLoad(options)", "onVoiceWakeup(event)", "onKeyUp(event)", "finish()")


def block(src: str, open_tag: str) -> str:
    m = re.search(re.escape(open_tag) + r"(.*?)</script>", src, re.S)
    assert m, f"找不到 {open_tag} 區塊"
    return m.group(1)


def main() -> int:
    src = INK.read_text(encoding="utf-8")
    fails = []

    def ok(msg):
        print("✓", msg)

    # 1) <script def> 必須係合法 JSON
    try:
        manifest = json.loads(block(src, "<script def>"))
        assert "navigationBarTitleText" in manifest
        ok("<script def> JSON 合法")
    except Exception as e:
        fails.append(f"<script def> JSON: {e}")

    # 2) app.json 指向嘅 page 要真存在
    try:
        pages = json.loads(APP.read_text(encoding="utf-8"))["pages"]
        for p in pages:
            assert (ROOT / f"{p}.ink").exists(), f"app.json 指住 {p} 但冇 {p}.ink"
        ok(f"app.json 嘅 {len(pages)} 個 page 都存在")
    except Exception as e:
        fails.append(f"app.json: {e}")

    # 2b) page 級 render-time 契約:description + schema.data(冇就 LLM route 唔到)
    try:
        m = json.loads(block(src, "<script def>"))
        assert isinstance(m.get("description"), str) and len(m["description"]) > 20, \
            "description 缺失或太短(要 observable)"
        props = m.get("schema", {}).get("data", {}).get("properties")
        assert isinstance(props, dict) and props, "schema.data.properties 缺失"
        assert "step" in props, "schema.data 未聲明 step"
        ok(f"render-time 契約齊(description + schema.data.step)")
    except Exception as e:
        fails.append(f"page 契約: {e}")

    # 3) <script setup> JS 語法
    tmp = pathlib.Path(tempfile.mkdtemp()) / "page.js"
    tmp.write_text(block(src, "<script setup>"), encoding="utf-8")
    r = subprocess.run(["node", "--check", str(tmp)], capture_output=True, text=True)
    if r.returncode == 0:
        ok("<script setup> JS 語法合法")
    else:
        fails.append(f"JS 語法: {r.stderr.strip().splitlines()[-1] if r.stderr else '?'}")

    # 4) agent 必需嘅 hook
    missing = [h for h in HOOKS if h not in src]
    if missing:
        fails.append(f"唔見 hook: {missing}")
    else:
        ok(f"{len(HOOKS)} 個必需 hook 齊")

    # 5) 控制指令前綴 + 其他禁用 pattern
    bad = [w for w in BANNED_JS if w in src]
    if bad:
        fails.append(f"用咗禁用 pattern(會靜靜哋唔 render): {bad}")
    else:
        assert "ink:for" in src or "ink:if" in src
        ok("冇 a:/wx: 前綴,冇 Widget()")

    # 6) <page> 單一根,冇同 <widget> 混
    if src.count("<page>") == 1 and "<widget" not in src:
        ok("<page> 單一根")
    else:
        fails.append("page 結構:<page> 唔係唯一根或者混咗 <widget>")

    # 7) 亮度階:所有 rgba(64,255,94,α) 要喺 ladder 內(或者用 #40ff5e = 100%)
    alphas = set(re.findall(r"rgba\(64, 255, 94, ([0-9.]+)\)", src))
    off = sorted(a for a in alphas if float(a) not in ALPHA_LADDER)
    if off:
        fails.append(f"alpha 唔喺亮度階 {sorted(ALPHA_LADDER)}: {off}")
    else:
        ok(f"亮度階合規(用到 {sorted(alphas, key=float)})")

    # 8) 字級階
    sizes = {int(x) for x in re.findall(r"font-size: (\d+)px", src)}
    off = sorted(sizes - TYPE_LADDER - TYPE_LADDER_DISPLAY)
    if off:
        fails.append(f"字級唔喺 ladder: {off}")
    else:
        ok(f"字級合規(display 例外 {sorted(sizes & TYPE_LADDER_DISPLAY)})")

    # 9) 禁用 CSS
    hits = [w for w in BANNED_CSS if w in src]
    if hits:
        fails.append(f"用咗禁用 CSS(唔准用 shadow/animation 做深度): {hits}")
    else:
        ok("冇 box-shadow / animation / sticky")

    # 10) setTimeout 一定要有 clearTimeout(唔好喺 onHide 之後仲 fire)
    if "setTimeout" in src:
        if "clearTimeout" in src and "onHide()" in src:
            ok("timer 有 handle + onHide cleanup")
        else:
            fails.append("有 setTimeout 但冇 clearTimeout / onHide cleanup")
    else:
        ok("冇 timer,唔需要 cleanup")

    # 11) 模擬聲明唔可以漏
    if "SIMULATION" in src:
        ok("保留 SIMULATION 聲明")
    else:
        fails.append("漏咗 SIMULATION 聲明")

    if fails:
        print("\n❌ FAIL")
        for f in fails:
            print("  -", f)
        return 1
    print("\nALL CHECKS PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
