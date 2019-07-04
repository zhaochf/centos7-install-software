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