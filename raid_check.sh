#! /bin/bash

STATUS=$(sas2ircu 0 DISPLAY | grep "Status of volume" | awk '{print $4}')
HOST=$(hostname)

if [ "$STATUS" != "Okay" ]; then
	echo "Subject: RAID Array on host: $HOST needs attention" > /tmp/raid_msg.txt
	sas2ircu 0 DISPLAY >> /tmp/raid_msg.txt
	msmtp -t email@example.com < /tmp/raid_msg.txt
	rm -f /tmp/raid_msg.txt
else
	logger "RAID Array Check completed. Status: Okay"
fi
	
	
