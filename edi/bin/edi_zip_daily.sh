#!/bin/bash

DATE=`date +%Y_%m_%d_%H_%M_%S`

#ZIP DAILY


cd /home/Kromco_MES


#zip and compress all files in directory
#sudo tar -cvzf /home/Kromco_MES/edi_in/errors_$(date +%y%m%d).tar.gz /home/Kromco_MES/edi_in/errors/transport/
tar -cvzf /home/Kromco_MES/edi_in/errors$DATE.tar.gz /home/Kromco_MES/edi_in/errors/transport


#remove the original files recursively

#read -p "check where we are again"
find /home/Kromco_MES/edi_in/errors/test/* -exec rm -f {}  \;
find /home/Kromco_MES/edi_in/errors/transport/* -exec rm -f {}  \;
