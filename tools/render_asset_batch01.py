#!/usr/bin/env python3
"""Capture the standalone asset candidates with a real Godot desktop renderer."""
from __future__ import annotations
import argparse
import os
from pathlib import Path
import socket
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--xorg-config',type=Path,default=Path('/etc/X11/xorg.conf'))
    args=parser.parse_args();out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
    with socket.socket() as probe:
        probe.bind(('127.0.0.1',0));port=probe.getsockname()[1]
    display=port-6000
    if display<=0:raise RuntimeError('No valid display allocation')
    env=dict(os.environ,DISPLAY=f'127.0.0.1:{display}',LIBGL_ALWAYS_SOFTWARE='1')
    with (out/'display.log').open('w') as logfile:
        server=subprocess.Popen(['Xorg',f':{display}','-config',str(args.xorg_config.resolve()),'-noreset','-ac','-nolisten','unix','-nolisten','local','-listen','tcp','-extension','MIT-SHM','-logfile',str(out/'xorg.log')],stdout=logfile,stderr=subprocess.STDOUT,env=env)
        try:
            for _ in range(60):
                if server.poll() is not None:raise RuntimeError('Review display startup failed')
                try:
                    with socket.create_connection(('127.0.0.1',port),.2):break
                except OSError:time.sleep(.1)
            else:raise RuntimeError('Review display did not become ready')
            command=[str(args.godot.resolve()),'--path',str(ROOT/'art/asset_batch_01/review'),'--audio-driver','Dummy','--resolution','960x960','--fixed-fps','30','--disable-vsync','--','--capture-dir='+str(out)]
            with (out/'game.log').open('w') as log:
                run=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
            if run.returncode:raise RuntimeError('Asset capture failed; inspect game.log')
            print((out/'game.log').read_text())
        finally:
            server.terminate();server.wait(timeout=10)


if __name__=='__main__':main()
