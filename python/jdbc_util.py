"""Arranque de una sola JVM para jaydebeapi.

El proceso Python comparte una única JVM; no se puede agregar classpath a una
JVM ya iniciada. Por eso se registran los jars de lib/ + h2/lib/ ANTES del
primer connect (Oracle ojdbc11.jar, H2, etc.).
"""

from __future__ import annotations

from pathlib import Path

import jpype

_CP: list[str] = []


def register_jar(path) -> None:
    p = str(Path(path).resolve())
    if p not in _CP:
        _CP.append(p)


def classpath_from_root(root: Path) -> None:
    for glob in ("lib/*.jar", "h2/lib/*.jar"):
        for jar in sorted(root.glob(glob)):
            register_jar(jar)


def ensure_jvm() -> None:
    if not jpype.isJVMStarted():
        jpype.startJVM(jpype.getDefaultJVMPath(), classpath=_CP or None)


def connect(driver: str, url: str, user: str, password: str, root: Path):
    try:
        import jaydebeapi
    except ImportError as exc:
        raise SystemExit(
            "Falta jaydebeapi. Instala: pip install -r python/requirements.txt"
        ) from exc
    classpath_from_root(root)
    ensure_jvm()
    return jaydebeapi.connect(driver, url, [user, password])