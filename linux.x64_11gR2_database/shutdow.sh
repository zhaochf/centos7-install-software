#!/bin/sh

su - oracle -c "sqlplus -S '/ as sysdba' << ! 
shutdown immediate
exit 
!"

