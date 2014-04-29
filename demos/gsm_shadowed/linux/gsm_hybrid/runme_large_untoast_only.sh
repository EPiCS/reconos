#!/bin/sh

# runme_large_untoast_only.sh
# 
# shell script to run various untoast_hybrid configurations
# with large input
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

bin/untoast -fps -c data/large.au.run.gsm > output_large.decode.run 2> large_times.log
bin/untoast_hybrid -fps -c -H 0 0 data/large.au.run.gsm > output_large_hybrid_0swt_0hwt.decode.run 2>> large_times.log
bin/untoast_hybrid -fps -c -H 1 0 data/large.au.run.gsm > output_large_hybrid_1swt_0hwt.decode.run 2>> large_times.log
bin/untoast_hybrid -fps -c -H 0 1 data/large.au.run.gsm > output_large_hybrid_0swt_1hwt.decode.run 2>> large_times.log
