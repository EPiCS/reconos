#!/usr/bin/python

import sys, re, string, pexpect, subprocess, getpass, time, datetime, os, json , serial
import multiprocessing
import multiprocessing.managers
import os.path
from time import sleep
from multiprocessing.managers import BaseManager




class ml605Reset:
    serialDevice = "/dev/ttyACM0"
    serialSpeed = 9600

    def __init__(self, _method="serial"):
        self.lock = multiprocessing.Lock()
        if _method == "serial":
            self.serial = serial.Serial(self.serialDevice, self.serialSpeed, timeout=1)
            self.reset = self.resetSerial
        elif _method == "sispmctl":
            # nothing to initialize for sispmctl
            self.reset = self.resetSispmctl 
        
    def resetSerial(self, _boardNr):
        # boardNr: 0->'A', 1->'B', ...
        char = chr(_boardNr + ord('A'))
        
        self.lock.acquire()
        # Reset is active low. Lower case char switches reset channel to zero level,
        # upper case char switches reset channel to high level.
        self.serial.write(char.lower())
        sleep(1)
        self.serial.write(char.upper())
        sleep(1)
        self.lock.release()

    def resetSispmctl(self, _boardNr):
        self.lock.acquire()
        FNULL = open(os.devnull, 'w')
        #switch socket off
        subprocess.call(["sispmctl","-f", str(_boardNr+1)], stdout=FNULL, stderr=subprocess.STDOUT)
        sleep(1)
        #switch socket on
        subprocess.call(["sispmctl","-o", str(_boardNr+1)], stdout=FNULL, stderr=subprocess.STDOUT)
        sleep(1)
        self.lock.release()


class InternalMl605ResetManager(multiprocessing.managers.BaseManager):
    pass

class ml605ResetManager:
    mode = "uninitialized"

    def __init__(self, _lockFilename,_resetMethod="serial"):
        
        InternalMl605ResetManager.register("ml605Reset", ml605Reset)
                      # exposed=[ '__str__', 'acquire', 'release'])
        
        self.manager = InternalMl605ResetManager(address=(_lockFilename), authkey='')
        
        if os.path.exists(_lockFilename):
            # if file exists, server is already running, so we are client!
            print("We are reset client!")
            self.mode="client"
            self.manager.connect()
        else:
            print("We are reset server!")
            self.mode="server"
            self.manager.start()
        #get proxy
        self.ml605Reset =  self.manager.ml605Reset(_resetMethod)
        
    def reset(self, _boardNr):
        self.ml605Reset.reset(_boardNr)
        
    
    def shutdown(self):
        if self.mode == "server":
            self.manager.shutdown()


if __name__ == "__main__":
    #with open("/dev/ttyACM0" , 'w') as f:
    ml605 = ml605ResetManager("/tmp/sh_mem_err_inj_reset", "sispmctl");
    
    while True:
        print("a reset")
        ml605.reset(0)
        
        print("b reset")
        ml605.reset(1)
        