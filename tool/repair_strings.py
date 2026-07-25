#!/usr/bin/env python3
"""Per-string repair for locales that have no fully clean commit.

Instead of rolling the whole file back (which would drop hundreds of good
translations), this walks git history for each corrupted string individually
and takes the newest version of that string which is clean. Strings with no
clean version anywhere fall back to the English text.

Run:  python tool/repair_strings.py de es
"""
import collections
import io
import json
import os
import subprocess
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
I18N = os.path.join(REPO, 'assets', 'i18n')

FFFD = u'�'
CYRILLIC_LOCALES = {'ru', 'uk'}


def is_corrupt(text, code):
    if not isinstance(text, str):
        return False
    if any(0x80 <= ord(ch) <= 0x9f for ch in text):
        return True
    if FFFD in text:
        return True
    if code not in CYRILLIC_LOCALES:
        if any(0x0400 <= ord(ch) <= 0x052f for ch in text):
            return True
    return False


def load_json(path):
    with io.open(path, encoding='utf-8-sig') as fh:
        return json.load(fh, object_pairs_hook=collections.OrderedDict)


def history(rel):
    out = subprocess.check_output(
        ['git', 'log', '--format=%h', '--', rel], cwd=REPO).decode()
    return [s.strip() for s in out.splitlines() if s.strip()]


def repair(code):
    rel = 'assets/i18n/%s.json' % code
    path = os.path.join(I18N, '%s.json' % code)
    data = load_json(path)
    en = load_json(os.path.join(I18N, 'en.json'))

    bad_keys = [k for k, v in data.items() if is_corrupt(v, code)]
    if not bad_keys:
        print('%s: nothing to repair' % code)
        return

    # Load each historical revision once, newest first.
    revisions = []
    for sha in history(rel):
        try:
            blob = subprocess.check_output(
                ['git', 'show', '%s:%s' % (sha, rel)],
                cwd=REPO, stderr=subprocess.DEVNULL).decode('utf-8-sig')
            revisions.append((sha, json.loads(blob)))
        except Exception:
            continue

    recovered, fallback = [], []
    for key in bad_keys:
        fixed = None
        for sha, rev in revisions:
            val = rev.get(key)
            if isinstance(val, str) and val and not is_corrupt(val, code):
                fixed = val
                recovered.append((key, sha))
                break
        if fixed is None:
            fixed = en.get(key, data[key])
            fallback.append(key)
        data[key] = fixed

    with io.open(path, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write('\n')

    print('%s: %d corrupted -> %d recovered from history, %d EN fallback'
          % (code, len(bad_keys), len(recovered), len(fallback)))
    if fallback:
        print('    EN fallback keys: %s%s'
              % (', '.join(fallback[:8]),
                 ' ...' if len(fallback) > 8 else ''))


def main():
    codes = sys.argv[1:] or ['de', 'es']
    for code in codes:
        repair(code)
    return 0


if __name__ == '__main__':
    sys.exit(main())
