#!/usr/bin/python

import sys, pprint, png, virtex6, json, os.path, random



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
        if _address[idx] == virtex6.ADDRESS_MAX_VALUES[idx]:
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
    ''' _addressList is a python list with addresses. 
    This list is written to  _filename in json format'''
    
    json.dump(_addressList, open(_filename, "w"), separators=(',', ':'))
    

def genFullColumn(_argv):
    ''' Address generator for fault injection tests. Given a start address and a file name it will generate a json file with addresses until the end of the column.
    '''
    start_address=[0,0,2,17,0,0,0]
    
    if len(_argv) >= 2:
        start_address = parse_string_to_address(_argv[0], start_address)
        filename = _argv[1]
    else:
        print("Too few arguments!")
        print("Syntax: "+ sys.argv[0] +" <startAddress> <filename>")
    
    addressList = genAddresses(start_address)
    print(addressList[0:10])
    print("Generated {} addresses.".format(len(addressList)))
    saveAddresses(addressList, filename)
    

def splitArray(a, n):
    k, m = len(a) / n, len(a) % n
    return [a[i * k + min(i, m):(i + 1) * k + min(i + 1, m)] for i in xrange(n)]

def countAddresses(_argv):
    ''' Counts the addresses in a json file.'''

    #
    # Parse command line
    #
    if len(_argv) >= 1:
        addressFile = _argv[0]
    else:
        print("Too few arguments!")
        print("Syntax: "+ sys.argv[0] +"<filename>")
        sys.exit(1)
    
    #
    # Open file
    #
    try:
        addressList = json.load(open(addressFile, "r"))
        print("Address count in file {}: {}".format(addressFile,len(addressList)))
    except:
        print("Error reading file: {}".format(addressFile))
        print(sys.exc_info()[0:2])
        sys.exit(1)

def splitAddressFile(_argv):
    ''' Given a json file with fault injection addresses, this function reads 
    it in and writes out the first half of addresses to file one and the second 
    half of addresses to file two.'''
    
    
    #
    # Parse command line
    #
    if len(_argv) >= 2:
        parts = int(_argv[0])
        addressFile = _argv[1]
    else:
        print("Too few arguments!")
        print("Syntax: "+ sys.argv[0] +"<parts> <filename>")
        sys.exit(1)
    
    #
    # Open file
    #
    try:
        addressList = json.load(open(addressFile, "r"))
        print("Address count in file {}: {}".format(addressFile,len(addressList)))
    except:
        print("Error reading file: {}".format(addressFile))
        print(sys.exc_info()[0:2])
        sys.exit(1)
    
    #
    # Split file
    #
    
    splittedAddressList = splitArray(addressList, parts)
    for al, i in zip(splittedAddressList, xrange(len(splittedAddressList))):
        print( "Part {}: {}".format( i, len(al) ) )
        base, ext = os.path.splitext(addressFile)
        base +="_{}".format(i) 
        saveAddresses(al, base+ext)
    

def shuffleAddressFile(_argv):
    ''' Given a json file with fault injection addresses, this function reads 
    it in and shuffles the order of the list and writes it out again.'''
    
    
    #
    # Parse command line
    #
    if len(_argv) >= 2:
        infile  = _argv[0]
        outfile = _argv[1]
    else:
        print("Too few arguments!")
        print("Syntax: "+ sys.argv[0] +"<infile> <outfile>")
        sys.exit(1)
    
    #
    # Open file
    #
    try:
        addressList = json.load(open(infile, "r"))
        print("Address count in file {}: {}".format(infile,len(addressList)))
    except:
        print("Error reading file: {}".format(infile))
        print(sys.exc_info()[0:2])
        sys.exit(1)
    
    #
    # Shuffle file
    
    random.shuffle(addressList)
    saveAddresses(addressList, outfile)


if __name__ == '__main__':
    help='''
    Usage:
    ./addressGenerator.py -l <infile>             # outputs number of addresses in file
    ./addressGenerator.py -g <address> <outfile>  # generate a column of addresses
    ./addressGenerator.py -s <parts> <infile>     # split a given address file
    ./addressGenerator.py -x <infile> <outfile>   # reads infile, shuffles order of addresses and writes outfile
    ./addressGenerator.py -h                      # print this help message
    '''
    
    #
    # Parse command line
    #
    if len(sys.argv) >= 2:
        option = sys.argv[1]
    else:
        print("Too few arguments!")
        print(help)
        sys.exit(1)
    
    if option == "-g":
        genFullColumn(sys.argv[2:])
    elif option == "-s":
        splitAddressFile(sys.argv[2:])
    elif option == "-l":
        countAddresses(sys.argv[2:])
    elif option == "-x":
        shuffleAddressFile(sys.argv[2:])
    elif option == "-h":
        print(help)
    else:
        print("Unknown option!")
        print(help)
    