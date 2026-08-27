-- =============================================================================
-- APP — tabla destino local Acciones_Ubigeo (PIN) para RPT_ACCIONES_UBIGEO
-- Instancia: localhost:1524 / BD_CURSOR
-- Usuario  : app
-- JDBC     : jdbc:oracle:thin:@//localhost:1524/BD_CURSOR
--
-- Crear conectado como app. r/main.R hace TRUNCATE + INSERT (no CREATE).
-- =============================================================================

-- Requiere (como SYS): ALTER USER APP DEFAULT TABLESPACE USERS;
--                     ALTER USER APP QUOTA UNLIMITED ON USERS;
-- Evita ORA-01950 (sin privilegios en SYSTEM).

CREATE TABLE APP.RPT_ACCIONES_UBIGEO (
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
    TXDISTRITO          VARCHAR2(4000)
) TABLESPACE USERS;

CREATE INDEX IDX_RPT_ACC_UBI_CUC ON APP.RPT_ACCIONES_UBIGEO (TXCUC) TABLESPACE USERS;
CREATE INDEX IDX_RPT_ACC_UBI_FEFIN ON APP.RPT_ACCIONES_UBIGEO (FEFIN) TABLESPACE USERS;
CREATE INDEX IDX_RPT_ACC_UBI_IDUF ON APP.RPT_ACCIONES_UBIGEO (IDUF_SIG) TABLESPACE USERS;
