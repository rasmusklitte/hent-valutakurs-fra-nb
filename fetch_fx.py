import sys
from contextlib import contextmanager
from datetime import datetime

import pyodbc

from config import connection_string

USAGE = "Usage: python fetch_fx.py <YYYY-MM-DD|YYYYMMDD> <CURRENCY>\n  example: python fetch_fx.py 2010-01-04 EUR"

DATE_FORMATS = ("%Y-%m-%d", "%Y%m%d")

QUERY = """
SELECT TOP 1 rate_date, currency, dkk_per_1, dkk_per_100
FROM fx_rates_nationalbanken
WHERE currency = ? AND rate_date <= ?
ORDER BY rate_date DESC
"""


@contextmanager
def get_connection():
    conn = None
    try:
        conn = pyodbc.connect(connection_string())
        yield conn
    finally:
        if conn:
            conn.close()


def parse_args(argv):
    if len(argv) != 2:
        print(USAGE, file=sys.stderr)
        sys.exit(2)
    raw_date, raw_currency = argv
    rate_date = None
    for fmt in DATE_FORMATS:
        try:
            rate_date = datetime.strptime(raw_date, fmt).date()
            break
        except ValueError:
            continue
    if rate_date is None:
        print(
            f"Invalid date '{raw_date}'. Expected format YYYY-MM-DD or YYYYMMDD.",
            file=sys.stderr,
        )
        sys.exit(2)
    return rate_date, raw_currency.strip().upper()


def fetch_rate(rate_date, currency):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(QUERY, (currency, rate_date))
        return cursor.fetchone()


def main():
    requested_date, currency = parse_args(sys.argv[1:])
    row = fetch_rate(requested_date, currency)

    if row is None:
        print(
            f"No rate found for {currency} on or before {requested_date}.",
            file=sys.stderr,
        )
        sys.exit(1)

    found_date, _currency, dkk_per_1, dkk_per_100 = row
    value = dkk_per_1 if dkk_per_1 is not None else dkk_per_100 / 100

    if found_date != requested_date:
        print(f"# using rate from {found_date}", file=sys.stderr)

    print(value)


if __name__ == "__main__":
    main()
