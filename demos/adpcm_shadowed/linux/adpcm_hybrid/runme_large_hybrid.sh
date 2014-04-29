#!/bin/sh

# runme_large_hybrid.sh
# 
# shell script to run various rawcaudio_hybrid and rawdaudio_hybrid configurations
# with large input
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

./bin/rawcaudio < data/large.pcm > encoder_output/output_large.adpcm 2> encoder_output/large_encode.log
./bin/rawdaudio < data/large.adpcm > decoder_output/output_large.pcm 2> decoder_output/large_decode.log

#hybrid adpcm encoder
./bin/rawcaudio_hybrid < data/large.pcm > encoder_output/output_large_hybrid_normal.adpcm 2>> encoder_output/large_encode.log
./bin/rawcaudio_hybrid 1 0 < data/large.pcm > encoder_output/output_large_hybrid_1swt.adpcm 2>> encoder_output/large_encode.log
./bin/rawcaudio_hybrid 0 1 < data/large.pcm > encoder_output/output_large_hybrid_1hwt.adpcm 2>> encoder_output/large_encode.log

#hybrid adpcm decoder
./bin/rawdaudio_hybrid < data/large.adpcm > decoder_output/output_large_hybrid_normal.pcm 2>> decoder_output/large_decode.log
./bin/rawdaudio_hybrid 1 0 < data/large.adpcm > decoder_output/output_large_hybrid_1swt.pcm 2>> decoder_output/large_decode.log
./bin/rawdaudio_hybrid 0 1 < data/large.adpcm > decoder_output/output_large_hybrid_1hwt.pcm 2>> decoder_output/large_decode.log
