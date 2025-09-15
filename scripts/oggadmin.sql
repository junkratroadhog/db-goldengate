-- Usage: sqlplus / as sysdba @oggadmin.sql <PDB_NAME> <USERNAME> <PASSWORD>

SET DEFINE ON
SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100

PROMPT === Enabling GoldenGate Replication in CDB$ROOT ===

-- Enable GoldenGate replication at CDB level
ALTER SYSTEM SET ENABLE_GOLDENGATE_REPLICATION=TRUE SCOPE=BOTH;
ALTER SYSTEM SET STREAMS_POOL_SIZE=512M SCOPE=BOTH;

-- Enable supplemental logging at the CDB level
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY, UNIQUE, FOREIGN KEY) COLUMNS;

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
    v_user  VARCHAR2(30) := UPPER('&2');
    v_pass  VARCHAR2(30) := '&3';
    v_table VARCHAR2(30) := '&4';
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = v_user;

    IF v_count = 0 THEN
        -- Create user with unlimited quota on USERS tablespace
        EXECUTE IMMEDIATE 
            'CREATE USER ' || v_user || 
            ' IDENTIFIED BY ''' || v_pass || '''' ||
            ' DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users';

        DBMS_OUTPUT.PUT_LINE('OGGADMIN user created in PDB ' || SYS_CONTEXT('USERENV','CON_NAME'));
    ELSE
        DBMS_OUTPUT.PUT_LINE('OGGADMIN user already exists in PDB ' || SYS_CONTEXT('USERENV','CON_NAME'));

        -- Ensure quota, password, and unlock
        EXECUTE IMMEDIATE 'ALTER USER ' || v_user || ' QUOTA UNLIMITED ON USERS';
        EXECUTE IMMEDIATE 'ALTER USER ' || v_user || ' IDENTIFIED BY ''' || v_pass || '''';
        EXECUTE IMMEDIATE 'ALTER USER ' || v_user || ' ACCOUNT UNLOCK';
    END IF;

    -- Grant required system privileges
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, CONNECT, RESOURCE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT FLASHBACK ANY TABLE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ANY TRANSACTION TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT ALTER ANY TABLE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT ALTER SYSTEM TO ' || v_user;

    -- Grant required EXECUTE privileges
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_FLASHBACK TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_LOGMNR TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_LOGMNR_D TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_CAPTURE_ADM TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_APPLY_ADM TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_STREAMS_ADM TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT LOGMINING TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_GOLDENGATE_AUTH TO ' || v_user;

    -- Grant XStream / GoldenGate packages for Integrated Replicat
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_XSTREAM_ADM TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_XSTREAM_GG_ADMIN TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_XSTREAM_GG_ADM TO ' || v_user;

    -- Required SELECT privileges on V$ views for logmining
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$DATABASE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$THREAD TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$PARAMETER TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$TIMEZONE_NAMES TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$ARCHIVED_LOG TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$LOG TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$LOGFILE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$LOGMNR_LOGS TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$LOGMNR_CONTENTS TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$TRANSACTION TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$SESSION TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$INSTANCE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$DATABASE_INCARNATION TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$TABLESPACE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$DATAFILE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$TEMPFILE TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$SYSTEM_PARAMETER TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$PROCESS TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$SESS_IO TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$ROLLNAME TO ' || v_user;
    EXECUTE IMMEDIATE 'GRANT SELECT ON V_$ROLLSTAT TO ' || v_user;

    -- Grant GoldenGate admin privilege across all containers
    DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE(v_user, CONTAINER => 'ALL');

    DBMS_OUTPUT.PUT_LINE('Privileges granted to OGGADMIN in PDB ' || SYS_CONTEXT('USERENV','CON_NAME'));
END;
/

    -- Dynamically enable table-level supplemental logging for the table if provided
    IF v_table IS NOT NULL THEN
        BEGIN
            EXECUTE IMMEDIATE 
                'ALTER TABLE ' || v_table || 
                ' ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY, UNIQUE, FOREIGN KEY) COLUMNS';
            DBMS_OUTPUT.PUT_LINE('Supplemental logging enabled for table ' || v_table);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Warning: Could not enable supplemental logging for table ' || v_table || '. ' || SQLERRM);
        END;
    END IF;

END;
/

-- Insert minimal redo activity to populate LogMiner dictionary
PROMPT === Creating minimal redo activity for LogMiner ===
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE logminer_dummy(id NUMBER)';
    EXECUTE IMMEDIATE 'INSERT INTO logminer_dummy VALUES(1)';
    EXECUTE IMMEDIATE 'COMMIT';
    EXECUTE IMMEDIATE 'DROP TABLE logminer_dummy';
    EXECUTE IMMEDIATE 'COMMIT';
END;
/

-- Build LogMiner dictionary in PDB
PROMPT === Building LogMiner dictionary in PDB &1 ===
EXEC DBMS_LOGMNR_D.BUILD(OPTIONS => DBMS_LOGMNR_D.STORE_IN_REDO_LOGS);

-- Verify creation
SELECT username, account_status, common 
FROM dba_users 
WHERE username = UPPER('&2');

EXIT;
