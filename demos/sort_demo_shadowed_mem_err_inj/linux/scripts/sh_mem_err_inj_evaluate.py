#!/usr/bin/python

# For print without newline at the end
from __future__ import print_function

import sys, pprint, png



totalFaultsInjected = 0
faultByErrorCode = [0 for x in xrange(-1, 256)]
longestRunningNoError = 0
longestRunningError = 0

errorList = [] # contains addresses of observed faults

# Extracts fault address from fault string and returns array containing address elements
# FA 0,0,2,17,4,58,29 Wed Jan  6 10:30:35 2016 ./sort_demo_shadowed -h 1 -s 0 -m 0 -b 1 -a  --level 3 >> 2016-01-06/sort_perf_on_lvl3_run 2>&1
def getAddress(_string):
    address = _string.split(" ")[1]
    try:
        address_array = [int(x) for x in address.split(",")]
    except:
        address_array = [-1 for x in xrange(7)]
    return address_array

# parse file from commandline
    #  - statistics:
    #  - total injected errors
    #  - total faults
    #  - faults by error code
    #  - longest running no error
    #  - longest run of errors
    #  - error density
    #  - heat map!!!!
def parseFile(_file):
    
    # Statistics
    _totalFaultsInjected = 0
    _faultByErrorCode = [0 for x in xrange(-1, 256)]
    _longestRunningNoError = 0
    _longestRunningNoErrorEndAddress= [-1 for x in xrange(7)]
    _longestRunningError = 0
    _longestRunningErrorEndAddress= [-1 for x in xrange(7)]
    
    _errorList = []
    
    longestRunningNoErrorCounter=0
    longestRunningErrorCounter=0
    
    # Initialize parser state machine
    parseState = "SearchFaultInjection" #"SearchError", "SearchErrorDescription"
    address = [-1 for x in xrange(7)]
    
    for line in _file:
        if parseState == "SearchFaultInjection": # basically skips garbage in log file 
            if line.startswith("FA "):
                parseState = "SearchError"
            # else goes to next line
        if parseState == "SearchError": # runs through fault injections and looks for one that created an error
            if line.startswith("FA "):
                _totalFaultsInjected = _totalFaultsInjected + 1
                longestRunningNoErrorCounter = longestRunningNoErrorCounter +1
                
                if longestRunningNoErrorCounter == 2: # at least one error-less fault injection -> reset counter
                    if _longestRunningError < longestRunningErrorCounter:
                        _longestRunningError = longestRunningErrorCounter
                        _longestRunningErrorEndAddress = address
                    longestRunningErrorCounter = 0
                 
                address = getAddress(line)
                parseState = "SearchError"
            else:
                # found error!
                if _longestRunningNoError < longestRunningNoErrorCounter:
                    _longestRunningNoError = longestRunningNoErrorCounter
                    _longestRunningNoErrorEndAddress = address
                longestRunningNoErrorCounter = 0
                
                #if longestRunningNoErrorCounter == 1: # 
                longestRunningErrorCounter = longestRunningErrorCounter + 1
                
                parseState = "SearchErrorDescription"
                
        if parseState == "SearchErrorDescription":
            if line.startswith("Return") :
                # EXAMPLE: Return Code 203 indicated error. Logging to 2015-11-30/sort_perf_on_lvl3_run
                errorCode =  int( line.split(" ")[2] )
                _faultByErrorCode[errorCode] = _faultByErrorCode[errorCode] + 1 
                _errorList.append((address,errorCode))
                parseState = "SearchFaultInjection"
            elif line.startswith("Program"):
                # EXAMPLE: Program aborted due to timeout. Logging to 2015-11-30/sort_perf_on_lvl3_run
                errorCode = -1
                _faultByErrorCode[errorCode] = _faultByErrorCode[errorCode] + 1
                _errorList.append((address,errorCode))
                parseState = "SearchFaultInjection"
            elif line.startswith("Status query aborted"):
                # EXAMPLE: Program aborted due to timeout. Logging to 2015-11-30/sort_perf_on_lvl3_run
                errorCode = -2
                _faultByErrorCode[errorCode] = _faultByErrorCode[errorCode] + 1
                _errorList.append((address,errorCode))
                parseState = "SearchFaultInjection"
            elif line.startswith("FA "):
                # oops, should not happen! Emit debug info!
                print("PARSE ERROR: Found next fault injection where error description should be!")
                print(line)
                sys.exit(2)
                
    return _totalFaultsInjected, _faultByErrorCode, _longestRunningNoError,_longestRunningNoErrorEndAddress, _longestRunningError,_longestRunningErrorEndAddress, _errorList
    
