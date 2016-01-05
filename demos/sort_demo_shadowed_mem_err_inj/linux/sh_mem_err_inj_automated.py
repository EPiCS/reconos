#!/usr/bin/python

import sys, re, string, pexpect, subprocess, getpass, time, datetime, os


TIMEOUT_SEC = 30
REPEAT_COUNT = 1 #10

BIT_COUNT=32
WORD_COUNT=128
MINOR_COUNT=128
COLUMN_COUNT=256
ROW_COUNT=32
HALF_COUNT=2

EXPORT_DIR= "/exports/rootfs_mb"
RECONOS= "/home/meise/git/reconos_epics"
DOW = RECONOS+"/tools/dow"
KERNEL = "/home/meise/git/linux-2.6-xlnx/arch/microblaze/boot/simpleImage.ml605_epics"


# Log files must end in "_run"
LOG_FILE_BASELINE_OLD= "baseline_old_run"
LOG_FILE_BASELINE_OLD_SH="baseline_old_sh_run"
LOG_FILE_BASELINE_OLD_SH_ON_LVL1="baseline_old_sh_on_lvl1_run"
LOG_FILE_BASELINE_OLD_SH_ON_LVL2="baseline_old_sh_on_lvl2_run"
LOG_FILE_BASELINE_OLD_SH_ON_LVL3="baseline_old_sh_on_lvl3_run" # makes no sense for baseline, do it for sanity checking
LOG_FILE_BASELINE="baseline_run"
LOG_FILE_BASELINE_SH="baseline_sh_run"
LOG_FILE_BASELINE_SH_ON_LVL1="baseline_sh_on_lvl1_run"
LOG_FILE_BASELINE_SH_ON_LVL2="baseline_sh_on_lvl2_run"
LOG_FILE_BASELINE_SH_ON_LVL3="baseline_sh_on_lvl3_run" # makes no sense for baseline, do it for sanity checking
LOG_FILE_REL_ON_LVL1="rel_on_lvl1_run"
LOG_FILE_REL_ON_LVL2="rel_on_lvl2_run"
LOG_FILE_REL_ON_LVL3="rel_on_lvl3_run"
LOG_FILE_PERF_ON_LVL1="perf_on_lvl1_run"
LOG_FILE_PERF_ON_LVL2="perf_on_lvl2_run"
LOG_FILE_PERF_ON_LVL3="perf_on_lvl3_run"

BIT_SORT_OLD = RECONOS+"/demos/sort_demo_shadowed_mem/hw/edk_linux_rq/implementation/system.bit"
BIT_SORT = RECONOS+"/demos/sort_demo_shadowed_mem/hw/edk/implementation/system.bit"
BIT_SORT_REL = RECONOS+"/demos/sort_demo_shadowed_mem/hw/edk_mem_rel/implementation/system.bit"
#BIT_SORT_PERF = RECONOS+"/demos/sort_demo_shadowed_mem/hw/edk_mem_perf/implementation/system.bit"
#BIT_SORT_PERF = "/home/meise/Desktop/system_arb_perf_8192.bit"
BIT_SORT_PERF = "/home/meise/git/reconos_epics/demos/sort_demo_shadowed_mem_err_inj/hw/planahead_bitfile/bitfile_analysis.runs/impl_1/system.bit"

SORT_DEMO_DIR="/demos/sort_demo_shadowed_mem_err_inj"

SORT_PARAMS = [1] #4,8,16,32,64,128,256,512

#sort_commands_baseline_old = ["./sort_demo -h 1 -s 0 -b "+str(x)+" -t 2 >> {}/sort_"+LOG_FILE_BASELINE_OLD+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline_old += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -t 2 >> {}/sort_"+LOG_FILE_BASELINE_OLD_SH+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline_old += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a --level 1 -t 2  >> {}/sort_"+LOG_FILE_BASELINE_OLD_SH_ON_LVL1+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline_old += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a --level 2 -t 2  >> {}/sort_"+LOG_FILE_BASELINE_OLD_SH_ON_LVL2+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline_old += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a --level 3 -t 2  >> {}/sort_"+LOG_FILE_BASELINE_OLD_SH_ON_LVL3+" 2>&1" for x in SORT_PARAMS]

