#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <math.h>

#include <arpa/inet.h>

// ReconOS
#include "reconos.h"
#include "mbox.h"

#include "icap_demo.h"


//------------------------------------------------------------------------------
// preload bitstream and save it in memory
// Returns 1 if successfull, 0 otherwise
//------------------------------------------------------------------------------
int bitstream_open(const char* path, struct pr_bitstream_t* stream)
{
  int retval = 0;

  int fd = open(path, O_RDONLY);
  if(fd == -1) {
    printf("bitstream_open: Could not open file %s\n", path);

    goto FAIL;
  }

  // determine file size
  stream->length = lseek(fd, 0L, SEEK_END);
  if(stream->length == -1) {
    printf("bitstream_open: Could not determine file size\n");
    goto FAIL;
  }

  lseek(fd, 0L, SEEK_SET);

  if((stream->length & 0x3) != 0) {
    printf("bitstream_open: File size is not a multiple of 4 bytes\n");

    goto FAIL;
  }

  // convert file size from bytes to 32 bit words
  stream->length = stream->length / 4;

  // allocate memory for file
  stream->block = (uint32_t*)malloc(stream->length * sizeof(uint32_t));
  if(stream->block == NULL) {
    printf("bitstream_open: Could not allocate memory\n");

    goto FAIL;
  }

  // read whole file in one command
  if( read(fd, stream->block, sizeof(uint32_t) * stream->length) != (stream->length * sizeof(uint32_t))) {
    printf("bitstream_open: Something went wrong while reading from file\n");

    free(stream->block);

    goto FAIL;
  }

  // check if we can find the synchronization sequence, this is usally in the first few words
  // if we can't find it in the first 20 words, there probably is no synchronization sequence
  unsigned int i;
  for(i = 0; i < 20; i++) {
    if( stream->block[i] == 0xAA995566 ) {
      // we have found the synchronization sequence
      retval = 1;

      // flush the cache to ensure that valid data lies in the main memory
      reconos_cache_flush();
      break;
    }
  }
  
  // free the already loaded bitstream, it seems to be invalid
  if(retval == 0) {
    printf("bitstream_open: Bitstream seems to be invalid, no synchronization sequence found!\n");
    free(stream->block);
  }

FAIL:
  close(fd);

  return retval;
}


//------------------------------------------------------------------------------
// Free allocated memory
//------------------------------------------------------------------------------
void bitstream_close(struct pr_bitstream_t* stream)
{
  free(stream->block);
}



#define MAX_PR_FRAMES 64

//------------------------------------------------------------------------------
// Capture the current state of the FPGA. The original partial bitstream which
// was used to program the FPGA must be given here as the necessary information
// for capturing is extracted from it.
// All information needed for state capturing is then stored inside stream_out
// The function bitstream_capture_exec can then be used to actually capture the
// current state
//------------------------------------------------------------------------------
int bitstream_capture_prepare(struct pr_bitstream_t* stream_in, struct pr_capture_t* stream_out)
{
  // copy input stream as we override it with the current values in the FPGA
  stream_out->length = stream_in->length;
  stream_out->block = (uint32_t*)malloc(stream_out->length * sizeof(uint32_t));
  memcpy(stream_out->block, stream_in->block, stream_out->length * sizeof(uint32_t));

  if(stream_out->block == NULL) {
    printf("bitstream_capture_prepare: Could not allocate memory\n");
    return 0;
  }

  unsigned int numFrames = 0;
  struct pr_frame_t arrFrames[MAX_PR_FRAMES];

  //----------------------------------------------------------------------------
  // parse bitstream
  //----------------------------------------------------------------------------
  uint8_t synced = 0; 
  uint32_t lastFar = 0xAABBCCDD;

  // overwrite CRC checks as they will fail anyway after capturing the new values
  unsigned int i;
  for(i = 0; i < stream_in->length; i++) {
    uint32_t word = htonl(stream_in->block[i]);

    if(!synced) {
      if(word == 0xAA995566)
        synced = 1;
    } else {
      // we are synchronized, now real commands follow
      uint8_t header = word >> 29;
      uint8_t opcode = (word >> 27) & 0x3;

      if(header == 0x1) {
        // type 1 packet

        if(opcode == 0) {
          // NOOP
        } else if(opcode == 2) {
          // write
          uint8_t regaddr = (word >> 13) & 0x1F;
          unsigned int packet_counter = word & (0x7FF);

          // decode register
          switch(regaddr) {
            case 0: // CRC
              // replace CRC command with NOOP as we are not doing CRC calculations
              stream_out->block[i] = htonl(0x20000000);

              if(packet_counter != 1 || (i + 1) >= stream_out->length) {
                printf("bitstream_capture: Bitstream seems to be invalid!\n");
                return 0;
              }

              stream_out->block[i + 1] = htonl(0x20000000);
              i++;
              break;

            case 1: // FAR
              if(packet_counter != 1 || (i + 1) >= stream_out->length) {
                printf("Bitstream seems to be invalid!\n");
                return 0;
              }

              lastFar = htonl(stream_in->block[i + 1]);
              i++;
              break;

            case 2: // FDRI
              if(packet_counter != 0 || (i + 1) >= stream_out->length) {
                printf("Bitstream seems to be invalid!\n");
                return 0;
              }

              word = htonl(stream_in->block[i + 1]);
              header = word >> 29;
              packet_counter = word & (0x7FFFFFF);

              if( header != 0x2 || (i + 1 + packet_counter) >= stream_out->length) {
                printf("Bitstream seems to be invalid!\n");
                return 0;
              }

              if(numFrames >= MAX_PR_FRAMES) {
                printf("Bitstream contains too many frames, a maximum of %d frames are supported\n", MAX_PR_FRAMES);
                return 0;
              }

              arrFrames[numFrames].far = lastFar;
              arrFrames[numFrames].offset = i + 2;
              arrFrames[numFrames].words = packet_counter;
              numFrames++;

              i += packet_counter + 1;
              break;

            case 4: // CMD
              if(packet_counter != 1 || (i + 1) >= stream_out->length) {
                printf("Bitstream seems to be invalid!\n");
                return 0;
              }

              word = htonl(stream_in->block[i + 1]);

              // desync received
              if(word == 13)
                synced = 0;

              i++;
              break;

            default:
              break;
          }
        }
      } else if(header == 0x2) {
        // type 2 packet
      }
    }
  }

  if(numFrames == 0) {
    printf("Did not find any configuration frames in the bitstream\n");
    return 0;
  }

  stream_out->frames = (struct pr_frame_t*) malloc( numFrames * sizeof(struct pr_frame_t));
  memcpy(stream_out->frames, arrFrames, numFrames * sizeof(struct pr_frame_t));

  stream_out->nFrames = numFrames;

  return 1;
}


