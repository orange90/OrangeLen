"""Synthetic review inputs only; no personal documents or network access."""
import pathlib
import sqlite3
import sys
import zipfile

p = pathlib.Path(sys.argv[1])
p.mkdir(parents=True, exist_ok=True)
with sqlite3.connect(p / 'generated.sqlite') as c:
    c.execute('CREATE TABLE sample(a INTEGER, doubled INTEGER GENERATED ALWAYS AS (a*2), label TEXT)')
    c.execute("INSERT INTO sample(a,label) VALUES(7,'orange')")
    c.execute('CREATE TABLE oversized(payload TEXT)')
    c.execute('INSERT INTO oversized VALUES(?)', ('x' * 1000100,))
with zipfile.ZipFile(p / 'blocked.docx', 'w', compression=zipfile.ZIP_DEFLATED) as z:
    # Only a ZIP preflight probe, deliberately not a complete Word document.
    z.writestr('word/document.xml', 'a' * 6000000)
with zipfile.ZipFile(p / 'aliases.zip', 'w') as z:
    z.writestr('folder/a.txt', 'FIRST')
    z.writestr('folder//a.txt', 'SECOND')
with zipfile.ZipFile(p / 'shared.xlsx', 'w') as z:
    # Minimal parts accepted by OfficeContentPreview, not a full Office package.
    z.writestr('xl/sharedStrings.xml', '<sst><si><t>' + 'x' * 1000 + '</t></si></sst>')
    z.writestr('xl/worksheets/sheet1.xml', '<worksheet><sheetData><row>' + ''.join(
        f'<c r="A{i}" t="s"><v>0</v></c>' for i in range(100)) + '</row></sheetData></worksheet>')
