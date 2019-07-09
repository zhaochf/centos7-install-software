#! /bin/bash
#
# Install mysql-5.7.26 shell
#

# MySQL instal path

select_sql="show master status"
result=`mysql -uroot -proot -Bse "${select_sql}"`
echo result

file=`echo ${result} | awk '{print $1}'`
position=`echo ${result} | awk '{print $2}'`

echo "file: $file, position: $position"
