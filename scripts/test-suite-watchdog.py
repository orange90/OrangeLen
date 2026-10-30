#!/usr/bin/env python3
"""Run one suite in its own process group; sample XCTest before timeout cleanup."""
import os
import signal
import subprocess
import sys
import time

suite = sys.argv[1]
limit = int(os.environ.get('ORANGELEN_SUITE_TIMEOUT_SECONDS', '1500'))
if limit <= 0:
    sys.exit('ORANGELEN_SUITE_TIMEOUT_SECONDS must be positive')
process = subprocess.Popen(sys.argv[2:], start_new_session=True)
try:
    sys.exit(process.wait(timeout=limit))
except subprocess.TimeoutExpired:
    print(f'=== WATCHDOG {suite} exceeded {limit} seconds', flush=True)
    rows = subprocess.check_output(['ps', '-axo', 'pid=,pgid=,comm='], text=True)
    for row in rows.splitlines():
        fields = row.split(None, 2)
        if len(fields) == 3 and int(fields[1]) == process.pid and 'xctest' in fields[2]:
            try:
                subprocess.run(['sample', fields[0], '10', '-file',
                                f'build/sample-{suite}.txt'], timeout=20, check=False)
            except (OSError, subprocess.TimeoutExpired):
                pass
    try:
        os.killpg(process.pid, signal.SIGTERM)
        time.sleep(2)
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()
    sys.exit(124)
