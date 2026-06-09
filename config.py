import os

DRIVER = os.getenv("PE_DB_DRIVER", "ODBC Driver 17 for SQL Server")
SERVER = os.getenv("PE_DB_SERVER", r"sql1\ppim")
DATABASE = os.getenv("PE_DB_NAME", "PE")


def connection_string() -> str:
    return (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVER};"
        f"Database={DATABASE};"
        "Trusted_Connection=Yes;"
    )
