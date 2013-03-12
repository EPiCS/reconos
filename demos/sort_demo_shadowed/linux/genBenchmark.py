#!/usr/bin/python

import sys

'''
Generates a shell script file with commands for a full benchmark spanning 
several threads and hw/sw combinations. The shell script is as simple as 
possible because the embedded ash on the virtex 6 board does not support 
any fancy programming constructs.
'''

#hwt =[0, 0,  0,   0,    0, 0,  0,   0,    0, 0,  0,   0,    0,  0,  0,   0,    1, 1,  1,   1,    2, 2,  2,   2,    4, 4,  4,   4,    8,  8,  8,   8,]
#swt= [1, 1,  1,   1,    2, 2,  2,   2,    4, 4,  4,   4,    8,  8,  8,   8,    0, 0,  0,   0,    0, 0,  0,   0,    0, 0,  0,   0,    0,  0,  0,   0]
#nb=  [1, 16, 128, 1024, 2, 16, 128, 1024, 4, 16, 128, 1024, 8,  16, 128, 1024, 1, 16, 128, 1024, 2, 16, 128, 1024, 4, 16, 128, 1024, 8,  16, 128, 1024]

HWT=0
SWT=1
NB =2
IF =3
runConf = [
    #(hwt, swt, blocks)
    #sw only
    (0,1,1),
    (0,1,8),
    (0,1,16),
    (0,1,32),
    (0,1,64),
    (0,2,2),
    (0,2,8),
    (0,2,16),
    (0,2,32),
    (0,2,64),
    (0,3,3),
    (0,3,8),
    (0,3,16),
    (0,3,32),
    (0,3,64),
    (0,4,4),
    (0,4,8),
    (0,4,16),
    (0,4,32),
    (0,4,64),
#    (0,8,8),
#    (0,8,16),
#    (0,8,32),
#    (0,8,64),
            
    #hw only            
    (1,0,1),
    (1,0,8),
    (1,0,16),
    (1,0,32),
    (1,0,64),
    (2,0,2),
    (2,0,8),
    (2,0,16),
    (2,0,32),
    (2,0,64),
    (3,0,2),
    (3,0,8),
    (3,0,16),
    (3,0,32),
    (3,0,64),
    (4,0,4),
    (4,0,8),
    (4,0,16),
    (4,0,32),
    (4,0,64),
#    (5,0,2),
#    (5,0,16),
#    (5,0,32),
#    (5,0,64),
#    (6,0,2),
#    (6,0,16),
#    (6,0,32),
#    (6,0,64),
#    (7,0,7),
#    (7,0,16),
#    (7,0,32),
#    (7,0,64),
    ]


#ofiles = ["bench_sortdemo_shmem.txt", "bench_sortdemo_shadowed_off_shmem.txt", "bench_sortdemo_shadowed_on_shmem.txt",
#          "bench_sortdemo_mbox.txt", "bench_sortdemo_shadowed_off_mbox.txt", "bench_sortdemo_shadowed_on_mbox.txt",
#          "bench_sortdemo_rqueue.txt", "bench_sortdemo_shadowed_off_rqueue.txt", "bench_sortdemo_shadowed_on_rqueue.txt",
#          ]

ofiles = ["bench_sortdemo.txt", "bench_sortdemo_shadowed.txt"]

def genSortDemoRuns (_runIdx, _runConf, _ofile, _threadInterface, _start_idx, _end_idx):
    for i in range(_start_idx, _end_idx):
        cmdString = "./sort_demo " + str(_runConf[i][HWT]) + " " + str(_runConf[i][SWT]) + " " + str(_runConf[i][NB]) + " " + str(_threadInterface) + " >> " + _ofile + "\n"
        f.write("if [ $STARTIDX -le " + str(_runIdx) + " ]; then \n") 
        f.write("echo -n \" " + str(_runIdx) + " " + cmdString+ "\"\n")
        f.write(cmdString)
        f.write("echo -e \"\\n##############################################\\n\" >> " + _ofile + "\n")
        f.write("fi\n\n")
        _runIdx += 1
    f.write("echo\n")
    return _runIdx

def genSortDemoShadowedRuns (_runIdx, _runConf, _ofile, _threadInterface, _start_idx, _end_idx, _shadowed):
    for i in range(_start_idx, _end_idx):
        cmdString = "./sort_demo_shadowed " + str(_runConf[i][HWT]) + " " + str(_runConf[i][SWT]) + " " + str(_runConf[i][NB]) + " " + str(_threadInterface) + " " + str(_shadowed) + " >> " + _ofile + "\n"
        f.write("if [ $STARTIDX -le " + str(_runIdx) + " ]; then \n")
        f.write("echo -n \" " + str(_runIdx) + " " + cmdString+ "\"\n")
        f.write(cmdString)
        f.write("echo -e \"\\n##############################################\\n\" >> " + _ofile + "\n")
        f.write("fi\n\n")
        _runIdx += 1
    f.write("echo\n")    
    return _runIdx

if __name__ == "__main__":
    filename = sys.argv[1] 
    
    runIdx = 0
    f = open(filename, 'w')
    f.write("#!/bin/sh\n\n")
    
    f.write("# This is an automatically generated benchmark script.\n")
    f.write("# Do not modify this by hand. Modify the generator genBenchmark.py\n\n")
        
    #deletes old data files for consistency: old measurements don't mix with new ones
    for i in range(0, len(ofiles)):
        f.write("echo \"\" >" + ofiles[i] + "\n")
    
    #set variables
    f.write("if [ -n \"$1\" ]; then STARTIDX=$1; else STARTIDX=0; fi\n\n")
    
    f.write("echo \"First run with unmodified sort_demo...\"\n")
    runIdx = genSortDemoRuns(runIdx, runConf, ofiles[0], 0, 0, len(runConf))
    runIdx = genSortDemoRuns(runIdx, runConf, ofiles[0], 1, 0, len(runConf))
    runIdx = genSortDemoRuns(runIdx, runConf, ofiles[0], 2, 0, len(runConf))
    
    f.write("echo \"Second run with sort_demo_shadowed (shadowing off)...\"\n")
    runIdx = genSortDemoShadowedRuns (runIdx, runConf, ofiles[1], 0, 0, len(runConf), 1)
    runIdx = genSortDemoShadowedRuns (runIdx, runConf, ofiles[1], 1, 0, len(runConf), 1)
    runIdx = genSortDemoShadowedRuns (runIdx, runConf, ofiles[1], 2, 0, len(runConf), 1)
    
    f.write("echo \"Third run with sort_demo_shadowed (shadowing_on)...\"\n")
    runIdx = genSortDemoShadowedRuns (runIdx, runConf, ofiles[1], 0, 0, len(runConf)-10, 2)
    runIdx = genSortDemoShadowedRuns (runIdx, runConf, ofiles[1], 1, 0, len(runConf)-10, 2)
    runIdx = genSortDemoShadowedRuns (runIdx, runConf, ofiles[1], 2, 0, len(runConf)-10, 2)
    