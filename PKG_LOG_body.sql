CREATE OR REPLACE PACKAGE BODY PKG_LOG AS

iIndent INTEGER := 0;
iLvl INTEGER := 0;

PROCEDURE LOG_LINE(sText IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iCommitLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ')
IS
BEGIN
   IF iLvl <= NVL(iInsLvl, iDefaultInsLvl) THEN
      INSERT INTO LOGT(LOGT_ID, LOGT_TIME, LOGT_TEXT, LOGT_INDENT, LOGT_LVL)VALUES(SEQ_LOGT.NEXTVAL, CURRENT_TIMESTAMP, sText, iIndent, iLvl);
      IF iLvl <= NVL(iCommitLvl, iDefaultCommitLvl) THEN
         COMMIT;
      END IF;
   END IF;
   IF iLvl <= NVL(iOutputLvl, iDefaultOutputLvl) THEN
      DBMS_OUTPUT.PUT_LINE('.' || RPAD(sPad, iIndent*LENGTH(sPad), sPad) || sText);
   END IF;
END LOG_LINE;

PROCEDURE LOG_INDENT_INC(bDoModififyLvl IN BOOLEAN DEFAULT TRUE, iNbLevel IN INTEGER DEFAULT 1)
IS
BEGIN
   --MOD_20211016.exc_err_log
   iIndent := iIndent + iNbLevel;
   IF bDoModififyLvl THEN
      LOG_LVL_INC(iNbLevel);
   END IF;
END LOG_INDENT_INC;

PROCEDURE LOG_INDENT_DEC(bDoModififyLvl IN BOOLEAN DEFAULT TRUE, iNbLevel IN INTEGER DEFAULT 1)
IS
BEGIN
   --MOD_20211016.exc_err_log
   iIndent := iIndent - iNbLevel;
   IF bDoModififyLvl THEN
      LOG_LVL_DEC(iNbLevel);
   END IF;
END LOG_INDENT_DEC;

PROCEDURE LOG_LVL_INC(iNbLevel IN INTEGER DEFAULT 1)
IS
BEGIN
   --MOD_20211016.exc_err_log
   iLvl := iLvl + iNbLevel;
END LOG_LVL_INC;

PROCEDURE LOG_LVL_DEC(iNbLevel IN INTEGER DEFAULT 1)
IS
BEGIN
   --MOD_20211016.exc_err_log
   iLvl := iLvl - iNbLevel;
END LOG_LVL_DEC;

PROCEDURE LOG_BEGIN(sProcName IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iCommitLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ', bDoModififyLvl IN BOOLEAN DEFAULT TRUE)
IS
BEGIN
   LOG_LINE('BEGIN<' || sProcName || '>', iInsLvl, iCommitLvl, iOutputLvl, sPad);
   LOG_INDENT_INC(bDoModififyLvl);
END LOG_BEGIN;

--MOD_20200120.exc_warning
PROCEDURE LOG_END2(sProcName IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iCommitLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ', bDoModififyLvl IN BOOLEAN DEFAULT TRUE, iExitCode IN INTEGER DEFAULT NULL)
IS
   sLine VARCHAR2(4000);
BEGIN
   LOG_INDENT_DEC(bDoModififyLvl);
   IF iExitCode IS NULL THEN
      sLine := 'END<' || sProcName || '>';
   ELSIF iExitCode = 0 THEN
      sLine := 'END<' || sProcName || '>(Success)';
   ELSIF iExitCode < 0 THEN
      sLine := 'END<' || sProcName || '>(Error(s))';
   ELSIF iExitCode > 0 THEN
      sLine := 'END<' || sProcName || '>(Warning(s))';
   END IF;
   LOG_LINE(sLine, iInsLvl, iCommitLvl, iOutputLvl, sPad);
END LOG_END2;

PROCEDURE LOG_END(sProcName IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iCommitLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ', bDoModififyLvl IN BOOLEAN DEFAULT TRUE, bSuccess BOOLEAN DEFAULT NULL)
IS
   sLine VARCHAR2(4000);
BEGIN
   LOG_INDENT_DEC(bDoModififyLvl);
   IF bSuccess IS NULL THEN
      sLine := 'END<' || sProcName || '>';
   ELSIF bSuccess THEN
      sLine := 'END<' || sProcName || '>(Success)';
   ELSE
      sLine := 'END<' || sProcName || '>(Error(s))';
   END IF;
   LOG_LINE(sLine, iInsLvl, iCommitLvl, iOutputLvl, sPad);
END LOG_END;

PROCEDURE LOG_LINE_NC(sText IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ')
IS
BEGIN
   IF iLvl <= NVL(iInsLvl, iDefaultInsLvl) THEN
      INSERT INTO LOGT(LOGT_ID, LOGT_TIME, LOGT_TEXT, LOGT_INDENT, LOGT_LVL)VALUES(SEQ_LOGT.NEXTVAL, CURRENT_TIMESTAMP, sText, iIndent, iLvl);
   END IF;
   IF iLvl <= NVL(iOutputLvl, iDefaultOutputLvl) THEN
      DBMS_OUTPUT.PUT_LINE('.' || RPAD(sPad, iIndent*LENGTH(sPad), sPad) || sText);
   END IF;
END LOG_LINE_NC;

PROCEDURE LOG_BEGIN_NC(sProcName IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ', bDoModififyLvl IN BOOLEAN DEFAULT TRUE)
IS
BEGIN
   LOG_LINE_NC('BEGIN<' || sProcName || '>', iInsLvl, iOutputLvl, sPad);
   LOG_INDENT_INC(bDoModififyLvl);
END LOG_BEGIN_NC;

PROCEDURE LOG_END_NC(sProcName IN VARCHAR2, iInsLvl IN INTEGER DEFAULT NULL, iOutputLvl IN INTEGER DEFAULT NULL, sPad IN VARCHAR2 DEFAULT '   ', bDoModififyLvl IN BOOLEAN DEFAULT TRUE)
IS
BEGIN
   LOG_INDENT_DEC(bDoModififyLvl);
   LOG_LINE_NC('END<' || sProcName || '>', iInsLvl, iOutputLvl, sPad);
END LOG_END_NC;

END PKG_LOG;
/
show err
