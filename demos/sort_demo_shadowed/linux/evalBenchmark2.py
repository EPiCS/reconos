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
        
        # Timing analysis
        # Timestats (min,avg,max) in us of shadowed thread 0x100a53c4: dot 12, 12, 14 , detlat: -16189, 949, 11999
        # Timestats summary (min/avg/max) in us: dot 12, 12, 14, detlat: -16189, 949, 11999
        if type == "shadowon":
            while not re.match("Timestats summary", line):
                line=f.readline()
                if len(line) == 0: break
            if len(line) == 0: break
            splittedLine = re.split(" |,",line)
            dot_min = splittedLine[6]
            dot_avg = splittedLine[8]
            dot_max = splittedLine[10]
            detlat_min = splittedLine[13]
            detlat_avg = splittedLine[15]
            detlat_max = string.strip(splittedLine[17])
        
        
        # old style csv output for every single run
        #print( ", ".join([type, interface, hwt, swt, blocks, shadowing, runtime]))
            
        # new style data accumulation:
        key= ", ".join([interface, hwt, swt, blocks])
        if not summary.has_key(key):
            summary[key] = {}
        summary[key][type] = runtime
        if type == "shadowon": 
            summary[key]['dot_min'] = dot_min
            summary[key]['dot_avg'] = dot_avg
            summary[key]['dot_max'] = dot_max
            summary[key]['detlat_min'] = detlat_min
            summary[key]['detlat_avg'] = detlat_avg
            summary[key]['detlat_max'] = detlat_max
        #(runtime, dot_min, dot_avg, dot_max, detlat_min, detlat_avg, detlat_max) 
        
        # read in next line before looping
        line=f.readline()
        
    print("# interface, hwt,swt, blocks, runtime normal (ms), runtime shadowoff (ms), runtime shadowon (ms), dot_min (us), dot_avg (us), dot_max (us), detlat_min (us), detlat_avg (us), detlat_max (us)")
    for k,v in sorted(summary.items()):
        record = k
        for t in ['normal', 'shadowoff', 'shadowon', "dot_min", "dot_avg", "dot_max", "detlat_min", "detlat_avg", "detlat_max"] :       
            record += ", "
            if v.has_key(t): record +=  v[t]
        print (record)
        