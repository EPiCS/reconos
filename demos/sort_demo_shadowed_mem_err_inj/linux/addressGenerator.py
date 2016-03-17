#!/usr/bin/python

import sys, pprint, png, pickle

BIT_COUNT=32
WORD_COUNT=128
MINOR_COUNT=128
COLUMN_COUNT=256
ROW_COUNT=32
HALF_COUNT=2
TYPE_COUNT=4
ADDRESS_MAX_VALUES = [TYPE_COUNT-1, HALF_COUNT-1, ROW_COUNT-1, COLUMN_COUNT-1, MINOR_COUNT-1, WORD_COUNT-1, BIT_COUNT-1]


def parse_string_to_address(_string, _fallback_value):
    list = _string.split(',');
    if len(list) != 7:
        return _fallback_value
    try:
        return [int(x) for x in list]
    except:
        return _fallback_value

def incAddress(_address):
    """ address = [type, half, row, column, minor, word, bit] """
    carry = False
    for idx in reversed( xrange( len(_address) ) ):
        if _address[idx] == ADDRESS_MAX_VALUES[idx]:
            _address[idx] = 0;
            carry = True;
        else:
            _address[idx] += 1
            break
    return _address[:]

def cmpAddress(_address_a, _address_b):
    """Returns -1 if a<b , 0 if a==b and 1 if a>b"""
    for a,b in zip(_address_a, _address_b ):
        if a < b: return -1
        elif a > b: return 1
    return 0

def addressGeneratorColumn(_startAddress):
    currentAddress= _startAddress
    while(currentAddress[-3:] != [127,127,31]):
        yield currentAddress

def genAddresses(_startAddress):
    addressList = []
    currentAddress = _startAddress
    while currentAddress[-3:] != [127,127,31]:
        addressList.append(incAddress(currentAddress))
        
    addressList.append(currentAddress) # add last address of column to list
    return addressList

def saveAddresses(_addressList, _filename):
    pickle.dump(_addressList, open(_filename, "w"))

if __name__ == '__main__':
    ''' Address generator for fault injection tests. Given a start address and a file name it will generate a pickle file with addresses until the end of the column.
    '''
    
    start_address=[0,0,2,17,0,0,0]
    
    if len(sys.argv) >= 2:
        start_address = parse_string_to_address(sys.argv[1], start_address)
        filename = sys.argv[2]
    else:
        print("Too few arguments!")
        print("Syntax: "+ sys.argv[0] +" <startAddress> <filename>")
    
    addressList = genAddresses(start_address)
    print(addressList[0:10])
    print("Generated {} addresses.".format(len(addressList)))
    
    firstHalf  = addressList[:len(addressList)/2]
    secondHalf = addressList[len(addressList)/2:]
    print("First half: {},  second half {}.".format(len(firstHalf), len(secondHalf)) )
    saveAddresses(firstHalf, filename+"_1")
    saveAddresses(secondHalf, filename+"_2")
    
    
    
