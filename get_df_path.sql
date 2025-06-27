set linesize 1500 pagesize 1500
set heading off
SET FEEDBACK OFF
select name from v$datafile where rownum <=1;
exit;

