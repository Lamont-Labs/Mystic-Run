#!/usr/bin/env python3
"""Package actual native renders and raw measurements for owner evaluation."""
import base64
import hashlib
import html
import json
import re
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "generated-artifacts/knight-rig"
OUT = BASE / "delivery"
FONT = ImageFont.load_default(size=17)


def panel(left, right):
    image = Image.new("RGB", (720, 712), "#181622")
    d = ImageDraw.Draw(image)
    d.text((10, 9), "Previous whole-image cutout", font=FONT, fill="#ffdd99")
    d.text((370, 9), "New jointed 2D Knight", font=FONT, fill="#ffdd99")
    for x, path in [(0, left), (360, right)]:
        with Image.open(path) as source:
            image.paste(source.convert("RGB"), (x, 34))
    d.text((12, 684), "Actual game replay · fixed clock · not phone FPS", font=FONT, fill="#eee5ff")
    return image


def uri(path, mime):
    return "data:" + mime + ";base64," + base64.b64encode(path.read_bytes()).decode()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    old = sorted((BASE / "final/cutout-capture").glob("lab-*.png"))
    new = sorted((BASE / "final/layered-capture").glob("lab-*.png"))
    assert len(old) == len(new) and len(new) > 120
    video = OUT / "Knight_Actual_Gameplay_Comparison.mp4"
    process = subprocess.Popen([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-f", "rawvideo",
        "-pixel_format", "rgb24", "-video_size", "720x712", "-framerate", "20",
        "-i", "-", "-an", "-c:v", "libx264", "-threads", "2", "-pix_fmt", "yuv420p",
        "-movflags", "+faststart", str(video)], stdin=subprocess.PIPE)
    for a, b in zip(old, new):
        process.stdin.write(panel(a, b).tobytes())
    process.stdin.close()
    if process.wait():
        raise RuntimeError("Game comparison encoding failed")
    panel(old[44], new[44]).save(OUT / "Knight_Gameplay_Comparison.jpg", quality=94)

    # Contact sheet and loop come from Godot's transparent SubViewport renders.
    poses = BASE / "final-poses"
    sheet = Image.new("RGB", (1024, 1280), "#282332")
    draw = ImageDraw.Draw(sheet)
    for i in range(16):
        x, y = (i % 4) * 256, (i // 4) * 320
        with Image.open(poses / f"run-{i:02}.png") as source:
            thumb = source.convert("RGBA")
            thumb.thumbnail((256, 288))
            sheet.paste(thumb, (x + (256 - thumb.width) // 2, y + 22), thumb)
        draw.text((x + 10, y + 5), f"Native rig phase {i + 1:02}/16", font=FONT, fill="#ffdd99")
    sheet.save(OUT / "Knight_16_Run_Phases.jpg", quality=93)
    loop = OUT / "Knight_Run_Closeup.mp4"
    subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-stream_loop", "5",
                    "-framerate", "34.4", "-i", str(poses / "run-%02d.png"),
                    "-vf", "format=rgb24,pad=384:448:0:0:color=0x282332",
                    "-c:v", "libx264", "-threads", "2", "-pix_fmt", "yuv420p",
                    "-movflags", "+faststart", str(loop)], check=True)
    actions = ["idle", "jump", "fall", "land", "slide", "attack", "damage", "power", "victory", "defeat"]
    sheet = Image.new("RGB", (1280, 640), "#282332")
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(actions):
        x, y = i % 5 * 256, i // 5 * 320
        with Image.open(poses / (name + ".png")) as source:
            thumb = source.convert("RGBA");thumb.thumbnail((256, 288))
            sheet.paste(thumb, (x + (256 - thumb.width) // 2, y + 25), thumb)
        draw.text((x + 12, y + 5), name.upper() + " · pose preview", font=FONT, fill="#ffdd99")
    sheet.save(OUT / "Knight_Action_Poses.jpg", quality=93)
    reports = {name: json.loads((BASE / "final" / name / "report.json").read_text())
               for name in ["cutout-capture", "cutout-benchmark", "layered-capture", "layered-benchmark"]}
    files = ["experiments/knight_rig/rig.gd", "experiments/knight_rig/motion.gd",
             "experiments/knight_rig/art/knight_layers.png", "experiments/knight_rig/art/rig.json",
             "experiments/architecture_validation/lab.gd", "tools/build_knight_layers.py"]
    evidence = {"reports": reports, "source_sha256": {
        name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in files},
        "limits": "One descriptive Linux llvmpipe sample per renderer, no phone test; pose previews are not gameplay action verification.",
        "tests": {"native_joint_and_foot_checks": 468, "movement_controls": 238,
                  "concept_assets": 156, "legacy_rig": 29, "runner_controls": 38}}
    raw = json.dumps(evidence, indent=2) + "\n"
    (OUT / "Knight_Measurements.json").write_text(raw)
    (ROOT / "tests/evidence/knight-layered-rig.json").write_text(raw)
    rows = []
    for name in ["cutout-benchmark", "layered-benchmark"]:
        r = reports[name]
        rows.append(f"<tr><td>{name}</td><td>{r['mean_fps']:.2f}</td><td>{r['frame_interval_ms']['p95']:.1f}</td><td>{r['health']}</td></tr>")
    content = """<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>MysticRun — one layered Knight experiment</title><style>
body{margin:0;background:#171420;color:#f0e9fa;font:17px/1.6 system-ui}main{max-width:1080px;margin:auto;padding:28px}
h1,h2{color:#ffdd99}section{background:#252030;padding:24px;border-radius:16px;margin:24px 0}
video,img{max-width:100%;height:auto}video{display:block;width:100%;margin:auto;max-height:760px}table{width:100%;border-collapse:collapse}
th,td{text-align:left;padding:12px;border-bottom:1px solid #57445f}code{overflow-wrap:anywhere}
</style><main><h1>One concept-faithful, jointed 2D Knight</h1>
<p>Playable rear-view experiment only. Fourteen original painted parts; native Godot Skeleton2D;
planted ankles, rear-view leg foreshortening, independent head, cape, shield, arm and sword.
No new generated design and no whole-image action crossfade.</p>
<section><h2>Actual game: matched movement sequence</h2>
<p>Same Castle camera and controls. Pad movement/release, rapid reversal, jumps, slides, conflicting
commands and attack. Fixed-clock captures do not show actual device FPS.</p>
<video controls preload="metadata" poster="GAME" src="VIDEO"></video><img alt="Actual jumping gameplay comparison" src="GAME"></section>
<section><h2>Sixteen distinct native-rig run phases</h2><p>These are samples of continuous joint animation,
not sixteen independently painted frames. The close-up loop is not gameplay footage.</p>
<video controls loop preload="metadata" src="LOOP"></video><img alt="16 run poses rendered by Godot" src="RUN"></section>
<section><h2>Authored action targets</h2><p>Pose previews only; the actual game sequence above exercises running,
jumping, falling, landing, sliding and attack. Damage, power, victory and defeat targets were rendered
in isolation, not claimed as end-to-end gameplay verification.</p><img alt="Ten isolated action poses" src="ACTIONS"></section>
<section><h2>Measured, not approved for production</h2><p>360×640 Linux Mesa llvmpipe/Xvfb, one seven-second
simulation per case after 0.8 s warm-up. No phone hardware, physical touch latency, battery or Android FPS test.</p>
<table><tr><th>Renderer</th><th>Mean FPS</th><th>p95 frame ms</th><th>Health</th></tr>ROWS</table>
<p>The samples do not establish a performance improvement. Native rig checks validate numerical foot targets,
not artistic quality or pixel-perfect contact with a curved road.</p></section>
<section><h2>Limitations and next decision</h2><p>This is a rigid layered-painting prototype, not a finished
deformable production character. It uses one rear painting: no front/side artwork or concealed surfaces were invented.
Limb cuts and cape layering still need artistic review; full action polish, physical-phone profiling and production
integration are not approved by this experiment. All normal gameplay, artwork, saves, Android identity and signing
remain untouched. No APK or release was made.</p><p>Open <code>experiments/knight_rig/playable.tscn</code>
in Godot 4.7.2 and press F6. R cycles the three rendering paths. Test profile only.</p></section></main></html>"""
    media = {
        "VIDEO": uri(video, "video/mp4"), "GAME": uri(OUT / "Knight_Gameplay_Comparison.jpg", "image/jpeg"),
        "LOOP": uri(loop, "video/mp4"), "RUN": uri(OUT / "Knight_16_Run_Phases.jpg", "image/jpeg"),
        "ACTIONS": uri(OUT / "Knight_Action_Poses.jpg", "image/jpeg"), "ROWS": "".join(rows)
    }
    # One substitution pass: short words such as RUN also occur in base64.
    # Repeated global replace would corrupt previously embedded video bytes.
    content = re.sub(r"\b(?:VIDEO|GAME|LOOP|RUN|ACTIONS|ROWS)\b",
                     lambda match: media[match.group()], content)
    embedded = re.findall(r'src="data:video/mp4;base64,([^"]+)"', content)
    assert [base64.b64decode(value) for value in embedded] == [video.read_bytes(), loop.read_bytes()]
    (OUT / "Knight_Rig_Review.html").write_text(content)
    print("Packaged matched native-game video, actual joint renders, source hashes and raw measurements")


if __name__ == "__main__":
    main()
