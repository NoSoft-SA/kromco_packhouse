#!/bin/bash
cd /home/Kromco_MES
edi/bin/run_edi_file_joiner edi_out/staging/cape5 edi_out/cape5
edi/bin/run_edi_file_joiner edi_out/staging/cape5 edi_out/cape5 PS
edi/bin/run_edi_file_joiner edi_out/staging/capespan_mail edi_out/capespan_mail
edi/bin/run_edi_file_joiner edi_out/staging/capespan_mail edi_out/capespan_mail PS
edi/bin/run_edi_file_joiner edi_out/staging/cs edi_out/cs ps
edi/bin/run_edi_file_joiner edi_out/staging/dc edi_out/dc
edi/bin/run_edi_file_joiner edi_out/staging/dc edi_out/dc PS
edi/bin/run_edi_file_joiner edi_out/staging/ff edi_out/ff
edi/bin/run_edi_file_joiner edi_out/staging/ff edi_out/ff ps
edi/bin/run_edi_file_joiner edi_out/staging/gm edi_out/gm
edi/bin/run_edi_file_joiner edi_out/staging/gm edi_out/gm PS
edi/bin/run_edi_file_joiner edi_out/staging/go edi_out/go ps
edi/bin/run_edi_file_joiner edi_out/staging/kromco edi_out/kromco
edi/bin/run_edi_file_joiner edi_out/staging/oj edi_out/oj PS
edi/bin/run_edi_file_joiner edi_out/staging/paltrack edi_out/paltrack
edi/bin/run_edi_file_joiner edi_out/staging/paltrack edi_out/paltrack PS
edi/bin/run_edi_file_joiner edi_out/staging/paltrack edi_out/paltrack PM
edi/bin/run_edi_file_joiner edi_out/staging/trucape edi_out/trucape
edi/bin/run_edi_file_joiner edi_out/staging/capespan_ftp edi_out/capespan_ftp
edi/bin/run_edi_file_joiner edi_out/staging/capespan_ftp edi_out/capespan_ftp PS
edi/bin/run_edi_file_joiner edi_out/staging/dole_ftp edi_out/dole_ftp
edi/bin/run_edi_file_joiner edi_out/staging/dole_ftp edi_out/dole_ftp PS
edi/bin/run_edi_file_joiner edi_out/staging/br edi_out/br PS

