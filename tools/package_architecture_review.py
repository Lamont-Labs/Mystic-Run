#!/usr/bin/env python3
"""Package measured native-game evidence; no generated art or invented timings."""
import base64
import hashlib
import html
import json
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "generated-artifacts/architecture-validation"
OUT = BASE / "delivery"
FONT = ImageFont.load_default(size=16)


def frames(folder):
    return sorted((BASE / folder).glob("lab-*.png"))


def panel(left, right, title_left, title_right):
    canvas = Image.new("RGB", (720, 712), "#15131d")
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 9), title_left, font=FONT, fill="#ffe2a1")
    draw.text((372, 9), title_right, font=FONT, fill="#ffe2a1")
    for x, path in [(0, left), (360, right)]:
        with Image.open(path) as source:
            canvas.paste(source.convert("RGB").resize((360, 640)), (x, 34))
    draw.text((12, 683), "Actual fixed-rate game replay · not a phone FPS test", font=FONT, fill="#d8d2e6")
    return canvas


def movie(left, right, filename, labels):
    command = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-f", "rawvideo",
               "-pixel_format", "rgb24", "-video_size", "720x712", "-framerate", "20",
               "-i", "-", "-an", "-c:v", "libx264", "-threads", "2",
               "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(OUT / filename)]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    for a, b in zip(left, right):
        process.stdin.write(panel(a, b, *labels).tobytes())
    process.stdin.close()
    if process.wait():
        raise SystemExit("Failed to encode real-game comparison")


