create sequence SEQ_LOGT;

/*==============================================================*/
/* Table : LOGT                                                 */
/*==============================================================*/
prompt Create Table LOGT
create table LOGT  (
   LOGT_ID              INTEGER                         not null,
   LOGT_TIME            TIMESTAMP                       not null,
   LOGT_TEXT            VARCHAR2(4000),
   LOGT_INDENT          INTEGER                        default 0
      constraint CKC_LOGT_INDENT_LOGT check (LOGT_INDENT is null or (LOGT_INDENT >= 0)),
   LOGT_LVL             INTEGER                        default 0
      constraint CKC_LOGT_LVL_LOGT check (LOGT_LVL is null or (LOGT_LVL >= 0))
);

exec DBMS_STATS.LOCK_TABLE_STATS(USER, 'LOGT')

alter table LOGT
   add constraint PK_LOGT primary key (LOGT_ID);

