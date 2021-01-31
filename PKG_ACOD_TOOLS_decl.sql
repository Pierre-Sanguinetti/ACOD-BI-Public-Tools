CREATE OR REPLACE PACKAGE PKG_ACOD_TOOLS AS
-- Copyright (c) 2021 Pierre-Sanguinetti
-- v64+
/*
Package d'outils divers.
Ce package est public et peut �tre install� sur n'importe quel schemas.
*/

PROCEDURE EXECUTE_IMMEDIATE(sText IN VARCHAR2);
/*
Description
--+----+---
Execute une commande SQL dynamique.
Utilis�e pour faire des commandes DDL via un DB link.

Test
----
exec PKG_ACOD_TOOLS.EXECUTE_IMMEDIATE('DROP TABLE TMP')
*/

PROCEDURE DROP_TABLE(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0);
PROCEDURE DROP_TABLE(sTableName IN ALL_TABLES.TABLE_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0);
/*
Description
--+----+---
Detruit une table.

Test
----
set serveroutput on size 1000000
exec PKG_ACOD_TOOLS.DROP_TABLE('TMP')
*/


PROCEDURE DROP_MVIEW(sOwner IN ALL_MVIEWS.OWNER%TYPE, sMViewName IN ALL_MVIEWS.MVIEW_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1);
PROCEDURE DROP_MVIEW(sMViewName IN ALL_MVIEWS.MVIEW_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1);
/*
Description
--+----+---
Detruit une vue materialis�e.

Test
----
set serveroutput on size 1000000
exec PKG_ACOD_TOOLS.DROP_MVIEW('TMP')
*/


PROCEDURE DROP_OBJECT(sOwner IN ALL_OBJECTS.OWNER%TYPE, sObjectName IN ALL_OBJECTS.OBJECT_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0);
PROCEDURE DROP_OBJECT(sObjectName IN ALL_OBJECTS.OBJECT_NAME%TYPE, iSkipDoesNotExist INTEGER DEFAULT 1, iCascade INTEGER DEFAULT 0);
/*
Description
--+----+---
Detruit un object.

Test
----
*/


PROCEDURE DROP_TABLE_BACKUP_DATA(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE, sBackupTableName IN ALL_TABLES.TABLE_NAME%TYPE DEFAULT NULL, iCascade INTEGER DEFAULT 0);
PROCEDURE DROP_TABLE_BACKUP_DATA(sTableName IN ALL_TABLES.TABLE_NAME%TYPE, sBackupTableName IN ALL_TABLES.TABLE_NAME%TYPE DEFAULT NULL, iCascade INTEGER DEFAULT 0);
/*
Description
--+----+---
Sauvegarde les donnees d'une table en d�truisant tous les objets associ�s � la table et en renommant celle-ci.

Test
----
*/


PROCEDURE COMPILE_1OWNER(sOWNER VARCHAR2 DEFAULT USER, bVerbose IN BOOLEAN DEFAULT TRUE, bDebug IN BOOLEAN DEFAULT TRUE);
/*
Description
--+----+---
Compile les objects d'un utilisateur.

Test
----
set serveroutput on size 1000000
exec PKG_ACOD_TOOLS.COMPILE_1OWNER(USER)
*/


PROCEDURE ALTER_TABLE_DISABLE_FK(
   sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
PROCEDURE ALTER_TABLE_DISABLE_FK(sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
/*
Description
--+----+--
Desactive les FK d'une table.

Test
----
exec PKG_ACOD_TOOLS.ALTER_TABLE_DISABLE_FK(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/

PROCEDURE ALTER_TABLE_ENABLE_FK(
   sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0);
PROCEDURE ALTER_TABLE_ENABLE_FK(
   sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0);
/*
Description
--+----+---
Reactive les FK d'une table sans les v�rifier (NOVALIDATE).

Test
----
exec PKG_ACOD_TOOLS.ALTER_TABLE_ENABLE_FK(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/

PROCEDURE ALTER_TABLE_ENABLE_CHILD_FK(
   sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0);
PROCEDURE ALTER_TABLE_ENABLE_CHILD_FK(
   sTableName IN ALL_TABLES.TABLE_NAME%TYPE,
   iValidate INTEGER DEFAULT 0);
/*
Description
--+----+---
Reactive les FK faisant r�f�rence � une table sans les v�rifier (NOVALIDATE).

Test
----
exec PKG_ACOD_TOOLS.ALTER_TABLE_ENABLE_CHILD_FK(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1', 'CHILD_TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1', 'CHILD_TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/


PROCEDURE ALTER_TABLE_UNUSABLE_INDEXES(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
PROCEDURE ALTER_TABLE_UNUSABLE_INDEXES(sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
/*
Description
--+----+---
Rend inutilisables (UNUSABLE STATUS) les indexes d'une table.

Test
----
ALTER SESSION SET SKIP_UNUSABLE_INDEXES = TRUE;
exec PKG_ACOD_TOOLS.ALTER_TABLE_UNUSABLE_INDEXES(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/

PROCEDURE ALTER_TABLE_REBUILD_INDEXES(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
PROCEDURE ALTER_TABLE_REBUILD_INDEXES(sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
/*
Description
--+----+---
Reconstruit (REBUILD) les indexes d'une table.

Test
----
exec PKG_ACOD_TOOLS.ALTER_TABLE_REBUILD_INDEXES(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/


PROCEDURE ALTER_TABLE_BEFORE_DLOAD(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
PROCEDURE ALTER_TABLE_BEFORE_DLOAD(sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
/*
Description
--+----+---
Rend inutilisables (UNUSABLE STATUS) les indexes d'une table.
D�sactive les �ventuelles constraintes d'unicit�.
Pour que l'alimentation de la table soit convenablement pr�par�e par cette proc�dure,
les �ventuelles contraintes d'unicit� doivent s'appuyer sur des indexes non uniques.


Test
----
ALTER SESSION SET SKIP_UNUSABLE_INDEXES = TRUE;
exec PKG_ACOD_TOOLS.ALTER_TABLE_BEFORE_DLOAD(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/

PROCEDURE ALTER_TABLE_AFTER_DLOAD(sOwner IN ALL_TABLES.OWNER%TYPE, sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
PROCEDURE ALTER_TABLE_AFTER_DLOAD(sTableName IN ALL_TABLES.TABLE_NAME%TYPE);
/*
Description
--+----+---
Reconstruit (REBUILD) les indexes d'une table.
R�active les �ventuelles constraintes d'unicit�.

Test
----
exec PKG_ACOD_TOOLS.ALTER_TABLE_AFTER_DLOAD(USER, 'TST1')

SELECT STATUS, USER_INDEXES.* FROM USER_INDEXES
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, INDEX_NAME;

SELECT STATUS, VALIDATED, RELY, USER_CONSTRAINTS.* FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN('TST1') ORDER BY TABLE_NAME, CONSTRAINT_NAME;

*/

/*
Outils divers specifiques aux datamarts ACOD.
*/

PROCEDURE DTM_CLEAN(sDTM_TABLE_PREFIX IN VARCHAR2 DEFAULT NULL, sDTM_TABLE_SUFFIX IN VARCHAR2 DEFAULT NULL);
/*
Description
-----------
Detruit toutes les structures du datamart creees par le generateur.
La procedure se base sur les prefixes des noms d'objets.

Context
-------
Aucun.

Test
----
exec PKG_ACOD_TOOLS.DTM_CLEAN

*/


END PKG_ACOD_TOOLS;
/
show err