#!/bin/sh
#-----------------------------------------------------------------------
# This sh is install oracle 11gR2 on centos7 program
#-----------------------------------------------------------------------

echo "Starting install oracle 11gR2 database, don't stop this program..."

firewall-cmd --permanent --zone=public --add-port=1521/tcp
systemctl restart firewalld

yum -y install unzip

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

# unzip oracle software files
unzip_software() {
  echo ""
  if [ -d "$oracle_home/database" ]
  then
    rm -rf "$oracle_home/database"
  fi
  
  unzip -q linux.x64_11gR2_database_1of2.zip && \
  unzip -q linux.x64_11gR2_database_2of2.zip && \
  unzip -q linux.x64_11gR2_database_rpm.zip && \
  echo "Finished install step 1: unzip the software files..."
}

unzip_software

# Install oracle dependencies
rpm -U "$software_path/rpm/*.rpm" --nodeps --force
echo ""
echo "Finished install step 2: install dependcies."

# Setup system environment and parameters
# Add oracle user and groups
sudo groupadd oinstall && \
sudo groupadd dba && \
sudo groupadd asmadmin && \
sudo groupadd asmdba && \
useradd -g oinstall -G dba,asmdba oracle -d /home/oracle

# Update system parameters
if [ ! -a "/etc/sysctl.conf.bak" ]
then
  cp /etc/sysctl.conf /etc/sysctl.conf.bak
fi
sudo sed -i "s/fs.aio-max-nr = .*/fs.aio-max-nr = 1048576/g" /etc/sysctl.conf && \
sudo sed -i "s/fs.file-max = .*/fs.file-max = 6815744/g" /etc/sysctl.conf && \
sudo sed -i "s/kernel.shmall = .*/kernel.shmall = 2097152/g" /etc/sysctl.conf && \
sudo sed -i "s/kernel.shmmax = .*/kernel.shmmax = 536870912/g" /etc/sysctl.conf && \
sudo sed -i "s/kernel.shmmni = .*/kernel.shmmni = 4096/g" /etc/sysctl.conf && \
sudo sed -i "s/kernel.sem = .*/kernel.sem = 250 32000 100 128/g" /etc/sysctl.conf && \
sudo sed -i "s/net.ipv4.ip_local_port_range = .*/net.ipv4.ip_local_port_range = 9000 65500/g" /etc/sysctl.conf && \
sudo sed -i "s/net.core.rmem_default = .*/net.core.rmem_default = 262144/g" /etc/sysctl.conf && \
sudo sed -i "s/net.core.rmem_max = .*/net.core.rmem_max = 4194304/g" /etc/sysctl.conf && \
sudo sed -i "s/net.core.wmem_default = .*/net.core.wmem_default = 262144/g" /etc/sysctl.conf && \
sudo sed -i "s/net.core.wmem_max = .*/net.core.wmem_max = 1048576/g" /etc/sysctl.conf && \
sudo /sbin/sysctl -p

# Update system security limit parameters
if [ ! -a "/etc/security/limits.conf.bak" ]
then
  cp /etc/security/limits.conf /etc/security/limits.conf.bak
fi
if [ ! -a "/etc/pam.d/login.bak" ]
then
  cp /etc/pam.d/login /etc/pam.d/login.bak
fi

sudo sed -i '/# End of file/i oracle    soft    nproc    2047' /etc/security/limits.conf && \
sudo sed -i '/# End of file/i oracle    hard    nproc    16384' /etc/security/limits.conf && \
sudo sed -i '/# End of file/i oracle    soft    nofile    1024' /etc/security/limits.conf && \
sudo sed -i '/# End of file/i oracle    hard    nofile    65536' /etc/security/limits.conf && \
sudo sed -i '/# End of file/i oracle    soft    stack    10240' /etc/security/limits.conf && \
sudo sed -i '/# End of file/i oracle    hard    stack    10240' /etc/security/limits.conf && \
sudo sed -i '$a session    required    pam_limits.so' /etc/pam.d/login

