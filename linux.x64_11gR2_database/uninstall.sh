#!/bin/sh
#-----------------------------------------------------------------------
# This sh is install oracle 11gR2 on centos7 program
#-----------------------------------------------------------------------

echo "String uninstall oracle 11gR2 database, don't stop this program..."

su - oracle -c "lsnrctl stop"

su - oracle -c "sqlplus -S '/ as sysdba' << !
shutdown immediate
exit
!"

# oracle install base dir
oracle_home=/home/oracle
install_home=/data/app/oracle

find_software_basedir() {
  if [ -z "$1" ]
  then
    echo "Path not specified to software_basedir"
    return 1
  fi
  echo "$1"
}

# Define oracle software dir
software_path=`find_software_basedir "$(pwd)"`

# remove oracle software files
if [ -d "$software_path/database" ] 
then
    rm -rf "$software_path/database"
fi

if [ -d "$software_path/rpm" ] 
then
    rm -rf "$software_path/rpm"
fi

echo ""
echo "Finished uninstall step 1: rmove the oracle software files..."


# Setup system environment and parameters
# Delete oracle user and groups
userdel -r oracle && \
sudo groupdel oinstall && \
sudo groupdel dba && \
sudo groupdel asmadmin && \
sudo groupdel asmdba

# Update system parameters
if [ -a "/etc/sysctl.conf.bak" ]
then 
  cp -f /etc/sysctl.conf.bak /etc/sysctl.conf
fi
sudo /sbin/sysctl -p

# Update system security limit parameters
if [ -a "/etc/security/limits.conf.bak" ]
then 
  cp -f /etc/security/limits.conf.bak /etc/security/limits.conf
fi
if [ -a "/etc/pam.d/login.bak" ]
then 
  cp -f /etc/pam.d/login.bak /etc/pam.d/login
fi

# Reset user login limits
if [ -a "/etc/profile.bak" ]
then 
  cp -f /etc/profile.bak /etc/profile
fi

sudo -s source /etc/profile

echo ""
echo "Finished uninstall step 2: rmove the oracle user and parameters..."

rm -f /etc/oratab
rm -rf $install_home

chkconfig --del oracle
rm -f /etc/init.d/oracle

echo ""
echo "Finished uninstall step 3: rmove the oracle software..."




