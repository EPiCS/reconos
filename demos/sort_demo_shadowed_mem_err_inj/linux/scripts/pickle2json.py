#!/usr/bin/python

import sys, json, pickle

if __name__ == "__main__":
    '''Converts fault address lists from old pickle format into newer JSON format'''
    
    if len(sys.argv) >= 2:
        addressFile = sys.argv[1]
    else:
        sys.exit(1)
    
    try:
        print("Reading JSON file...")
        addressList = pickle.load(open(addressFile, "r"))
        print("Address count in file {}: {}".format(addressFile,len(addressList)))
        print("Writing to JSON file...")
        addressFile= addressFile.replace('.pickle', '.json')
        json.dump(addressList, open(addressFile, "w"), separators=(',', ':'))
    except:
        print("Error reading file: {}".format(addressFile))
        print(sys.exc_info()[0:2])
        sys.exit()