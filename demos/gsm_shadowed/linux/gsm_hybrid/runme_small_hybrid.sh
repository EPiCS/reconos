#!/bin/sh

# runme_small_hybrid.sh
# 
# shell script to run various toast_hybrid and untoast_hybrid configurations
# with small input
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

#MiBench run
echo **********toast********** > small.log
bin/toast -fps -c data/small.au > output_small.encode.gsm 2>> small.log
echo **********untoast********** >> small.log
bin/untoast -fps -c data/small.au.run.gsm > output_small.decode.run 2>> small.log

#MiBench Hybrid normal
echo **********toast_hybrid********** >> small.log
bin/toast_hybrid -fps -c data/small.au > output_small_hybrid_normal.encode.gsm 2>> small.log
echo **********untoast_hybrid********** >> small.log
bin/untoast_hybrid -fps -c data/small.au.run.gsm > output_small_hybrid_normal.decode.run 2>> small.log

#MiBench Hybrid softwarethread
echo **********toast_hybrid********** >> small.log
bin/toast_hybrid -fps -c -H 1 0 data/small.au > output_small_hybrid_1swt_0hwt.encode.gsm 2>> small.log
echo **********untoast_hybrid********** >> small.log
bin/untoast_hybrid -fps -c -H 1 0 data/small.au.run.gsm > output_small_hybrid_1swt_0hwt.decode.run 2>> small.log

#MiBench Hybrid hardwarethread
echo **********toast_hybrid********** >> small.log
bin/toast_hybrid -fps -c -H 0 1 data/small.au > output_small_hybrid_0swt_1hwt.encode.gsm 2>> small.log
echo **********untoast_hybrid********** >> small.log
bin/untoast_hybrid -fps -c -H 0 1 data/small.au.run.gsm > output_small_hybrid_0swt_1hwt.decode.run 2>> small.log
