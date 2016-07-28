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

    def __init__(self):
        self.serial = serial.Serial(self.serialDevice, self.serialSpeed, timeout=1)
        self.lock = multiprocessing.Lock()
        
    def reset(self, _boardNr):
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

class InternalMl605ResetManager(multiprocessing.managers.BaseManager):
    pass

class ml605ResetManager:
    mode = "uninitialized"

    def __init__(self, _lockFilename,):
        
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
        self.ml605Reset =  self.manager.ml605Reset()
        
    def reset(self, _boardNr):
        self.ml605Reset.reset(_boardNr)
        
    
    def shutdown(self):
        if self.mode == "server":
            self.manager.shutdown()


if __name__ == "__main__":
    #with open("/dev/ttyACM0" , 'w') as f:
    ml605 = ml605ResetManager("/tmp/sh_mem_err_inj_reset");
    
    while True:
        print("a reset")
        ml605.reset(0)
        
        print("b reset")
        ml605.reset(1)
        