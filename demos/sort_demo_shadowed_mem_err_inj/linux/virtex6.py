#!/usr/bin/python


virtex6Layout = [(1,"IO"),(4, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (8, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (4, "CLB"), (1, "IO"), (10, "CLB"), (1, "MMCM"),
 (4, "CLB"), (1, "IO"), (4, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (8, "CLB"), (1, "BRAM"), (2, "CLB"), (1, "DSP"), (4, "CLB"), (1, "DSP"), (2, "CLB"), (1, "BRAM"), (7, "CLB"), (1, "BRAM"), (1, "GTX")]

maxMinorPerType = {"IO": 44,"CLB":36,"DSP":28,"BRAM":28,"MMCM":38,"GTX":32}

WordsPerMinor = 81
RowsPerFPGA = 6

BIT_COUNT=32
WORD_COUNT=128
MINOR_COUNT=128
COLUMN_COUNT=256
ROW_COUNT=32
HALF_COUNT=2
TYPE_COUNT=4
ADDRESS_MAX_VALUES = [TYPE_COUNT-1, HALF_COUNT-1, ROW_COUNT-1, COLUMN_COUNT-1, MINOR_COUNT-1, WORD_COUNT-1, BIT_COUNT-1]