#sort_commands_baseline = ["./sort_demo -h 1 -s 0 -b "+str(x)+" >> {}/sort_"+LOG_FILE_BASELINE+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" >> {}/sort_"+LOG_FILE_BASELINE_SH+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a --level 1 >> {}/sort_"+LOG_FILE_BASELINE_SH_ON_LVL1+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a --level 2 >> {}/sort_"+LOG_FILE_BASELINE_SH_ON_LVL2+" 2>&1" for x in SORT_PARAMS]
#sort_commands_baseline += ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a --level 3 >> {}/sort_"+LOG_FILE_BASELINE_SH_ON_LVL3+" 2>&1" for x in SORT_PARAMS]

#LOG_FILE_REL_OFF="rel_off_run"

#sort_commands_rel = ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a  --level 1 >> {}/sort_"+LOG_FILE_REL_ON_LVL1 +" 2>&1" for x in SORT_PARAMS] 
#sort_commands_rel +=["./sort_demo_shadowed -h 1 -s 0 -b "+str(y)+" -a  --level 2 >> {}/sort_"+LOG_FILE_REL_ON_LVL2 +" 2>&1" for y in SORT_PARAMS]
#sort_commands_rel +=["./sort_demo_shadowed -h 1 -s 0 -b "+str(y)+" -a  --level 3 >> {}/sort_"+LOG_FILE_REL_ON_LVL3 +" 2>&1" for y in SORT_PARAMS]

#LOG_FILE_PERF_OFF="perf_off_run"

#sort_commands_perf = ["./sort_demo_shadowed -h 1 -s 0 -b "+str(x)+" -a  --level 1 >> {}/sort_"+LOG_FILE_PERF_ON_LVL1 +" 2>&1" for x in SORT_PARAMS] 
#sort_commands_perf +=["./sort_demo_shadowed -h 1 -s 0 -b "+str(y)+" -a  --level 2 >> {}/sort_"+LOG_FILE_PERF_ON_LVL2 +" 2>&1" for y in SORT_PARAMS]
sort_commands_perf =["./sort_demo_shadowed -h 1 -s 0 -m 0 -b "+str(y)+" -a  --level 3 >> {}/sort_"+LOG_FILE_PERF_ON_LVL3 +" 2>&1" for y in SORT_PARAMS]


BIT_MATRIX = RECONOS+"/demos/matrixmul_shadowed_mem/hw/edk_linux/implementation/system.bit"
BIT_MATRIX_REL = RECONOS+"/demos/matrixmul_shadowed_mem/hw/edk_linux_mem_rel/implementation/system.bit"
BIT_MATRIX_PERF = RECONOS+"/demos/matrixmul_shadowed_mem/hw/edk_linux_mem_perf/implementation/system.bit"
MATRIX_DEMO_DIR="/demos/matrixmul_shadowed_mem"

MATRIX_PARAMS = [512] #256,1024]

