set linesize 300
col file_name format a120
set heading off
set feedback off

select 'set newname for datafile ' ||FILE#|| ' to '||'''/data/oracle/oradata/TEST/'|| substr(name,instr(name,'/',-1)+1, instr(substr(name,instr(name,'/',-1)+1),'.')-1 ) ||'.dbf'' ;' file_name from v$datafile;
exit;
