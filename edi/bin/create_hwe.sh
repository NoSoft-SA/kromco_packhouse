#!/bin/bash
cd /home/Kromco_MES
source /usr/local/rvm/environments/ruby-1.8.7-head

script/runner -e production 'EdiOutProposal.send_doc({"organization_code" => "KR"}, "hwe")'
