-- Usage:
-- sqlplus / as sysdba @ogg_grants.sql <PDB_NAME> <USERNAME> <ROLE>
-- ROLE = CAPTURE for Extract side, APPLY for Replicat side

SET DEFINE ON
SET SERVEROUTPUT ON

PROMPT === Configuring GoldenGate user &2 in PDB &1 with role &3 ===

-- Switch to target PDB
ALTER SESSION SET CONTAINER=&1;

DECLARE
    v_user  VARCHAR2(30) := UPPER('&2');
    v_role  VARCHAR2(30) := UPPER('&3');
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = v_user;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: User ' || v_user || ' does not exist. Please create it manually first.');
    ELSE
        -- Core privileges (common for CAPTURE and APPLY)
        EXECUTE IMMEDIATE 'GRANT CONNECT, CREATE SESSION TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT FLASHBACK ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT SELECT ANY TRANSACTION TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER ANY TABLE TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT ALTER SYSTEM TO ' || v_user;

        -- Core package grants
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_FLASHBACK TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_LOGMNR TO ' || v_user;
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_LOGMNR_D TO ' || v_user;

        -- Role-specific grants
        IF v_role = 'CAPTURE' THEN
            EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_CAPTURE_ADM TO ' || v_user;
            DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE(v_user, privilege_type => 'CAPTURE', grant_select_privileges => TRUE);
            DBMS_OUTPUT.PUT_LINE('Granted CAPTURE privileges to ' || v_user);
        ELSIF v_role = 'APPLY' THEN
            EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_APPLY_ADM TO ' || v_user;
            DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE(v_user, privilege_type => 'APPLY', grant_select_privileges => TRUE);
            DBMS_OUTPUT.PUT_LINE('Granted APPLY privileges to ' || v_user);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Invalid role ' || v_role || ' (must be CAPTURE or APPLY).');
        END IF;
    END IF;
END;
/

EXIT;
