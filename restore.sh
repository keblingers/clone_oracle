source /home/oracle/TEST.env

BACKUP_DIR=/home/oracle/rman
DF_DIR=/data/oracle/oradata/TEST
CTL_ALIAS=CF

if ps -ef | grep pmon | grep -i "$ORACLE_SID"; then
  sqlplus / as sysdba <<EOF
  shutdown immediate;
  exit;
EOF
else
  echo "continue to next step"
fi

echo "=== REMOVING EXISTING DATABASE FILE ==="
rm -rf $DF_DIR/*
echo "=== Done ==="

ctl_file=$(ls $BACKUP_DIR | grep -i "$CTL_ALIAS")

echo "=== STARTUP NO MOUNT TARGET DB $ORACLE_SID ==="

sqlplus / as sysdba <<EOF
startup nomount;
exit;
EOF

echo "=== RESTORE CONTROLFILE ON TARGET DB $ORACLE_SID ==="

rman target / <<EOF
restore controlfile from '$BACKUP_DIR/$ctl_file';
alter database mount;
catalog start with '$BACKUP_DIR/' noprompt;
exit;
EOF

echo "=== RESTORE DATABASE ON TARGET DB $ORACLE_SID ==="


sqlplus -s / as sysdba @/home/oracle/scripts/set_newname.sql > /home/oracle/scripts/log/set_newname.txt
newname=$(cat /home/oracle/scripts/log/set_newname.txt)

sqlplus -s / as sysdba @/home/oracle/scripts/tempfile.sql > /home/oracle/scripts/log/tempfile.txt
tempfile=$(cat /home/oracle/scripts/log/tempfile.txt)

rman target / <<EOF
RUN {
  $newname
  $tempfile
  restore database;
  switch datafile all;
  switch tempfile all;
}
EOF

echo "=== GET SCN NUMBER FROM DATAFILE HEADER OF RESTORED DB $ORACLE_SID"

sqlplus -s / as sysdba @/home/oracle/scripts/get_scn.sql > /home/oracle/scripts/log/scn.txt

scn=$(tail -1 /home/oracle/scripts/log/scn.txt | awk '{print $1}')

echo "=== RECOVER DATABASE UNTIL SCN: $scn FROM ABOVE $ORACLE_SID"

rman target / <<EOF
recover database until scn $scn;
EOF

echo "=== ACTIVATE DATABASE FROM STANDBY AND OPEN ==="

sqlplus / as sysdba <<EOF
set linesize 1500 pagesize 1500
set echo on
alter database activate standby database;
alter database open;
select host_name, instance_name from v\$instance;
select name, db_unique_name, open_mode, log_mode, database_role from v\$database;
exit;
EOF
