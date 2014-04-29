#!/bin/sh

# runme_small_hybrid.sh
# 
# shell script to run various rawcaudio_hybrid and rawdaudio_hybrid configurations
# with small input
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

./bin/rawcaudio < data/small.pcm > encoder_output/output_small.adpcm 2> encoder_output/small_encode.log
./bin/rawdaudio < data/small.adpcm > decoder_output/output_small.pcm 2> decoder_output/small_decode.log

#hybrid adpcm encoder
./bin/rawcaudio_hybrid < data/small.pcm > encoder_output/output_small_hybrid_normal.adpcm 2>> encoder_output/small_encode.log
./bin/rawcaudio_hybrid 1 0 < data/small.pcm > encoder_output/output_small_hybrid_1swt.apdcm 2>> encoder_output/small_encode.log
./bin/rawcaudio_hybrid 0 1 < data/small.pcm > encoder_output/output_small_hybrid_1hwt.apdcm 2>> encoder_output/small_encode.log

#hybrid adpcm decoder
./bin/rawdaudio_hybrid < data/small.adpcm > decoder_output/output_small_hybrid_normal.pcm 2>> decoder_output/small_decode.log
./bin/rawdaudio_hybrid 1 0 < data/small.adpcm > decoder_output/output_small_hybrid_1swt.pcm 2>> decoder_output/small_decode.log
./bin/rawdaudio_hybrid 0 1 < data/small.adpcm > decoder_output/output_small_hybrid_1hwt.pcm 2>> decoder_output/small_decode.log
