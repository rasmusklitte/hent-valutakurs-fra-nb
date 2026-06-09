# hent-valutakurs-fra-nb

Look up a single FX rate from the PE database table `fx_rates_nationalbanken`
(Danish Nationalbanken, DKK-quoted rates) for a given date and currency.

If the requested date has no rate (weekend/holiday), the most recent rate on or
before that date is returned. The value printed is **DKK per 1 unit** of the currency.

## Prerequisites

- Python 3
- ODBC Driver 17 for SQL Server
- Access to the `PE` database on `sql1\ppim` via Windows authentication

## Install

```
pip install -r requirements.txt
```

## Usage

```
hent.bat <YYYY-MM-DD|YYYYMMDD> <CURRENCY>
```

Examples:

```
hent.bat 2010-01-04 EUR
hent.bat 2024-12-31 USD
```

The rate is printed to stdout. If the date fell on a non-business day, a note such as
`# using rate from 2010-01-04` is written to stderr (stdout stays clean for scripting).
Unknown currencies, dates before the available data, and malformed input exit with a
non-zero status and an error message on stderr.

## Configuration

Connection settings default to `sql1\ppim` / database `PE` with Windows auth. Override via
environment variables if needed: `PE_DB_DRIVER`, `PE_DB_SERVER`, `PE_DB_NAME` (see `config.py`).
