-- Usage: sqlplus / as sysdba @oggadmin.sql <PDB_NAME> <USERNAME> <PASSWORD>

SET DEFINE ON
SET SERVEROUTPUT ON
PROMPT === Switching to PDB &1 ===

-- Enable ENABLE_GOLDENGATE_REPLICATION parameter
ALTER SYSTEM SET ENABLE_GOLDENGATE_REPLICATION=TRUE SCOPE=BOTH;

-- Switch to the target PDB
ALTER SESSION SET CONTAINER=&1;
SHOW CON_NAME;

DECLARE
    v_count NUMBER;
    v_user  VARCHAR2(30) := '&2';
    v_pass  VARCHAR2(30) := '&3';
BEGIN
    -- Check if user exists
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = UPPER(v_user);

    IF v_count = 0 THEN
        -- Create user with default tablespace and quota
        EXECUTE IMMEDIATE 
            'CREATE USER ' || v_user || 
            ' IDENTIFIED BY ' || v_pass || 
            ' DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users';

        -- Grant required privileges
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT FLASHBACK ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY TRANSACTION TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_FLASHBACK TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_CAPTURE_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_APPLY_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_STREAMS_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT LOGMINING TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION, CONNECT, RESOURCE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY TRANSACTION TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT FLASHBACK ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_FLASHBACK TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_CAPTURE_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_APPLY_ADM TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER SYSTEM TO ' || v_user;

        -- Grant GoldenGate admin privilege
        DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE(v_user);
    END IF;
END;
/

-- Verify creation
SELECT username, account_status, common 
FROM dba_users 
WHERE username = UPPER('&2');

EXIT;
