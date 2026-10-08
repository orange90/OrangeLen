# Synthetic boundary fixtures

Generated locally with Python stdlib; no user data or network requests. `python3 generate.py` rebuilds the known fixture files.

- `generated.sqlite`: generated column between ordinary fields; oversized SQLite cell.
- `types.sqlite`: stored/virtual generated columns in multiple positions, sortable values, NULL vs text, BLOB vs text, tabs/newlines/quotes, NUL and malformed UTF-8 TEXT.
- `aliases.zip`: distinct directory entries that collapse to one displayed path.
- `blocked.docx`: ZIP preflight test only, deliberately not a complete Word file.
- `shared.xlsx`: minimal XML parts for cumulative shared-string expansion; not a complete Excel workbook.

Full native document/media samples remain in `../system-preview/`.
