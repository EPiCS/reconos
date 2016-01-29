#!/usr/bin/python

import sys, re, string


if __name__ == "__main__":
    filename = sys.argv[1] 
    
    f = open(filename, 'r')
    # input:  output of sort_demo*
    
    type=""
    subtype=""
    interface = ""
    hwt = -1
    swt = -1
    blocks = -1
    shadowing = -1
    runtime = -1
    summary={}
    
    error_flag=False
    
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
        
        #print(line)
        
        splits = re.split(":|,", line)
        #['Parameters', ' hwt', '  0', ' swt', '  1', ' blocks', '     1', ' thread interface', ' MBOX', ' shadowing', ' off']
        hwt= string.strip(splits[2])
        swt= string.strip(splits[4])
        blocks= string.strip(splits[6])
        interface=   string.strip(splits[8])
        
        shadowing = string.strip(splits[10])
        if shadowing == "off":
            if type == "shadow": subtype = "off"
        else:
            if type == "shadow": subtype = "on"
            
        schedule   = string.strip(splits[12])
        if type == "shadow" and subtype == "on" and schedule == '1': subtype = "rr"
            
        transmodal = string.strip(splits[14])
        if type == "shadow" and subtype != "off" and transmodal == '1': subtype +="_tm"
        
        
        #print(type, schedule, transmodal, subtype)
        
            
        # search for results
        # Total computation time (sort & merge): 2752 ms
        while not re.match("Total computation time", line):
            line=f.readline()
            if len(line) == 0: break
            if re.match("##############################################", line):
                error_flag=True
                break
        if len(line) == 0: break
        if re.match("##############################################", line): continue
        
        runtime = string.strip((re.split(" ",line)[6]))
        
        # Timing analysis
        # Timestats (min,avg,max) in us of shadowed thread 0x100a53c4: dot 12, 12, 14 , detlat: -16189, 949, 11999
        # Timestats summary (min/avg/max) in us: dot 12, 12, 14, detlat: -16189, 949, 11999
        if type == "shadow":
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
        
        # Cycles analysis: How many application cylces have been shadowed, how many haven't been?
        # Cycle Stats Summary: inactive: 0.000000, preactive: 0.000000, active: 22.333333
        if type == "shadow":
            while not re.match("Cycle Stats Summary:", line):
                line=f.readline()
                if len(line) == 0: break
            if len(line) == 0: break
            splittedLine = re.split(" |,",line)
            inactive_cycles = splittedLine[4]
            preactive_cycles = splittedLine[7]
            active_cycles = string.strip(splittedLine[10])
        
        # old style csv output for every single run
        #print( ", ".join([type, interface, hwt, swt, blocks, shadowing, runtime]))
            
        # new style data accumulation:
        key= ", ".join([interface, hwt, swt, blocks])
        if not summary.has_key(key):
            summary[key] = {}
        if summary[key].has_key(type+subtype): print("WARNING: Overwriting data! Key:" + key + " type+subtype: " + type+subtype)
        summary[key][type+subtype] = runtime
        if type == "shadow" and subtype != "off": 
            summary[key][subtype+'_dot_min'] = dot_min
            summary[key][subtype+'_dot_avg'] = dot_avg
            summary[key][subtype+'_dot_max'] = dot_max
            summary[key][subtype+'_detlat_min'] = detlat_min
            summary[key][subtype+'_detlat_avg'] = detlat_avg
            summary[key][subtype+'_detlat_max'] = detlat_max
            summary[key][subtype+'_inactive_cycles'] = inactive_cycles
            summary[key][subtype+'_preactive_cycles'] = preactive_cycles
            summary[key][subtype+'_active_cycles'] = active_cycles
        #(runtime, dot_min, dot_avg, dot_max, detlat_min, detlat_avg, detlat_max) 
        
        # read in next line before looping
        line=f.readline()
        
    print("# interface, hwt,swt, blocks,"+\
           "runtime normal (ms),"+\
           "runtime shadowoff (ms),"+\
           "runtime shadowon (ms),dot_min (us), dot_avg (us), dot_max (us), detlat_min (us), detlat_avg (us), detlat_max (us), inactive_cycles, preactive_cycles, active_cycles,"+\
           "runtime shadowrr (ms), dot_min (us), dot_avg (us), dot_max (us), detlat_min (us), detlat_avg (us), detlat_max (us), inactive_cycles, preactive_cycles, active_cycles,"+\
           "runtime shadowon_tm (ms),dot_min (us), dot_avg (us), dot_max (us), detlat_min (us), detlat_avg (us), detlat_max (us), inactive_cycles, preactive_cycles, active_cycles,"+\
           "runtime shadowrr_tm (ms), dot_min (us), dot_avg (us), dot_max (us), detlat_min (us), detlat_avg (us), detlat_max (us),  inactive_cycles, preactive_cycles, active_cycles")
    for k,v in sorted(summary.items()):
        record = k
        for t in ['normal', 
                  'shadowoff', 
                  'shadowon', "on_dot_min", "on_dot_avg", "on_dot_max", "on_detlat_min", "on_detlat_avg", "on_detlat_max", "on_inactive_cycles", "on_preactive_cycles", "on_active_cycles",
                  'shadowrr', "rr_dot_min", "rr_dot_avg", "rr_dot_max", "rr_detlat_min", "rr_detlat_avg", "rr_detlat_max", "rr_inactive_cycles", "rr_preactive_cycles", "rr_active_cycles",
                  'shadowon_tm', "on_tm_dot_min", "on_tm_dot_avg", "on_tm_dot_max", "on_tm_detlat_min", "on_tm_detlat_avg", "on_tm_detlat_max", "on_tm_inactive_cycles", "on_tm_preactive_cycles", "on_tm_active_cycles",
                  'shadowrr_tm', "rr_tm_dot_min", "rr_tm_dot_avg", "rr_tm_dot_max", "rr_tm_detlat_min", "rr_tm_detlat_avg", "rr_tm_detlat_max", "rr_tm_inactive_cycles", "rr_tm_preactive_cycles", "rr_tm_active_cycles"] :       
            record += ", "
            if v.has_key(t): record +=  v[t]
        print (record)
    if error_flag:
         print("Warning! Source file might contain errors. Results may not be accurate!")   