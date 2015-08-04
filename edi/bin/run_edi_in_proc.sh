# Run the ruby script

# Where are we?
SCRIPT=`readlink -f $0`
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH
#$SCRIPTPATH/run_edi_in_proc ~/edi_test/edi_in 3
#./run_edi_in_proc ~/edi_test/edi_in 3

source /usr/local/rvm/environments/ruby-1.8.7-head

/home/Kromco_MES/edi/bin/run_edi_in_proc /home/Kromco_MES/edi_in/receive 5
