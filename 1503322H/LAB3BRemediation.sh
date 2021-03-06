#!/bin/bash

#7.1
printf "\n \033[0;30m${bold}7.1 Set Password Expiration Days${normal} \n\n"
printf "Checking user account defaults: (Password Max Days)\n"
#Checks the defaults for password max days, only gets the numbers
maxDays=$(grep ^PASS_MAX_DAYS /etc/login.defs | grep -o '[0-9]*')
if [ $maxDays -le 90 ]; then
	printf "\e[32m$maxDays Pass\e[0m\n"
else
	printf "\e[31m$maxDays Fail\e[0m\n"
	#Set the PASS_MAX_DAYS parameter to 90 in /etc/login.defs
	sudo nano /etc/login.defs
	PASS_MAX_DAYS 90
fi
#Gets existing users
USER=$(cat /etc/passwd | grep "/bin/bash" | cut -d : -f 1)
list=(${USER})
printf "Checking existing user accounts: (Password Max Days)\n"
#For loop through each existing user to check max days
for i in "${list[@]}"
do
	day=$(chage -l $i | grep "Maximum number" | cut -d : -f 2)
	if [ $day -le 90 ]; then 
		printf "\e[32m$i $day Pass\e[0m\n"
	else
		#Modify user parameters for all users with a password set to match
		printf "\e[31m$i $day Fail\e[0m\n"
		chage --maxdays 90 <user>
	fi
done

#7.2 
#Set the PASS_MIN_DAYS parameter to 7 in /etc/login.defs
sudo nano /etc/login.defs

#Modify user parameters for all users with a password set to match: 
chage --mindays 7 <user>

#7.3
#Set the PASS_WARN_AGE parameter to 7 in /etc/login.defs: 
sudo nano /etc/login.defs

#Modify user parameters for all users with a password set to match: 
chage --warndays 7 <user>

#7.4
#Execute the following commands for each misconfigured system account,
usermod -L <user name>
usermod -s /sbin/nologin <user name> 

#7.5
#Run the following command to set the root user default group to GID 0: 
usermod -g 0 root

#7.6
#Edit the /etc/bashrc and /etc/profile.d/cis.sh files (and the appropriate files for any other shell supported on your system) and add the following the UMASK parameter as shown:
umask 077

#7.7
#Run the following command to disable accounts that are inactive for 35 or more days
useradd -D -f 35

#7.8
#If any accounts in the /etc/shadow file do not have a password, run the following command to lock the account until it can be determined why it does not have a password
/usr/bin/passwd -l <username>
#Also, check to see if the account is logged in and investigate what it is being used for to determine if it needs to be forced off. 

#7.9
#Run the following command and verify that no output is returned:
grep '^+:' /etc/passwd
grep '^+:' /etc/shadow
grep ‘^+:’ /etc/group
#Delete these entries if they exist using userdel.

#This script will give the information of legacy account.
LG=$(grep '^+:' /etc/passwd) #if they're in passwd, they're a user
if [$? -eq 0]; then 
    #We've found a user
    echo "We've found the user '+'!"
    sudo userdel '+'
    echo "Deleted."
else
    echo "Couldn't find the user '+'."
fi

#7.10
#Run the following command and verify that only the word "root" is returned:
/bin/cat /etc/passwd | /bin/awk -F: '($3 == 0) { print $1 }‘
root

#Delete any other entries that are displayed using userdel
userdel -r <username>

#7.11
#Rectify or justify any questionable entries found in the path.
- none of the path entries should be empty
- none of the path entries should be the “.” (current directory)
- path entries should be directories
- path entries should only be writable by the owner (use the chmod command to rectify)
- path entries should preferably be owned by root (use the chown command to rectify)

#7.12
printf "\n \033[0;30m${bold}7.12 Check Permissions on User Home Directories${normal} \n\n"
for RESULT in `cat /etc/passwd | egrep -v '(root|halt|sync|shutdown)' |awk -F: '($7!="/usr/sbin/nologin" && $7!="/sbin/nologin" && $7!="/bin/false") { print $6 }'`; do
resultperm=$(ls -ld $RESULT)
if [[ ` echo $resultperm | grep "^......w..." ` ]]; then 
	echo "Fail, Group Write permission is set on directory $RESULT"
else
	echo "Pass, Group Write permission is not set on directory $RESULT"
fi
#Checks that 8th character of permissions is '-'
if [[ ` echo $resultperm | grep "^.......-.." `  ]]; then
	echo "Pass, Other Read permission is not set on directory $RESULT"
else
	echo "Fail, Other Read permission is set on directory $RESULT"
