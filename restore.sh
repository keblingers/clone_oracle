source /home/oracle/TEST.env

BACKUP_DIR=/data/rman/backup_standby
DF_DIR=/data/oracle/oradata/TEST/

ctl_file=$(ls $BACKUP_DIR | grep -i "ctl")

echo " === STARTUP NO MOUNT TARGET DB $ORACLE_SID ==="

sqlplus / as sysdba <<EOF
startup nomount;
exit;
EOF

echo "=== RESTORE CONTROLFILE ON TARGET DB $ORACLE_SID ==="

echo YES | rman target / <<EOF
restore controlfile from '$BACKUP_DIR/$ctl_file';
alter database mount;
catalog start with '$BACKUP_DIR/' noprompt;
exit;
EOF

echo "=== RESTORE DATABASE ON TARGET DB $ORACLE_SID ==="


sqlplus -s / as sysdba @/home/oracle/scripts/set_newname.sql > /home/oracle/scripts/log/set_newname.txt
newname=$(cat /home/oracle/scripts/log/set_newname.txt)

rman target / <<EOF
RUN {
  $newname
  RESTORE DATABASE;
  switch datafile all;
}
EOF

echo "=== GET SCN NUMBER FROM DATAFILE HEADER OF RESTORED DB $ORACLE_SID"

sqlplus -s / as sysdba @/home/oracle/scripts/get_scn.sql > /home/oracle/scripts/log/scn.txt

scn=$(tail -1 /home/oracle/scripts/log/scn.txt | awk '{print $1}')

echo "=== RECOVER DATABASE UNTIL SCN FROM ABOVE $ORACLE_SID"

rman target / <<EOF
recover database until scn $scn;
EOF

echo "=== GET DATAFILE PATH FOR TEMPFILE ==="

sqlplus -s / as sysdba @/home/oracle/scripts/get_df_path.sql > /home/oracle/scripts/log/df_path.txt

fullpath=$(dirname "$(tail -1 /home/oracle/scripts/log/df_path.txt)")

echo "=== ACTIVATE DATABASE FROM STANDBY AND OPEN ==="

sqlplus / as sysdba <<EOF
alter database activate standby database;
alter database open;
ALTER TABLESPACE TEMP ADD TEMPFILE '$fullpath/temp01.dbf' size 10m;
exit;
EOF