matrix_commands_baseline = ["./matrixmul -f -h 1 -s 0 -b "+str(x)+" >> {}/matrix_"+LOG_FILE_BASELINE+" 2>&1" for x in MATRIX_PARAMS]
matrix_commands_baseline += ["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(x)+" >> {}/matrix_"+LOG_FILE_BASELINE_SH+" 2>&1" for x in MATRIX_PARAMS]
matrix_commands_baseline += ["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(x)+" -a --level 1 >> {}/matrix_"+LOG_FILE_BASELINE_SH_ON_LVL1+" 2>&1" for x in MATRIX_PARAMS]
matrix_commands_baseline += ["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(x)+" -a --level 2 >> {}/matrix_"+LOG_FILE_BASELINE_SH_ON_LVL2+" 2>&1" for x in MATRIX_PARAMS]
matrix_commands_baseline += ["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(x)+" -a --level 3 >> {}/matrix_"+LOG_FILE_BASELINE_SH_ON_LVL3+" 2>&1" for x in MATRIX_PARAMS]

#LOG_FILE_REL_OFF="rel_off_run"

matrix_commands_rel = ["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(x)+" -a  --level 1 >> {}/matrix_"+LOG_FILE_REL_ON_LVL1 +" 2>&1" for x in MATRIX_PARAMS] 
matrix_commands_rel +=["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(y)+" -a  --level 2 >> {}/matrix_"+LOG_FILE_REL_ON_LVL2 +" 2>&1" for y in MATRIX_PARAMS]
matrix_commands_rel +=["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(y)+" -a  --level 3 >> {}/matrix_"+LOG_FILE_REL_ON_LVL3 +" 2>&1" for y in MATRIX_PARAMS]

#LOG_FILE_PERF_OFF="perf_off_run"

matrix_commands_perf = ["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(x)+" -a  --level 1 >> {}/matrix_"+LOG_FILE_PERF_ON_LVL1 +" 2>&1" for x in MATRIX_PARAMS] 
matrix_commands_perf +=["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(y)+" -a  --level 2 >> {}/matrix_"+LOG_FILE_PERF_ON_LVL2 +" 2>&1" for y in MATRIX_PARAMS]
matrix_commands_perf +=["./matrixmul_shadowed -f -h 1 -s 0 -b "+str(y)+" -a  --level 3 >> {}/matrix_"+LOG_FILE_PERF_ON_LVL3 +" 2>&1" for y in MATRIX_PARAMS]



BIT_GSM = RECONOS+"/demos/gsm_shadowed_mem/hw/edk_linux/implementation/system.bit"
BIT_GSM_REL = RECONOS+"/demos/gsm_shadowed_mem/hw/edk_linux_mem_rel/implementation/system.bit"
BIT_GSM_PERF = RECONOS+"/demos/gsm_shadowed_mem/hw/edk_linux_mem_perf/implementation/system.bit"
GSM_DEMO_DIR="/demos/gsm_shadowed_mem"

GSM_PARAMS = ['large'] #'small',


gsm_commands_baseline = ["./bin/untoast_hybrid           -fps -c        -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_BASELINE for x in GSM_PARAMS]
gsm_commands_baseline += ["./bin/untoast_hybrid_shadowed -fps -c        -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_BASELINE_SH for x in GSM_PARAMS]
gsm_commands_baseline += ["./bin/untoast_hybrid_shadowed -fps -c -S -L1 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_BASELINE_SH_ON_LVL1 for x in GSM_PARAMS]
gsm_commands_baseline += ["./bin/untoast_hybrid_shadowed -fps -c -S -L2 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_BASELINE_SH_ON_LVL2 for x in GSM_PARAMS]
gsm_commands_baseline += ["./bin/untoast_hybrid_shadowed -fps -c -S -L3 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_BASELINE_SH_ON_LVL3 for x in GSM_PARAMS]

#LOG_FILE_REL_OFF="rel_off_run"

gsm_commands_rel = ["./bin/untoast_hybrid_shadowed -fps -c -S -L1 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_REL_ON_LVL1 for x in GSM_PARAMS] 
gsm_commands_rel +=["./bin/untoast_hybrid_shadowed -fps -c -S -L2 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_REL_ON_LVL2 for x in GSM_PARAMS]
gsm_commands_rel +=["./bin/untoast_hybrid_shadowed -fps -c -S -L3 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_REL_ON_LVL3 for x in GSM_PARAMS]

#LOG_FILE_PERF_OFF="perf_off_run"

gsm_commands_perf = ["./bin/untoast_hybrid_shadowed -fps -c -S -L1 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_PERF_ON_LVL1 for x in GSM_PARAMS] 
gsm_commands_perf +=["./bin/untoast_hybrid_shadowed -fps -c -S -L2 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_PERF_ON_LVL2 for x in GSM_PARAMS]
gsm_commands_perf +=["./bin/untoast_hybrid_shadowed -fps -c -S -L3 -H 0 1 data/"+x+".au.run.gsm > {0}/output_"+x+".decode.run 2>> {0}/gsm_"+LOG_FILE_PERF_ON_LVL3 for x in GSM_PARAMS]


def downloadStuff(_bitstreamOrKernel):
    FNULL = open(os.devnull, 'w')
    return subprocess.call([DOW, _bitstreamOrKernel], stdout=FNULL, stderr=subprocess.STDOUT)

def reboot(_bitstream, _telnetPasswd, _work_dir):
    # do we need to logout properly?
    # what if command line hangs?
    
    # Reset HW and OS
    print("Downloading Bitstream...")
    downloadStuff(_bitstream)
    print("Downloading Kernel...")
    downloadStuff(KERNEL)
    print("Waiting for system boot...")
    time.sleep(60)
    
    # LOGIN
    child = pexpect.spawn ('telnet 192.168.35.2')
    child.expect ('reconos login:.*')
    child.sendline ('root')
    child.expect ('Password:.*')
    child.sendline (_telnetPasswd)
    
    # Preparations
    child.expect('# ')
    child.sendline('cd '+ _work_dir)
    child.expect('# ')
    
    return child

def runErrInj(_benchmarkTag, _telnetPasswd, _bitstream, _commands, _work_dir, _start_address):

    # LOGIN
    child = pexpect.spawn ('telnet 192.168.35.2')
    child.expect ('reconos login:.*')
    child.sendline ('root')
    child.expect ('Password:.*')
    child.sendline (_telnetPasswd)
    
    # Preparations
    child.expect('# ')
    child.sendline('cd '+ _work_dir)
    
    child.expect('# ')
    child.sendline('mkdir -p '+ _benchmarkTag)
    child.expect('# ')
    child.sendline('chmod o+rw '+ _benchmarkTag)
    child.expect('# ')
    
    pexpectLogging = False
    rebootNeeded = False
    
    _half   = _start_address[1]
    _row    = _start_address[2]
    _column = _start_address[3]
    _minor_start = _start_address[4]
    _word_start  = _start_address[5]
    _bit_start   = _start_address[6]
    # Benchmarks
    for minor in xrange(_minor_start, MINOR_COUNT):
        for word in xrange(_word_start, WORD_COUNT):
            for bit in xrange(_bit_start, BIT_COUNT):
                for cmd in _commands:   
                    log_file = cmd.format(_benchmarkTag).split('_run')[0].split(' ')[-1]+"_run"
                    child.sendline('echo -e "###########" >> ' + log_file)
                    child.expect('# ')
                    
                    # Fault injection
                    faultInjCMD = "./xilsem_err_inj -p0,{},{},{},{},{},{}".format(_half,_row,_column,minor,word,bit)
                    child.sendline(faultInjCMD)
                    child.expect('# ')
                    child.sendline('echo -e "' + faultInjCMD + '" >> ' + log_file)
                    child.expect('# ')
                    
                    # Execute command to test if fault affect test programm
                    print("FA 0,{},{},{},{},{},{} ".format(_half,_row,_column,minor,word,bit) + time.ctime()+ ' ' +cmd.format(_benchmarkTag))
                    child.sendline(cmd.format(_benchmarkTag))
                    
                    # Programm runs. Several possibilities now:
                    # - timeout: program got stuck and did not terminate
                    # - termination with error
                    # - termination without error
                    response = child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                    if response == 1: # on timeout
                        # abort programm via CTRL-C
                        child.sendcontrol('c')
                        response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                        if response== 1: print("Timeout while controlling child. Continuing with reboot...") 
                        # insert abortion message into logfile
                        print ("Program aborted due to timeout. Logging to {}".format(log_file))
                        
                        child.sendline('echo "PROGRAM ABORTED!  TIMEOUT EXCEEDED!" >> ' + log_file)
                        response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                        if response== 1: print("Timeout while writing error message to logfile. Continuing with reboot...") 
                        rebootNeeded=True
                    else:
                        # test error code 
                        child.sendline('echo $?') 
                        #time.sleep(5)
                        response= child.expect(['echo \$\?\r\n0\r\n# ', 'echo \$\?\r\n[1-9][0-9]*\r\n# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)

                        if response == 1: # On error return code
                            print(child.before)
                            print(child.after)
                            
                            if pexpectLogging == False :
                                child.logfile = file('telnet.log','w') #sys.stdout
                                pexpectLogging = True
                            
                            print ("Return Code {0} indicated error. Logging to {1}".format(child.after.split('\r\n')[1], log_file))
                            child.sendline('echo "PROGRAM ABORTED!  RETURNCODE INDICATED ERROR: {0}" >> '.format(child.after.split('\r\n')[1]) + log_file)
                            response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                            if response== 1: print("Timeout while writing error message to logfile. Continuing with reboot...") 
                            rebootNeeded=True
                        elif response == 2: # on timeout
                            print("#######################################################################")
                            print(child.before)
                            print("#")
                            print(child.after)
                            print("#######################################################################")
                            
                            # abort programm via CTRL-C
                            child.sendcontrol('c')
                            response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                            if response== 1: print("Timeout while controlling child. Continuing with reboot...") 
                            
                            print("#######################################################################")
                            print(child.before)
                            print("#")
                            print(child.after)
                            print("#######################################################################")
                            
                            # insert abortion message into logfile
                            log_file = cmd.format(_benchmarkTag).split('_run')[0].split(' ')[-1]+"_run"
                            print ("Status query aborted due to timeout. Logging to {}".format(log_file))
                            
                            child.sendline('echo "STATUS QUERY FAILED!  TIMEOUT EXCEEDED!" >> ' + log_file)
                            response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                            if response== 1: print("Timeout while writing error message to logfile. Continuing with reboot...")
                            rebootNeeded=True
                            #sys.exit(1)
                            
                    # Revert Fault injection
                    # either by reboot or by flipping the bit again
                    if rebootNeeded:
                    	child=reboot(_bitstream, _telnetPasswd, _work_dir)
                    	rebootNeeded=False
                    else:
                        child.sendline(faultInjCMD)
                        child.expect('# ')
                        child.sendline('echo -e "' + faultInjCMD + '" >> ' + log_file)
                        child.expect('# ')
            _bit_start = 0 #next loop run shall start from 0 again
        _word_start = 0 #next loop run shall start from 0 again
    _minor_start = 0 #next loop run shall start from 0 again
    # Exit
    child.sendline('exit')
    child.expect('Connection closed by foreign host.')

def fault_inject(_tagBase, _telnetPasswd, _bitstream, _commands, _work_dir, _start_address):
    print("Downloading Bitstream...")
    downloadStuff(_bitstream)
    print("Downloading Kernel...")
    downloadStuff(KERNEL)
    print("Waiting for system boot...")
    time.sleep(60)
    print("Executing Benchmark...")
    runErrInj(_tagBase, _telnetPasswd, _bitstream, _commands, _work_dir, _start_address)

def parse_string_to_tuple(_string, _fallback_value):
    list = _string.split(',');
    if len(list) != 7:
        return _fallback_value
    try:
        return [int(x) for x in list]
    except:
        return _fallback_value
   
if __name__ == "__main__":
    
    start_address=[0,0,2,17,0,0,0]
    
    if len(sys.argv) == 1:
        pass
    elif len(sys.argv) == 2:
        start_address = parse_string_to_tuple(sys.argv[1], start_address)
    
    telnetPasswd = getpass.getpass('telnet password: ')
    
    benchmarkTagBase = str(datetime.date(1,1,1).today())
    
    #
    # Benchmarks
    #
    fault_inject(benchmarkTagBase, telnetPasswd, BIT_SORT_PERF, sort_commands_perf, SORT_DEMO_DIR, start_address)

    
    
    print("Done!")
    sys.exit()
    