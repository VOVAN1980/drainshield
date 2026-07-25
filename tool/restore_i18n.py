#!/usr/bin/env python3
"""Restore locale files from the last known-clean commit, then re-add the
handful of keys that were introduced after it.

Strategy per locale:
  1. Base    = the file as of CLEAN_COMMIT (verified free of mojibake).
  2. Drop    = keys not present in en.json (dead legacy keys).
  3. Re-add  = keys present in en.json but missing from the base. The value is
               taken from the CURRENT file only if that specific string is
               clean; otherwise the English text is used as a safe fallback
               (readable English beats unreadable mojibake).
  4. Order   = follow en.json key order for reviewable diffs.
  5. Write   = UTF-8, no BOM, LF endings, 2-space indent.

Run:  python tool/restore_i18n.py
"""
import collections
import io
import json
import os
import subprocess
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
I18N = os.path.join(REPO, 'assets', 'i18n')

CLEAN_COMMIT = '5ed6975'
LOCALES = ['ar', 'fr', 'hi', 'id', 'it', 'ja', 'ko', 'pl',
           'pt', 'ru', 'tr', 'uk', 'vi', 'zh']

# Keys renamed after CLEAN_COMMIT: old name -> new name.
RENAMES = {'riskLabelCapture': 'riskLabelCaution'}

FFFD = u'�'
CYRILLIC_LOCALES = {'ru', 'uk'}


def is_corrupt(text, code):
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


def git_json(commit, rel):
    blob = subprocess.check_output(['git', 'show', '%s:%s' % (commit, rel)],
                                   cwd=REPO).decode('utf-8-sig')
    return json.loads(blob, object_pairs_hook=collections.OrderedDict)


def main():
    en = load_json(os.path.join(I18N, 'en.json'))
    report = []

    for code in LOCALES:
        rel = 'assets/i18n/%s.json' % code
        path = os.path.join(I18N, '%s.json' % code)

        base = git_json(CLEAN_COMMIT, rel)
        current = load_json(path)

        # Apply known renames onto the base.
        for old, new in RENAMES.items():
            if old in base and new not in base:
                base[new] = base.pop(old)

        # Drop keys that no longer exist in en.json.
        for key in [k for k in base if k not in en]:
            base.pop(key)

        # Re-add keys that en.json has but the base lacks.
        from_current, from_english = [], []
        for key in en:
            if key in base:
                continue
            val = current.get(key)
            if isinstance(val, str) and val and not is_corrupt(val, code):
                base[key] = val
                from_current.append(key)
            else:
                base[key] = en[key]
                from_english.append(key)

        # Order keys like en.json.
        out = collections.OrderedDict((k, base[k]) for k in en if k in base)
        for k in base:
            if k not in out:
                out[k] = base[k]

        with io.open(path, 'w', encoding='utf-8', newline='\n') as fh:
            json.dump(out, fh, ensure_ascii=False, indent=2)
            fh.write('\n')

        report.append((code, len(out), from_current, from_english))

    print('%-5s %-6s %s' % ('loc', 'keys', 're-added keys'))
    for code, n, cur, eng in report:
        bits = []
        if cur:
            bits.append('from-current: ' + ','.join(cur))
        if eng:
            bits.append('EN-FALLBACK: ' + ','.join(eng))
        print('%-5s %-6d %s' % (code, n, '; '.join(bits) or '-'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
