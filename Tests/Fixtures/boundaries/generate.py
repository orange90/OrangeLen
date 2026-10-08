"""Synthetic review inputs only; no personal documents or network access."""
import pathlib
import sqlite3
import sys
import zipfile

p = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).parent
p.mkdir(parents=True, exist_ok=True)
(p / 'generated.sqlite').unlink(missing_ok=True)
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

(p / 'types.sqlite').unlink(missing_ok=True)
with sqlite3.connect(p / 'types.sqlite') as c:
    c.execute('CREATE TABLE cases(first INTEGER GENERATED ALWAYS AS (value+1) STORED, value INTEGER, middle INTEGER GENERATED ALWAYS AS (value*2) VIRTUAL, label TEXT, last TEXT GENERATED ALWAYS AS (label || value) STORED)')
    c.executemany('INSERT INTO cases(value,label) VALUES(?,?)', [(3,'a'), (1,'b')])
    c.execute('CREATE TABLE typed(n, literal, b, pretend, multiline, bad, zero)')
    c.execute("INSERT INTO typed VALUES(NULL,'NULL',X'00FF','[BLOB 2 bytes]',?,CAST(X'FF' AS TEXT),?)", ('a\tb\n"c"','x\x00y'))
    c.execute('CREATE TABLE reals(value REAL)')
    c.executemany('INSERT INTO reals VALUES(?)', [(1.2345678901234567,), (float('inf'),)])
