# sysadmin-scripts
Various scripts to automate system administration tasks

PLEASE READ BEFORE USING 

These are Bash shell scripts I wrote and only tested in my environment. Use them at your own risk. Please make full backups of your data before trying to run any of them.
Here's an overview of them

Restic B2 Helper

I wrote this to automate backups using the tool "Restic" in order to upload to BackBlaze B2. In the config directory, you will have to enter your BackBlaze account ID, Restic repo password and other account info.
In the actual shell script, you will need to edit the variables under the "Custom Settings" portion of the file. I used "mutt" to send email alerts, so you will need to have that installed and configured correctly, as well as restic.

Website Backup

This is a short script made to backup a website running on LAMP. It backs up the website files in the public directory and then makes a (mySQL or mariaDB) database dump and then uses rsync to send them to a remote server. This will also require you to edit a few variables to suit your specific environment. You will need to edit the settings in the db.sh file.

civi_db_dump.sh

This is a script I wrote for the purpose of making a mysqldump dump of a CiviCRM database. It was useful at the time because the database was merged with a Joomla database and we needed to make a backup of only the CiviCRM tables.

raid_check.sh

A short script that polls the sas2ircu command to receive the status of the volume. It then sends an email to a chosen email address with the status in a text file. This requires msmtp to be installed and configured. 
