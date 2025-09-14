-- Usage: sqlplus / as sysdba @oggadmin.sql <PDB_NAME> <USERNAME> <PASSWORD>

SET DEFINE ON
SET SERVEROUTPUT ON
PROMPT === Enabling GoldenGate Replication in CDB$ROOT ===

-- Enable GoldenGate replication at CDB level
ALTER SYSTEM SET ENABLE_GOLDENGATE_REPLICATION=TRUE SCOPE=BOTH;

-- Switch to CDB$ROOT (for confirmation only)
ALTER SESSION SET CONTAINER=CDB$ROOT;
SHOW CON_NAME;

-- Switch to target PDB
PROMPT === Switching to PDB &1 ===
ALTER SESSION SET CONTAINER=&1;
SHOW CON_NAME;

-- Create OGGADMIN user in PDB if it doesn't exist and grant privileges
DECLARE
    v_count NUMBER;
    v_user  VARCHAR2(30) := '&2';
    v_pass  VARCHAR2(30) := '&3';
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = UPPER(v_user);

    IF v_count = 0 THEN
        -- Create user
        EXECUTE IMMEDIATE 
            'CREATE USER ' || v_user || 
            ' IDENTIFIED BY ' || v_pass || 
            ' DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users';

        -- Grant required privileges
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION, CONNECT, RESOURCE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT FLASHBACK ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY TRANSACTION TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER SYSTEM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_FLASHBACK TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_CAPTURE_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_APPLY_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_STREAMS_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT LOGMINING TO ' || v_user;

        -- Grant GoldenGate admin privilege
        DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE(v_user);

        DBMS_OUTPUT.PUT_LINE('OGGADMIN user created and privileges granted in PDB ' || SYS_CONTEXT('USERENV','CON_NAME'));
    ELSE
        DBMS_OUTPUT.PUT_LINE('OGGADMIN user already exists in PDB ' || SYS_CONTEXT('USERENV','CON_NAME'));
    END IF;
END;
/
-- Build LogMiner dictionary in PDB (outside PL/SQL block)
PROMPT === Building LogMiner dictionary in PDB &1 ===
EXEC DBMS_LOGMNR_D.BUILD(OPTIONS => DBMS_LOGMNR_D.STORE_IN_REDO_LOGS);

-- Verify creation
SELECT username, account_status, common 
FROM dba_users 
WHERE username = UPPER('&2');

EXIT;
