#!/usr/bin/python

import multiprocessing
import multiprocessing.managers
import os.path

class InternalLockManager(multiprocessing.managers.BaseManager):
    pass

class LockManager:
    mode = "uninitialized"
    
    def get_lock(self):
        return self.mplock

    def __init__(self, _filename):
        self.mplock = multiprocessing.Lock()
        
        InternalLockManager.register("lock", self.get_lock, exposed=[ '__str__', 'acquire', 'release'])
        
        self.manager = InternalLockManager(address=(_filename), authkey='')
        
        if os.path.exists(_filename):
            # if file exists, server is already running, so we are client!
            print("We are lock client!")
            self.mode="client"
            self.manager.connect()
        else:
            print("We are lock server!")
            self.mode="server"
            self.manager.start()
        #get proxy
        self.lock =  self.manager.lock()
        
    def acquire(self):
        self.lock.acquire()
        
    def release(self):
        self.lock.release()
    
    def shutdown(self):
        if self.mode == "server":
            self.manager.shutdown()
        

if __name__ == '__main__':
    print("This is a library. Include in other python script for usage!")