#!/usr/bin/env python3
"""Validate i18n assets before a release.

Checks, per locale file:
  1. Valid UTF-8 and valid JSON.
  2. Key set identical to en.json (no missing, no extra).
  3. No encoding corruption ("mojibake").

Corruption detection deliberately avoids naive substring markers such as 'Ã',
which are legitimate characters in Portuguese (REPUTAÇÃO) and Vietnamese
(ĐÃ QUÉT). Instead it uses three signals that cannot occur in healthy text:

  * C1 control characters U+0080-U+009F
  * U+FFFD replacement characters
  * Cyrillic letters inside a non-Cyrillic locale (and, for ru/uk, the
    classic "Р<x>" / "С<x>" bigrams produced by UTF-8 read as CP1251)

Run:  python tool/verify_i18n.py      exit 0 = ok, 1 = problems
"""
import glob
import io
import json
import os
import sys

I18N_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        '..', 'assets', 'i18n')

FFFD = u'�'
CYRILLIC_LOCALES = {'ru', 'uk'}
# Bigrams that appear when Cyrillic UTF-8 is decoded as CP1251.
CYRILLIC_MOJIBAKE = (u'Рџ', u'РЎ', u'Рћ', u'РЅ', u'Р°', u'Р¸', u'СЃ', u'Сѓ')


def has_c1(text):
    return any(0x80 <= ord(ch) <= 0x9f for ch in text)


def has_cyrillic(text):
    return any(0x0400 <= ord(ch) <= 0x052f for ch in text)


def corruption_reason(text, code):
    """Return a short reason string if text looks corrupted, else None."""
    if has_c1(text):
        return 'C1 control char'
    if FFFD in text:
        return 'U+FFFD replacement char'
    if code in CYRILLIC_LOCALES:
        for seq in CYRILLIC_MOJIBAKE:
            if seq in text:
                return 'CP1251 mojibake sequence %r' % seq
    elif has_cyrillic(text):
        return 'stray Cyrillic in non-Cyrillic locale'
    return None


def safe(text):
    """Printable on legacy consoles without raising."""
    enc = sys.stdout.encoding or 'ascii'
    return text.encode(enc, 'backslashreplace').decode(enc)


def main():
    files = sorted(glob.glob(os.path.join(I18N_DIR, '*.json')))
    if not files:
        print('FAIL: no locale files found in %s' % I18N_DIR)
        return 1

    with io.open(os.path.join(I18N_DIR, 'en.json'), encoding='utf-8-sig') as fh:
        en_keys = set(json.load(fh))

    failures = []
    for path in files:
        name = os.path.basename(path)
        code = name[:-5]

        try:
            with io.open(path, encoding='utf-8-sig') as fh:
                data = json.load(fh)
        except Exception as exc:
            failures.append('%s: invalid JSON/UTF-8: %s' % (name, exc))
            print('%-10s %-6s' % (name, 'FAIL'))
            continue

        problems = []
        missing = en_keys - set(data)
        extra = set(data) - en_keys
        if missing:
            problems.append('missing %d key(s): %s'
                            % (len(missing), sorted(missing)[:5]))
        if extra:
            problems.append('extra %d key(s): %s'
                            % (len(extra), sorted(extra)[:5]))

        bad = []
        for key, val in data.items():
            if not isinstance(val, str):
                continue
            reason = corruption_reason(val, code)
            if reason:
                bad.append((key, reason))
        if bad:
            problems.append('%d corrupted string(s), e.g. %s (%s)'
                            % (len(bad), bad[0][0], bad[0][1]))

        print('%-10s %-6s keys=%d' % (name, 'OK' if not problems else 'FAIL',
                                      len(data)))
        for p in problems:
            failures.append('%s: %s' % (name, p))

    if failures:
        print('\n--- FAILURES ---')
        for f in failures:
            print(' * ' + safe(f))
        return 1

    print('\nAll %d locale files: valid JSON, key sets match en.json, '
          'no encoding corruption.' % len(files))
    return 0


if __name__ == '__main__':
    sys.exit(main())