def data_uri(path, mime):
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    mapping = {
        "baseline_cutout": "final/baseline-cutout-benchmark",
        "baseline_skeletal": "final/baseline-skeletal-benchmark",
        "prototype_cutout": "candidate/prototype-cutout-benchmark",
        "prototype_skeletal": "candidate/prototype-skeletal-benchmark",
        "baseline_gargoyle": "final/baseline-gargoyle-capture",
        "prototype_gargoyle": "candidate/prototype-gargoyle-capture",
        "prototype_witch": "candidate/prototype-witch-capture",
    }
    reports = {key: json.loads((BASE / folder / "report.json").read_text())
               for key, folder in mapping.items()}
    source_files = [
        "game/main.gd", "game/hero.gd", "game/rig_motion.gd", "game/cutout_motion.gd",
        "game/runner_steering.gd", "game/gesture_input.gd", "game/steering_pad.gd",
        "game/world.gd", "assets/shaders/cutout_motion.gdshader",
        "experiments/architecture_validation/lab.gd",
        "experiments/architecture_validation/camera_rig.gd",
        "experiments/architecture_validation/castle_segment.gd",
        "tools/run_architecture_review.py",
    ]
    evidence = {
        "baseline_commit": "4a168264d15d06ab751571794a08e006858e6552",
        "verified_controls_commit": "5af74df",
        "runtime_source_sha256": {
            name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in source_files
        },
        "reports": reports,
        "decision": "Retain Godot; do not approve the current presentation for a full production rebuild. Prototype a properly segmented 2D character rig and profile it on the target phone first.",
        "known_limits": [
            "No Samsung or other physical Android device was measured.",
            "Uncapped software-rendered Linux FPS is not Android performance.",
            "One short run per matrix cell; descriptive evidence, not a statistical performance certification.",
            "Camera, scenery and representation gating change together; FPS differences are not single-component causal measurements.",
            "Cutout quad bounds include transparent pixels; not a rendered pixel-occlusion measurement.",
            "Whole-image transition ghosting and a one-tick slide/fall state flicker remain in the prototype.",
            "The detailed Castle candidate is slower than baseline in the measured software renderer.",
            "Legacy 3D animation is genuine skeletal motion, but its character appearance is not the approved concept.",
        ],
    }
    (OUT / "measurements.json").write_text(json.dumps(evidence, indent=2) + "\n")
    (ROOT / "tests/evidence/architecture-validation.json").write_text(json.dumps(evidence, indent=2) + "\n")
    old = frames("final/baseline-cutout-capture")
    new = frames("candidate/prototype-cutout-capture")
    skeletal = frames("candidate/prototype-skeletal-capture")
    movie(old, new, "movement-before-after.mp4", ("BASELINE · BUILD 2011", "CASTLE PROTOTYPE"))
    movie(new, skeletal, "cutout-versus-skeletal.mp4", ("CONCEPT CUTOUT", "LEGACY SKELETAL MODEL"))
    panel(old[44], new[44], "BASELINE · JUMP / OBSTACLE", "CASTLE CANDIDATE").save(OUT / "castle-before-after.jpg", quality=94)
    panel(new[44], skeletal[44], "CONCEPT CUTOUT", "SKELETAL · MATCHED HEIGHT").save(OUT / "render-path-comparison.jpg", quality=94)
    garg_old = frames("final/baseline-gargoyle-capture")
    garg_new = frames("candidate/prototype-gargoyle-capture")
    panel(garg_old[14], garg_new[14], "GARGOYLE · OLD CAMERA", "GARGOYLE · NEW CAMERA").save(OUT / "gargoyle-framing.jpg", quality=94)

    rows = []
    for key in ["baseline_cutout", "baseline_skeletal", "prototype_cutout", "prototype_skeletal"]:
        report = reports[key]
        frame = report["frame_interval_ms"]
        rows.append(
            f"<tr><th>{html.escape(key.replace('_', ' '))}</th>"
            f"<td>{report['mean_fps']:.2f}</td><td>{frame['p50']:.1f}</td>"
            f"<td>{frame['p95']:.1f}</td><td>{frame['p99']:.1f}</td>"
            f"<td>{report['animation_microbenchmark_us']['p50']:.0f}</td></tr>"
        )
    media = []
    for filename, title in [
        ("movement-before-after.mp4", "Same native input sequence: baseline versus prototype"),
        ("cutout-versus-skeletal.mp4", "Same prototype controls and camera: cutout versus skeletal"),
    ]:
        media.append(f"<section><h2>{title}</h2><video controls playsinline preload='metadata' "
                     f"src='{data_uri(OUT / filename, 'video/mp4')}'></video></section>")
    for filename, title in [
        ("castle-before-after.jpg", "Character, road, obstacle and background together"),
        ("render-path-comparison.jpg", "Rendering paths at matched rest-display height"),
        ("gargoyle-framing.jpg", "Gargoyle: same 1.59 world-height setting, different camera"),
    ]:
        media.append(f"<section><h2>{title}</h2><img alt='{title}' src='{data_uri(OUT / filename, 'image/jpeg')}'></section>")
    page = """<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MysticRun — architecture validation</title>
<style>
body{margin:0;background:#15131d;color:#eee9f5;font:17px/1.6 system-ui,sans-serif}
main{max-width:960px;margin:auto;padding:28px 18px}h1,h2{line-height:1.2;color:#ffe2a1}
section{margin:30px 0;padding:20px;background:#211d2d;border:1px solid #443852;border-radius:12px}
video,img{display:block;width:100%;max-width:720px;height:auto;margin:auto;background:#09080c}
table{border-collapse:collapse;width:100%;font-size:14px}th,td{padding:10px;text-align:left;border-bottom:1px solid #544565}
.table{overflow-x:auto}.warn{border-left:4px solid #ffb173;padding:14px;background:#33252a}
a{color:#8fe7dc}code{overflow-wrap:anywhere}li{margin:9px 0}
</style><main><h1>MysticRun: validate before expanding</h1>
<p><b>Recommendation: retain Godot, change the character-animation approach, and do not authorize the full rebuild yet.</b>
The engine is not shown to be the limiting factor. The current animation presentation and unverified device budget are.</p>
<p class="warn">This is a measured prototype, not a declaration of premium quality.
No APK was built, no branch was merged into main, no saved game was touched, and no signing identity changed.</p>
<section><h2>Measured, not inferred</h2>
<p>360×640, Linux Mesa llvmpipe/Xvfb, V-Sync disabled, seven simulated seconds per case.
One descriptive sample per case; frame intervals exclude the first 0.8 s.
The videos use a separate fixed render clock and must not be used to infer FPS.</p>
<div class="table"><table><thead><tr><th>Case</th><th>Mean FPS</th><th>p50 ms</th><th>p95 ms</th><th>p99 ms</th><th>Animation CPU µs</th></tr></thead><tbody>""" + "".join(rows) + """</tbody></table></div>
<p>The detailed candidate is slower in this renderer. Gating invisible skeletal work saves under 0.1 ms
per isolated animation call, not enough to establish an overall frame-rate win.
These results do not measure or predict Samsung S23 performance.</p></section>
<section><h2>What actually changed</h2><ul>
<li>Latest jump/slide intent owns the action; the old implementation could execute the opposite action.</li>
<li>Thumb input has a neutral deadzone and relinquishes ownership. Release settles into a lane instead of leaving the runner stranded.</li>
<li>Injected steering/jump inputs reach simulation in one 60 Hz tick, about 16.7 ms. This is not physical touch-to-visible-frame latency.</li>
<li>The baseline did not settle to the intended lane within the 500 ms observation window. The prototype settled in about 200 ms.</li>
<li>The new camera reduces conservative maximum quad height from about 34.2% to 25.0% for Knight, and 26.5% to 18.5% for Gargoyle.</li>
<li>Gargoyle's existing 1.59 height was retained. It was not shrunk another 35–40%.</li>
<li>One Castle-only track candidate uses existing painted paving/towers and approved gateway meshes. No three-biome expansion was undertaken.</li>
</ul></section>""" + "".join(media) + """<section><h2>What is not solved</h2><ul>
<li>Whole-image cutout transitions can ghost, and a slide/landing sequence still contains a brief state flicker.</li>
<li>Legacy skeletal models do not reproduce the approved concept. Their smoother joint motion does not make their appearance acceptable.</li>
<li>The Castle candidate still needs artistic acceptance and an Android performance budget. It is not certified premium.</li>
<li>No physical phone was controlled, timed or profiled. No 60 FPS or hardware input-latency claim is made.</li>
</ul></section>
<section><h2>Architecture decision</h2><p>
Keep the existing Godot gameplay, progression and Android release foundation.
Prototype one properly separated, layered 2D Knight rig with meaningful authored motion and native Godot animation blending.
Use one active presentation path; do not keep sampling invisible representations.
Keep real collision dimensions independent from presentation, and validate contact/landing recovery explicitly.
Profile that bounded prototype on the target phone before expanding environments or producing all characters.</p>
<p>Investigate Unity only if a target-device prototype or a specific required production tool demonstrates a Godot limitation.
Changing engines would not supply missing animation artwork, fix incorrect input ownership, or establish concept fidelity.</p>
<p>The playable Godot scene is <code>experiments/architecture_validation/playable.tscn</code>.
Open it in the pinned Godot 4.7.2 editor and press F6. R switches rendering paths; arrows control movement;
Space attacks. The lab uses a test profile, not the owner's saves. See the accompanying repository README for baseline replay commands.</p>
</section></main></html>"""
    (OUT / "MysticRun_Architecture_Review.html").write_text(page)
    print(OUT)


if __name__ == "__main__":
    main()
