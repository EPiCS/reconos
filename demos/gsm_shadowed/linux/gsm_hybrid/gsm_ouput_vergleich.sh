#!/bin/sh

echo "##########SMALL##########"
for file in *small*.decode.run 
do
	echo cmp output_small.decode.run $file
	cmp output_small.decode.run $file
done

#for file in *small*.encode.gsm
#do
#	echo cmp output_small.encode.gsm $file
#	cmp output_small.encode.gsm $file
#done

echo "##########LARGE##########"
for file in *large*.decode.run 
do
	echo cmp output_large.decode.run $file
	cmp output_large.decode.run $file
done

#for file in *large*.encode.gsm
#do
#	echo cmp output_large.encode.gsm $file
#	cmp output_large.encode.gsm $file
#done
