---
name: database-connection
description: Patterns and configuration for connecting to the PE SQL Server database using pyodbc. Use when writing code that needs database access, creating new queries, adding database operations, or troubleshooting connection issues.
---

# Database Connection

How to connect to and interact with the PE SQL Server database in this project.

## Technology Stack

- **Database**: Microsoft SQL Server (`sql1\ppim`, database `PE`)
- **Driver**: ODBC Driver 17 for SQL Server
- **Library**: `pyodbc` (direct connections, no ORM)
- **Results**: Returned as `pandas.DataFrame`
- **Config**: `pydantic-settings` with optional `.env` file
- **Logging**: `loguru`

## Configuration

All database settings live in `config.py` via the `DatabaseConfig` class. A global singleton `db_config` is ready to use:

```python
from config import db_config

connection_string = db_config.connection_string
```

### Default Configuration

| Setting | Default Value |
|---------|---------------|
| `driver` | `ODBC Driver 17 for SQL Server` |
| `server` | `sql1\ppim` |
| `database` | `PE` |
| `trusted_connection` | `Yes` |
| `username` | `None` |
| `password` | `None` |

### Authentication Modes

**Windows Authentication** (default — no credentials needed):
```
DRIVER={ODBC Driver 17 for SQL Server};SERVER=sql1\ppim;Database=PE;Trusted_Connection=Yes;
```

**SQL Server Authentication** (when `username` and `password` are set):
```
DRIVER={ODBC Driver 17 for SQL Server};SERVER=sql1\ppim;Database=PE;UID=user;PWD=pass;
```

Settings can be overridden via environment variables or a `.env` file (handled by Pydantic Settings).

## Connection Pattern

All connections use a **context manager** in `database/connection.py`. Each operation opens a fresh connection and closes it when done — there is no persistent connection or pooling.

```python
from contextlib import contextmanager

@contextmanager
def get_connection(self):
    conn = None
    try:
        conn = pyodbc.connect(self.connection_string)
        yield conn
    finally:
        if conn:
            conn.close()
```

Never hold a connection outside a `with` block. Always use the `DatabaseConnection` methods instead of calling `pyodbc.connect()` directly.

## Using DatabaseConnection

### Initialization

```python
from database import DatabaseConnection

db = DatabaseConnection()
```

Or with a custom connection string:

```python
db = DatabaseConnection(connection_string="DRIVER=...")
```

### Available Operations

| Method | Returns | Use For |
|--------|---------|---------|
| `execute_query(query, params)` | `pd.DataFrame` | SELECT queries |
| `execute_procedure(name, params)` | `pd.DataFrame` | Stored procedures |
| `execute_insert(query, params)` | `int` (rows affected) | INSERT / UPDATE / DELETE |
| `test_connection()` | `bool` | Verifying connectivity |
| `get_table_names()` | `List[str]` | Listing all tables |
| `get_procedure_names()` | `List[str]` | Listing stored procedures |

### Examples

**Running a SELECT query:**
```python
df = db.execute_query(
    "SELECT * FROM tbl_pe_stamdata_fund WHERE fund_id = ?",
    params=(fund_id,)
)
```

**Calling a stored procedure:**
```python
df = db.execute_procedure("sp_GetFundSummary", [fund_id])
```

**Inserting data (auto-commits):**
```python
rows_affected = db.execute_insert(
    "INSERT INTO tbl_pe_transactions (fund_id, amount) VALUES (?, ?)",
    params=(fund_id, amount)
)
```

**Testing the connection:**
```python
if db.test_connection():
    print("Connected")
```

## Architecture Layers

```
PEDatabaseManager          (main.py — orchestrator)
├── DatabaseConnection     (database/connection.py — connection + raw queries)
├── SchemaDiscovery        (database/schema.py — table metadata + relationships)
├── QueryBuilder           (database/queries.py — pre-built domain queries)
└── TransactionManager     (transactions/transaction_manager.py — CRUD + stored procs)
```

- `PEDatabaseManager` is the main entry point. It initializes all components and tests the connection on startup.
- `DatabaseConnection` is the only class that talks to SQL Server. All other components receive a `DatabaseConnection` instance.
- `QueryBuilder` and `TransactionManager` wrap common domain queries so callers don't write raw SQL.

### Typical Initialization (via PEDatabaseManager)

```python
from main import PEDatabaseManager

pe = PEDatabaseManager()
# Connection is already tested at this point

df = pe.run_custom_query("SELECT TOP 10 * FROM tbl_pe_stamdata_fund")
```

## Key Files

| File | Purpose |
|------|---------|
| `config.py` | `DatabaseConfig` + connection string generation |
| `database/connection.py` | `DatabaseConnection` class |
| `database/queries.py` | `QueryBuilder` with domain-specific queries |
| `database/schema.py` | `SchemaDiscovery` for table metadata |
| `database/__init__.py` | Exports `DatabaseConnection`, `SchemaDiscovery`, `QueryBuilder` |
| `main.py` | `PEDatabaseManager` — ties everything together |
| `transactions/transaction_manager.py` | `TransactionManager` for CRUD operations |
| `requirements.txt` | Lists `pyodbc`, `pandas`, `pydantic-settings`, etc. |

## Rules

- Always use parameterized queries (`?` placeholders) — never concatenate user input into SQL strings.
- Use `execute_query` for reads and `execute_insert` for writes. `execute_insert` auto-commits.
- Pass `DatabaseConnection` instances to new components; don't create extra connections.
- Log database operations via `loguru` (`from loguru import logger`).
- Keep domain queries in `QueryBuilder` or `TransactionManager`, not scattered in application code.
