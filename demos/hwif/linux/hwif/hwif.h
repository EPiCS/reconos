/*
 * hwif.h
 *
 *  Created on: Mar 24, 2014
 *      Author: meise
 */

#ifndef HWIF_H_
#define HWIF_H_

#include <stdio.h>
#include <stdint.h>

/* -----------------------------
 * PRIVTE AREA - MOVE TO .c FILE
 * -----------------------------
 */


#define C_HWIF_BASE_ADDRESS		0x80000000Ul
#define C_HWIF_ADDRESS_SPACE_BITS 16 // How many address bits are reserved per hardware thread?
#define C_HWIF_IF_COUNT 14

/*
 * Copy of constants from hwif package:
 *
 *  constant C_ID_PERFMON  : std_logic_vector(31 downto 0) := X"DEADAFFE";
 *  constant C_ID_IDENTITY : std_logic_vector(31 downto 0) := X"DEADBEEF";
 *  constant C_CAP_PERFMON : std_logic_vector(31 downto 0) := X"00000001";
 */
#define C_ID_PERFMON 0xDEADAFFE
#define C_ID_IDENTITY 0xDEADBEEF
#define C_CAP_PERFMON 0x00000001


/* ----------------
 * Public Interface
 * ----------------
 */

void hwif_init(); // Opens device file; might build table of modules and capabilities
void hwif_close();

/*
 * Low Level API
 */

/*
 * Hmm, per module, we expect the registers to be contiguous?
 */

uint32_t hwif_read(uint32_t module_nr, uint32_t reg_nr);
void hwif_write(uint32_t module_nr, uint32_t reg_nr, uint32_t value);


/*
 * High Level API
 */
uint32_t hwif_read_id(uint32_t module_nr);
uint32_t hwif_read_cap(uint32_t module_nr);


/*
 * The following APIs should go into separate library files, to support the modularization.
 */
void hwif_perfmon_reset(uint32_t module_nr);
void hwif_perfmon_activate(uint32_t module_nr);
void hwif_perfmon_deactivate(uint32_t module_nr);
void hwif_perfmon_get_number_of_counters(uint32_t module_nr);
void hwif_perfmon_read_counter(uint32_t module_nr);


#endif /* HWIF_H_ */
