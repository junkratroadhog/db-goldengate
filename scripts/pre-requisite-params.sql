WHENEVER SQLERROR EXIT FAILURE;

PROMPT === Checking FORCE LOGGING status in CDB ===
SELECT force_logging FROM v$database;

PROMPT === Enabling FORCE LOGGING in CDB if not already enabled ===
DECLARE
    v_force_logging VARCHAR2(3);
BEGIN
    SELECT force_logging INTO v_force_logging FROM v$database;
    IF v_force_logging = 'NO' THEN
        EXECUTE IMMEDIATE 'ALTER DATABASE FORCE LOGGING';
    END IF;
END;
/
SELECT force_logging AS FORCE_LOGGING_ENABLED FROM v$database;

PROMPT === Checking Supplemental Log Data in CDB$ROOT ===
SELECT supplemental_log_data_min FROM v$database;

PROMPT === Enabling Supplemental Log Data in CDB$ROOT if not already enabled ===
DECLARE
    v_sup VARCHAR2(3);
BEGIN
    SELECT supplemental_log_data_min INTO v_sup FROM v$database;
    IF v_sup = 'NO' THEN
        EXECUTE IMMEDIATE 'ALTER DATABASE ADD SUPPLEMENTAL LOG DATA';
    END IF;
END;
/
SELECT supplemental_log_data_min AS SUP_LOG_ENABLED_CDB FROM v$database;

PROMPT === Switching to PDB &1 ===
ALTER SESSION SET CONTAINER=&1;
SHOW CON_NAME;

PROMPT === Checking Supplemental Log Data in PDB ===
SELECT supplemental_log_data_min FROM v$database;

PROMPT === Enabling Supplemental Log Data in PDB if not already enabled ===
DECLARE
    v_sup VARCHAR2(3);
BEGIN
    SELECT supplemental_log_data_min INTO v_sup FROM v$database;
    IF v_sup = 'NO' THEN
        EXECUTE IMMEDIATE 'ALTER DATABASE ADD SUPPLEMENTAL LOG DATA';
    END IF;
END;
/
SELECT supplemental_log_data_min AS SUP_LOG_ENABLED_PDB FROM v$database;

EXIT;
