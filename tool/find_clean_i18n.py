#!/usr/bin/env python3
"""For each locale file, walk git history (newest first) and report the most
recent commit in which the file has no encoding corruption.

Corruption signals (all use explicit escapes - never literal control chars):
  1. C1 control characters U+0080-U+009F  - never valid in UI strings.
  2. U+FFFD replacement character         - lossy decode already happened.
  3. Cyrillic in a non-Cyrillic locale    - the "UTF-8 read as CP1251" tell.
"""
import json
import os
import re
import subprocess
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

C1 = re.compile(u'[-]')
FFFD = u'�'
CYRILLIC = re.compile(u'[Ѐ-ӿԀ-ԯ]')
CYRILLIC_LOCALES = {'ru', 'uk'}


def corruption(text, code):
    """Return (key_count, bad_string_count) or (None, None) if unparsable."""
    try:
        data = json.loads(text)
    except Exception:
        return None, None
    bad = 0
    for val in data.values():
        if not isinstance(val, str):
            continue
        if C1.search(val) or FFFD in val:
            bad += 1
        elif code not in CYRILLIC_LOCALES and CYRILLIC.search(val):
            bad += 1
    return len(data), bad


def commits_for(rel):
    out = subprocess.check_output(
        ['git', 'log', '--format=%h|%ad', '--date=short', '--', rel],
        cwd=REPO).decode('utf-8', 'replace')
    rows = []
    for line in out.strip().splitlines():
        if '|' in line:
            sha, date = line.split('|', 1)
            rows.append((sha.strip(), date.strip()))
    return rows


def main():
    i18n = os.path.join(REPO, 'assets', 'i18n')
    print('%-10s %-9s %-12s %-6s %s'
          % ('file', 'commit', 'date', 'keys', 'result'))
    for name in sorted(os.listdir(i18n)):
        if not name.endswith('.json'):
            continue
        code = name[:-5]
        rel = 'assets/i18n/' + name
        history = commits_for(rel)
        if not history:
            print('%-10s %-9s %-12s %-6s %s'
                  % (name, '-', '-', '-', 'NO HISTORY FOUND'))
            continue

        found = None
        worst = []
        for sha, date in history:
            try:
                blob = subprocess.check_output(
                    ['git', 'show', '%s:%s' % (sha, rel)],
                    cwd=REPO, stderr=subprocess.DEVNULL).decode('utf-8-sig')
            except Exception:
                continue
            keys, bad = corruption(blob, code)
            if keys is None:
                continue
            worst.append((sha, date, keys, bad))
            if bad == 0:
                found = (sha, date, keys)
                break

        if found:
            print('%-10s %-9s %-12s %-6d %s'
                  % (name, found[0], found[1], found[2], 'CLEAN'))
        else:
            best = min(worst, key=lambda r: r[3]) if worst else None
            if best:
                print('%-10s %-9s %-12s %-6d least-corrupt: %d bad strings'
                      % (name, best[0], best[1], best[2], best[3]))
            else:
                print('%-10s %-9s %-12s %-6s %s'
                      % (name, '-', '-', '-', 'UNREADABLE'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
