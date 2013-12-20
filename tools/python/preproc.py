#!/usr/bin/env python
# coding: utf8

#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS
#   author:       Christoph Rüthing, University of Paderborn
#   description:  A simple preprocessor which handles "GENERATE LOOP"
# 
# ======================================================================

import sys

def generate_loop(filename, num_hwts):
	STATE_COPY = 0
	STATE_LOOP = 1

	fin = open(filename, "r")
	state = STATE_COPY

	while True:
		line = fin.readline()

		if not line:
			break;

		if "END GENERATE LOOP" in line:
			state = STATE_COPY

		if state == STATE_COPY:
			sys.stdout.write(line)
		else:
			for i in range(num_hwts):
				loopline = line.replace("#i#", str(i))
				sys.stdout.write(loopline)

		if "BEGIN GENERATE LOOP" in line:
			state = STATE_LOOP


	fin.close();

generate_loop(sys.argv[1], int(sys.argv[2]))
