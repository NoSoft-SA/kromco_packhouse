#!/bin/bash
cd /home/Kromco_MES
script/runner -e production 'EdiOutProposal.send_doc({"organization_code" => "KR"}, "hwe")'
