#!/usr/bin/python

import sys, re, string


if __name__ == "__main__":
    filename = sys.argv[1] 
    
    f = open(filename, 'r')
    # input:  output of sort_demo*
    
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
    summary={}
    
    line=f.readline()
    while len(line) > 0:
        # search for program header
        while not re.match("sort_demo", line): 
            line=f.readline()
            if len(line) == 0: break
        if len(line) == 0: break
        if re.match("sort_demo ", line): type="normal"
        if re.match("sort_demo_shadowed ", line): type="shadow"
        
        #search for parameter line
        while not re.match("Parameters:", line): 
            line=f.readline()
            if len(line) == 0: break
        if len(line) == 0: break
        
        splits = re.split(":|,", line)
        #['Parameters', ' hwt', '  0', ' swt', '  1', ' blocks', '     1', ' thread interface', ' MBOX', ' shadowing', ' off']
        hwt= string.strip(splits[2])
        swt= string.strip(splits[4])
        blocks= string.strip(splits[6])
        interface=   string.strip(splits[8])
        shadowing = string.strip(splits[10])
        if shadowing == "off":
            shadowing = "1"
            if type == "shadow": type = "shadowoff"
        else:
            shadowing = "2"
            if type == "shadow": type = "shadowon"
            
        # search for results
        # Total computation time (sort & merge): 2752 ms
        while not re.match("Total computation time", line):
            line=f.readline()
            if len(line) == 0: break
        if len(line) == 0: break
        
        runtime = string.strip((re.split(" ",line)[6]))
        
        # old style csv output for every single run
        #print( ", ".join([type, interface, hwt, swt, blocks, shadowing, runtime]))
            
        # new style data accumulation:
        key= ", ".join([interface, hwt, swt, blocks])
        if not summary.has_key(key):
            summary[key] = {}
        summary[key][type] = runtime 
        
        # read in next line before looping
        line=f.readline()
        
    print("# interface, hwt,swt, blocks, shadowing, runtime normal, runtime shadowoff, runtime shadowon")
    for k,v in sorted(summary.items()):       
        record = k + ", "
        if v.has_key('normal'): record +=  v['normal']
        record += ", "
        if v.has_key('shadowoff'): record +=  v['shadowoff']
        record += ", "
        if v.has_key('shadowon'): record +=  v['shadowon']
        print (record)
        