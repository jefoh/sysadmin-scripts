#!/bin/bash
#
#Uses restic to backup specified directories with logging and error reporting
#Designed to run automatically in a cronjob
#Only tested on Debian 10 Buster
#Requires the following packages to run
#
#postfix 
#mutt
#restic
#
#postfix and mutt must be preconfigured to send SMTP emails for alerting to work
#Restic must be preconfigured to point to an existing Backblaze B2 bucket by setting env variables in ~/.restic/config/restic-env
#Run "restic init" on the B2 bucket before running this script
#
#
#
#Default settings. No need to edit.
######################################################
#Current system hostname
HOST=$(hostname)
#Restic logs and config
RDIR="${HOME}/.restic"
#Environmental variables used by Restic to authenticate
RVARS="${RDIR}/config/restic-env"
#Logfile location and name with date
DATE=$(date "+%m%d%Y")
LOGFILE="${RDIR}/logs/${DATE}_restic.log"
PID_FILE="${HOME}/.restic_b2.pid"
######################################################
#
#
#
#Custom Settings. Edit these to fit your environment.
######################################################
#
#Email Alert Recipient address
RECIPIENT="email@example.com"
#
#Directory that needs to be backed up
BACKUPDIR="/path/to/dir"
#
#How many days weeks months and years to retain backups
PRUNELAST=1
PRUNEDAYS=5
PRUNEWEEKS=4
PRUNEMONTHS=6
PRUNEYEARS=1
#
#Number of parrellel connections to make to B2
B2_THREADS=40
#
#How many days to retain log files
LOGRETENTION=30
#
######################################################

#Create directory to store logs
mkdir -p "${RDIR}/logs"

#Creates log entry
log(){
	echo -e "$(date "+%m%d%Y_%H%M%S"): ${1}" | tee -a $LOGFILE	
}

#Sends an email alert
emailAlert(){
	tail $LOGFILE > /tmp/restic_email.txt
	mutt -a $LOGFILE -s "${1}" -- $RECIPIENT < /tmp/restic_email.txt
	if [[ -f "/tmp/restic_email.txt" ]];then
		rm -f "/tmp/restic_email.txt"
	fi	
}

#Check if Restic is already running
if [[ -f "$PID_FILE" ]];then
	PID=$(cat $PID_FILE)
	ps -p $PID > /dev/null 2>&1
	if [[ $? -eq 0 ]];then
		log "File $PID_FILE exists. Backup may be in progress with PID: ${PID}. Exiting..."
		emailAlert "[Restic is still running, but attempted to start again. No Backup was made.]"
		exit 1
	else
		log "File $PID_FILE exists, but no process was found under PID: ${PID} Continuing backup..."
	fi
fi

#Create PID File
echo $$ > $PID_FILE

#Check if environmental variable file exists
if [[ ! -f "$RVARS" ]]; then
	log "Environmental variable file $RVARS does not exist. Exiting..."
	exit 1
fi

source ${RVARS}

echo "--------------------------------------------------------------------------------------------" >> $LOGFILE
log "Starting restic backup..."

#Start backup
restic backup -o b2.connections=${B2_THREADS} $BACKUPDIR >> $LOGFILE 2>&1

if [[ $? -eq 0 ]];then
	log "Restic backup completed successfully."
else
	log "There were errors completing Restic backup. Exiting..."
	emailAlert "[Restic encountered errors during backup process on host: $HOST]"
	exit 1
fi

log "Starting Restic Check..."

#Verify Backup
restic check -o b2.connections=${B2_THREADS} >> $LOGFILE 2>&1

if [[ $? -eq 0 ]]; then
	log "Restic check completed successfully."
else
	log "There were errors completing Restic check. Exiting..."
	emailAlert "[Restic encountered errors during check on host: $HOST]"
	exit 1
fi

log "Starting Restic forget and prune process..."
log "Snapshots older than ${PRUNEDAYS} days, ${PRUNEWEEKS} weeks, ${PRUNEMONTHS} months, and ${PRUNEYEARS} years will be removed."

#Delete old snapshots
restic forget -o b2.connections=${B2_THREADS} --keep-last ${PRUNELAST} --keep-daily ${PRUNEDAYS} --keep-weekly ${PRUNEWEEKS} --keep-monthly ${PRUNEMONTHS} --keep-yearly ${PRUNEYEARS} --prune >> $LOGFILE 2>&1

if [[ $? -eq 0 ]]; then
	log "Restic forget and prune operations completed successfully."
else
	log "There were errors during the forget and prune process. Exiting..."
	emailAlert "[Restic encountered errors during forget and prune on host: $HOST]"
	exit 1
fi

#Delete old log files
log "Cleaning up log files older than $LOGRETENTION days."
find "${RDIR}/logs/" -type f -mtime +"$LOGRETENTION" -exec rm -f {} \;

echo "---------------------------------------------------------------------------------------------" >> $LOGFILE
emailAlert "[Restic backup, check and prune process completed successfully on host: $HOST]"

rm -f $PID_FILE

