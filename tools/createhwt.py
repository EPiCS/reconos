#!/usr/bin/env python

'''
Created on 31.01.2012

@author: meise
'''

import sys, os, shutil, subprocess
from refactorname import refactorname
from shutil import copytree



def print_help():
    print "This tool creates a new skeleton of a hardware thread."
    print "Usage: createhwt <name> [path]"
    print "<name>\tIs the name of the new hardware thread."
    print "[path]\tIs the optional path, where the hardware thread shall be created."
    print "\t\t\t If left empty, the current path will be used."
    sys.exit(0)

def copyTemplate(reconosPath, destPath):
    copytree(os.path.join(reconosPath, "designs/hwt_template_empty"), os.path.join(destPath,"hwt_template_empty"))

def renameTemplate(newName, path):
    
    # Get unified diff
    diff = refactorname("template_empty", newName, path)

    # Apply patch
    patchCmd = ["patch", "-ul", "--verbose","-p0"]
    p = subprocess.Popen(args= patchCmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    (output, error) = p.communicate(input=diff)
    if error:
        print output, error
    
    # QUICKFIX START ####
    # the patch program has problems with some of the *.pao files and always creates
    # a backup of the original. We don't want that file to clutter the directory,
    # so we delete it.
    backupFile = os.path.join(path,"hw/hwt_template_empty_v1_00_b/data/hwt_template_empty_v2_1_0.pao.orig")
    if os.path.isfile(backupFile): os.remove(backupFile)
    
    # QUICKFIX END   ####
        
    moveCmd = ["sh", os.path.join(path,"move.sh")]
    p = subprocess.Popen(args= moveCmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    p.wait()
    (output, error) = p.communicate()
    if error:
        print output, error
        
    
if __name__ == '__main__':
    
    if not 2 <= len(sys.argv) <= 3:
        print_help()        
    if len(sys.argv) >= 2: hwtName = sys.argv[1]
    if len(sys.argv) >= 3: destPath = sys.argv[2]
    else :  destPath = os.getcwd()
  
    reconosPath = os.environ["RECONOS"]
    if reconosPath == "":
        print "$RECONOS is not set. Can't find template directory."
        sys.exit(1)
    
    
    #print "New name of hwt: " + hwtName + " Destination Path: " + destPath
    if os.path.isdir(os.path.join(destPath, "hwt_template_empty")) or os.path.isdir(os.path.join(destPath, "hwt_" + hwtName)):
        print "Either hwt_template_empty or hwt_"+hwtName+" directory already exists. Please move or delete this directory."
        sys.exit(1)
      
    copyTemplate(reconosPath, destPath)
    renameTemplate(hwtName, os.path.join(destPath,"hwt_template_empty"))
  
    sys.exit(0)
    