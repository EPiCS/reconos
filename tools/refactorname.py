#!/usr/bin/env python

'''
Created on 26.01.2012

@author: meise
'''


import sys, os, re, difflib
from os.path import isabs, split
from difflib import unified_diff

def print_help():
    print ""
    print "Used to rename a designator in file contents and names in a directory tree."
    print "Outputs a unified diff. Review this diff and apply it via 'patch -p0 < <diff_file>'."
    print "Run 'sh <path>/move.sh' after applying the patch to rename files and directories."
    print "Usage: refactorname.py <oldname> <newname> <path>"
    print ""
    sys.exit(0)

def diffFileContent(oldname, newname, filepath):
    """ This function finds all occurences of $oldname  in the file $filepath and returns a string 
        containing the unified diff to change all accurences to $newname.
        $filepath needs to be an absolute path.
    """
    # Check for absolute path
    if not isabs(filepath):
        return 0
    
    f = open(filepath, 'r')
    origlines = f.read()
    newlines  = re.sub(oldname, newname, origlines)
    diff      = unified_diff(re.split("\n",origlines), re.split("\n",newlines), filepath, filepath, lineterm = "")
    
    diff_in_strings = ""
    for line in diff:
        diff_in_strings =  diff_in_strings + line + "\n"
    return diff_in_strings
    

def diffFileName(oldname, newname, filepath):
    """ This function emits a 'mv' command to rename the original file to have the 
        desired substition incorporated. $filepath needs to be an absolute path.
    """
    
    # Check for absolute path
    if not isabs(filepath):
        return 0
    
    
    (path, filename) = split(filepath)
    newfilename = re.sub(oldname, newname, filename)
    
    if (filename == newfilename):
        return ""
    else:
        newfilepath = os.path.join(path, newfilename)
        movecommand = "+mv " + filepath + " " + newfilepath + "\n"
        return  movecommand

def refactorname(oldname, newname, path):
    """ Substitutes oldname with uname in all files and paths below $path.
        $path needs to be an absolute path.
    """
    # Check for absolute path
    if not isabs(path):
        path = os.path.join(os.getcwd(), path)
    
    # Step 1: Generate diffs for file contents
    diff = ""        
    for root, dirs, files in os.walk(path):        
        for file in files:
            diff = diff +  diffFileContent(oldname, newname, os.path.join(root,file))

    # Step 2: Add a shell script to the diff, so that it creates the file move.sh 
    #         with instructions to rename all files
    movesCount = 0
    movesCommand = ""
    movesAllCommands = ""
    for root, dirs, files in os.walk(path, topdown = False):
        for file in files:
            movesCommand = diffFileName(oldname, newname, os.path.join(root,file))
            if movesCommand != "":
                movesCount += 1
                movesAllCommands += movesCommand
        for dir in dirs:
            movesCommand = diffFileName(oldname, newname, os.path.join(root,dir))
            if movesCommand != "":
                movesCount += 1
                movesAllCommands += movesCommand
            
    movesDiffHeader = "--- {0}/move.sh ''timestamp''\n+++ {0}/move.sh ''timestamp''\n".format(path) + "@@ -0,0 +1,{0} @@\n".format(movesCount+1) + "+#!/bin/sh\n"
    movesDiff = movesDiffHeader + movesAllCommands

    return diff + movesDiff


if __name__ == "__main__":
    
    if len(sys.argv) != 4:
        print_help()
  
    print refactorname(sys.argv[1], sys.argv[2], sys.argv[3])  
    sys.exit(0)
    