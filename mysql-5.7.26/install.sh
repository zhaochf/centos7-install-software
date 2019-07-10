#! /bin/bash
#
# Install mysql-5.7.26 shell
#

# MySQL instal path

usage() {
  cat << EOF


Usage: install mysql 5.7.26 [OPTIONS] [arg [arg ...]]
  -p MySQL instance install path, default /data/app

Examples:
  install.sh -h
  install.sh or install.sh -p /data/app
EOF
}

find_software_basedir() {
  if [ -z "$1" ]
  then
  echo "Path not specified to software_basedir"
  return 1
  fi
  echo "$1"
}

software_path=`find_software_basedir "$(pwd)"`
install_path="/data/app"

while getopts ":hp:" opt; do
  case $opt in
  p)
    install_path=$OPTARG
    ;;
  h)
    usage
    exit 0
    ;;
  ?)
    usage
    exit 1
    ;;
  esac
done

install() {
  # Delete centos7 default my.cnf and create install path
  rm -rf /etc/my.cnf*
  firewall-cmd --permanent --zone=public --add-port=3306/tcp
  systemctl restart firewalld
  
  # Install mysql
  yum -q -y install libaio
  groupadd mysql
  useradd -r -g mysql -s /bin/false mysql
  tar -xf mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz -C $install_path
  cd $install_path
  ln -s mysql-5.7.26-linux-glibc2.12-x86_64 mysql
  cd mysql
  mkdir mysql-files data tmp logs
  chown mysql:mysql mysql-files data tmp logs
  chmod -R 750 mysql-files
  cp $software_path/my.cnf /etc/my.cnf
  
  sed -i "s#^basedir = .*#basedir = $install_path/mysql#g" /etc/my.cnf  && \
  sed -i "s#^datadir = .*#datadir = $install_path/mysql/data#g" /etc/my.cnf  && \
  sed -i "s#^tmpdir = .*#tmpdir = $install_path/mysql/tmp#g" /etc/my.cnf  && \
  sed -i "s#^log_error = .*#log_error = $install_path/mysql/logs/error.log#g" /etc/my.cnf  && \
  sed -i "s#^slow_query_log_file = .*#slow_query_log_file = $install_path/mysql/logs/query.log#g" /etc/my.cnf
  
  bin/mysqld --defaults-file=/etc/my.cnf --initialize-insecure --user=mysql
  cp support-files/mysql.server /etc/init.d/
  chkconfig --add mysql.server
  service mysql.server start
}

change_passowrd() {
  bin/mysql -u root --skip-password << EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
EOF
}

create_replaction() {
  bin/mysql -uroot -proot << EOF
    CREATE USER 'repl'@'%' IDENTIFIED BY 'repl';
    GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
EOF
}

echo "Starting install mysql-5.7.26..."
echo ""
install

count=`ps -ef | grep mysql | grep -v "grep" | wc -l`
if [ $count -gt 0 ]; then
  change_passowrd
  create_replaction
  echo "MySQL install succeed..."
  echo ""
else
  echo "MySQL install failed..."
  echo ""
fi
