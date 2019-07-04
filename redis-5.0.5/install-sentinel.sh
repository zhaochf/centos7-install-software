#! /bin/bash
#
# Install redis sentinel shell
#
host=0.0.0.0
port=26379
master=""

usage() {
  cat << EOF


Usage: install-sentinel [OPTIONS] [arg [arg ...]]
  -i Redis sentinel instance ip address, default 0.0.0.0.
  -p Redis sentinel instance port , default 26379.
  -m Specify the redis master instance address.

Examples:
  install-sentinel.sh -h
  install-sentinel.sh -i 0.0.0.0 -p 26379 -m "192.168.1.10 6379"
EOF
}


while getopts ":hi:p:m:" opt; do
  case $opt in
  i)
    host=$OPTARG
    ;;
  p)
    port=$OPTARG
    ;;
  m)
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

if [ -z "$master" ]; then
  echo "To install redids sentinel, you must specify the master host parameter..."
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
  tar -xf $software_path/redis-5.0.5.tar.gz
  cd redis-5.0.5
  make -s MALLOC=libc
  cd ..
}

install() {
  mkdir -p $install_path/bin && \
  mkdir -p $install_path/conf && \
  mkdir -p $install_path/logs
  cp -rf $software_path/redis-5.0.5/src/redis-sentinel $install_path/bin && \
  cp -rf $software_path/redis-5.0.5/sentinel.conf $install_path/conf/sentinel_$port.conf
}

master() {
  cd $install_path/conf
  sed -i "/# protected-mode no/aprotected-mode no" $install_path/conf/sentinel_$port.conf && \
  sed -i "/protected-mode no/abind 0.0.0.0" $install_path/conf/sentinel_$port.conf && \
  sed -i "s/^port 26379/port $port/g" $install_path/conf/sentinel_$port.conf && \
  sed -i "s/^daemonize no/daemonize yes/g" $install_path/conf/sentinel_$port.conf && \
  sed -i "s#^pidfile.*#pidfile $install_path/sentinel_$port.pid#g" $install_path/conf/sentinel_$port.conf && \
  sed -i "s#^logfile.*#logfile \"$install_path/logs/sentinel_$port.log\"#g" $install_path/conf/sentinel_$port.conf
}


auto() {
  cat << EOF > /usr/lib/systemd/system/sentinel.service
[Unit]
Description=Redis service
After=network.target

[Service]
Type=forking
ExecStart=$install_path/bin/redis-sentinel $install_path/conf/sentinel_$port.conf
ExecReload=
ExecStop=$install_path/bin/redis-cl -p $port shutdown
PrivateTmp=true

[Install]
WantedBy=multi-user.target

EOF

  systemctl daemon-reload
  systemctl enable sentinel.service
  systemctl start sentinel.service
}

echo "Starting install redis sentinel 5.0.5..."
echo "The instance bind ip: $host, bind $port, redids master: $master"
echo ""

# Compile redis software
compile

# Install redis to specified path
install

# Config master properties
master

# Config auto start redis
auto

# Setup firewall
firewall-cmd --permanent --zone=public --add-port=$port/tcp
systemctl restart firewalld


# Check redis sentinel running process id
count=`ps -ef | grep redis-sentinel | grep -v "grep" | wc -l`
if [ $count -gt 0 ]; then
  echo "Redis sentinel install succeed..."
  echo ""
else
  echo "Redis sentinel install failed..."
  echo ""
fi

echo "Finished install redis sentinel..."
