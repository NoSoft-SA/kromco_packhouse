#!/bin/bash

DATE=`date +%Y_%m_%d_%H_%M_%S`

#ZIP DAILY


cd /home/Kromco_MES


#zip and compress all files in directory
sudo tar -cvzf /home/Kromco_MES/edi/edi_in_logs$DATE.tar.gz /home/Kromco_MES/edi/logs/in --newer-mtime+30
sudo tar -cvzf /home/Kromco_MES/edi/edi_out_logs$DATE.tar.gz /home/Kromco_MES/edi/logs/out --newer-mtime+30

#remove the original files recursively

#read -p "check where we are again"
sudo  find /home/Kromco_MES/edi/logs/in -mtime +30 -exec rm -rf {}  \;
sudo  find /home/Kromco_MES/edi/logs/out  -mtime +30 -exec rm -rf {}  \;
