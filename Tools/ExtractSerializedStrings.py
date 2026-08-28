import struct
import sys
from pathlib import Path

tool_dir = Path(__file__).resolve().parent
roots = [tool_dir.parent, tool_dir.parent.parent]
root = next((candidate for candidate in roots if (candidate / 'Gekko Episode of Nova_Data').is_dir()), None)
if root is None:
    raise SystemExit('Could not locate the game root from the tools directory.')
asset = root / 'Gekko Episode of Nova_Data' / 'sharedassets0.assets'
archive_work = tool_dir.parent / 'TranslationWork'
output = (archive_work if archive_work.is_dir() else root / 'TranslationWork') / 'serialized_candidates.tsv'
data = asset.read_bytes()
seen = set()
ordered = []

def looks_like_text(value):
    if not value or len(value) < 2 or len(value) > 20000:
        return False
    if not any(('\u3040' <= c <= '\u30ff') or ('\u3400' <= c <= '\u9fff') for c in value):
        return False
    bad = sum(1 for c in value if ord(c) < 32 and c not in '\r\n\t')
    return bad == 0

for pos in range(0, len(data) - 4):
    size = struct.unpack_from('<I', data, pos)[0]
    if size == 0 or size > 20000 or pos + 4 + size > len(data):
        continue
    raw = data[pos + 4:pos + 4 + size]
    try:
        value = raw.decode('utf-8')
    except UnicodeDecodeError:
        continue
    if looks_like_text(value):
        clean = value.replace('\r', '\\r').replace('\n', '\\n').replace('\t', '\\t').replace('\x00', '')
        if clean not in seen:
            seen.add(clean)
            ordered.append(clean)

with output.open('w', encoding='utf-8', newline='') as handle:
    handle.write('source\ttranslation\tstatus\n')
    for value in ordered:
        handle.write(value + '\t\t\n')
print('Wrote', len(seen), 'serialized string candidates to', output)
