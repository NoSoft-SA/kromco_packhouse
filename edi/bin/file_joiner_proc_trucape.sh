#!/bin/bash
cd /home/Kromco_MES
source /usr/local/rvm/environments/ruby-1.8.7-head

ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/paltrack edi_out/paltrack
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/paltrack edi_out/paltrack PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/paltrack edi_out/paltrack PM

ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/cape5 edi_out/cape5
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/cape5 edi_out/cape5 PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/capespan_mail edi_out/capespan_mail
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/capespan_mail edi_out/capespan_mail PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/cs edi_out/cs ps
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/dc edi_out/dc
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/dc edi_out/dc PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/ff edi_out/ff
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/ff edi_out/ff ps
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/gm edi_out/gm
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/gm edi_out/gm PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/go edi_out/go ps
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/kromco edi_out/kromco
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/oj edi_out/oj PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/trucape edi_out/trucape
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/capespan_ftp edi_out/capespan_ftp
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/capespan_ftp edi_out/capespan_ftp PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/dole_ftp edi_out/dole_ftp
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/dole_ftp edi_out/dole_ftp PS
ruby  "edi/bin/run_edi_file_joiner"  edi_out/staging/br edi_out/br PS

