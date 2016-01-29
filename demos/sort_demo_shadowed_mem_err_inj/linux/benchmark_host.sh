#!/bin/sh

# This is an automatically generated benchmark script.
# Do not modify this by hand. Modify the generator genBenchmark.py

if [ -n "$1" ]; then 
    STARTIDX=$1;
else
    STARTIDX=0;
    echo "" >bench.txt
fi

echo "First run with unmodified sort_demo..."
if [ $STARTIDX -le 0 ]; then 
echo -n " 0 ./sort_demo  --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 1 ]; then 
echo -n " 1 ./sort_demo  --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 2 ]; then 
echo -n " 2 ./sort_demo  --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 3 ]; then 
echo -n " 3 ./sort_demo  --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 4 ]; then 
echo -n " 4 ./sort_demo  --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 5 ]; then 
echo -n " 5 ./sort_demo  --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 6 ]; then 
echo -n " 6 ./sort_demo  --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 7 ]; then 
echo -n " 7 ./sort_demo  --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo  --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

echo
echo "Second run with sort_demo_shadowed (shadowing off)..."
if [ $STARTIDX -le 8 ]; then 
echo -n " 8 ./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 9 ]; then 
echo -n " 9 ./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 10 ]; then 
echo -n " 10 ./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 11 ]; then 
echo -n " 11 ./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 12 ]; then 
echo -n " 12 ./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 13 ]; then 
echo -n " 13 ./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 14 ]; then 
echo -n " 14 ./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 15 ]; then 
echo -n " 15 ./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

echo
echo "Third run with sort_demo_shadowed (shadowing_on, all shadows active)..."
if [ $STARTIDX -le 16 ]; then 
echo -n " 16 ./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 17 ]; then 
echo -n " 17 ./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 18 ]; then 
echo -n " 18 ./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 19 ]; then 
echo -n " 19 ./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 20 ]; then 
echo -n " 20 ./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 21 ]; then 
echo -n " 21 ./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 22 ]; then 
echo -n " 22 ./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 23 ]; then 
echo -n " 23 ./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

echo
echo "Fourth run with sort_demo_shadowed (shadowing_on, round-robin with 1 shadow)..."
if [ $STARTIDX -le 24 ]; then 
echo -n " 24 ./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 25 ]; then 
echo -n " 25 ./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 26 ]; then 
echo -n " 26 ./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 27 ]; then 
echo -n " 27 ./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 28 ]; then 
echo -n " 28 ./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 29 ]; then 
echo -n " 29 ./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 30 ]; then 
echo -n " 30 ./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 31 ]; then 
echo -n " 31 ./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

echo
echo "Fifth run with sort_demo_shadowed (shadowing_on, all shadows, transmodal)..."
if [ $STARTIDX -le 32 ]; then 
echo -n " 32 ./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 33 ]; then 
echo -n " 33 ./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 34 ]; then 
echo -n " 34 ./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 35 ]; then 
echo -n " 35 ./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 36 ]; then 
echo -n " 36 ./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 37 ]; then 
echo -n " 37 ./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 38 ]; then 
echo -n " 38 ./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 39 ]; then 
echo -n " 39 ./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

echo
echo "Sixth run with sort_demo_shadowed (shadowing_on, round-robin with 1 shadow, transmodal)..."
if [ $STARTIDX -le 40 ]; then 
echo -n " 40 ./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 0 --swt 1 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 41 ]; then 
echo -n " 41 ./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 1 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 42 ]; then 
echo -n " 42 ./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 2 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 43 ]; then 
echo -n " 43 ./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 3 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 44 ]; then 
echo -n " 44 ./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 4 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 45 ]; then 
echo -n " 45 ./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 5 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 46 ]; then 
echo -n " 46 ./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 6 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

if [ $STARTIDX -le 47 ]; then 
echo -n " 47 ./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
"
./sort_demo_shadowed --hwt 7 --swt 0 --blocks 64 --thread-interface 2 >> bench.txt
echo -e "\n##############################################\n" >> bench.txt
fi

echo
