source /home/oracle/TEST.env

rman target / cmdfile=/home/oracle/scripts/backup.rman >> /home/oracle/scripts/log/backup.log 2>&1 &
