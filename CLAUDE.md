# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

A single-purpose CLI that looks up one FX rate from the PE SQL Server table
`fx_rates_nationalbanken` (Danish Nationalbanken, DKK-quoted rates) for a given date and
currency. If the requested date has no rate (weekend/holiday), the most recent rate on or
before that date is returned. The printed value is **DKK per 1 unit** of the currency.

## Commands

```
pip install -r requirements.txt          # install deps (pyodbc)
python fetch_fx.py <YYYY-MM-DD|YYYYMMDD> <CURRENCY>   # core lookup, e.g. 2010-01-04 EUR
hent-valutakurs-fra-nb.bat               # interactive Windows wrapper (loops, prompts)
```

There are no tests, linters, or build steps in this repo.

## Architecture

Three files do all the work:

- `fetch_fx.py` — the program. Parses two positional args (date in `YYYY-MM-DD` or
  `YYYYMMDD`, currency), runs one parameterized `SELECT TOP 1 ... WHERE currency=? AND
  rate_date<=? ORDER BY rate_date DESC`, and prints the rate. Connections go through the
  `get_connection()` context manager (fresh connect/close per run, no pooling).
- `config.py` — `connection_string()` builds an ODBC string for `sql1\ppim` / database `PE`
  with Windows auth. Overridable via env vars `PE_DB_DRIVER`, `PE_DB_SERVER`, `PE_DB_NAME`.
- `hent-valutakurs-fra-nb.bat` — interactive loop for non-technical users. Resolves the
  script directory (local OneDrive path, then a `P:\` fallback), checks for Python and
  `pyodbc` (offers to `pip install -r requirements.txt` if missing), then repeatedly prompts
  for date/currency. Enter = today / EUR; `exit`/`quit`/`q` ends the loop.

## Conventions

- **stdout vs stderr contract**: only the numeric rate goes to stdout. Diagnostics — the
  `# using rate from <date>` note when a fallback date is used, "no rate found", usage,
  parse errors — go to stderr. Keep stdout clean so the tool stays scriptable.
- **Exit codes**: `2` for bad arguments / unparseable input, `1` for no matching rate, `0`
  on success. Preserve these when changing behavior.
- The DB value handling reads `dkk_per_1` when present, else `dkk_per_100 / 100`.

## Note on the database-connection skill

`.claude/skills/database-connection/SKILL.md` documents a much larger architecture
(`DatabaseConnection`, `QueryBuilder`, `pydantic-settings`, `loguru`, a `database/` package,
`main.py`). None of that exists here — it is boilerplate carried over from another PE
project. For this repo, the real DB access pattern is `fetch_fx.py` + `config.py` above. The
skill is still a useful reference for the broader PE database conventions (parameterized
queries, the `sql1\ppim` / `PE` target, ODBC Driver 17).
