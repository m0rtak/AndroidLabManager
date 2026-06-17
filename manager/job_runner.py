#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path


def write(path, text):
    Path(path).write_text(text)


def append(path, text):
    with open(path, 'a', encoding='utf-8', errors='replace') as f:
        f.write(text)
        f.flush()


def main():
    if len(sys.argv) != 2:
        print('usage: job_runner.py JOB_JSON', file=sys.stderr)
        return 2
    cfg_path = Path(sys.argv[1])
    cfg = json.loads(cfg_path.read_text())
    lab_home = Path(cfg['lab_home'])
    log_path = Path(cfg['log_path'])
    status_path = Path(cfg['status_path'])
    title = cfg.get('title', 'Android Lab job')
    env_base = os.environ.copy()
    env_base['LAB_HOME'] = str(lab_home)
    write(status_path, 'running')
    write(log_path, f'[+] Job started: {title}\n')
    code = 0
    for idx, step in enumerate(cfg.get('steps', []), 1):
        args = step.get('args', [])
        env = env_base.copy()
        env.update({k: str(v) for k, v in step.get('env', {}).items() if v is not None})
        cmd = [str(lab_home / 'androidlab.sh')] + args
        append(log_path, f"\n[+] Step {idx}/{len(cfg.get('steps', []))}: {' '.join(args)}\n")
        try:
            p = subprocess.Popen(cmd, cwd=lab_home, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
            assert p.stdout is not None
            for line in p.stdout:
                append(log_path, line)
            code = p.wait()
        except Exception as e:
            append(log_path, f'[-] Failed to execute step: {e}\n')
            code = 127
        append(log_path, f'[+] Step exit code: {code}\n')
        if code != 0:
            write(status_path, f'failed:{code}')
            append(log_path, f'[-] Job failed with exit code {code}\n')
            return code
    write(status_path, 'done')
    append(log_path, '[+] Job complete\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
