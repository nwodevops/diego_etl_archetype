-- =============================================================================
-- REPOCSEP — tabla destino Acciones_Ubigeo (PIN) para RPT_ACCIONES_UBIGEO
-- Instancia: oracle-repocsep @ 10.6.0.15:1532 / dvoefacore
-- Usuario  : REPOCSEP
-- JDBC     : jdbc:oracle:thin:@//10.6.0.15:1532/dvoefacore
--
-- Crear manualmente conectado como REPOCSEP. El script R
-- r/main.R hace TRUNCATE + INSERT (no CREATE).
-- =============================================================================

CREATE TABLE REPOCSEP.RPT_ACCIONES_UBIGEO (
    TXCOORDINACION      VARCHAR2(4000),
    SUBSECTOR           VARCHAR2(4000),
    TXCUC               VARCHAR2(4000),
    FEFIN               DATE,
    IDADMINISTRADO      VARCHAR2(4000),
    IDUF_SIG            VARCHAR2(4000),
    TXTIPSUP            VARCHAR2(4000),
    TXFUENTE            VARCHAR2(4000),
    TXACCION            VARCHAR2(4000),
    FGSUP_ORIENTATIVA   VARCHAR2(4000),
    TXUBIGEO_INEI       VARCHAR2(4000),
    TXUBIGEO_INAF       VARCHAR2(4000),
    TXDEPARTAMENTO      VARCHAR2(4000),
    TXPROVINCIA         VARCHAR2(4000),
    TXDISTRITO          VARCHAR2(4000),
    FE_CARGA            DATE
);

CREATE INDEX IDX_RPT_ACC_UBI_CUC ON REPOCSEP.RPT_ACCIONES_UBIGEO (TXCUC);
CREATE INDEX IDX_RPT_ACC_UBI_FEFIN ON REPOCSEP.RPT_ACCIONES_UBIGEO (FEFIN);
CREATE INDEX IDX_RPT_ACC_UBI_IDUF ON REPOCSEP.RPT_ACCIONES_UBIGEO (IDUF_SIG);
CREATE INDEX IDX_RPT_ACC_UBI_CARGA ON REPOCSEP.RPT_ACCIONES_UBIGEO (FE_CARGA);

-- Si la tabla ya existe (migración):
-- ALTER TABLE REPOCSEP.RPT_ACCIONES_UBIGEO ADD (FE_CARGA DATE);
-- CREATE INDEX IDX_RPT_ACC_UBI_CARGA ON REPOCSEP.RPT_ACCIONES_UBIGEO (FE_CARGA);

-- Verificación rápida:
-- SELECT COUNT(*), MAX(FE_CARGA) FROM REPOCSEP.RPT_ACCIONES_UBIGEO;
