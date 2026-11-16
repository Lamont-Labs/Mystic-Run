#!/usr/bin/env python3
"""Exercise the compiled Defold WASM engine, not a JavaScript game substitute."""
import argparse
import json
import os
from pathlib import Path
import shutil
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"generated-artifacts/defold-knight/review"


def main(url):
    OUT.mkdir(parents=True,exist_ok=True)
    os.environ.setdefault("PLAYWRIGHT_NODEJS_PATH",shutil.which("node") or "node")
    logs=[]
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path=shutil.which("chromium"),headless=True,
            args=["--no-sandbox","--use-gl=angle","--use-angle=swiftshader","--enable-unsafe-swiftshader"])
        ctx=browser.new_context(viewport={"width":402,"height":874},device_scale_factor=1,
            is_mobile=True,has_touch=True,record_video_dir=str(OUT/"video"))
        page=ctx.new_page()
        page.on("console",lambda message:logs.append(message.text))
        page.on("pageerror",lambda error:logs.append("PAGEERROR "+str(error)))
        results={}
        try:
            page.goto(url,wait_until="networkidle",timeout=90000)
            frame=page.frame_locator("#game")
            child=page.locator("#game").element_handle().content_frame()
            child.wait_for_function("window.__MYSTICRUN_STATE",timeout=60000)
            state=lambda:child.evaluate("window.__MYSTICRUN_STATE")
            results["initial"]=state()
            assert state()["state"]=="ready"
            page.screenshot(path=str(OUT/"01-ready.jpg"))
            canvas=frame.locator("#canvas")
            rect=canvas.bounding_box()
            def tap(x,y):
                page.touchscreen.tap(rect["x"]+rect["width"]*x/720,
                    rect["y"]+rect["height"]*(1280-y)/1280)
            tap(360,663)
            child.wait_for_function("window.__MYSTICRUN_STATE.state==='running'")
            tap(196,104)
            child.wait_for_function("window.__MYSTICRUN_STATE.x>.90")
            results["touch_lane"]=state()
            tap(357,104)
            child.wait_for_function("window.__MYSTICRUN_STATE.height>.6")
            page.screenshot(path=str(OUT/"02-jump.jpg"))
            child.wait_for_function("window.__MYSTICRUN_STATE.height===0")
            tap(518,104)
            child.wait_for_function("window.__MYSTICRUN_STATE.crouch>.55")
            page.screenshot(path=str(OUT/"03-slide.jpg"))
            tap(649,104)
            child.wait_for_function("window.__MYSTICRUN_STATE.attacks>0")
            results["actions"]=state()
            tap(626,1075)
            child.wait_for_function("window.__MYSTICRUN_STATE.state==='paused'")
            before=state()["distance"]
            page.wait_for_timeout(350)
            assert state()["distance"]==before
            results["paused_distance"]=before
            tap(360,663)
            child.wait_for_function("window.__MYSTICRUN_STATE.state==='running'")
            # Keyboard receives actual browser events, not state injection.
            canvas.focus()
            page.keyboard.press("ArrowLeft")
            child.wait_for_function("window.__MYSTICRUN_STATE.lane===0")
            page.keyboard.press("ArrowLeft")
            child.wait_for_function("window.__MYSTICRUN_STATE.lane===-1")
            page.keyboard.press("ArrowUp")
            child.wait_for_function("window.__MYSTICRUN_STATE.jumps>=2")
            page.wait_for_timeout(450)
            page.screenshot(path=str(OUT/"04-running.jpg"))
            # Restart through real input, then allow the three centre-lane
            # teaching obstacles to hit. Exercise defeat and touch recovery.
            page.keyboard.press("r")
            child.wait_for_function("window.__MYSTICRUN_STATE.distance<5")
            child.wait_for_function("window.__MYSTICRUN_STATE.state==='defeat'",timeout=24000)
            results["defeat"]=state()
            page.screenshot(path=str(OUT/"05-defeat.jpg"))
            tap(360,663)
            child.wait_for_function("window.__MYSTICRUN_STATE.state==='running' && window.__MYSTICRUN_STATE.hp===3")
            results["restart"]=state()
            assert not [line for line in logs if "ERROR:SCRIPT" in line or "PAGEERROR" in line],logs[-12:]
            results["status"]="passed"
        except Exception:
            page.screenshot(path=str(OUT/"failure.jpg"))
            results["status"]="failed"
            raise
        finally:
            (OUT/"browser-console.json").write_text(json.dumps(logs,indent=2))
            (OUT/"browser-results.json").write_text(json.dumps(results,indent=2))
            ctx.close();browser.close()
            print(json.dumps(results,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--url",required=True)
    main(parser.parse_args().url)
