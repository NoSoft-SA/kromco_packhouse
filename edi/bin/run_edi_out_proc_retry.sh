# Run the ruby script

# Where are we?
SCRIPT=`readlink -f $0`
# Absolute path this script is in:
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH

#./run_edi_out_proc ~/edi_test/edi_out 15 retry
source /usr/local/rvm/environments/ruby-1.8.7-head
./run_edi_out_proc /home/Kromco_MES/edi_out 600 retry
