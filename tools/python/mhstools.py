#!/usr/bin/env python
# coding: utf8

#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS
#   author:       Enno Lübbers, University of Paderborn
#   description:  API for parsing and manipulationg mhs files.
# 
# ======================================================================

import string
import sys


# return a binary representation of a number
# x: number
# n: number of binary digits
def ntob(x, n):
        s = "";
        for i in range(0, n):
                if (x << i) & (1 << n-1):
                        s += "1";
                else:
                        s += "0";
        return s;


class MHSLine:
        """
This class represents a single line of a mhs file
fields: self.type   : the first word on the line (eg. PARAMETER, PORT,...)
        self.content: list containing key/value pairs
"""
        
        def __init__(self, line, line_num = 0):
                s = line.split()
                self.type = s[0]
                
                s = " ".join(s[1:])
                s = s.split(",")
                
                self.content = []
                
                self.line_num = line_num
                
                for x in s:
                        y = map(lambda x: x.strip(), x.split("="))
                        if not len(y) == 2:
                                raise "parse error at line %i" % line_num
                        self.content.append((y[0],y[1]))
                        
        def __str__(self):
                s = self.type + " " + self.content[0][0] + " = " + str(self.content[0][1])
                for k in self.content[1:]:
                        s += ", " + k[0] + " = " + k[1]
                return s
        

class MHSPCore:
        """
This class represents a pcore instance
fields: self.ip_name
        self.instance_name
        self.content       : list of lines 
"""
        def __init__(self,ip_name):
                self.ip_name = ip_name
                self.content = []
                
        def addLine(self,line):
                if line.type == "PARAMETER" and line.content[0][0] == "INSTANCE":
                        self.instance_name = line.content[0][1]
                        return
                self.content.append(line)
                
        def getValue(self,key):
                for line in self.content:
                        if line.content[0][0].lower() == key.lower():   # MHS files are case insensitive
                                return line.content[0][1]
                return None
                                
        def setValue(self,key,value):
                for line in self.content:
                        if line.content[0][0] == key:
                                line.content[0] = (line.content[0][0],value)

        def addEntry(self,name,key,value):
                self.addLine(MHSLine(name + " " + key + " = " + str(value)))
                                
        def __str__(self):
                result = "BEGIN " + self.ip_name + "\n"
                result += "\tPARAMETER INSTANCE = " + self.instance_name + "\n"
                for k in self.content:
                        result += "\t" + str(k) + "\n"
                result += "END\n"
                return result
                
class MHS:
        """
This class represents a mhs file.
fields: self.pcores   : list of MHSPCore objects
        self.toplevel : list of MHSLine objects
"""
        def __init__(self, filename = None):
                self.pcores = []
                self.toplevel = [MHSLine("PARAMETER VERSION = 2.1.0",0)]
                if filename:
                        self.parse(filename)
                
        def isComment(self,line_trimmed):
                return line_trimmed[0] == '#'
                
        def addPCore(self,pcore):
                self.pcores.append(pcore)
                
        def parse(self,filename):
                STATE_TOPLEVEL = 0
                STATE_PCORE = 1
                
                state = STATE_TOPLEVEL
                line_count = 0
                
                fin = open(filename,"r")
                
                self.pcores = []
                self.toplevel = []
                
                pcore = None
                
                while True:
                        line_count += 1
                        line = fin.readline()
                        if not line:
                                if state == STATE_PCORE:
                                        raise "unexpected end of file: '%s' at line %i" % (filename,line_count)
                                break
                                        
                        line = line.strip()
                        
                        if not line: continue
                        
                        if self.isComment(line): continue
                        
                        s = line.split()
                        name = s[0]
                        s = " ".join(s[1:])
                        
                        if state == STATE_TOPLEVEL:
                                if name == "BEGIN":
                                        state = STATE_PCORE
                                        pcore = MHSPCore(s)
                                        continue
                                else:
                                        self.toplevel.append(MHSLine(line,line_count))
                                        continue
                        else:
                                if name == "END":
                                        state = STATE_TOPLEVEL
                                        self.pcores.append(pcore)
                                        continue
                                else:
                                        pcore.addLine(MHSLine(line,line_count))
                                        continue
                                        
        def __str__(self):
                result = ""
                for k in self.toplevel:
                        result += str(k) + "\n"
                                
                for pcore in self.pcores:
                        result += "\n" + str(pcore)
                        
                return result
                        
        def getPCores(self,ip_name):
                result = []
                for pcore in self.pcores:
                        if pcore.ip_name == ip_name:
                                result.append(pcore)
                return result
                
        def getPCore(self,instance_name):
                for pcore in self.pcores:
                        if pcore.instance_name == instance_name:
                                return pcore
                return None
                
        def delPCore(self, instance_name):
                pcore = self.getPcore(instance_name)
                self.pcores.remove(pcore)