def printFaultByErrorCode(_faultByErrorCodeList):
    errorCodeToString = [ "UNKNOWN_ERROR" for x in xrange(-1, 256)]
    
    #
    # Application error codes
    #
    errorCodeToString[2]="MALLOC"
    errorCodeToString[3]="CMD_LINE_PARSE"
    errorCodeToString[4]="FAULTY_RESULT"
    errorCodeToString[5]="FAULTY_RQ_RECV"
    errorCodeToString[6]="SEGFAULT"
    
    errorCodeToString[128+4]="MAIN_THREAD_SIGILL"
    errorCodeToString[128+6]="MAIN_THREAD_SIGABORT"
    errorCodeToString[128+11]="MAIN_THREAD_SIGSEGV"
        
    #
    # Thread shadowing error codes
    #
    
    errorCodeToString[16]="FUNC_ERROR"
    errorCodeToString[17]="WATCHDOG"
    errorCodeToString[18]="OSIF_NR_ILLEGAL"
    errorCodeToString[19]="OSIF_PARAM_ILLEGAL"
    errorCodeToString[20]="FILE_OPEN_ERORR"
    errorCodeToString[21]="FILE_READWRITE_ERROR"
    errorCodeToString[22]="GENERIC_ERROR"
    errorCodeToString[23]="MALLOC_ERROR"
    errorCodeToString[24]="PROC_CONTROL_ERROR"
    
    errorCodeToString[64+4]="SHADOW_THREAD_SIGILL"
    errorCodeToString[64+6]="SHADOW_THREAD_SIGABORT"
    errorCodeToString[64+11]="SHADOW_THREAD_SIGSEGV"
    
    errorCodeToString[192+4]="PROC_CONTROL_THREAD_SIGILL"
    errorCodeToString[192+6]= "PROC_CONTROL_THREAD_SIGABORT"
    errorCodeToString[192+11]="PROC_CONTROL_THREAD_SIGSEGV"
    errorCodeToString[192+32]="PROC_CONTROL_THREAD_MEMIF_ERR"

    errorCodeToString[255]="TIMEOUT_SYSTEM"    
    errorCodeToString[256]="TIMEOUT_APPLICATION"
    print("faultByErrorCode:")
    for errorCnt, errorCode in zip(_faultByErrorCodeList, xrange(len(_faultByErrorCodeList))):
        if ( errorCnt != 0 ) or ( errorCodeToString[errorCode] != "UNKNOWN_ERROR" ) :
            print("\t{}\t{}:\t{}".format(errorCode,errorCodeToString[errorCode].ljust(30), errorCnt))

# Assumes _errorList to contain only errors from one row and generates an image
# of 128x 128 Pixels (Minors x Words), with the amount of faults in a word determining
# its color value
def errorListToHeatMap(_errorList, _filename, _maxErrorCount=None):
    #format of pixels is [R,G,B, R,G,B, ...]
    pixels = [ [255 for word in xrange(128*3)] for minor in xrange(128) ]
    
    # sum up errors
    for error in errorList:
        minor = error[0][4] #minor
        word = error[0][5] #word
        if pixels[minor][word*3] == 255:
            pixels[minor][word*3] = 0
            pixels[minor][word*3+1] = 0
            pixels[minor][word*3+2] = 0
        pixels[minor][word*3] += 1
        
    # determine maximum error count
    max = 0
    for x in pixels:
        for y in x:
            if y !=255 and y > max: max = y;
    print("Maximum pixel value: {}".format( max) )
    
    if _maxErrorCount != None: 
        if max < _maxErrorCount:
            max=_maxErrorCount
            print("Maximum pixel value overruled to : {}".format( max) )
    
    #scale colors in bitmap 
    for x in xrange(len(pixels)):
        for y in xrange(0,len(pixels[x]), 3):
            if pixels[x][y] != 255:
                pixels[x][y] = int( pixels[x][y]*(255.0/(max)) ) 
                
    # write out png image
    png.from_array(pixels, "RGB", {"height":128,"width":128}).save(_filename)