# Set oracle user login limits
if [ ! -a "/etc/profile.bak" ]
then
  cp /etc/profile /etc/profile.bak
fi

sudo sed -i '/pathmunge () {/i #Set oracle user login limits' /etc/profile && \
sudo sed -i '/pathmunge () {/{x;p;x;}' /etc/profile && \
sudo sed -i '/#Set oracle user login limits/a if [ $USER = "oracle" ]; then\n  if [ $SHELL = "/bin/ksh" ]; then\n    ulimit -p 16384\n    ulimit -n 65536\n  else\n    ulimit -u 16384 -n 65536\n  fi\nfi' /etc/profile && \
sudo -s source /etc/profile

# Set oracle user enviroment and set  install files
sudo mkdir -p "$install_home" && \
sudo chown -R oracle:oinstall "$install_home"  && \
sudo chmod -R 775 "$install_home" && \
su - oracle -c "sed -i '/# User specific environment and startup programs/a export ORACLE_BASE=/data/app/oracle\nexport ORACLE_SID=orcl\nexport ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1\nexport TNS_ADMIN=\$ORACLE_HOME/network/admin\nexport PATH=.:\${PATH}:$HOME/bin:\$ORACLE_HOME/bin\nexport PATH=\${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin\nexport LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$ORACLE_HOME/lib\nexport LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$ORACLE_HOME/oracm/lib\nexport LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib\nexport CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/JRE\nexport CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/JRE/lib\nexport CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/jlib\nexport CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/rdbms/jlib\nexport CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/network/jlib\nexport LIBPATH=\${CLASSPATH}:\$ORACLE_HOME/lib:\$ORACLE_HOME/ctx/lib\nexport ORACLE_OWNER=oracle\nexport SPFILE_PATH=\$ORACLE_HOME/dbs\nexport ORA_NLS10=\$ORACLE_HOME/nls/data' /home/oracle/.bash_profile" && \
su - oracle -c "source ~/.bash_profile"

# Copy response files
su - oracle -c "mkdir -p /home/oracle/etc" && \
su - oracle -c "cp $software_path/database/response/* /home/oracle/etc/"

sudo sed -i "s/^oracle.install.option=.*/oracle.install.option=INSTALL_DB_SWONLY/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^ORACLE_HOSTNAME=.*/ORACLE_HOSTNAME=localhost/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^UNIX_GROUP_NAME=.*/UNIX_GROUP_NAME=oinstall/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^INVENTORY_LOCATION=.*/INVENTORY_LOCATION=\/data\/app\/oracle\/oraInventory/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^SELECTED_LANGUAGES=.*/SELECTED_LANGUAGES=en,zh_CN/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^ORACLE_HOME=.*/ORACLE_HOME=\/data\/app\/oracle\/product\/11.2.0\/db_1/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^ORACLE_BASE=.*/ORACLE_BASE=\/data\/app\/oracle/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.InstallEdition=.*/oracle.install.db.InstallEdition=EE/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.isCustomInstall=.*/oracle.install.db.isCustomInstall=true/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.DBA_GROUP=.*/oracle.install.db.DBA_GROUP=dba/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.OPER_GROUP=.*/oracle.install.db.OPER_GROUP=oinstall/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.config.starterdb.type=.*/oracle.install.db.config.starterdb.type=GENERAL_PURPOSE/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.config.starterdb.globalDBName=.*/oracle.install.db.config.starterdb.globalDBName=orcl/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.config.starterdb.SID=.*/oracle.install.db.config.starterdb.SID=orcl/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.config.starterdb.memoryLimit=.*/oracle.install.db.config.starterdb.memoryLimit=512/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^oracle.install.db.config.starterdb.password.ALL=.*/oracle.install.db.config.starterdb.password.ALL=oracle/g" /home/oracle/etc/db_install.rsp && \
sudo sed -i "s/^DECLINE_SECURITY_UPDATES=.*/DECLINE_SECURITY_UPDATES=true/g" /home/oracle/etc/db_install.rsp