int bitstream_capture_exec(struct pr_capture_t* stream)
{
  if(stream->nFrames == 0) {
    printf("bitstream_capture_exec: Did not find any reconfiguration frames in the bitstream\n");
    return 0;
  }

  //----------------------------------------------------------------------------
  // write CFG_CLB to FPGA
  //----------------------------------------------------------------------------

  // first check if we have a CFG_CLB section, should be the first one in the blocks array
  if(stream->frames[0].far != 0x00400000) {
    printf("Did not find CFG_CLB block in bitstream\n");
    return 0;
  }

  hw_icap_write_frame(stream->frames[0].far, stream->block + stream->frames[0].offset, stream->frames[0].words);

  //----------------------------------------------------------------------------
  // readback of data, also doing gcapture in the process
  //----------------------------------------------------------------------------

  hw_icap_read_capture(stream->frames + 1, stream->nFrames - 1, stream->block);

  // try to set bit 0x00020000 to zero in block ram regions, where needed
  // Don't know if this is correct, this is just guessing based on the observation
  // that when this bit is set, new ram content is not accepted
  unsigned int i;
  for(i = 1; i < stream->nFrames; i++) {
    if((stream->frames[i].far & 0xFFE00000) != 0x00200000)
      continue; // not a block RAM

    // printf("FAR 0x%08X points to RAM region, trying to clean it up\n", readFrames[i].far);
    uint32_t* mem = stream->block + stream->frames[i].offset;

    unsigned int k, j;
    for(k = 0;; k++) {
      j = 4 + k * 10 + ((k+4) / 8);
      if(j >= stream->frames[i].words)
        break;

      mem[j] &= ~0x00020000;
    }
  }

  return 1;
}

//------------------------------------------------------------------------------
// Save a given bitstream to the file system
//------------------------------------------------------------------------------
int bitstream_save(const char* path, struct pr_bitstream_t* stream)
{
  int retval = 0;

  int fd = open(path, O_CREAT|O_WRONLY|O_TRUNC);
  if(fd == -1) {
    printf("Could not open file %s\n", path);

    goto FAIL;
  }

  size_t size = stream->length * sizeof(uint32_t);
  // write whole file in one command
  if( write(fd, stream->block, size) != size) {
    printf("Something went wrong while writing to file\n");

    goto FAIL;
  }

  retval = 1;

FAIL:
  if(fd != -1)
    close(fd);

  return retval;
}

//------------------------------------------------------------------------------
// Restore a captured state. This is done by writing the bitstream to ICAP and
// then issuing a GRESTORE. GRESTORE is actually part of the bitstream, but it
// does not work so we trigger it manually afterwards.
// WARNING: As we trigger the GRESTORE after writing the bitstream to the FPGA,
// the FPGA potentially starts with the wrong state and is reset to the right
// state a few clock cycles later. This could potentially lead to a corrupted
// state (e.g.  in RAM?). To avoid this the clock in the reconfigurable region
// has to be stopped.
//------------------------------------------------------------------------------
int bitstream_restore(struct pr_capture_t* stream)
{
  hw_icap_write(stream->block, stream->length * 4);

  hw_icap_grestore();

  return 1;
}
