#!/usr/bin/env python3
"""Deep scan of i18n assets for encoding corruption.

Detects three independent signals that a translation file has been through a
bad encode/decode round-trip:

  1. C1 control characters (U+0080-U+009F) - never legitimate in UI strings.
  2. U+FFFD replacement characters - lossy decode already happened.
  3. Stray Cyrillic in non-Cyrillic locales (and vice versa) - the classic
     "UTF-8 read as CP1251" signature, which is what corrupted ru/uk/es/ko.
"""
import glob
import io
import json
import os
import re
import sys

I18N_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'i18n')

C1 = re.compile(u'[-]')
CYRILLIC = re.compile(u'[Ѐ-ӿԀ-ԯ]')
CYRILLIC_LOCALES = {'ru', 'uk'}


def scan():
    rows = []
    total_bad = 0
    for path in sorted(glob.glob(os.path.join(I18N_DIR, '*.json'))):
        name = os.path.basename(path)
        code = name[:-5]
        with io.open(path, encoding='utf-8-sig') as fh:
            data = json.load(fh)

        c1_keys, fffd_keys, cyr_keys = [], [], []
        for key, val in data.items():
            if not isinstance(val, str):
                continue
            if C1.search(val):
                c1_keys.append(key)
            if u'�' in val:
                fffd_keys.append(key)
            if code not in CYRILLIC_LOCALES and CYRILLIC.search(val):
                cyr_keys.append(key)

        bad = len(c1_keys) + len(fffd_keys) + len(cyr_keys)
        total_bad += bad
        rows.append((name, len(c1_keys), len(fffd_keys), len(cyr_keys),
                     (c1_keys + fffd_keys + cyr_keys)[:4]))

    print('%-10s %-6s %-7s %-9s %s'
          % ('file', 'C1', 'U+FFFD', 'strayCyr', 'sample keys'))
    for name, c1, fffd, cyr, sample in rows:
        flag = '' if (c1 + fffd + cyr) == 0 else '  <== CORRUPT'
        print('%-10s %-6d %-7d %-9d %s%s'
              % (name, c1, fffd, cyr, ', '.join(sample), flag))

    if total_bad:
        print('\n%d corrupted string(s) found.' % total_bad)
        return 1
    print('\nNo encoding corruption detected in any locale.')
    return 0


if __name__ == '__main__':
    sys.exit(scan())
