#!/bin/bash

DATE=`date +%Y_%m_%d_%H_%M_%S`

#ZIP DAILY


cd /home/Kromco_MES


#zip and compress all files in directory
tar -cvzf /home/Kromco_MES/edi/edi_in_logs$DATE.tar.gz /home/Kromco_MES/edi/logs/in --newer-mtime+30
tar -cvzf /home/Kromco_MES/edi/edi_out_logs$DATE.tar.gz /home/Kromco_MES/edi/logs/out --newer-mtime+30
tar -cvzf /home/Kromco_MES/edi/edi_join_logs$DATE.tar.gz /home/Kromco_MES/edi/logs/join --newer-mtime+30

#remove the original files recursively

#read -p "check where we are again"
find /home/Kromco_MES/edi/logs/in -mtime +30 -exec rm -rf {}  \;
find /home/Kromco_MES/edi/logs/out  -mtime +30 -exec rm -rf {}  \;
find /home/Kromco_MES/edi/logs/join  -mtime +30 -exec rm -rf {}  \;
