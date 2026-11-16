#!/usr/bin/env python3
"""Reproducible isolated Defold trial. Web/Linux bundles; Android compile ONLY."""
import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import time
import urllib.request
from PIL import Image, ImageDraw, ImageFilter
from verify_defold_build import BOB_URL, BOB_SHA256, digest

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "generated-artifacts/defold-knight"
SOURCE = ROOT / "experiments/defold-knight"


def lua(value):
    if isinstance(value, dict):
        return "{" + ",".join(f'[{json.dumps(k)}]={lua(v)}' for k, v in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ",".join(lua(v) for v in value) + "}"
    return json.dumps(value)


def prepare():
    project = OUT / "project"
    shutil.copytree(SOURCE, project, dirs_exist_ok=True, ignore=shutil.ignore_patterns("web"))
    art = project / "art"
    art.mkdir(parents=True, exist_ok=True)
    rig = json.loads((ROOT / "experiments/knight_rig/art/rig.json").read_text())
    original = ROOT / rig["source"]
    if digest(original) != rig["source_sha256"]:
        raise RuntimeError("Approved Knight source hash changed")
    sheet = Image.open(ROOT / "experiments/knight_rig/art/knight_layers.png").convert("RGBA")
    for p in rig["parts"]:
        x, y, w, h = p["region"]
        sheet.crop((x, y, x+w, y+h)).save(art / f'p_{p["name"]}.png')
    (art / "rig.lua").write_text("return " + lua(rig) + "\n")
    vista = Image.open(ROOT / "assets/environment/living-world/castle_vista.jpg")
    vista.resize((1024, 1024)).save(art / "vista.png")
    stone = Image.open(ROOT / "assets/environment/living-world/castle_stone.jpg").convert("RGBA")
    stone = stone.resize((512, 512))
    draw = ImageDraw.Draw(stone)
    # Reuse the painted stone texture; add lane inlays, not new character artwork.
    for x in (10, 174, 338, 500):
        draw.line((x, 0, x, 512), fill=(214, 173, 85, 190), width=3)
    for y in range(0, 512, 128):
        draw.line((0, y, 512, y), fill=(40, 42, 55, 160), width=3)
    for i in range(32):
        stone.crop((0, i*16, 512, i*16+16)).save(art / f"strip_{i:02}.png")
    def image(name, size, paint):
        im = Image.new("RGBA", size)
        paint(im, ImageDraw.Draw(im))
        im.save(art / (name + ".png"))
    def coin(im,d):
        d.ellipse((13,13,115,115),fill=(52,168,183,45),outline=(246,204,107),width=8)
        d.ellipse((24,24,104,104),fill=(43,91,135,230),outline=(255,238,174),width=3)
        d.polygon([(64,31),(75,55),(99,64),(75,73),(64,98),(54,73),(30,64),(54,55)],fill=(255,226,138))
    image("coin",(128,128),coin)
    def hurdle(im,d):
        im.alpha_composite(stone.resize((108,76)),(10,38))
        d.rounded_rectangle((10,38,118,114),radius=9,outline=(235,195,112),width=5)
        d.rectangle((18,32,110,45),fill=(190,170,140),outline=(245,212,145),width=3)
        d.line((18,71,109,71),fill=(56,53,61),width=3)
        d.polygon([(64,48),(76,70),(64,93),(52,70)],fill=(97,180,198),outline=(255,223,140))
    image("hurdle",(128,128),hurdle)
    def arch(im,d):
        for x in (7,99):
            d.rounded_rectangle((x,27,x+23,184),radius=5,fill=(103,107,125),outline=(225,194,123),width=3)
            d.rectangle((x-3,167,x+26,186),fill=(197,177,131))
        d.rounded_rectangle((0,12,127,62),radius=9,fill=(103,56,91),outline=(247,203,112),width=5)
        d.polygon([(64,25),(73,38),(64,53),(55,38)],fill=(249,216,147))
    image("arch",(128,192),arch)
    def ward(im,d):
        d.ellipse((12,8,116,119),fill=(91,56,172,40),outline=(217,177,251),width=3)
        d.polygon([(64,12),(102,62),(64,110),(25,62)],fill=(113,89,194),outline=(251,214,138),width=4)
        d.polygon([(64,12),(64,110),(46,60)],fill=(174,149,240))
        d.line((35,86,94,38),fill=(246,225,181),width=4)
    image("ward",(128,128),ward)
    def rail(im,d):
        d.polygon([(12,18),(26,18),(32,92),(6,92)],fill=(122,132,154),outline=(238,205,133))
        d.ellipse((7,6,31,30),fill=(100,182,197),outline=(246,217,140),width=3)
        d.rectangle((3,85,35,96),fill=(199,173,121))
    image("rail",(40,100),rail)
    def panel(im,d):
        d.rounded_rectangle((2,2,125,125),radius=17,fill=(255,255,255),outline=(255,255,255),width=2)
    image("panel",(128,128),panel)
    image("shadow",(128,32),lambda im,d:d.ellipse((1,1,126,30),fill=(255,255,255,170)))
    image("spark",(16,16),lambda im,d:d.ellipse((3,3,13,13),fill=(255,255,255,210)))
    image("veil",(16,128),lambda im,d:[
        d.line((0,y,16,y),fill=(255,255,255,int(255*y/127))) for y in range(128)])
    for name, original_font in (("ui","manrope"),("title","cinzel")):
        shutil.copyfile(ROOT / f"assets/fonts/{original_font}.ttf", art / f"{name}.ttf")
        shutil.copyfile(ROOT / f"assets/fonts/{original_font}-OFL.txt", art / f"{name}-OFL.txt")
        (art / f"{name}.font").write_text(
            f'font: "/art/{name}.ttf"\nmaterial: "/builtins/fonts/font-df.material"\n'
            'size: 32\nantialias: 1\noutput_format: TYPE_DISTANCE_FIELD\n'
            'characters: " !\\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~•"\n'
        )
    (art / "game.atlas").write_text(
        "".join(f'images {{ image: "/art/{p.name}" }}\n' for p in sorted(art.glob("*.png")))
        + "margin: 0\ninner_padding: 0\nextrude_borders: 2\n"
    )
    provenance = {
        "restriction": "Noncommercial concept use only. No AI repaint or new character poses.",
        "knight_source": rig["source"], "source_sha256": rig["source_sha256"],
        "layer_source": "experiments/knight_rig/art/knight_layers.png",
        "layer_sha256": digest(ROOT / "experiments/knight_rig/art/knight_layers.png"),
        "background": "assets/environment/living-world/castle_vista.jpg",
        "road": "assets/environment/living-world/castle_stone.jpg",
        "fixture_art": "Procedural 2D collision fixtures and relic glyph; not finished environment art",
    }
    (OUT / "provenance.json").write_text(json.dumps(provenance,indent=2)+"\n")
    return project


def execute(args, name, cwd=None):
    start=time.monotonic()
    r=subprocess.run(args,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=360)
    (OUT / name).write_text(r.stdout)
    print(r.stdout,flush=True)
    if r.returncode:
        raise RuntimeError(f"{name} failed: {r.returncode}")
    return round(time.monotonic()-start,3),r.stdout


def build():
    project=prepare()
    bob=OUT / "bob.jar"
    if not bob.exists() or digest(bob)!=BOB_SHA256:
        urllib.request.urlretrieve(BOB_URL,bob)
    if digest(bob)!=BOB_SHA256:
        raise RuntimeError("Bob checksum mismatch")
    base=["java","-jar",str(bob),"--root",str(project),"--max-cpu-threads","2"]
    results={"bob_sha256":BOB_SHA256,"android_apk":False,"android_signing":False}
    results["android_seconds"],_=execute(base+[
        "--platform","armv7-android","--architectures","arm64-android",
        "--output","build/android","--archive","build"],"android.log")
    results["web_seconds"],_=execute(base+[
        "--platform","wasm-web","--architectures","wasm-web",
        "--output","build/web","--archive","--variant","release",
        "--bundle-output",str(OUT / "bundles"),"build","bundle"],"web.log")
    built=OUT / "bundles/MysticRunKnight"
    target=OUT / "web"
    shutil.copytree(built,target / "game",dirs_exist_ok=True)
    shutil.copyfile(SOURCE / "web/index.html",target / "index.html")
    # A restricted same-origin bridge. Commands are consumed by actual Lua code.
    entry=target / "game/index.html"
    bridge="""<script>
    window.__MR_COMMANDS=[];
    addEventListener('message',function(e){
      if(e.origin!==location.origin||e.source!==parent||!e.data||e.data.type!=='mysticrun-command')return;
      if(['pause','resume','restart'].includes(e.data.action))window.__MR_COMMANDS.push(e.data.action);
    });
    </script>"""
    entry.write_text(entry.read_text().replace("</body>",bridge+"</body>"))
    # The host's optional backdrop is a copied approved game environment, not a remote URL.
    (target / "assets").mkdir(exist_ok=True)
    shutil.copyfile(ROOT / "assets/environment/living-world/castle_vista.jpg",target / "assets/castle_vista.jpg")
    results["linux_seconds"],_=execute(base+[
        "--platform","x86_64-linux","--output","build/linux","--archive",
        "--variant","headless","--bundle-output",str(OUT / "linux"),"build","bundle"],"linux.log")
    executable=next((OUT / "linux").rglob("*.x86_64"))
    results["smoke_seconds"],logs=execute(
        [str(executable),"--config=prototype.smoke=1"],"runtime.log",executable.parent)
    if "DEFOLD_KNIGHT_CHECKS_PASSED" not in logs:
        raise RuntimeError("Lua regression checks never executed")
    (OUT / "evidence.json").write_text(json.dumps(results,indent=2)+"\n")
    for p in OUT.rglob("*"):
        if p.is_file() and p.suffix in {".keystore",".jks",".apk",".aab"}:
            raise RuntimeError("Unexpected signing or Android package output")
    print(json.dumps(results,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--prepare-only",action="store_true")
    args=parser.parse_args()
    prepare() if args.prepare_only else build()
