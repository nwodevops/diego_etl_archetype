"""Introspección Oracle: ALL_TAB_COLUMNS. No extrae filas.

Usa JDBC (ojdbc11.jar) igual que Hop/R, porque python-oracledb en modo
thin no soporta Oracle 23ai+ (DPY-3015, password verifier 0x939).
"""

from __future__ import annotations

from pathlib import Path

from config import project_root, require_live_conn
from h2_ddl import Column, map_h2_type, sanitize_ident
from jdbc_util import connect as jdbc_connect

ORA_DRIVER = "oracle.jdbc.OracleDriver"


def _split_object(object_name: str) -> tuple[str, str]:
    parts = object_name.strip().split(".")
    if len(parts) != 2:
        raise ValueError(
            f"object Oracle debe ser OWNER.NOMBRE, recibido: {object_name!r}"
        )
    return parts[0].upper(), parts[1].upper()


def _jdbc_url(cv: dict[str, str]) -> str:
    if cv["url"]:
        return cv["url"]
    port = int(cv["port"]) if str(cv["port"]).isdigit() else 1521
    return f"jdbc:oracle:thin:@//{cv['host']}:{port}/{cv['database']}"


def introspect(source: dict, variables: dict[str, str], root=None) -> list[Column]:
    connection = source.get("connection") or "oracle_sisud"
    object_name = source.get("object")
    if not object_name:
        raise ValueError(f"{source.get('stg_table')}: falta object (OWNER.NOMBRE)")

    owner, table = _split_object(object_name)
    cv = require_live_conn(connection, variables)
    url = _jdbc_url(cv)
    root = Path(root) if root else project_root()

    conn = jdbc_connect(ORA_DRIVER, url, cv["username"], cv["password"], root)
    try:
        cur = conn.cursor()
        try:
            cur.execute(
                """
                SELECT COLUMN_NAME, DATA_TYPE, DATA_SCALE
                FROM ALL_TAB_COLUMNS
                WHERE OWNER = ? AND TABLE_NAME = ?
                ORDER BY COLUMN_ID
                """,
                (owner, table),
            )
            rows = cur.fetchall()
        finally:
            cur.close()
    finally:
        conn.close()

    if not rows:
        raise ValueError(f"Oracle {owner}.{table}: 0 columnas (¿owner/nombre mal?)")

    used: set[str] = set()
    cols: list[Column] = []
    for name, data_type, scale in rows:
        sc = None if scale is None else int(scale)
        cols.append(
            Column(
                name=sanitize_ident(str(name), used),
                h2_type=map_h2_type(str(data_type), scale=sc),
            )
        )
    return cols