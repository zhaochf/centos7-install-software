# centos7-install-software
centos7 auto install software shell.

## Install redis and sentinel
1. wget http://download.redis.io/releases/redis-5.0.5.tar.gz
2. mv redis-5.0.5.tar.gz redis-5.0.5
3. cd redis-5.0.5
4. ./install-redis.sh -t master -i 0.0.0.0 -p 6379
5. more install option to use: ./install-redis.sh -h

## Install oracle11gR2
1. download oracle11gR2 software
2. mv linux.x64_11gR2_database_*.zip linux.x64_11gR2_database
3. ./install.sh
4. uninstall use: uninstall.sh

## Install MySQL master and slave
1. Install MySQL master
  ./install.sh
2. Init master database data
  FLUSH TABLES WITH READ LOCK;
  mysqldump --databases dbname > dbname.sql
  UNLOCK TABLES;
3. Install MySQL slave
  ./install.sh -p /data/app
  sed -i "s#^server_id = 1.*#server_id = 2#g" /etc/my.cnf
  service mysql start
4. Init slave database data
  bin/mysql -uroot -proot -e "source /xxx/dbname.sql" dbname
5. Start slave
  On master execute:
  bin/mysql -uroot -proot
  show master status;
  On slave execute:
  bin/mysql -uroot -proot
  CHANGE MASTER TO
         MASTER_HOST='${master}',
         MASTER_USER='repl',
         MASTER_PASSWORD='repl',
         MASTER_LOG_FILE='${file}',
         MASTER_LOG_POS=${p};
  START SLAVE;
6. help install option to use: ./install.sh -h