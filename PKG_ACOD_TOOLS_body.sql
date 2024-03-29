CREATE OR REPLACE PACKAGE BODY PKG_ACOD_TOOLS AS
-- Copyright (c) 2021 Pierre-Sanguinetti
-- v65+
table_does_not_exist EXCEPTION;
PRAGMA EXCEPTION_INIT(table_does_not_exist, -942);

dimension_does_not_exist EXCEPTION;
PRAGMA EXCEPTION_INIT(dimension_does_not_exist, -30333);

mview_does_not_exist EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_does_not_exist, -12003);

/*-----
PROCEDURE EXECUTE_IMMEDIATE(sText IN VARCHAR2)
IS
BEGIN
   EXECUTE IMMEDIATE sText;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(sText);
      RAISE;
END EXECUTE_IMMEDIATE;
*/
PROCEDURE EXECUTE_IMMEDIATE(sText IN VARCHAR2)
IS
BEGIN
   EXECUTE IMMEDIATE sText;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20000, 'Statement : ' || NVL(SUBSTR(sText, 1, 2000), '<NULL>') || CHR(10) || 'Error : ' || NVL(SQLERRM, '<NULL>'));
END EXECUTE_IMMEDIATE;

PROCEDURE CHECK_TABLE_NAME(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   DECLARE
      iCount INTEGER;
   BEGIN
      SELECT COUNT(*) INTO iCOunt
         FROM ALL_TABLES
         WHERE OWNER = sOwner
         AND TABLE_NAME = sTableName;
      IF iCount = 0 THEN
         RAISE_APPLICATION_ERROR(-20000, 'Table ' || NVL(sOwner, '<NULL>') || '.' || NVL(sTableName, '<NULL>') || ' does not exist.');
      END IF;
   END;
END CHECK_TABLE_NAME;

PROCEDURE DROP_TABLE(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0)
IS
   sSQL VARCHAR2(250);
BEGIN
   sSQL := 'DROP TABLE ' || sOwner || '.' || sTableName;
   IF iCascade = 1 THEN
      sSQL := sSQL || ' CASCADE CONSTRAINTS';
   END IF;
   EXECUTE IMMEDIATE sSQL;
EXCEPTION
   WHEN table_does_not_exist THEN
      IF iSkipDoesNotExist = 0 THEN
         RAISE;
      END IF;
END DROP_TABLE;

PROCEDURE DROP_TABLE(sTableName IN ALL_TABLES.TABLE_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0)
IS
BEGIN
   DROP_TABLE(USER, sTableName, iSkipDoesNotExist, iCascade);
END DROP_TABLE;

PROCEDURE DROP_MVIEW(sOwner IN ALL_MVIEWS.OWNER%TYPE, sMViewName IN ALL_MVIEWS.MVIEW_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1)
IS
   sSQL VARCHAR2(250);
BEGIN
   sSQL := 'DROP MATERIALIZED VIEW ' || sOwner || '.' || sMViewName;
   EXECUTE IMMEDIATE sSQL;
EXCEPTION
   WHEN mview_does_not_exist THEN
      IF iSkipDoesNotExist = 0 THEN
         RAISE;
      END IF;
END DROP_MVIEW;

PROCEDURE DROP_MVIEW(sMViewName IN ALL_MVIEWS.MVIEW_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1)
IS
BEGIN
   DROP_MVIEW(USER, sMViewName, iSkipDoesNotExist);
END DROP_MVIEW;

PROCEDURE DROP_OBJECT(sOwner IN ALL_OBJECTS.OWNER%TYPE, sObjectName IN ALL_OBJECTS.OBJECT_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0)
IS
   sSQL VARCHAR2(250);
   bObjectExists BOOLEAN;
   sOBJECT_TYPE ALL_OBJECTS.OBJECT_TYPE%TYPE;
BEGIN
   BEGIN
      SELECT OBJECT_TYPE INTO sOBJECT_TYPE
         FROM ALL_OBJECTS
         WHERE ALL_OBJECTS.OWNER = sOWNER
            AND ALL_OBJECTS.OBJECT_NAME = sObjectName
            AND ALL_OBJECTS.OBJECT_TYPE != 'PACKAGE BODY';
      bObjectExists := TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         bObjectExists := FALSE;
   END;
   IF bObjectExists THEN
      IF sOBJECT_TYPE = 'TABLE' THEN
         DROP_TABLE(sOwner, sObjectName, iSkipDoesNotExist, iCascade);
      ELSE
         sSQL := 'DROP ' || sOBJECT_TYPE || ' ' || sOwner || '.' || sObjectName;
         EXECUTE IMMEDIATE sSQL;
      END IF;
   ELSE
      IF iSkipDoesNotExist = 0 THEN
         RAISE_APPLICATION_ERROR(-20000, 'Object ' || NVL('"' || sOwner || '"."' || sObjectName || '"', NULL) || ' does not exist');
      END IF;
   END IF;
END DROP_OBJECT;

PROCEDURE DROP_OBJECT(sObjectName IN ALL_OBJECTS.OBJECT_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0)
IS
BEGIN
   DROP_OBJECT(USER, sObjectName, iSkipDoesNotExist, iCascade);
END DROP_OBJECT;

PROCEDURE DROP_TABLE_BACKUP_DATA(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE, sBackupTableName IN ALL_TABLES.TABLE_NAME%TYPE DEFAULT NULL, iCascade INTEGER DEFAULT 0)
IS
   sSQL VARCHAR2(250);
   sRealBackupTableName VARCHAR2(30);
BEGIN
   IF sBackupTableName IS NOT NULL THEN
      sRealBackupTableName := sBackupTableName;
   ELSE
      sRealBackupTableName := SUBSTR(sTableName, 1, 26) || '_OLD';
   END IF;
   DECLARE
      CURSOR cTrigger IS
         SELECT OWNER, TRIGGER_NAME
            FROM ALL_TRIGGERS
            WHERE TABLE_OWNER=sOwner
               AND TABLE_NAME=sTableName;
   BEGIN
      FOR rTrigger IN cTrigger LOOP
         sSQL := 'DROP TRIGGER ' || rTrigger.OWNER || '.' || rTrigger.TRIGGER_NAME;
         EXECUTE IMMEDIATE sSQL;
      END LOOP;
   END;
   DECLARE
      CURSOR cCons IS
         SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE
            FROM ALL_CONSTRAINTS
            WHERE OWNER=sOwner
               AND TABLE_NAME = sTableName
            ORDER BY CONSTRAINT_TYPE, CONSTRAINT_NAME;
   BEGIN
      FOR rCons IN cCons LOOP
         sSQL := 'ALTER TABLE ' || sOwner || '.' || sTableName || ' DROP CONSTRAINT ' || rCons.CONSTRAINT_NAME;
         IF iCascade > 0 AND rCons.CONSTRAINT_TYPE IN ('U', 'P') THEN
            sSQL := sSQL || ' CASCADE';
         END IF;
         EXECUTE IMMEDIATE sSQL;
      END LOOP;
   END;
   DECLARE
      CURSOR cInd IS
         SELECT OWNER, INDEX_NAME
            FROM ALL_INDEXES
            WHERE TABLE_OWNER=sOwner
               AND TABLE_NAME=sTableName
               AND INDEX_TYPE <> 'LOB';
   BEGIN
      FOR rInd IN cInd LOOP
         sSQL := 'DROP INDEX ' || rInd.OWNER || '.' || rInd.INDEX_NAME;
         EXECUTE IMMEDIATE sSQL;
      END LOOP;
   END;
   sSQL := 'ALTER TABLE ' || sOwner || '.' || sTableName || ' RENAME TO ' || sRealBackupTableName;
   EXECUTE IMMEDIATE sSQL;
END DROP_TABLE_BACKUP_DATA;

PROCEDURE DROP_TABLE_BACKUP_DATA(sTableName IN ALL_TABLES.TABLE_NAME%TYPE, sBackupTableName IN ALL_TABLES.TABLE_NAME%TYPE DEFAULT NULL, iCascade INTEGER DEFAULT 0)
IS
BEGIN
   DROP_TABLE_BACKUP_DATA(USER, sTableName, sBackupTableName, iCascade);
END DROP_TABLE_BACKUP_DATA;

PROCEDURE COMPILE_1OWNER(sOWNER VARCHAR2 DEFAULT USER, bVerbose IN BOOLEAN DEFAULT TRUE, bDebug IN BOOLEAN DEFAULT TRUE)
IS
   CURSOR cObjectsWithCompilation IS
      SELECT
         OBJECT_NAME,
         OBJECT_TYPE
      FROM ALL_OBJECTS
      WHERE OWNER = sOwner
         AND OBJECT_TYPE IN ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'TRIGGER')
         AND OBJECT_NAME <> 'PKG_ACOD_TOOLS'
         ----- MOD_20190114_Exchange AND NOT EXISTS(SELECT 1 FROM ALL_RECYCLEBIN WHERE ALL_RECYCLEBIN.OWNER = ALL_OBJECTS.OWNER AND ALL_RECYCLEBIN.OBJECT_NAME = ALL_OBJECTS.OBJECT_NAME)
      ORDER BY
         OBJECT_TYPE,
         OBJECT_NAME;

   sSQLStatement VARCHAR2(4000);

   --MOD_20190114_Exchange
   --!!!!! erreur non incluse dans success_with_compilation_error
   db_link_error EXCEPTION;
   PRAGMA EXCEPTION_INIT(db_link_error, -04052);

   success_with_compilation_error EXCEPTION;
   PRAGMA EXCEPTION_INIT(success_with_compilation_error, -24344);
   bCompilationErrors BOOLEAN;

   PROCEDURE EXECUTE_IMMEDIATE
   IS
   BEGIN
      IF bVerbose THEN
         DBMS_OUTPUT.PUT_LINE(sSQLStatement || ';');
      END IF;
      BEGIN
         EXECUTE IMMEDIATE sSQLStatement;
      EXCEPTION
         WHEN success_with_compilation_error THEN
            IF bVerbose THEN
               DBMS_OUTPUT.PUT_LINE(SQLERRM);
            END IF;
            bCompilationErrors := TRUE;
         --MOD_20190114_Exchange
         WHEN db_link_error THEN
            IF bVerbose THEN
               DBMS_OUTPUT.PUT_LINE(SQLERRM);
            END IF;
            -- bCompilationErrors := TRUE;
      END;
   END;

