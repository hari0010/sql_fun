--DBMS_METADATA is used to retrieve object definitions as DDL or XML.
--Most used functions.
FUNCTION get_ddl (
  object_type         IN VARCHAR2,
  name                IN VARCHAR2,
  schema              IN VARCHAR2 DEFAULT NULL,
  version             IN VARCHAR2 DEFAULT 'COMPATIBLE',
  model               IN VARCHAR2 DEFAULT 'ORACLE',
  transform           IN VARCHAR2 DEFAULT NULL)
RETURN CLOB;

FUNCTION get_dependent_ddl (
  object_type         IN VARCHAR2,
  base_object_name    IN VARCHAR2,
  base_object_schema  IN VARCHAR2 DEFAULT NULL,
  version             IN VARCHAR2 DEFAULT 'COMPATIBLE',
  model               IN VARCHAR2 DEFAULT 'ORACLE',
  transform           IN VARCHAR2 DEFAULT 'DDL',
  object_count        IN NUMBER   DEFAULT 10000)
RETURN CLOB;

FUNCTION get_xml (
  object_type         IN VARCHAR2,
  name                IN VARCHAR2,
  schema              IN VARCHAR2 DEFAULT NULL,
  version             IN VARCHAR2 DEFAULT 'COMPATIBLE',
  model               IN VARCHAR2 DEFAULT 'ORACLE',
  transform           IN VARCHAR2 DEFAULT NULL)
RETURN CLOB;

---
--below are few examples for using the DBMS_METADATA
--1. db_link_ddl.sql
SELECT DBMS_METADATA.get_ddl ('DB_LINK', db_link, owner)
FROM   dba_db_links
WHERE  owner = DECODE(UPPER('&1'), 'ALL', owner, UPPER('&1'));

--2. directory_ddl.sql
SELECT DBMS_METADATA.get_ddl ('DIRECTORY', directory_name)
FROM   dba_directories
WHERE  directory_name = DECODE(UPPER('&1'), 'ALL', directory_name, UPPER('&1'));

--3. fks_on_table_ddl.sql
SELECT DBMS_METADATA.get_ddl ('REF_CONSTRAINT', constraint_name, owner)
FROM   all_constraints
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
AND    constraint_type = 'R';

--4. fks_ref_table_ddl.sql
SELECT DBMS_METADATA.get_ddl ('REF_CONSTRAINT', ac1.constraint_name, ac1.owner)
FROM   all_constraints ac1
       JOIN all_constraints ac2 ON ac1.r_owner = ac2.owner AND ac1.r_constraint_name = ac2.constraint_name
WHERE  ac2.owner      = UPPER('&1')
AND    ac2.table_name = UPPER('&2')
AND    ac2.constraint_type IN ('P','U')
AND    ac1.constraint_type = 'R';

--5. role_ddl.sql
variable v_role VARCHAR2(30);

exec :v_role := upper('&1');

select dbms_metadata.get_ddl('ROLE', r.role) AS ddl
from   dba_roles r
where  r.role = :v_role
union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_role
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  sp.grantee = :v_role
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  tp.grantee = :v_role
and    rownum = 1
/

--6. sequence_ddl.sql
SELECT DBMS_METADATA.get_ddl ('SEQUENCE', sequence_name, sequence_owner)
FROM   all_sequences
WHERE  sequence_owner = UPPER('&1')
AND    sequence_name  = DECODE(UPPER('&2'), 'ALL', sequence_name, UPPER('&2'));

--7.  table_ddl.sql
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
   -- Uncomment the following lines if you need them.
   --DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SEGMENT_ATTRIBUTES', false);
   --DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'STORAGE', false);
END;
/

SELECT DBMS_METADATA.get_ddl ('TABLE', table_name, owner)
FROM   all_tables
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON


--8. table_indexes_ddl.sql
SELECT DBMS_METADATA.get_ddl ('INDEX', index_name, owner)
FROM   all_indexes
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

--9. table_constraints_ddl.sql
SELECT DBMS_METADATA.get_ddl ('CONSTRAINT', constraint_name, owner)
FROM   all_constraints
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
AND    constraint_type IN ('U', 'P');

--10. tablespace_ddl.sql
SELECT DBMS_METADATA.get_ddl ('TABLESPACE', tablespace_name)
FROM   dba_tablespaces
WHERE  tablespace_name = DECODE(UPPER('&1'), 'ALL', tablespace_name, UPPER('&1'));

--11. user_ddl.sql
variable v_username VARCHAR2(30);

exec:v_username := upper('&1');

select dbms_metadata.get_ddl('USER', u.username) AS ddl
from   dba_users u
where  u.username = :v_username
union all
select dbms_metadata.get_granted_ddl('TABLESPACE_QUOTA', tq.username) AS ddl
from   dba_ts_quotas tq
where  tq.username = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  sp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  tp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('DEFAULT_ROLE', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_username
and    rp.default_role = 'YES'
and    rownum = 1
union all
select to_clob('/* Start profile creation script in case they are missing') AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
and    rownum = 1
union all
select dbms_metadata.get_ddl('PROFILE', u.profile) AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
union all
select to_clob('End profile creation script */') AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
and    rownum = 1
/

--12. view_ddl.sql
SELECT DBMS_METADATA.get_ddl ('VIEW', view_name, owner)
FROM   all_views
WHERE  owner      = UPPER('&1')
AND    view_name = DECODE(UPPER('&2'), 'ALL', view_name, UPPER('&2'));

