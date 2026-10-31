#!/usr/bin/env python3
"""Render the actual game in an isolated Xvfb and capture game-owned frames."""
import argparse
import os
from pathlib import Path
import shutil
import socket
import subprocess
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--xvfb', default=shutil.which('Xvfb'))
    parser.add_argument('--library-path')
    parser.add_argument('--drivers-path')
    parser.add_argument('--font-path')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--character', choices=['knight','gargoyle','witch'], default='knight')
    parser.add_argument('--qa-ticks', type=int, default=0)
    parser.add_argument('--frames', type=int, default=150)
    parser.add_argument('--resolution', default='540x960')
    parser.add_argument('--screen', default='home')
    parser.add_argument('--navigation',action='store_true')
    args = parser.parse_args()
    if not args.xvfb:
        raise SystemExit('Xvfb is required for actual rendered previews')
    root = Path(__file__).resolve().parents[1]
    args.output.mkdir(parents=True, exist_ok=True)
    with socket.socket() as probe:
        probe.bind(('127.0.0.1',0))
        port = probe.getsockname()[1]
    display = port - 6000
    if display <= 0:
        raise SystemExit('Invalid display allocation')
    env = os.environ.copy()
    env.update({'DISPLAY':f'127.0.0.1:{display}','LIBGL_ALWAYS_SOFTWARE':'1'})
    if args.library_path:
        env['LD_LIBRARY_PATH'] = args.library_path
    if args.drivers_path:
        env['LIBGL_DRIVERS_PATH'] = args.drivers_path
    xcommand = [args.xvfb,f':{display}','-screen','0','720x1280x24','-ac','-nolisten','unix','-nolisten','local','-listen','tcp','-extension','MIT-SHM']
    if args.font_path:
        xcommand += ['-fp',args.font_path]
    with (args.output/'display.log').open('w') as xlog:
        server = subprocess.Popen(xcommand,env=env,stdout=xlog,stderr=subprocess.STDOUT)
        try:
            for _ in range(60):
                if server.poll() is not None:
                    raise RuntimeError('Virtual display failed; inspect display.log')
                try:
                    with socket.create_connection(('127.0.0.1',port),.2):
                        break
                except OSError:
                    time.sleep(.1)
            else:
                raise RuntimeError('Virtual display did not become ready')
            command = [str(args.godot),'--path',str(root),'--audio-driver','Dummy','--resolution',args.resolution]
            if args.navigation:
                command += ['--script','res://tests/gameplay_navigation.gd']
            if not args.qa_ticks and not args.navigation:
                command += ['--quit-after',str(args.frames)]
            command += ['--',f'--capture-dir={args.output}',f'--character={args.character}']
            command += ['--qa',f'--qa-ticks={args.qa_ticks}'] if args.qa_ticks else [] if args.navigation else ['--qa-menu',f'--screen={args.screen}']
            with (args.output/'game.log').open('w') as log:
                run = subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=360 if args.qa_ticks or args.navigation else 60)
            print(f'Render exit={run.returncode}; output={args.output}')
            return run.returncode
        finally:
            server.terminate()
            server.wait(timeout=8)


if __name__ == '__main__':
    raise SystemExit(main())