def wordsWithoutErrors(_errorList):
    errorsPerWord = [ [0 for word in xrange(128)] for minor in xrange(128) ]
    emptyWordCnt = 0
    unemptyWordCnt = 0
    for error in errorList:
        minor = error[0][4] #minor
        word = error[0][5] #word
        errorsPerWord[minor][word] =  errorsPerWord[minor][word] + 1
    for minor in errorsPerWord[0:8]:
        for word in minor:
            if word == 0:
                emptyWordCnt = emptyWordCnt + 1
            else:
                unemptyWordCnt = unemptyWordCnt + 1
    #print(errorsPerWord)
    return  emptyWordCnt, unemptyWordCnt

def myPrettyListPrint(l):
    for item, index in zip(l, xrange(len(l))):
        print(item, end="")
        print(",", end="")
        if index % 4 == 3:
            print("")
    print("")

if __name__ == "__main__":
    # open file from commandline
    print("Opening file {}...".format(sys.argv[1]))
    try:
        fp = open(sys.argv[1])
    except IOError as e:
        print(e)
        sys.exit(1)
    
    print("Parsing file ...")
    totalFaultsInjected, faultByErrorCode, longestRunningNoError, longestRunningNoErrorEndAddress,longestRunningError, longestRunningErrorEndAddress,errorList = parseFile(fp)
    
    print("Statistics\n----------")
    print("totalFaultsInjected: {}\nerrorDensity: {}\nlongestRunningNoError: {}\nlongestRunningNoErrorEndAddress: {}\nlongestRunningError: {}\nlongestRunningErrorEndAddress: {}".format(totalFaultsInjected, float(len(errorList))/float(totalFaultsInjected),longestRunningNoError,longestRunningNoErrorEndAddress,longestRunningError, longestRunningErrorEndAddress))
    printFaultByErrorCode(faultByErrorCode)
    print("errorList length: {}".format(len(errorList)))

    if False:
        print("errorList of CMD_LINE_PARSE:")
        clList = [x[0] for x in errorList if x[1] == 1 ]
        myPrettyListPrint(clList)
    
    if False:
        print("errorList of MALLOC:")
        maList = [x[0] for x in errorList if x[1] == 2 ]
        myPrettyListPrint(maList)
        
    if True:
        print("errorList of FAULTY_RESULT:")
        frList = [x[0] for x in errorList if x[1] == 4 ]
        myPrettyListPrint(frList)
        
    if False:
        print("errorList of FC_EXIT_CODE:")
        fcList = [x[0] for x in errorList if x[1] == 16 ]
        myPrettyListPrint(fcList)
        
    if False:
        print("errorList of MAIN_THREAD_SIGSEGV:")
        mtssList = [x[0] for x in errorList if x[1] == 139 ]
        myPrettyListPrint(mtssList)
        
    if False:
        print("errorList of PROC_CONTROL_THREAD_SIGSEGV:")
        pcssList = [x[0] for x in errorList if x[1] == 203 ]
        myPrettyListPrint(pcssList)
        
    if False:
        print("errorList of PROC_CONTROL_THREAD_MEMIF_ERROR:")
        meList = [x[0] for x in errorList if x[1] == 224 ]
        myPrettyListPrint(meList)
        
    if False:
        print("errorList of TIMEOUTS:")
        toList = [x[0] for x in errorList if x[1] == -1 ]
        myPrettyListPrint(toList)
    
    if False:
        print("errorList of errors outside implemented addresses:")
        # address: type, half, row, column, minor, word, bit
        # implemented addresses: minor from 0 to 35, words from 0 to 80
        outsidersList = [x for x in errorList if x[0][4] > 35 or x[0][5] > 80 ]
        myPrettyListPrint(outsidersList)
        print("outsidersList length: {}".format(len(outsidersList)))
    
    
    
    #pprint.pprint(errorList)
    woE, wE = wordsWithoutErrors(errorList)
    print("Word with errors : {}, Words without Errors: {}, Percentage of words with errors: {}".format(wE, woE, float(wE)*100.0/(wE+woE)) )
    errorListToHeatMap(errorList, "Heatmaptest.png", _maxErrorCount=20)
    
    sys.exit()