fi
#Checks that 9th character of permissions is '-'
if [[ `echo $resultperm | grep "^........-."` ]]; then
	echo "Pass, Other Write permission is not set on directory $RESULT"
else
	echo "Fail, Other Write permission is set on directory $RESULT"
fi
#Check that 10th character of permissions is '-'
if [[ `echo $resultperm | grep "^.........-"` ]]; then
	echo "Pass, Other Execute permission is not set on directory $RESULT"
else
	echo "Fail, Other Execute permission is set on directory $RESULT"
fi
done
printf "It is recommended that a monitoring policy be established to report user file permissions."

#7.13
printf "\n \033[0;30m${bold}7.13 Check User Dot File Permissions${normal} \n\n"
#For loop to get hidden files in the user's home directory
printf "Checking user dot file permissions\n"
for dir in `cat /etc/passwd | egrep -v '(root|sync|halt|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print $6 }'`; do
for file in $dir/.[A-Za-z0-9]*; do
#Checks that 6th and 9th character of permissions are not 'w'
perm6=$(ls -ld $file | grep "^.....w....")
perm9=$(ls -ld $file | grep "^........w.")
if [ -z "$perm6" ] && [ -z "$perm9" ]; then
	printf "\e[32mPass - $file\e[0m\n"
else
	printf "\e[31mFail - $file\e[0m\n"
	printf "It is recommended that a monitoring policy be established to report user dot file permissions.\n"
fi
done
done

#7.14
printf "\n \033[0;30m${bold}7.14 Checking for Existence and Permission of User .netrc Files${normal} \n\n" 

#Determines the home directory of interactive user accounts
for dir in `/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' |/bin/awk -F: '($7 != "/sbin/nologin") { print $6 }'`; do

#Searches the home directory of interactive user accounts for .netrc file
for file in $dir/.netrc; do
if [ ! -h "$file" -a -f "$file" ]; then
printf "\033[33;30m Found! .netrc file found in directory $dir, checking file permissions... \n"
else
printf "\033[33;35m No .netrc file found in directory $dir. \n"
fi
printf "It is recommended that a monitoring policy be established to report users’ use of .netrc and .netrc file permissions."

#7.15
#If any users have .rhosts files determine why they have them. These files should be deleted if they are not needed.
#To search for and remove .rhosts files by using the find(1) command
printf "\n \033[0;30m${bold}7.15 Check for Presence of User .rhosts Files${normal} \n\n"
#Get interactive user accounts
printf "\033[0;30mChecking for Presence of User .rhosts Files \n"
for dir in `/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' |/bin/awk -F: '($7 != "/sbin/nologin") { print $6 }'`; do
#For loop to see if rhost file exists in user's home directory
for file in $dir/.rhosts; do
#Checks if rhosts file is needed
if [ ! -h "$file" -a -f "$file" ]; then
printf "\033[33;31m.rhosts file found in $dir, please delete file if it is not needed. \n"
find /export/home -name .rhosts -print | xargs -i -t rm{}
else
printf "\033[33;32mNo .rhosts file found in $dir \n"
fi
echo  -en "\e[0m"
done
done

#7.16
printf "\n \033[0;30m${bold}7.16 Check Groups in /etc/passwd${normal} \n\n"
#For every row in /etc/passwd
for i in $(cat /etc/passwd | cut -d : -f 4 | sort -u); do 
#Verifies GID defined in /etc/group
	grep -q -P "^.*?:x:$i:" /etc/group
		if [ $? -ne 0 ]; then 
			echo "Group $i is referenced by /etc/passwd but does not exists in /etc/group"
		else
			printf "\e[32mPass - Group: $i\e[0m\n"
		fi
done
printf "Analyze the output of the Verification step on the right and perform the appropriate action to correct any discrepancies found."

#7.17
#If any users' home directories do not exist, create them and make sure the respective user owns the directory. 
#Users without assigned home directories should be removed or assigned a home directory as appropriate. 
printf "\n \033[0;30m${bold}7.17 Check That Users Are Assigned Valid Home Directories and Home Directory Ownership is Correct${normal} \n\n"
#In etc/passwd, check if home directory is defined in field no. 6. See if valid and exist
cat /etc/passwd | awk -F : '{print $1, $3, $6}' | while read user uid dir; do 
	if [ $uid -ge 1000 -a ! -d "$dir" -a $user != "nfsnobody" ]; then 
		printf "\e[31mHome directory ($dir) of user $user does not exist.\e[0m\n"
	elif [ ! -d $dir ] ; then
		printf "\e[31mHome Directory of $user cannot be found!\e[0m\n"
	else 
		printf "\e[32mPass - $user $dir\e[0m\n"
		echo "Checking if Home directory ownership of $user is correct"
		ls -ld $dir | awk '{print $3, $4}' | while read owner user1; do
		if [ "$owner" != "$user1" ] && [ $? -eq 0 ]; then
			printf "\e[31mThe home directory ($dir) of user $user1 is owned by $owner.\e[0m\n"
		else 
			printf "\e[32mPass\e[0m\n"
            		userdel $user1
		fi
		done
	fi
