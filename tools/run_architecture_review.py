#!/usr/bin/env python3
"""Run matched source snapshots through a real rendered Godot review, not mocks."""
import argparse
import os
from pathlib import Path
import shutil
import socket
import subprocess

BASELINE = "4a168264d15d06ab751571794a08e006858e6552"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--variant", choices=["baseline", "prototype"], required=True)
    parser.add_argument("--renderer", choices=["cutout", "skeletal", "layered"], default="cutout")
    parser.add_argument("--hero", choices=["knight", "gargoyle", "witch"], default="knight")
    parser.add_argument("--mode", choices=["benchmark", "capture", "interactive"], default="benchmark")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--resolution", default="360x640")
    parser.add_argument("--duration", type=float, default=7.0)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    project = root
    godot = args.godot.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if args.variant == "baseline":
        project = root / "generated-artifacts/architecture-validation/baseline-source"
        if not project.exists():
            project.mkdir(parents=True)
            # Read-only source snapshot: no branch/index/worktree administration.
            archive = subprocess.Popen(["git", "archive", BASELINE], cwd=root, stdout=subprocess.PIPE)
            try:
                subprocess.run(["tar", "-xf", "-", "-C", str(project)],
                               stdin=archive.stdout, check=True)
            finally:
                archive.stdout.close()
            if archive.wait():
                raise SystemExit("Failed to archive the pinned baseline")
            (project / ".godot").mkdir(exist_ok=True)
            (project / ".godot/imported").symlink_to(root / ".godot/imported", target_is_directory=True)
        shutil.copytree(root / "experiments/architecture_validation",
                        project / "experiments/architecture_validation", dirs_exist_ok=True)
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        display = probe.getsockname()[1] - 6000
    env = {**os.environ, "DISPLAY": f"127.0.0.1:{display}", "LIBGL_ALWAYS_SOFTWARE": "1"}
    command = [str(godot), "--path", str(project), "--audio-driver", "Dummy",
               "--resolution", args.resolution, "--disable-vsync",
               "--script", "res://experiments/architecture_validation/entry.gd"]
    if args.mode == "capture":
        command += ["--fixed-fps", "30"]
    if args.mode == "interactive":
        # Interactive mode uses the owner's desktop display, not a hidden Xvfb.
        if not os.environ.get("DISPLAY"):
            raise SystemExit("Interactive play requires a desktop display; use capture for workspace evidence.")
        env = os.environ.copy()
    command += ["--", f"--lab-mode={args.mode}", f"--lab-variant={args.variant}",
                f"--lab-renderer={args.renderer}", f"--lab-hero={args.hero}",
                f"--lab-duration={args.duration}",
                f"--lab-output={output}", f"--capture-dir={output}"]
    if args.mode == "interactive":
        subprocess.run(command, cwd=project, env=env, check=True)
        return
    xvfb = shutil.which("Xvfb")
    if not xvfb:
        raise SystemExit("Xvfb is required for rendered capture/benchmarks.")
    server = subprocess.Popen([xvfb, f":{display}", "-screen", "0", "720x1280x24",
                               "-ac", "-nolisten", "unix", "-listen", "tcp"],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        # Import is also a readiness handshake with the display; no fixed sleeps.
        with (output / "game.log").open("w") as log:
            subprocess.run([str(godot), "--headless", "--editor", "--path", str(project), "--import"],
                           cwd=project, env=env, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=120)
            subprocess.run(command, cwd=project, env=env, stdout=log,
                           stderr=subprocess.STDOUT, check=True, timeout=120)
    finally:
        server.terminate()
        server.wait(timeout=10)
    print(f"{args.variant} {args.renderer} {args.hero}: {output}")


if __name__ == "__main__":
    main()
