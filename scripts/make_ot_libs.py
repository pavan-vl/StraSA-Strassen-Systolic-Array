# Makes the two liberty files OpenTimer needs from one sky130 liberty
# sky130_ot_min.lib has no setup or recovery checks
# sky130_ot_max.lib has no hold or removal checks
# Both have min_pulse_width removed
# Usage: python3 make_ot_libs.py <lib>

import re
import sys

src = open(sys.argv[1]).read()

# Remove min_pulse_width attributes

src = re.sub(r'\n\s*min_pulse_width_(high|low)\s*:[^;]*;', '', src)

# Find every timing or min_pulse_width group and drop the ones that match

group_re = re.compile(r'\n(\s*)(timing|min_pulse_width)\s*\(\s*\)\s*\{')


def strip(text, drop_types):
    out = []
    pos = 0
    while True:
        m = group_re.search(text, pos)
        if not m:
            out.append(text[pos:])
            break

        # Walk to the matching closing brace

        end = m.end()
        depth = 1
        while depth:
            if text[end] == '{':
                depth += 1
            elif text[end] == '}':
                depth -= 1
            end += 1

        body = text[m.start():end]
        drop = m.group(2) == 'min_pulse_width' or re.search(
            r'timing_type\s*:\s*"?(?:' + drop_types + ')', body)

        out.append(text[pos:m.start()] if drop else text[pos:end])
        pos = end
    return ''.join(out)


open('sky130_ot_min.lib', 'w').write(strip(src, '(non_seq_)?setup_|recovery_|min_pulse'))
open('sky130_ot_max.lib', 'w').write(strip(src, '(non_seq_)?hold_|removal_|min_pulse'))

print('Wrote sky130_ot_min.lib and sky130_ot_max.lib')