done

#7.18
printf "\n \033[0;30m${bold}7.18 Check for Duplicate UIDs${normal} \n\n"
printf "Checking for duplicate UIDs\n"
#Get etc/passwd file
cat /etc/passwd| cut -f3 -d":" | sort -n | uniq -c | while read x ; do
[ -z "${x}" ] && break
set - $x
if [ $1 -gt 1 ]; then
#Checks for duplicate UIDs
	users=`/bin/gawk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd| /usr/bin/xargs`
	printf "\e[31mFail - Duplicate UID ($2)\e[0m\n"
	printf "Please establish unique UIDs and review all files owned by the shared UID to determine which UID they are supposed to belong to."
else
	printf "\e[32mPass - UID ($2)\e[0m\n"
fi
done

#7.19
printf "\n \033[0;30m${bold}7.19 Check for Duplicate GIDs${normal} \n\n"
printf "Checking for duplicate GIDs\n"
#Get etc/group file
cat /etc/group | cut -f3 -d":" | sort -n | uniq -c | while read x ; do
[ -z "${x}" ] && break
set - $x
if [ $1 -gt 1 ]; then
#Checks for duplicate GIDs
	grps=`/bin/gawk -F: '($3 == n) { print $1 }' n=$2 /etc/group | /usr/bin/xargs`
	printf "\e[31mFail - Duplicate GID ($2)\e[0m\n"
	printf "Please establish unique GIDs and review all files owned by the shared GID to determine which group they are supposed to belong to."
else
	printf "\e[32mPass - GID ($2)\e[0m\n"
fi
done

#7.20
#Based on the results of the above, change any UIDs that are in the reserved range to one that is in the user range. 
#Review all files owned by the reserved UID to determine which UID they are supposed to belong to.

#7.21
printf "\n \033[0;30m${bold}7.21 Check for Duplicate User Names${normal} \n\n"
#Get etc/passwd file
cat /etc/passwd | cut -f1 -d":" | /bin/sort -n | /usr/bin/uniq -c | while read x ; do
[ -z "${x}" ] && break
set - $x
#Checks for duplicate user names
if [ $1 -gt 1 ]; then
uids=`/bin/gawk -F: '($1 == n) { print $3 }' n=$2 \/etc/passwd | xargs`
printf "\e[31mFail - Duplicate User Name ($2)\e[0m\n"
printf "Please establish unique user names for the users. "
else
printf "\e[32mPass - ($2)\e[0m\n"
fi
done

#7.22
printf "\n \033[0;30m${bold}7.22 Check for Duplicate Group Names${normal} \n\n"
#Get etc/group file
cat /etc/group | cut -f1 -d":" | /bin/sort -n | /usr/bin/uniq -c | while read x ; do
[ -z "${x}" ] && break
set - $x
#Checks for duplicate group names
if [ $1 -gt 1 ]; then
gids=`/bin/gawk -F: '($1 == n) { print $3 }' n=$2 /etc/group | xargs`
printf "\e[31mFail - Duplicate Group Name ($2)\e[0m\n"
printf "Please establish unique names for the user groups."
else 
printf "\e[32mPass - ($2)\e[0m\n"
fi
done

#7.23
#Making global modifications to users' files without alerting the user community can result in unexpected outages and unhappy users. 
#Therefore, it is recommended that a monitoring policy be established to report user .forward files and determine the action to be taken in accordance with site policy.

#8.1
printf "\n \033[0;30m${bold}8.1 Set Warning Banner for Standard Login Services${normal} \n\n"
#Set counter to 0 and cut user and group of /etc/motd, /etc/issue and /etc/issue.net
counter=0
motdper=$(ls -l /etc/motd | cut -d " " -f 3 )
motdper1=$(ls -l /etc/motd | cut -d " " -f 4 )
issueper=$(ls -l /etc/issue | cut -d " " -f 3 )
issueper1=$(ls -l /etc/issue | cut -d " " -f 4 )
issuenetper=$(ls -l /etc/issue.net | cut -d " " -f 3 )
issuenetper1=$(ls -l /etc/issue.net | cut -d " " -f 4 )
#Checks if all are set as root 
printf "Checking that /etc/motd /etc/issue /etc/issue.net have root as user and group:\n"
if [ "$motdper" == "root" ] && [ "$motdper1" == "root" ] && [ "$issueper" == "root" ] && [ "$issueper1" == "root" ] && [ "$issuenetper" == "root" ] && [ "$issuenetper1" == "root" ]
then 
	printf "\033[33;32m PASS \n"
