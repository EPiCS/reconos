#!/usr/bin/python

import sys, re, string, pexpect, subprocess, getpass, time, datetime, os, json 
from virtex6 import *
from addressGenerator import *
from LockManager import *
from ml605ResetManager import *

SYSTEM_BOOT_TIME=35 #was 25
TIMEOUT_SEC = 30
REPEAT_COUNT = 1 #10


EXPORT_DIR= "/exports/rootfs_mb"
RECONOS= "/home/meise/git/reconos_epics"
DOW = RECONOS+"/tools/dow"
KERNEL = ["/home/meise/git/linux-2.6-xlnx/arch/microblaze/boot/simpleImage.ml605_epics_first_board",
          "/home/meise/git/linux-2.6-xlnx/arch/microblaze/boot/simpleImage.ml605_epics_second_board"]
IP_ADDRESS = ["192.168.35.2", "192.168.35.3"]

#ESN = ["0000145B17DE01", "0000145B185501"]
ESN = ["000013C81F0B01", "0000145B185501"]

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



BIT_SORT_PERF = "/home/meise/git/reconos_epics/demos/sort_demo_shadowed_mem_err_inj/hw/BIT_SORT_PERF_system.bit"
#BIT_SORT_PERF = "/home/meise/git/reconos_epics/demos/sort_demo_shadowed_mem_err_inj/hw/BIT_SORT_PERF_NEW_LAYOUT_system.bit"



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


def cleanCableLock():
    FNULL = open(os.devnull, 'w')
    return subprocess.call('echo -e "cleancablelock\nquit\n" | impact -batch', shell=True, stdout=FNULL, stderr=subprocess.STDOUT)

def downloadStuff(_bitstreamOrKernel, _esn=""):
    FNULL = open(os.devnull, 'w')
    returncode = subprocess.call([DOW, _bitstreamOrKernel, _esn], stdout=FNULL, stderr=subprocess.STDOUT)
    if returncode != 0:
        print ("Download of {} via cable {} failed. Returncode: {}".format(_bitstreamOrKernel, _esn, returncode))
    return returncode

def rebootOld(_bitstream, _telnetPasswd, _work_dir, _benchmarkTag, _boardNr, _cableLock, _silent=False):
    # do we need to logout properly?
    # what if command line hangs?
    
    _cableLock.acquire()
    # Reset HW and OS
    cleanCableLock();
    if not _silent: print("Downloading Bitstream...")
    downloadStuff(_bitstream, ESN[_boardNr])
    if not _silent: print("Downloading Kernel...")
    downloadStuff(KERNEL[_boardNr], ESN[_boardNr])
    
    _cableLock.release()
    
    if not _silent: print("Waiting for system boot...")
    time.sleep(SYSTEM_BOOT_TIME)
    
    # LOGIN
    child = pexpect.spawn ('telnet '+IP_ADDRESS[_boardNr])
    child.expect ('reconos login:.*')
    child.sendline ('root')
    child.expect ('Password:.*')
    child.sendline (_telnetPasswd)
    
    child.delaybeforesend = 0
    
    # Preparations
    child.expect('# ')
    child.sendline('cd '+ _work_dir)
    child.expect('# ')
    child.sendline('mkdir -p '+ _benchmarkTag)
    child.expect('# ')
    child.sendline('chmod o+rw '+ _benchmarkTag)
    child.expect('# ')
    return child

def reboot(_config, _silent=False):
    # do we need to logout properly?
    # what if command line hangs?
    
    # Reset the ML605 board and let it reload bitstream and linux kernel from compact flash 
    # we are reusing the _cablelock parameter here for reset
    if not _silent: print("Resetting ML605 board...")
    _config['ml605ResetMgr'].reset(_config['boardNr'])
    
    if not _silent: print("Waiting for system boot...")
    time.sleep(SYSTEM_BOOT_TIME)
    
    # LOGIN
    child = pexpect.spawn ('telnet '+IP_ADDRESS[_config['boardNr']])
    child.expect ('reconos login:.*')
    child.sendline ('root')
    child.expect ('Password:.*')
    child.sendline (_config['telnetPasswd'])
    
    child.delaybeforesend = 0
    
    # Preparations
    child.expect('# ')
    child.sendline('cd '+ _config['work_dir'])
    child.expect('# ')
    child.sendline('mkdir -p '+ _config['benchmarkTag'])
    child.expect('# ')
    child.sendline('chmod o+rw '+ _config['benchmarkTag'])
    child.expect('# ')
    return child

