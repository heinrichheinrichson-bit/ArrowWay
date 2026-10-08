import json,hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
m=json.loads((root/'localization/en.json').read_text(encoding='utf-8'))['messages']
audit=json.loads((root/'localization/completion_review.json').read_text(encoding='utf-8'))
entries=json.loads((root/'collections/discoveries.json').read_text(encoding='utf-8'))['entries']
def check(source,record):
    assert hashlib.sha256(source.encode('utf-8')).hexdigest()==record['source_sha256'], 'German original changed: '+source
    assert source in m, 'Missing English text: '+source
    assert hashlib.sha256(m[source].encode('utf-8')).hexdigest()==record['english_sha256'], 'English text changed: '+source
for path,entry in entries.items():
    assert path in audit['entries'], 'Not reviewed: '+path
    check(entry['text'],audit['entries'][path])
for source,record in audit['fallbacks'].items():check(source,record)
print(f"Completion review verified: {len(entries)} entries, {len(audit['fallbacks'])} fallbacks")
