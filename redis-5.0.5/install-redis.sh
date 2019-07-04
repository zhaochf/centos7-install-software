#! /bin/bash
#
# Install redis shell
#
type=master
host=0.0.0.0
port=6379
master=""

usage() {
  cat << EOF


Usage: install-redis [OPTIONS] [arg [arg ...]]
  -t Redis instance type master or slave, default master.
  -i Redis instance ip address, default 0.0.0.0.
  -p Redis instance port , default 6379.
  -r When the redis instance is slave, replica of master address.

Examples:
  install-redis.sh -h
  install-redis.sh -t master -i 0.0.0.0 -p 6379
  install-redis.sh -t slave -i 0.0.0.0 -p 6379 -r "192.168.1.10 6379"
EOF
}


while getopts ":ht:i:p:r:" opt; do
  case $opt in
  t)
    type=$OPTARG
    ;;
  i)
    host=$OPTARG
    ;;
  p)
    port=$OPTARG
    ;;
  r)
    master=$OPTARG
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

if [ $type != "master" -a $type != "slave" ]; then
  echo "The type of redids instance installed must be master or slave."
  echo "The default type is master..."
  usage
  exit 1
fi

if [ $type = "slave" -a -z "$master" ]; then
  echo "To install redids slave, you must specify the replicaof master host parameter..."
  exit 1
fi

find_software_basedir() {
  if [ -z "$1" ]
  then
  echo "Path not specified to software_basedir"
  return 1
  fi
  echo "$1"
}

# Define redis software dir
software_path=`find_software_basedir "$(pwd)"`
install_path="/data/app/redis-5.0.5"

compile() {
  yum -q -y install gcc
  tar -xf $software_path/redis-5.0.5.tar.gz
  cd redis-5.0.5
  make -s MALLOC=libc
  cd ..
}

install() {
  mkdir -p $install_path/bin && \
  mkdir -p $install_path/conf && \
  mkdir -p $install_path/logs
  cp -rf $software_path/redis-5.0.5/src/redis-server $install_path/bin && \
  cp -rf $software_path/redis-5.0.5/src/redis-cli $install_path/bin && \
  cp -rf $software_path/redis-5.0.5/src/redis-benchmark $install_path/bin && \
  cp -rf $software_path/redis-5.0.5/src/redis-check-aof $install_path/bin && \
  cp -rf $software_path/redis-5.0.5/src/redis-check-rdb $install_path/bin && \
  cp -rf $software_path/redis-5.0.5/redis.conf $install_path/conf/redis_$port.conf
}

master() {
  cd $install_path/conf
  sed -i "s/^bind 127.0.0.1/bind $host/g" $install_path/conf/redis_$port.conf && \
  sed -i "s/^protected-mode yes/protected-mode no/g" $install_path/conf/redis_$port.conf && \
  sed -i "s/^port 6379/port $port/g" $install_path/conf/redis_$port.conf && \
  sed -i "s/^daemonize no/daemonize yes/g" $install_path/conf/redis_$port.conf && \
  sed -i "s#^pidfile.*#pidfile $install_path/redis_$port.pid#g" $install_path/conf/redis_$port.conf && \
  sed -i "s#^logfile.*#logfile \"$install_path/logs/redis_$port.log\"#g" $install_path/conf/redis_$port.conf
}

slave() {
  sed -i "/# replicaof <masterip> <masterport>/areplicaof $master" $install_path/conf/redis_$port.conf
}

auto() {
  cat << EOF > /usr/lib/systemd/system/redis.service
[Unit]
Description=Redis service
After=network.target

[Service]
Type=forking
ExecStart=$install_path/bin/redis-server $install_path/conf/redis_$port.conf
ExecReload=
ExecStop=$install_path/bin/redis-cl -p $port shutdown
PrivateTmp=true

[Install]
WantedBy=multi-user.target

EOF

  systemctl daemon-reload
  systemctl enable redis.service
  systemctl start redis.service
}

echo "Starting install redis 5.0.5..."
echo "The instance type: $type, bind ip: $host, bind $port"
echo ""

# Compile redis software
compile

# Install redis to specified path
install

# Config master properties
master

# Config slave properties
if [ $type = "slave" ]; then
  slave
fi

# Config auto start redis
auto

# Setup firewall
firewall-cmd --permanent --zone=public --add-port=$port/tcp
systemctl restart firewalld


# Check redis running process id
count=`ps -ef | grep redis | grep -v "grep" | wc -l`
if [ $count -gt 0 ]; then
  echo "Redis install succeed..."
  echo ""
else
  echo "Redis install failed..."
  echo ""
fi

echo "Finished install redis..."
