#!/bin/bash

OUTFILE="error.log"
REPETITIONS=100000

#Empty output file
echo "" > $OUTFILE

for ((i=0; $i<$REPETITIONS; i=$i+1)); 
do 
	./sort_demo_shadowed 0 1 1 1 1 $i
	echo $? >> $OUTFILE.1; 
done

echo "" >> $OUTFILE


for ((i=0; $i<$REPETITIONS; i=$i+1)); 
do 
        ./sort_demo_shadowed 0 1 1 2 1 $i
        echo $? >> $OUTFILE.2; 
done

echo "" >> $OUTFILE

for ((i=0; $i<$REPETITIONS; i=$i+1)); 
do 
        ./sort_demo_shadowed 0 1 1 1 10 $i
        echo $? >> $OUTFILE.3; 
done

echo "" >> $OUTFILE

for ((i=0; $i<$REPETITIONS; i=$i+1)); 
do 
        ./sort_demo_shadowed 0 1 1 2 10 $i
        echo $? >> $OUTFILE.4; 
done

echo "" >> $OUTFILE

