#!/usr/bin/python

import sys, re, string


if __name__ == "__main__":
    filename = sys.argv[1] 
    
    f = open(filename, 'r')
    # input:  output of sort_demo*
    print("# type, interface, hwt,swt, blocks, shadowing, runtime")
    
    if len(sys.argv) >2:
        type= sys.argv[2]
    else:
        type = ""
        
    interface = ""
    hwt = -1
    swt = -1
    blocks = -1
    shadowing = -1
    runtime = -1
    line=f.readline()
    while len(line) > 0:
        if re.match("Parameters:", line):
            splits = re.split(":|,", line)
            #['Parameters', ' hwt', '  0', ' swt', '  1', ' blocks', '     1', ' thread interface', ' MBOX', ' shadowing', ' off']
            hwt= string.strip(splits[2])
            swt= string.strip(splits[4])
            blocks= string.strip(splits[6])
            interface=   string.strip(splits[8])
            shadowing = string.strip(splits[10])
            if shadowing == "off":
                shadowing = "1"
            else:
                shadowing = "2"
            
            line=f.readline()
            while not re.match("Total computation time", line): line=f.readline()
            runtime = string.strip((re.split(" ",line)[6]))
            print( ", ".join([type, interface, hwt, swt, blocks, shadowing, runtime]))
            
        line=f.readline()