def executeCommands(_config, _child, _faultAddress, _currentFaultIdx, _totalFaults):
                    #_child, _benchmarkTag, _telnetPasswd, _bitstream, _commands, _work_dir, _faultAddress, _boardNr, _cableLock, _currentFaultIdx, _totalFaults, _blockedFI=False):
    child = _child
    pexpectLogging = False
    rebootNeeded = False
    for cmd in _config['commands']:   
        log_file = cmd.format(_config['benchmarkTag']).split('_run')[0].split(' ')[-1]+"_run"
        child.sendline('echo -e "###########" >> ' + log_file)
        #child.expect('# ')
        
        # Fault injection
        if _config['blockedFaultInject']:
            # Blocked Fault injection: flip complete block 
            faultInjCMD = "./xilsem_err_inj -p{},{},{},{},{},{},{} -w".format(*_faultAddress)
        else:
            faultInjCMD = "./xilsem_err_inj -p{},{},{},{},{},{},{}".format(*_faultAddress)
            
        if not config['dry_run']:
            child.sendline(faultInjCMD)
            #child.expect('# ')
            child.sendline('echo -e "' + faultInjCMD + '" >> ' + log_file)
            #child.expect('# ')
        
        # Execute command to test if fault affect test programm
        print("FA {},{},{},{},{},{},{} ".format(*_faultAddress) + time.ctime()+
               ' ' +cmd.format(_config['benchmarkTag']) + ' ' + str(_currentFaultIdx) +
               '/' + str(_totalFaults))
        child.sendline(cmd.format(_config['benchmarkTag']))
        
        # Programm runs. Several possibilities now:
        # - timeout: program got stuck and did not terminate
        # - termination with error
        # - termination without error
        response = child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
        if response == 1: # on timeout
            print ("Program aborted due to timeout. Logging to {}".format(log_file))
            child.sendcontrol('c')
            child.sendcontrol('z')
            child.sendline('echo "PROGRAM ABORTED!  TIMEOUT EXCEEDED!" >> ' + log_file)
            response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
            if response== 1: print("Timeout while writing error message to logfile. Continuing with reboot...") 
            rebootNeeded=True
        else: # test error code 
            child.sendline('echo $?') 
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
                log_file = cmd.format(_config['benchmarkTag']).split('_run')[0].split(' ')[-1]+"_run"
                print ("Status query aborted due to timeout. Logging to {}".format(log_file))
                
                child.sendline('echo "STATUS QUERY FAILED!  TIMEOUT EXCEEDED!" >> ' + log_file)
                response=child.expect(['# ', pexpect.TIMEOUT],timeout=TIMEOUT_SEC)
                if response== 1: print("Timeout while writing error message to logfile. Continuing with reboot...")
                rebootNeeded=True
                #sys.exit(1)
                
        # Revert Fault injection
        # either by reboot or by flipping the bit again
        if rebootNeeded:
            child=reboot(_config)
            rebootNeeded=False
        else:
            if not config['dry_run']:
                child.sendline(faultInjCMD)
                #child.expect('# ')
                child.sendline('echo -e "' + faultInjCMD + '" >> ' + log_file)
                child.expect('# ')
                pass
    
    return child

