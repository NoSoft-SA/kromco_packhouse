#!/bin/bash
cd /home/Kromco_MES

source /usr/local/rvm/environments/ruby-1.8.7-head

ruby  "app/models/send_edi_script.rb" CA PS
ruby  "app/models/send_edi_script.rb" XT PS

ruby  "app/models/send_edi_script.rb" 7G PS
ruby  "app/models/send_edi_script.rb" FK PS
ruby  "app/models/send_edi_script.rb" DO PS
ruby  "app/models/send_edi_script.rb" CO PS
ruby  "app/models/send_edi_script.rb" ID PS
