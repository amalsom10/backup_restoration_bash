#!/bin/bash
echo -e "$(tput setaf 2) This script is very sensitive handle with care $(tput sgr 0)"
echo -e "\n$(tput setaf 1) This script is to restore account from backup $(tput sgr 0) \n "
echo -e "\n$(tput setaf 2)Below are the steps performed by the script \n\n1.Collect the account details\n2. Collect the inputed domain details from the cpanel accounting log\n3. Create a folder with date in pwd, you need to copy the backup files both file and database backups to it.\n4.All unzip and restoration will be done automatically\n $(tput sgr 0)"
read -n 1 -s -r -p "Press any key to continue"
echo -e "\n OK master !!!!!!!!!!!!!!!!  \n"
now=$(date +"%m_%d_%Y")
mkdir -p $now
echo -e "$(tput setaf 2)Creating folder to copy backup $now/filebackup... \n Copy file backup to folder $now/filebackup  $(tput sgr 0) \n"
mkdir -p $now/filebackup $now/dbbackup
read -n 1 -s -r -p "Press any key to continue"
echo -e "\nCopy paste the account list  here and use ctrl+D to exist \n"
cat > $now/accounts.txt
echo -e "$(tput setaf 1) \n\n Checking the accounts already exists or not$(tput sgr 0)"
for i in `cat $now/accounts.txt`
do
if sudo grep -w $i /etc/trueuserdomains ; then
temp=$i
fi
done
if [ -z "$temp" ] ; then
echo -e "No Account Found"
else
echo -e "Above accounts already exists in server\n"
fi
read -n 1 -s -r -p "Press any key to continue"
echo -e "$(tput setaf 2) \n\nCollecting user details from accounting log file $(tput sgr 0)"
for i in `cat $now/accounts.txt`
do
grep -w $i backupaccount | grep -i create | cut -d ':' -f7,9 | sed 's/:/ /g'| tr " " "\n"
done | tee $now/tmp
#echo -e "$(tput setaf 1)\nSystem is going to create the above accounts $(tput sgr 0)"
echo -e "\nDid you wish to make changes in the above list"
read open
if (("$open"=="y")); then
vim $now/tmp
else
exit
fi

actions() {

echo "----------------------------------------------"
echo " * * * * * * * Main Menu * * * * * * * * * * "
echo "----------------------------------------------"
echo -e "1. Create the accounts\n"
echo -e "2. Restore file using backup\n"
echo -e "3. Restore database using backup\n"
echo -e "4. Exit\n"
echo "----------------------------------------------"
echo -n -e "$(tput setaf 2) Enter your option [1-4] $(tput sgr 0) \n"
read opt
case $opt in
      1) echo -e "Creating the accounts using above details\n"
         echo -e "Enter password for the accounts:\n"
         read passwd
         cat $now/tmp | while read -r a; do read -r b; sudo /scripts/wwwacct "$a" "$b" "$passwd" ; done
         echo -e "\n"
          echo -e "\nAccount creation completed"
          ;;
       2)  echo -e "Restore file of account using file backup\n"
          grep -vF -r '.' $now/tmp | while read i; do sudo mkdir $now/filebackup/$i ; done
          echo -e "Extracting backup file\n"
          grep -vF -r '.' $now/tmp | while read i; do sudo tar -xvf $now/filebackup/`ls  $now/filebackup/ | grep $i | grep backup` -C $now/filebackup/$i/ ;  done
          echo -e "Copying files to user directory\n"
          grep -vF -r '.' $now/tmp | while read i ; do sudo rsync -avzP $now/filebackup/$i/ /home/$i/ ; done
          echo -e "Changing permission of the files copied\n"
            grep -vF -r '.' $now/tmp | while read i ; do sudo chown -R $i. /home/$i ; done
          grep -vF -r '.' $now/tmp | while read i ; do sudo chown $i:nobody /home/$i/public_html; sudo chown $i:mail /home/$i/etc ; done
          echo -e "$(tput setaf 1)Restoration of files completed $(tput sgr 0)"
          ;;
       3) echo -e "Restoring database of the account\n"
          echo -e "Need mysql password root password to restore database, you can get it from the file /root/.my.cnf"
          sudo cat /root/.my.cnf
          echo -e "Enter the password here"
          read mysqlpass
          me="$(whoami)"
          for i in `grep -vF -r '.' $now/tmp`;  do sudo ls $now/filebackup/$i/ | grep .sql | while read j; do sudo gzip -d $now/filebackup/$i/$j ; done
           sudo ls $now/filebackup/$i/ | grep .sql | awk -F "." '{print $1}' | while read p; do chown $me. $now/filebackup/$i/$p.sql ; done
          sudo ls $now/filebackup/$i/ | grep .sql | awk -F "." '{print $1}' | while read k; do  mysql -u root  --password=$mysqlpass -e "create database $k" ; done
          sudo ls $now/filebackup/$i/ | grep .sql | awk -F "." '{print $1}' | while read d; do sudo mysql  -u root  --password=$mysqlpass  $d < $now/filebackup/$i/$d.sql ; done
           sudo ls $now/filebackup/$i/ | grep .sql | awk -F "." '{print $1}' | while read g; do sudo /usr/local/cpanel/bin/dbmaptool "$i"  --type 'mysql' --dbs "$g" ; done
          done
         ;;
      4) echo -e "Bye Master\n"
          exit 0
         ;;
esac
}
actions

while : ; do
actions
done

