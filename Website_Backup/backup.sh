#!/bin/bash

source "/root/db.sh"
PATH_TO_WEBSITE="/path/to/website/files"
DAY=$(date +%m%d%Y)
BPATH="/path/to/your/backups"
RSYNC_DESTINATION="username@x.x.x.x:/path/on/remote/server/"

if [ $(date +%d) -eq 1 ]
then 
	BPATH="{$BPATH}/monthly"
elif [ $(date +%a) = "Sun" ]
then
	BPATH="${BPATH}/weekly"
else 
	BPATH="${BPATH}/daily"
fi

echo "$(date) Backup starting. Creating DB dump..." > "$BPATH/${DAY}_backup.log"

mysqldump -u $DBUSER -p${DBPASS} --add-drop-database --single-transaction $DBNAME | gzip > "$BPATH/${DAY}_${DBNAME}.sql.gz"

echo "$(date) DB dump completed. Creating archive of website files..." >> "$BPATH/${DAY}_backup.log"

tar -czf "$BPATH/${DAY}_${WEBSITE}.tgz" -C / ${PATH_TO_WEBSITE} 2>> "$BPATH/${DAY}_backup.log"

echo "$(date) Archive completed. Cleaning up..." >> "$BPATH/${DAY}_backup.log"

find /root/backups/daily/ -type f -mtime +7 -exec rm -f {} \;
find /root/backups/weekly/ -type f -mtime +31 -exec rm -f {} \;
find /root/backups/monthly/ -type f -mtime +183 -exec rm -f {} \;

echo "$(date) Copying backup to remote server..." >> "$BPATH/${DAY}_backup.log"

rsync --delete -a -e ssh "${BPATH}" "${RSYNC_DESTINATION}"