def runFaultInject(_config):
                   #_benchmarkTag, _telnetPasswd, _bitstream, _commands, _work_dir, _faultList, _boardNr, _cableLock, _blockedFaultInject=False):
    """ _blockeFaultInject=True flips complete words instead of single bits. Please prepare the _faultList such, that it contains
    every word address only once.""" 
    done = False
    exceptionCounter = 0
    checkpoint_address = 0
    addressListLength = len(_config['addressList'])
    
    while not done:
        try:
            # LOGIN
            child = reboot(_config, _silent=False)
            #print("B")
            
            # Benchmarks
            for address in _config['addressList'][checkpoint_address:] :
                # Due to reboots of system under tests, child might change inside the function.
                # Therefore we return it back to caller
                #print("Executing commands")
                #print(child, _benchmarkTag, _telnetPasswd, _bitstream, 
                #                _commands, _work_dir, [_half,_row,_column,_minor_start,_word_start, _bit_start], _blockedFaultInject)
                child = executeCommands( _config, child, address, checkpoint_address,addressListLength )
                
                checkpoint_address += 1
            
            # Exit
            child.sendline('exit')
            child.expect('Connection closed by foreign host.')
            done = True
            print("Number of exceptions during fault injection campaign: {}".format(exceptionCounter))
            
        except KeyboardInterrupt:
            exceptionCounter = exceptionCounter +1
            sys.exit()
        except pexpect.ExceptionPexpect as e:
            print(e)
            exceptionCounter = exceptionCounter +1
        
   
if __name__ == "__main__":
    ''' Performs fault injection tests. First command line argument specifies starting column address. Second argument specifies which board to use [0,1]
        Fault injection is performed until all essential bits in address have been tested.
    '''
    
    config = {
        'boardNr':0,
        'start_address': [0,0,2,17,0,0,0],
        'noFaultInjection': False,
        'blockedFaultInject': False,
        'addressFile': "",
        'benchmarkTag': str(datetime.date(1,1,1).today()),
        'addressList': [],
        'telnetPasswd': "",
        'ml605ResetMgr': None,
        
        'dry_run':False,
        
        'bitstream': BIT_SORT_PERF,
        'commands': sort_commands_perf,
        'work_dir': SORT_DEMO_DIR
        
    }
    
    ###boardNr = 0
    ###start_address=[0,0,2,17,0,0,0]
    ###noFaultInjection=False
    
    # Deactivate buffering in outputs. When piping output of this script 
    # through 'tee', standard io buffering prevents outputs until 4096 bytes 
    # are ready to be output.
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
    if len(sys.argv) < 4:
        print('Usage: {} <startAddress> <addressFilePath> <boardNr> [--dry-run]'.format(sys.argv[0]))
        sys.exit(1)
    if len(sys.argv) >= 4:
        config['start_address'] = parse_string_to_address(sys.argv[1], config['start_address'])
        config['addressFile'] = sys.argv[2]
        config['boardNr'] = int(sys.argv[3])
    if len(sys.argv) >= 5 and sys.argv[4] == "--dry-run":
        config['dry_run'] = True
        
    print("Using board {}, file {}  and start address {}".format(config['boardNr'],config['addressFile'], config['start_address']) )
    
    
    # Loads addresses of essential bits
#    column = start_address[3]
    try:
        config['addressList'] = json.load(open(config['addressFile'], "r"))
        print("Address count in file {}: {}".format(config['addressFile'],len(config['addressList'])))
    except:
        print("Error reading file: {}".format(config['addressFile']))
        print(sys.exc_info()[0:2])
        sys.exit()
    
    #
    # Fast forward essential bit list to address given on command line 
    #
    if cmpAddress(config['start_address'], "0,0,0,0,0,0,0") != 0:
        for addr, i in zip(config['addressList'], xrange(len(config['addressList']))):
            if cmpAddress(config['start_address'], addr) == 0:
                 config['ahttp://www.spiegel.de/ddressList'] = config['addressList'][i:]
                 break
    print("Address count after fast forwarding: {}".format(len(config['addressList'])))
    
    
    config['telnetPasswd'] = getpass.getpass('telnet password: ')
    #
    # Fault injection
    #
    #cableLock = LockManager("/tmp/sh_mem_err_inj_cable_lock")
    #runFaultInject(benchmarkTagBase, telnetPasswd, BIT_SORT_PERF, sort_commands_perf, SORT_DEMO_DIR, addressList, boardNr, cableLock)
    #cableLock.shutdown()
    
    config['ml605ResetMgr'] = ml605ResetManager("/tmp/sh_mem_err_inj_reset")
    runFaultInject(config)
    print("Done!")
    
    # Wait for input from user before exiting.
    # Other ml605ResetMgr clients might be connected to us, so we don't shut 
    # down automatically.
    raw_input("Press any key to exit.")
    config['ml605ResetMgr'].shutdown()
    sys.exit()
    