echo ""
echo "Finished install step 3: enviroment parameters setup."

su - oracle -c "$software_path/database/runInstaller -silent -force -responseFile /home/oracle/etc/db_install.rsp -ignorePrereq"
sleep 30s
count=`ps -ef | grep OraInstall | grep -v "grep" | wc -l`
while [  $count -gt 0 ]
do
  sleep 30s
  count=`ps -ef | grep OraInstall | grep -v "grep" | wc -l`
done

/data/app/oracle/product/11.2.0/db_1/root.sh
su - oracle -c "\$ORACLE_HOME/bin/netca /silent /responseFile /home/oracle/etc/netca.rsp"

sudo sed -i 's/GDBNAME = "orcl11g.us.oracle.com"/GDBNAME = "orcl"/g' /home/oracle/etc/dbca.rsp && \
sudo sed -i 's/SID = "orcl11g"/SID = "orcl"/g' /home/oracle/etc/dbca.rsp && \
sudo sed -i 's/#SYSPASSWORD = "password"/SYSPASSWORD = "oracle"/g' /home/oracle/etc/dbca.rsp && \
sudo sed -i 's/#SYSTEMPASSWORD = "password"/SYSTEMPASSWORD = "oracle"/g' /home/oracle/etc/dbca.rsp && \
sudo sed -i 's/#SYSTEMPASSWORD = "password"/SYSTEMPASSWORD = "oracle"/g' /home/oracle/etc/dbca.rsp && \
sudo sed -i 's/#NATIONALCHARACTERSET = "UTF8"/NATIONALCHARACTERSET = "UTF8"/g' /home/oracle/etc/dbca.rsp

rm -f /etc/oratab
su - oracle -c "\$ORACLE_HOME/bin/dbca -silent -responseFile /home/oracle/etc/dbca.rsp"

sudo sed -i '$a SID_LIST_LISTENER=\n  (SID_LIST=\n    (SID_DESC=\n        (GLOBAL_DBNAME=orcl)\n        (SID_NAME=orcl)\n        (ORACLE_HOME=/data/app/oracle/product/11.2.0/db_1)\n        (PRESPAWN_MAX=20)\n        (PRESPAWN_LIST=\n          (PRESPAWN_DESC=(PROTOCOL=tcp)(POOL_SIZE=2)(TIMEOUT=1))\n        )\n    )\n  )' /data/app/oracle/product/11.2.0/db_1/network/admin/listener.ora
su - oracle -c "lsnrctl stop"
su - oracle -c "lsnrctl start"

echo "orcl:/data/app/oracle/product/11.2.0/db_1:Y" > /etc/oratab

sudo sed -i '$asu oracle -lc "/data/app/oracle/product/11.2.0/db_1/bin/lsnrctl start"' /etc/rc.d/rc.local && \
sudo sed -i '$asu oracle -lc "/data/app/oracle/product/11.2.0/db_1/bin/dbstart"' /etc/rc.d/rc.local

sudo sed -i 's/ORACLE_HOME_LISTNER=$1/ORACLE_HOME_LISTNER=$ORACLE_HOME/g' /data/app/oracle/product/11.2.0/db_1/bin/dbstart && \
sudo sed -i 's/ORACLE_HOME_LISTNER=$1/ORACLE_HOME_LISTNER=$ORACLE_HOME/g' /data/app/oracle/product/11.2.0/db_1/bin/dbshut

cp -f $software_path/oracle /etc/init.d/ && \
chmod 750 /etc/rc.d/init.d/oracle && \
chkconfig --level 234 oracle on && \
chkconfig --add oracle && \
systemctl start oracle

echo ""
echo "Finished install step 4: Finished install the oracle software and star up..."

