#!/bin/bash

# Creates a mySQL dump file of the CiviCRM database tables 

# Must be run as superuser or root
if ! [ $(id -u) -eq 0 ]
then 
	echo "This script must be run as root."
else
	# Gets name of database containing CiviCRM's tables
	read -p "CiviCRM Database name: " DBNAME
	MATCH=$(mysql -e "show databases" | grep "$DBNAME")
	
	# Checks if database exists on the system
	if ! [ "$MATCH" == "$DBNAME" ]
	then
		echo "Error: Database does not exist."
	else 
		# Prepares a text file that lists CiviCRM's tables
		mysql -N information_schema -e "select table_name from tables where table_schema = '$DBNAME' and table_name like '%civi%'" > tables.txt
		# Lists text file so user can confirm all needed tables exist within it
		less "tables.txt"
		echo '=============================================================================='
		read -p '***All cache tables and civicrm_domain will be removed. Proceed? (Y/N)*** : ' ANSWER
		
		while ! [[ "$ANSWER" == [Yy] || "$ANSWER" == [Nn] ]]
		do	
			read -p "Please enter Y or N: " ANSWER 	
		done

		if [[ "$ANSWER" == [Yy] ]]
		then
			# Removes all cache tables, removes civicrm_domain tables and replaces newlines with spaces in text file
			sed '/cache/d' ./tables.txt
			sed '/civicrm_domain/d' ./tables.txt
			tr '\r\n' ' ' < tables.txt > ./tables_prepared.txt
			# Creates a mySQL dump of all the tables listed within the text file
			mysqldump -v --add-drop-table --single-transaction "$DBNAME" `cat tables_prepared.txt` | gzip > ./civi_tables.sql.gz
			rm -f ./tables.txt ./tables_prepared.txt
		# Exits script if user does not approve the text file
		elif [[ "$ANSWER" == [Nn] ]]
		then
			rm -f ./tables.txt
			echo "Exiting..."
		fi
	fi
fi
