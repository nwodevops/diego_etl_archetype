# Acciones PIN — Apache Hop + H2 + R

Proyecto ETL (clon del arquetipo OEFA) que carga 3 vistas Oracle SISUD → H2 `STG_*`
→ lógica R Acciones PIN → Oracle `RPT_ACCIONES_UBIGEO`.

## Uso rápido

1. Completar/activar entorno: `.\switch-env.ps1 local|remote` (o copiar
   `environments/local.json` → variables en `project-config.json`).
2. `pip install -r python/requirements.txt`
3. Diseño STG: en Hop, Play `workflows/wf_create_stg.hwf`.
4. Corrida: Play `workflows/wf_main.hwf`.

Fuentes declaradas en [`inputs.yaml`](inputs.yaml). Contrato R: [`r/CONTRATO.md`](r/CONTRATO.md).
Guía agentes: [`AGENTS.md`](AGENTS.md).

## Capas

| Capa | Rol |
|------|-----|
| `inputs.yaml` + Python | DDL `STG_ORA_*` (no extrae filas) |
| Hop `pl_stage_*` | Extract Oracle → H2 truncate |
| R `acciones_pin.R` | Reglas PIN → `Acciones_Ubigeo` |
| Oracle | Destino `RPT_ACCIONES_UBIGEO` (`DB_ORA_REPO_*`) |

H2 in-memory `mem:csep` puerto 9092; reset clean en cada corrida.
