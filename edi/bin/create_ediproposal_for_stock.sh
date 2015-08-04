#!/bin/bash
cd /home/Kromco_MES

source /usr/local/rvm/environments/ruby-1.8.7-head


ruby  "app/models/send_edi_script.rb" CA PS
ruby  "app/models/send_edi_script.rb" DC PS
ruby  "app/models/send_edi_script.rb" OJ PS
ruby  "app/models/send_edi_script.rb" CE PS
ruby  "app/models/send_edi_script.rb" GM PS
ruby  "app/models/send_edi_script.rb" XT PS
ruby  "app/models/send_edi_script.rb" FF PS
ruby  "app/models/send_edi_script.rb" 7G PS
ruby  "app/models/send_edi_script.rb" GO PS
ruby  "app/models/send_edi_script.rb" CS PS
ruby  "app/models/send_edi_script.rb" FK PS
ruby  "app/models/send_edi_script.rb" DO PS
ruby  "app/models/send_edi_script.rb" QC PS
ruby  "app/models/send_edi_script.rb" CO PS
ruby  "app/models/send_edi_script.rb" BR PS