BEGIN
   bCompilationErrors := FALSE;
   FOR recObject IN cObjectsWithCompilation LOOP
      sSQLStatement := 'ALTER ' || recObject.OBJECT_TYPE || '  ' || sOWNER || '.' || recObject.OBJECT_NAME || ' COMPILE';
      IF bDebug THEN
         sSQLStatement := sSQLStatement || ' DEBUG';
      END IF;
      --MOD_20190114_Exchange
      /*-----
      BEGIN
         EXECUTE_IMMEDIATE;
      EXCEPTION
         WHEN success_with_compilation_error THEN
            bCompilationErrors := TRUE;
      END;
      */
      EXECUTE_IMMEDIATE;
   END LOOP;
   IF bCompilationErrors THEN
      RAISE success_with_compilation_error;
   END IF;
END COMPILE_1OWNER;

PROCEDURE ALTER_TABLE_DISABLE_FK(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
/*
ALTER SESSION SET SKIP_UNUSABLE_INDEXES = TRUE;

exec PKG_ACOD_TOOLS.ALTER_TABLE_DISABLE_FK(USER, 'TST1')

*/
   CURSOR cCONSTRAINTS IS
      SELECT CONSTRAINT_NAME
      FROM ALL_CONSTRAINTS
      WHERE OWNER = sOwner
      AND TABLE_NAME = sTableName
      AND CONSTRAINT_TYPE = 'R'
      AND STATUS='ENABLED'
      ORDER BY OWNER, INDEX_NAME;

   TYPE ttCONSTRAINTS IS TABLE OF cCONSTRAINTS%ROWTYPE;
   tCONSTRAINTS ttCONSTRAINTS;
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tCONSTRAINTS := ttCONSTRAINTS(null);
   FOR recCONSTRAINTS IN cCONSTRAINTS LOOP
      tCONSTRAINTS.EXTEND;
      tCONSTRAINTS(cCONSTRAINTS%ROWCOUNT) := recCONSTRAINTS;
   END LOOP;
   FOR iConstraint IN tCONSTRAINTS.FIRST .. tCONSTRAINTS.LAST-1 LOOP
      sSql := 'ALTER TABLE ' || sOwner || '.' || sTableName || ' DISABLE CONSTRAINT ' || tCONSTRAINTS(iConstraint).CONSTRAINT_NAME;
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_DISABLE_FK;

PROCEDURE ALTER_TABLE_DISABLE_FK(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_DISABLE_FK(USER, sTableName);
END ALTER_TABLE_DISABLE_FK;

PROCEDURE ALTER_TABLE_ENABLE_FK(
   sOwner IN ALL_TABLES.OWNER%TYPE,
   sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0)
IS
/*
exec PKG_ACOD_TOOLS.ALTER_TABLE_ENABLE_FK(USER, 'TST1')

ALTER SESSION SET SKIP_UNUSABLE_INDEXES = FALSE;

*/
   CURSOR cCONSTRAINTS IS
      SELECT CONSTRAINT_NAME
      FROM ALL_CONSTRAINTS
      WHERE OWNER = sOwner
      AND TABLE_NAME = sTableName
      AND CONSTRAINT_TYPE = 'R'
      AND STATUS='DISABLED'
      ORDER BY OWNER, INDEX_NAME;

   TYPE ttCONSTRAINTS IS TABLE OF cCONSTRAINTS%ROWTYPE;
   tCONSTRAINTS ttCONSTRAINTS;
   --
   sValidateClause VARCHAR2(250);
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tCONSTRAINTS := ttCONSTRAINTS(null);
   FOR recCONSTRAINTS IN cCONSTRAINTS LOOP
      tCONSTRAINTS.EXTEND;
      tCONSTRAINTS(cCONSTRAINTS%ROWCOUNT) := recCONSTRAINTS;
   END LOOP;
   IF iValidate = 0 THEN
      sValidateClause := 'NOVALIDATE';
   ELSE
      sValidateClause := 'VALIDATE';
   END IF;
   FOR iConstraint IN tCONSTRAINTS.FIRST .. tCONSTRAINTS.LAST-1 LOOP
      sSql := 'ALTER TABLE ' || sOwner || '.' || sTableName || ' ENABLE ' || sValidateClause || ' CONSTRAINT ' || tCONSTRAINTS(iConstraint).CONSTRAINT_NAME;
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_ENABLE_FK;

PROCEDURE ALTER_TABLE_ENABLE_FK(
   sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0)
IS
BEGIN
   ALTER_TABLE_ENABLE_FK(USER, sTableName, iValidate);
END ALTER_TABLE_ENABLE_FK;

PROCEDURE ALTER_TABLE_ENABLE_CHILD_FK(
   sOwner IN ALL_TABLES.OWNER%TYPE,
   sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0)
IS
   CURSOR cCONSTRAINTS IS
      SELECT CONS.OWNER, CONS.TABLE_NAME, CONS.CONSTRAINT_NAME
      FROM ALL_CONSTRAINTS CONS, ALL_CONSTRAINTS R_CONS
      WHERE CONS.R_OWNER=R_CONS.OWNER
      AND CONS.R_CONSTRAINT_NAME=R_CONS.CONSTRAINT_NAME
      AND CONS.CONSTRAINT_TYPE = 'R'
      AND R_CONS.OWNER = sOwner
      AND R_CONS.TABLE_NAME = sTableName
      AND CONS.STATUS='DISABLED'
      ORDER BY CONS.OWNER, CONS.TABLE_NAME, CONS.CONSTRAINT_NAME;

   TYPE ttCONSTRAINTS IS TABLE OF cCONSTRAINTS%ROWTYPE;
   tCONSTRAINTS ttCONSTRAINTS;
   --
   sValidateClause VARCHAR2(250);
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tCONSTRAINTS := ttCONSTRAINTS(null);
   FOR recCONSTRAINTS IN cCONSTRAINTS LOOP
      tCONSTRAINTS.EXTEND;
      tCONSTRAINTS(cCONSTRAINTS%ROWCOUNT) := recCONSTRAINTS;
   END LOOP;
   IF iValidate = 0 THEN
      sValidateClause := 'NOVALIDATE';
   ELSE
      sValidateClause := 'VALIDATE';
   END IF;
   FOR iConstraint IN tCONSTRAINTS.FIRST .. tCONSTRAINTS.LAST-1 LOOP
      sSql := 'ALTER TABLE ' || tCONSTRAINTS(iConstraint).OWNER || '.' || tCONSTRAINTS(iConstraint).TABLE_NAME || ' ENABLE ' || sValidateClause || ' CONSTRAINT ' || tCONSTRAINTS(iConstraint).CONSTRAINT_NAME;
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_ENABLE_CHILD_FK;

PROCEDURE ALTER_TABLE_ENABLE_CHILD_FK(
   sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0)
IS
BEGIN
   ALTER_TABLE_ENABLE_CHILD_FK(USER, sTableName, iValidate);
END ALTER_TABLE_ENABLE_CHILD_FK;

--MOD_20201121.dload_fk
PROCEDURE ALTER_TABLE_DISABLE_PK_UK(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
   CURSOR cCONSTRAINTS IS
      SELECT CONSTRAINT_NAME
      FROM ALL_CONSTRAINTS
      WHERE OWNER = sOwner
      AND TABLE_NAME = sTableName
      AND CONSTRAINT_TYPE IN ('P', 'U')
      ORDER BY OWNER, INDEX_NAME;

   TYPE ttCONSTRAINTS IS TABLE OF cCONSTRAINTS%ROWTYPE;
   tCONSTRAINTS ttCONSTRAINTS;
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tCONSTRAINTS := ttCONSTRAINTS(null);
   FOR recCONSTRAINTS IN cCONSTRAINTS LOOP
      tCONSTRAINTS.EXTEND;
      tCONSTRAINTS(cCONSTRAINTS%ROWCOUNT) := recCONSTRAINTS;
   END LOOP;
   FOR iConstraint IN tCONSTRAINTS.FIRST .. tCONSTRAINTS.LAST-1 LOOP
      sSql := 'ALTER TABLE ' || sOwner || '.' || sTableName || ' DISABLE CONSTRAINT ' || tCONSTRAINTS(iConstraint).CONSTRAINT_NAME;
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_DISABLE_PK_UK;

--MOD_20201121.dload_fk
PROCEDURE ALTER_TABLE_DISABLE_PK_UK(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_DISABLE_PK_UK(USER, sTableName);
END ALTER_TABLE_DISABLE_PK_UK;

--MOD_20201121.dload_fk
PROCEDURE ALTER_TABLE_ENABLE_PK_UK(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
   CURSOR cCONSTRAINTS IS
      SELECT CONSTRAINT_NAME
      FROM ALL_CONSTRAINTS
      WHERE OWNER = sOwner
      AND TABLE_NAME = sTableName
      AND CONSTRAINT_TYPE IN ('P', 'U')
      ORDER BY OWNER, INDEX_NAME;

   TYPE ttCONSTRAINTS IS TABLE OF cCONSTRAINTS%ROWTYPE;
   tCONSTRAINTS ttCONSTRAINTS;
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tCONSTRAINTS := ttCONSTRAINTS(null);
   FOR recCONSTRAINTS IN cCONSTRAINTS LOOP
      tCONSTRAINTS.EXTEND;
      tCONSTRAINTS(cCONSTRAINTS%ROWCOUNT) := recCONSTRAINTS;
   END LOOP;
   FOR iConstraint IN tCONSTRAINTS.FIRST .. tCONSTRAINTS.LAST-1 LOOP
      sSql := 'ALTER TABLE ' || sOwner || '.' || sTableName || ' ENABLE CONSTRAINT ' || tCONSTRAINTS(iConstraint).CONSTRAINT_NAME;
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_ENABLE_PK_UK;

--MOD_20201121.dload_fk
PROCEDURE ALTER_TABLE_ENABLE_PK_UK(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_ENABLE_PK_UK(USER, sTableName);
END ALTER_TABLE_ENABLE_PK_UK;

PROCEDURE ALTER_TABLE_UNUSABLE_INDEXES(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
/*
ALTER SESSION SET SKIP_UNUSABLE_INDEXES = TRUE;

exec PKG_ACOD_TOOLS.ALTER_TABLE_UNUSABLE_INDEXES(USER, 'TST1')

*/
   CURSOR cINDEXES IS
      SELECT OWNER, INDEX_NAME
      FROM ALL_INDEXES
      WHERE TABLE_OWNER = sOwner
      AND TABLE_NAME = sTableName
      ORDER BY OWNER, INDEX_NAME;

   TYPE ttINDEXES IS TABLE OF cINDEXES%ROWTYPE;
   tINDEXES ttINDEXES;
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tINDEXES := ttINDEXES(null);
   FOR recINDEXES IN cINDEXES LOOP
      tINDEXES.EXTEND;
      tINDEXES(cINDEXES%ROWCOUNT) := recINDEXES;
   END LOOP;
   FOR iIndex IN tINDEXES.FIRST .. tINDEXES.LAST-1 LOOP
      sSql := 'ALTER INDEX ' || tINDEXES(iIndex).OWNER || '.' || tINDEXES(iIndex).INDEX_NAME || ' UNUSABLE';
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_UNUSABLE_INDEXES;

PROCEDURE ALTER_TABLE_UNUSABLE_INDEXES(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_UNUSABLE_INDEXES(USER, sTableName);
END ALTER_TABLE_UNUSABLE_INDEXES;

PROCEDURE ALTER_TABLE_REBUILD_INDEXES(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
/*
exec PKG_ACOD_TOOLS.ALTER_TABLE_REBUILD_INDEXES(USER, 'TST1')

ALTER SESSION SET SKIP_UNUSABLE_INDEXES = FALSE;

*/
   CURSOR cINDEXES IS
      SELECT OWNER, INDEX_NAME
      FROM ALL_INDEXES
      WHERE TABLE_OWNER = sOwner
      AND TABLE_NAME = sTableName
      ORDER BY OWNER, INDEX_NAME;

   TYPE ttINDEXES IS TABLE OF cINDEXES%ROWTYPE;
   tINDEXES ttINDEXES;
   --
   sSql VARCHAR2(250);
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   tINDEXES := ttINDEXES(null);
   FOR recINDEXES IN cINDEXES LOOP
      tINDEXES.EXTEND;
      tINDEXES(cINDEXES%ROWCOUNT) := recINDEXES;
   END LOOP;
   FOR iIndex IN tINDEXES.FIRST .. tINDEXES.LAST-1 LOOP
      sSql := 'ALTER INDEX ' || tINDEXES(iIndex).OWNER || '.' || tINDEXES(iIndex).INDEX_NAME || ' REBUILD';
      EXECUTE IMMEDIATE sSql;
   END LOOP;
END ALTER_TABLE_REBUILD_INDEXES;

PROCEDURE ALTER_TABLE_REBUILD_INDEXES(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_REBUILD_INDEXES(USER, sTableName);
END ALTER_TABLE_REBUILD_INDEXES;

PROCEDURE ALTER_TABLE_BEFORE_DLOAD(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
/*
ALTER SESSION SET SKIP_UNUSABLE_INDEXES = TRUE;

exec PKG_ACOD_TOOLS.ALTER_TABLE_BEFORE_DLOAD(USER, 'TST1')

*/
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   --MOD_20201121.dload_fk
   ALTER_TABLE_DISABLE_PK_UK(sOwner, sTableName);
   --MOD_20201121.dload_fk
   ALTER_TABLE_DISABLE_FK(sOwner, sTableName);
   --
   ALTER_TABLE_UNUSABLE_INDEXES(sOwner, sTableName);
END ALTER_TABLE_BEFORE_DLOAD;

PROCEDURE ALTER_TABLE_BEFORE_DLOAD(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_BEFORE_DLOAD(USER, sTableName);
END ALTER_TABLE_BEFORE_DLOAD;

PROCEDURE ALTER_TABLE_AFTER_DLOAD(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
/*
exec PKG_ACOD_TOOLS.ALTER_TABLE_AFTER_DLOAD(USER, 'TST1')

ALTER SESSION SET SKIP_UNUSABLE_INDEXES = FALSE;

*/
BEGIN
   CHECK_TABLE_NAME(sOwner, sTableName);
   --
   ALTER_TABLE_REBUILD_INDEXES(sOwner, sTableName);
   --
   --MOD_20201121.dload_fk
   ALTER_TABLE_ENABLE_FK(sOwner, sTableName);
   --MOD_20201121.dload_fk
   ALTER_TABLE_ENABLE_PK_UK(sOwner, sTableName);
END ALTER_TABLE_AFTER_DLOAD;

PROCEDURE ALTER_TABLE_AFTER_DLOAD(sTableName IN ALL_TABLES.TABLE_NAME%TYPE)
IS
BEGIN
   ALTER_TABLE_AFTER_DLOAD(USER, sTableName);
END ALTER_TABLE_AFTER_DLOAD;

PROCEDURE DTM_CLEAN(
   sDTM_TABLE_PREFIX IN VARCHAR2 DEFAULT NULL,
   sDTM_TABLE_SUFFIX IN VARCHAR2 DEFAULT NULL
)
IS
BEGIN
   --------------------------------------------------------------------------------
   -- FT
   --------------------------------------------------------------------------------
   -- FK de tables ou MV de fait (FT ou FM)
   DECLARE
      CURSOR cFK IS
         SELECT TABLE_NAME, CONSTRAINT_NAME
         FROM USER_CONSTRAINTS, USER_USERS
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(USER_CONSTRAINTS.TABLE_NAME, 1, 3) IN ('FM_', 'FT_')
         WHERE REGEXP_LIKE(USER_CONSTRAINTS.TABLE_NAME, '^' || sDTM_TABLE_PREFIX || '(FM_|FT_)')
            AND REGEXP_LIKE(USER_CONSTRAINTS.TABLE_NAME, sDTM_TABLE_SUFFIX || '$')
         AND CONSTRAINT_TYPE = 'R';
   BEGIN
      FOR recFK IN cFK LOOP
         EXECUTE_IMMEDIATE('ALTER TABLE ' || recFK.TABLE_NAME || ' DROP CONSTRAINT ' || recFK.CONSTRAINT_NAME);
      END LOOP;
   END;

   -- Vues mat+rialis+es (FM)
   DECLARE
      CURSOR cVM IS
         SELECT OBJECT_NAME
         FROM USER_OBJECTS
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(OBJECT_NAME, 1, 3) IN ('FM_', 'MV$')
         WHERE REGEXP_LIKE(OBJECT_NAME, '^' || sDTM_TABLE_PREFIX || '(FM_|MV$)')
            AND REGEXP_LIKE(OBJECT_NAME, sDTM_TABLE_SUFFIX || '$')
            AND OBJECT_TYPE = 'MATERIALIZED VIEW';
   BEGIN
      FOR recVM IN cVM LOOP
         EXECUTE_IMMEDIATE('DROP MATERIALIZED VIEW ' || recVM.OBJECT_NAME);
      END LOOP;
   END;

   -- Vues (FV AV)
   DECLARE
      CURSOR cVM IS
         SELECT OBJECT_NAME
         FROM USER_OBJECTS
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(OBJECT_NAME, 1, 3) IN ('FV_', 'AV_')
         WHERE REGEXP_LIKE(OBJECT_NAME, '^' || sDTM_TABLE_PREFIX || '(FV_|AV_)')
            AND REGEXP_LIKE(OBJECT_NAME, sDTM_TABLE_SUFFIX || '$')
            AND OBJECT_TYPE = 'VIEW';
   BEGIN
      FOR recVM IN cVM LOOP
         EXECUTE_IMMEDIATE('DROP VIEW ' || recVM.OBJECT_NAME);
      END LOOP;
   END;

   -- Tables de fait (FT, FM)
   DECLARE
      CURSOR cDT IS
         SELECT TABLE_NAME
         FROM USER_TABLES
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(TABLE_NAME, 1, 3) IN ('FM_', 'FT_');
         WHERE REGEXP_LIKE(USER_TABLES.TABLE_NAME, '^' || sDTM_TABLE_PREFIX || '(FM_|FT_)')
            AND REGEXP_LIKE(USER_TABLES.TABLE_NAME, sDTM_TABLE_SUFFIX || '$');
   BEGIN
      FOR recDT IN cDT LOOP
         DROP_TABLE(recDT.TABLE_NAME);
      END LOOP;
   END;

   --------------------------------------------------------------------------------
   -- DT
   --------------------------------------------------------------------------------
   -- Dimensions (DI)
   DECLARE
      CURSOR cDI IS
         SELECT DIMENSION_NAME
         FROM USER_DIMENSIONS
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(DIMENSION_NAME, 1, 3) IN ('DI_');
         WHERE REGEXP_LIKE(DIMENSION_NAME, '^' || sDTM_TABLE_PREFIX || 'DI_')
            AND REGEXP_LIKE(DIMENSION_NAME, sDTM_TABLE_SUFFIX || '$');
   BEGIN
      FOR recDI IN cDI LOOP
         EXECUTE_IMMEDIATE('DROP DIMENSION ' || recDI.DIMENSION_NAME);
      END LOOP;
   END;

   -- FK de tables de dimension, de tables de niveau ou de vues mat+rialis+es
   DECLARE
      CURSOR cFK IS
         SELECT TABLE_NAME, CONSTRAINT_NAME
         FROM USER_CONSTRAINTS, USER_USERS
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(USER_CONSTRAINTS.TABLE_NAME, 1, 3) IN ('DT_', 'DM_', 'DX_', 'LT_')
         WHERE REGEXP_LIKE(USER_CONSTRAINTS.TABLE_NAME, '^' || sDTM_TABLE_PREFIX || '(DT_|DM_|DX_|LT_)')
            AND REGEXP_LIKE(USER_CONSTRAINTS.TABLE_NAME, sDTM_TABLE_SUFFIX || '$')
            AND CONSTRAINT_TYPE = 'R';
   BEGIN
      FOR recFK IN cFK LOOP
         EXECUTE_IMMEDIATE('ALTER TABLE ' || recFK.TABLE_NAME || ' DROP CONSTRAINT ' || recFK.CONSTRAINT_NAME);
      END LOOP;
   END;

   -- Vues mat+rialis+es (DM et DT)
   DECLARE
      CURSOR cVM IS
         SELECT OBJECT_NAME
         FROM USER_OBJECTS
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(OBJECT_NAME, 1, 3) IN ('DT_', 'DM_', 'DX_')
         WHERE REGEXP_LIKE(OBJECT_NAME, '^' || sDTM_TABLE_PREFIX || '(DT_|DM_|DX_)')
            AND REGEXP_LIKE(OBJECT_NAME, sDTM_TABLE_SUFFIX || '$')
            AND OBJECT_TYPE = 'MATERIALIZED VIEW';
   BEGIN
      FOR recVM IN cVM LOOP
         EXECUTE_IMMEDIATE('DROP MATERIALIZED VIEW ' || recVM.OBJECT_NAME);
      END LOOP;
   END;

   -- Tables de dimension de de niveau (DM, DT, LT)
   DECLARE
      CURSOR cDT IS
         SELECT TABLE_NAME
         FROM USER_TABLES
         --MOD_20200120.tab_prefix_suffix
         -----WHERE SUBSTR(TABLE_NAME, 1, 3) IN ('DT_', 'DM_', 'DX_', 'LT_');
         WHERE REGEXP_LIKE(TABLE_NAME, '^' || sDTM_TABLE_PREFIX || '(DT_|DM_|DX_|LT_)')
            AND REGEXP_LIKE(TABLE_NAME, sDTM_TABLE_SUFFIX || '$');
   BEGIN
      FOR recDT IN cDT LOOP
         DROP_TABLE(recDT.TABLE_NAME);
      END LOOP;
   END;
END DTM_CLEAN;

END PKG_ACOD_TOOLS;
/
show err
