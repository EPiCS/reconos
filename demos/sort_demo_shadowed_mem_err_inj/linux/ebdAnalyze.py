#!/usr/bin/python

import sys, pprint, png

    

layout = [(1,"IO"),(4, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (8, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (4, "CLB"), (1, "IO"), (10, "CLB"), (1, "MMCM"),
 (4, "CLB"), (1, "IO"), (4, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (8, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (7, "CLB"), (1, "BRAM"), (1, "GTX")]
maxMinorPerType = {"IO": 44,"CLB":36,"DSP":28,"BRAM":28,"MMCM":38,"GTX":32}
WordsPerMinor = 81
RowsPerFPGA = 6

def ListToHeatMap(_list, _filename):
    """Gets a linear list of error counts (one element is one word of bitstream) and 
    converts it into a bitmap, where each line is a minor of the bitstream. The generated
    image does not represent the physical layout of the FPGA, but is intended for simple data 
    overview."""
    
    
    #format of pixels is [R,G,B, R,G,B, ...]
    pixels = [ [255 for word in xrange(WordsPerMinor*3)] for height in xrange(6*44) ]
    
    # Transform list into image: 
    # One Pixel ^= Bit set per word
    # One Line ^= One minor address range consiting of 81 words
    # 128 Lines ^= 1 Column
    
    word=0
    minor=0
    for el in _list:
        if el > 0:
            pixels[minor][word*3] =  el #R
            pixels[minor][word*3+1] = 0 #G
            pixels[minor][word*3+2] = 0 #B
        word = word + 1
        if word == 81:
            word = 0
            minor = minor + 1
    print("Minor: {}, Word: {}".format(minor, word))    
        
    # determine maximum error count
    max = 0
    for x in pixels:
        for y in x:
            if y !=255 and y > max: max = y;
    print("Maximum pixel value: {}".format( max) )
    
    #scale colors in bitmap 
    for x in xrange(len(pixels)):
        for y in xrange(0,len(pixels[0]),3):
            if pixels[x][y] != 255:
                pixels[x][y]= int(pixels[x][y] * (255.0/(max+1))) 
    # write out png image
    print ("image width {}".format(WordsPerMinor*3))
    print ("image width {}".format(len(pixels[0])))
    print ("image height {}".format(len(pixels)))
    png.from_array(pixels, "RGB").save(_filename)
    #, {"height":len(pixels)+1,"width":WordsPerMinor*3}



def physAddr2y(half, row, minor):
    maxMinor = max(maxMinorPerType.values())
    maxMinor * RowsPerFPGA
    if half == 0:
        y = ((maxMinor * RowsPerFPGA)/2) - (row*maxMinor) - minor - 1
    else:
        y = ((maxMinor * RowsPerFPGA)/2) + (row*maxMinor) + minor
    return y

def physAddr2x(column, word):
    maxColumns = sum(map(lambda x: x[0], layout))
    x = (column * WordsPerMinor) + word
    return x


def faultListToHeatMapFPGA(_list, _filename):
    """Gets a linear list of essential bits. List elements are lists of length 7 which encode a physical address in the FPGA.
    This data is then converted into an image that shows the physically correct position of the essential bits on the FPGA ASIC."""
    
    # Creates a plain white image. Format of pixels is [R,G,B, R,G,B, ...]
    maxColumns = sum(map(lambda x: x[0], layout))
    maxMinor = max(maxMinorPerType.values())
    pixels = [ [255 for width in xrange(maxColumns * WordsPerMinor * 3)] for height in xrange( maxMinor * RowsPerFPGA ) ]
    
    # Transform list into image: 
    # One Pixel ^= Bit set per word
    # One Line ^= One minor address range consiting of 81 words
    # 128 Lines ^= 1 Column
    
    for el in _list:
        # el = [type, half, row, column, minor, word, bit ]
        if el[1] < 2: # ignore data in third half...
            y = physAddr2y(el[1], el[2], el[4])
            x = physAddr2x(el[3], el[5])
            if pixels[y][x*3] == 255:
                pixels[y][x*3] =  0 #R
                pixels[y][x*3+1] = 0 #G
                pixels[y][x*3+2] = 0 #B
            pixels[y][x*3] +=  1 #R
            if pixels[y][x*3] > 32:
                print("Too many bits at address: {}".format(el))
    
    # determine maximum error count
    maxPixel = 0
    for x in pixels:
        for y in x:
            if y !=255 and y > maxPixel: maxPixel = y;
    print("Maximum pixel value: {}".format( maxPixel) )
    
    #scale colors in bitmap 
    for x in xrange(len(pixels)):
        for y in xrange(0,len(pixels[0]),3):
            if pixels[x][y] != 255:
                pixels[x][y]= int(pixels[x][y] * (255.0/(maxPixel+1))) 
    # write out png image
    print ("image width {}".format(len(pixels[0])))
    print ("image height {}".format(len(pixels)))
    return pixels
    

def countOnes(_line):
    count=0
    for char in _line:
        if char =="1": count = count + 1
    return count


# Configuration bitstream structure is complex and so is the ebd structure.
# Since we only want essential bits in CLBs, we skip over I/O, DSP and BRAM frames
# 
# Structutal data:
# 81 words per minor
# 21+4 minors intro
#
# 40+4 minors for I/Os
# 32+4 minors for CLBs
# 24+4 minors for DSPs
# 24+4 minors for BRAMs
# 34+4 minors for MMCMs
# 28+4 minors for GTX Tranceivers
#
# Pattern per row (exceptions apply!!!) :
# 1 IO, 4 CLB, 1 BRAM, 2 CLB, 1 DSP, 4 CLB, 1 DSP, 2 CLB, 1 BRAM, 8 CLB, 1 BRAM, 2 CLB, 1 DSP, 4 CLB, 1 DSP, 2 CLB, 1 BRAM, 4 CLB, 1 IO, 10 CLB, 1 MMCM,
# 4 CLB, 1 IO, 4 CLB, 1 BRAM, 2 CLB, 1 DSP, 4 CLB, 1 DSP, 2 CLB, 1 BRAM, 8 CLB, 1 BRAM, 2 CLB, 1 DSP, 4 CLB, 1 DSP, 2 CLB, 1 BRAM, 7 CLB, 1 BRAM, 1 GTX
#
# 81 CLB columns per row

def fileToFaultList(_file):
    
    addrType = 0
    addrHalf = 0
    addrRow  = 0
    addrColumn = 0
    addrMinor = 0
    addrWord = 0
    
    layoutIdx = 0
    
    faultList = []
    lineNr = 0
    for word in file:
        if lineNr > 7+ 25*WordsPerMinor: #skip header and unassignable minors
            for bit, bitIdx in zip(word, xrange(len(word)) ):
                if bit == "1":
                    
                    faultList.append([addrType, addrHalf, addrRow, addrColumn, addrMinor, addrWord, bitIdx] )
            # Address handling
            addrWord = addrWord +1 # 0..80 
            if addrWord == 81:
                addrWord = 0
                addrMinor = addrMinor + 1
                if addrMinor == maxMinorPerType[layout[layoutIdx][1]]:
                    addrMinor = 0
                    addrColumn = addrColumn + 1
                    if addrColumn >= sum(map(lambda x: x[0], layout[:layoutIdx+1])):
                        #print("{}/{}".format(addrColumn, sum(map(lambda x: x[0], layout[:layoutIdx])) ))
                        layoutIdx = layoutIdx + 1
                        
                    if addrColumn == sum(map(lambda x: x[0], layout)):
                        layoutIdx = 0
                        addrColumn = 0
                        addrRow = addrRow + 1
                        if addrRow == 3:
                            addrRow = 0
                            addrHalf = addrHalf + 1
                        #print("Half/Row {}/{}".format(addrHalf,addrRow))
        lineNr = lineNr + 1
    
    return faultList
        

def extractColumn(_addr, _imageFPGA):
    
    addrType = _addr[0]
    addrHalf = _addr[1]
    addrRow  = _addr[2]
    addrColumn = _addr[3]
    addrMinor = _addr[4]
    addrWord = _addr[5]
    
    maxMinor = max(maxMinorPerType.values())
    
    xStart = physAddr2x(addrColumn, 0) 
    xEnd =   physAddr2x(addrColumn, WordsPerMinor-1)
    
    yStart = physAddr2y(addrHalf, addrRow  , maxMinor-1)
    yEnd =   physAddr2y(addrHalf, addrRow, 0)
    if addrHalf == 1:
        temp = yStart;
        yStart = yEnd
        yEnd = temp

    list = _imageFPGA[yStart:yEnd+1]
    list = [ x[xStart*3:xEnd*3+3] for x in list ]
    print("FPGA image height: {}, width: {}".format( len(_imageFPGA), len(_imageFPGA[0]) ))
    print(yStart, yEnd, xStart, xEnd)
    print(list)
    print("Column image height: {}, width: {}".format( len(list), len(list[0]) ))
    return list

if __name__ == '__main__':
    
    # open file from commandline
    print("Opening file {}...".format(sys.argv[1]))
    try:
        file = open(sys.argv[1])
    except IOError as e:
        print(e)
        sys.exit(1)
        
    # Parse file and create visualization
    if False:
        bitsSetPerWord = []
        lineNr = 0
        for line in file:
            if lineNr > 7: #skip header
                bitsSetPerWord.append(countOnes(line))
            lineNr = lineNr + 1
            
        ListToHeatMap(bitsSetPerWord, "ebdHeatmap.png")
    
    # Parse file and emit list of fault injection addresses
    # Input file is just stream of ASCII '0's and '1's; 
    # Output ist list in the format "<Type>, <Half>, <Row>, <Column>, <Minor>, <Word>, <Bit>" 
    print("Parsing faults from {}...".format(sys.argv[1]))
    file.seek(0)
    faultList = fileToFaultList(file)
    print("Length of faultList: {}".format(len(faultList)))
    
    imageFPGApath = "ebdHeatmapFPGA.png"
    print("Creating image ...")
    imageFPGA = faultListToHeatMapFPGA(faultList, imageFPGApath)
    print("Saving image to {}...".format(imageFPGApath))
    png.from_array(imageFPGA, "RGB").save(imageFPGApath)
    
    imageColumnPath = "ebdHeatmapColumnHWT0_0.png"
    imageColumn= extractColumn([0,0,2,17,0,0,0], imageFPGA)
    print("Saving image to {}...".format(imageColumnPath))
    png.from_array(imageColumn, "RGB").save(imageColumnPath)
    
    imageColumnPath = "ebdHeatmapColumnHWT1_0.png"
    imageColumn= extractColumn([0,0,1,17,0,0,0], imageFPGA)
    print("Saving image to {}...".format(imageColumnPath))
    png.from_array(imageColumn, "RGB").save(imageColumnPath)
    #print(faultList)
    #hwt0FaultList = filter(lambda x: x[1]==0 and x[2]==2 and x[3]==17 , faultList)
    #print("Length of hwt0FaultList: {}".format(len(hwt0FaultList)))