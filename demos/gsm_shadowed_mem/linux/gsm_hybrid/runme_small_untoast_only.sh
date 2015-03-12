#!/bin/sh

# runme_small_untoast_only.sh
# 
# shell script to run various untoast_hybrid configurations
# with small input
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

bin/untoast -fps -c data/small.au.run.gsm > output_small.decode.run 2> small_times.log
bin/untoast_hybrid -fps -c -H 0 0 data/small.au.run.gsm > output_small_hybrid_0swt_0hwt.decode.run 2>> small_times.log
bin/untoast_hybrid -fps -c -H 1 0 data/small.au.run.gsm > output_small_hybrid_1swt_0hwt.decode.run 2>> small_times.log
bin/untoast_hybrid -fps -c -H 0 1 data/small.au.run.gsm > output_small_hybrid_0swt_1hwt.decode.run 2>> small_times.log