else
	counter=$((counter+1))
	printf "\033[33;31m FAIL \n"

fi
echo  -en "\e[0m"
#chmod of the 3 files
chmodmotd=$( stat --format '%a' /etc/motd)
chmodissue=$( stat --format '%a' /etc/issue)
chmodissuenet=$( stat --format '%a' /etc/issue.net)
#Checks if all files' chmod equals 644
printf "Checking that /etc/motd /etc/issue /etc/issue.net have chmod of 644 :\n"
if [ "$chmodmotd" -eq 644 ] && [ "$chmodissue" -eq 644 ] && [ "$chmodissuenet" -eq 644 ]
then 
	printf "\033[33;32m PASS \n"
else	
	counter=$((counter+1))
	printf "\033[33;31m FAIL \n"
fi
echo  -en "\e[0m"
#Checks if correct banner is set in issue and issue.net
mp="Authorized uses only. All activity may be \ monitored and reported."
catissue=$(cat /etc/issue)
catissuenet=$(cat /etc/issue.net)
printf "Checking that /etc/issue /etc/issue.net have proper motd :\n"
if [ "$catissue" == "$mp" ] && [ "$catissuenet" == "$mp" ]
then
	printf "\033[33;32m PASS \n"
else
	counter=$((counter+1))
	printf "\033[33;31m FAIL \n"
fi
echo  -en "\e[0m"
#If counter more than 0 then fails
if [ $counter -gt 0 ]; then
	printf "\e[31mOverall Fail\e[0m\n"
	touch /etc/motd
	echo "Authorized uses only. All activity may be \monitored and reported." > /etc/issue
	echo "Authorized uses only. All activity may be \monitored and reported." > /etc/issue.net
	chown root:root /etc/motd; chmod 644 /etc/motd
	chown root:root /etc/issue; chmod 644 /etc/issue
	chown root:root /etc/issue.net; chmod 644 /etc/issue.net
else
	printf "\e[32mOverall Pass\e[0m\n"
fi


#8.2
#Edit the /etc/motd, /etc/issue and /etc/issue.net files and remove any lines containing \m, \r, \s or \v.
printf "\n \033[0;30m${bold}8.2 Remove OS information from Login Banners${normal} \n\n"
#Greps if match 3 files
issue=$(egrep '(\\v|\\r|\\m|\\s)' /etc/issue)
motd=$(egrep '(\\v|\\r|\\m|\\s)' /etc/motd)
issuenet=$(egrep '(\\v|\\r|\\m|\\s)' /etc/issue.net)
#Set regular expression and counter
regex='(\\v|\\r|\\m|\\s)'
counter=0
#echo $issue
#Checks if match regex
printf "Checking /etc/issue:\n"
if [[ $issue =~ $regex ]]
then 
	counter=$((counter+1))
	printf "\033[33;31m FAIL \n"
else
	printf "\033[33;32m PASS \n"
fi
echo  -en "\e[0m"
#echo $motd
#Checks if match regex
printf "Checking /etc/motd:\n"
if [[ $motd =~ $regex ]]
then 
	counter=$((counter+1))
	printf "\033[33;31m FAIL \n"
else
	printf "\033[33;32m PASS \n"

fi
echo  -en "\e[0m"
#echo $issuenet
#Checks if match regex
printf "Checking /etc/issue.net:\n"
if [[ $issuenet =~ $regex ]]
then 
	counter=$((counter+1))
	printf "\033[33;31m FAIL \n"
else
	printf "\033[33;32m PASS \n"
fi
echo  -en "\e[0m"
#echo $counter
#Checks if counter greater than 0
if [ $counter -gt 0 ]; then
	printf "\e[31mOverall Fail\e[0m\n"
	sed -i '/\m/ d' /etc/motd
	sed -i '/\r/ d' /etc/motd
	sed -i '/\s/ d' /etc/motd
	sed -i '/\v/ d' /etc/motd
	sed -i '/\m/ d' /etc/issue
	sed -i '/\r/ d' /etc/issue
	sed -i '/\s/ d' /etc/issue
	sed -i '/\v/ d' /etc/issue
	sed -i '/\m/ d' /etc/issue.net
	sed -i '/\r/ d' /etc/issue.net
	sed -i '/\s/ d' /etc/issue.net
	sed -i '/\v/ d' /etc/issue.net
else
	printf "\e[32mOverall Pass\e[0m\n"
fi

