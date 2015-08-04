#!/bin/bash
cd /home/Kromco_MES
source /usr/local/rvm/environments/ruby-1.8.7-head

ruby  "app/models/send_edi_script.rb" TI PS

