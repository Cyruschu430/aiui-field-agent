#!/usr/bin/env python3
"""Self-check for the AIUI page: manifest JSON, page logic syntax, required hooks.

Run:  python3 scripts/check.py
Exits non-zero on any failure. Needs `node` on PATH for the syntax check.
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


def block(src: str, open_tag: str) -> str:
    m = re.search(re.escape(open_tag) + r"(.*?)</script>", src, re.S)
    assert m, f"找不到 {open_tag} 區塊"
    return m.group(1)


def main() -> int:
    src = INK.read_text(encoding="utf-8")
    fails = []

    # 1) <script def> 必須係合法 JSON
    try:
        manifest = json.loads(block(src, "<script def>"))
        assert "navigationBarTitleText" in manifest
        print("✓ <script def> JSON 合法")
    except Exception as e:
        fails.append(f"<script def> JSON: {e}")

    # 2) app.json 指向嘅 page 要真存在
    try:
        pages = json.loads(APP.read_text(encoding="utf-8"))["pages"]
        for p in pages:
            f = ROOT / f"{p}.ink"
            assert f.exists(), f"app.json 指住 {p} 但冇 {f}"
        print(f"✓ app.json 嘅 {len(pages)} 個 page 都存在")
    except Exception as e:
        fails.append(f"app.json: {e}")

    # 3) <script setup> JS 語法
    tmp = pathlib.Path(tempfile.mkdtemp()) / "page.js"
    tmp.write_text(block(src, "<script setup>"), encoding="utf-8")
    r = subprocess.run(["node", "--check", str(tmp)], capture_output=True, text=True)
    if r.returncode == 0:
        print("✓ <script setup> JS 語法合法")
    else:
        fails.append(f"JS 語法: {r.stderr.strip().splitlines()[-1] if r.stderr else '?'}")

    # 4) agent 必需嘅 hook
    for hook in ("onLoad(options)", "onVoiceWakeup(event)", "onKeyUp(event)", "finish()"):
        if hook in src:
            print(f"✓ hook 在: {hook}")
        else:
            fails.append(f"唔見 hook: {hook}")

    # 5) 控制指令前綴:一定係 ink:,唔可以有 a:/wx:
    bad = [w for w in ("a:for=", "a:if=", "wx:for=", "wx:if=") if w in src]
    if bad:
        fails.append(f"用錯控制指令前綴(會靜靜哋唔 render): {bad}")
    else:
        assert "ink:for" in src or "ink:if" in src
        print("✓ 控制指令全部用 ink: 前綴")

    # 6) 模擬聲明唔可以漏
    if "SIMULATION" in src:
        print("✓ 保留 SIMULATION 聲明")
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
