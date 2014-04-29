#!/bin/sh

# runme_large_hybrid.sh
# 
# shell script to run various toast_hybrid and untoast_hybrid configurations
# with large input
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

#MiBench run
echo **********toast********** > large.log
bin/toast -fps -c data/large.au > output_large.encode.gsm 2>> large.log
echo **********untoast********** >> large.log
bin/untoast -fps -c data/large.au.run.gsm > output_large.decode.run 2>> large.log

#MiBench Hybrid normal
echo **********toast_hybrid********** >> large.log
bin/toast_hybrid -fps -c data/large.au > output_large_hybrid_normal.encode.gsm 2>> large.log
echo **********untoast_hybrid********** >> large.log
bin/untoast_hybrid -fps -c data/large.au.run.gsm > output_large_hybrid_normal.decode.run 2>> large.log

#MiBench Hybrid Softwarethread
echo **********toast_hybrid********** >> large.log
bin/toast_hybrid -fps -c -H 1 0 data/large.au > output_large_hybrid_1swt_0hwt.encode.gsm 2>> large.log
echo **********untoast_hybrid********** >> large.log
bin/untoast_hybrid -fps -c -H 1 0 data/large.au.run.gsm > output_large_hybrid_1swt_0hwt.decode.run 2>> large.log

#MiBench Hybrid hardwarethread
echo **********toast_hybrid********** >> large.log
bin/toast_hybrid -fps -c -H 0 1 data/large.au > output_large_hybrid_0swt_1hwt.encode.gsm 2>> large.log
echo **********untoast_hybrid********** >> large.log
bin/untoast_hybrid -fps -c -H 0 1 data/large.au.run.gsm > output_large_hybrid_0swt_1hwt.decode.run 2>> large.log

