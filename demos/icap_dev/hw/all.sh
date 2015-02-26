#!/bin/bash

cd edk
./generate_netlist.sh
cd ..

cd pr_design/
./gen_bitfile.sh
