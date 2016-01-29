#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "cmdline_xilsem_err_inj.h"
#include "xilsem_core.h"
#include "xilsem_slice2physical.h"

#define EXIT_SUCCESS 0
#define EXIT_CMD_LINE_PARSE 1
#define EXIT_MALLOC 2
#define EXIT_FAULTY_RESULT 4
#define EXIT_FAULTY_RQ_RECV 24
#define EXIT_SEGFAULT 32

typedef struct {
	slice_address_t bottom_left;
	slice_address_t top_right;
} slice_area_t;

/*
 *AREA_GROUP "pblock_hwt_sort_demo_0" RANGE=SLICE_X24Y200:SLICE_X28Y239
 *AREA_GROUP "pblock_hwt_sort_demo_1" RANGE=SLICE_X24Y160:SLICE_X28Y199;
 */
slice_area_t tuo_area = {{24,200},{28,239}};

struct gengetopt_args_info args_info;

#define PA_LIST_LENGTH 16
physical_address_t pa_list[PA_LIST_LENGTH];
/*
 * Number of Injection Sequences // Address increments at each iteration
 */
#define INJ_LOOP 1000  //1048575

/*
 *INJ_ADDR_L makes 31-0 bits of SEM IP injection_data bus
 *INJ_ADDR_U makes 35-32 bits
 */
#define INJ_ADDR_L    0x10080000         // Injection Lower Address // start with row 2.col 0 and increment rest
#define INJ_ADDR_U    0x00000001         // Injection Upper Address  // physical addressing.top_b is 1





/**
 * @brief Used to check the range of a variable.
 */
int check_limit(int var, int lower, int upper) {
	if (var < lower || var > upper) {
		return 0;
	} else {
		return 1;
	}
}

/**
 * @brief Parses the command line arguments and checks for errors and limits parameters.
 */
void handle_commandline(int argc, char** argv){
	uint32_t paddress_max_vals[7] = {3,1,31,255,127,127,31};
	uint32_t saddress_max_vals[4] = {161,239,161,239};
	//
	// Parse command line arguments
	//
	if (cmdline_parser(argc, argv, &args_info) != 0) {
		exit(EXIT_CMD_LINE_PARSE);
	}
	if (args_info.paddress_given == 7){
		for(int i=0; i<7; i++){
			if(!check_limit(args_info.paddress_arg[i],0, paddress_max_vals[i])){
				printf("Physical address invalid or out of range.\n");
				exit(EXIT_CMD_LINE_PARSE);
			}
		}
	}
	if (args_info.saddress_given == 4){
		for(int i=0; i<4; i++){
			if(!check_limit(args_info.saddress_arg[i],0, saddress_max_vals[i])){
				printf("Slice area invalid or out of range.\n");
				exit(EXIT_CMD_LINE_PARSE);
			}
		}
	}
	if (args_info.ptranslate_given == 2){
		for(int i=0; i<2; i++){
			if(!check_limit(args_info.ptranslate_arg[i],0, saddress_max_vals[i])){
				printf("Slice address invalid or out of range.\n");
				exit(EXIT_CMD_LINE_PARSE);
			}
		}
	}

	if(args_info.verbose_flag){
		printf("xilsem_err_inj build: %s %s\n", __DATE__, __TIME__);
		fflush(NULL);
		if (args_info.paddress_given == 7){
			printf("Physical address to inject fault to: %i,%i,%i,%i,%i,%i,%i \n",
					args_info.paddress_arg[0],args_info.paddress_arg[1],args_info.paddress_arg[2],args_info.paddress_arg[3],
					args_info.paddress_arg[4],args_info.paddress_arg[5],args_info.paddress_arg[6]);
			fflush(NULL);
		}
		if (args_info.saddress_given == 4){
			printf("Slice area to inject error to: %i,%i,%i,%i\n",
					args_info.saddress_arg[0],args_info.saddress_arg[1],args_info.saddress_arg[2],args_info.saddress_arg[3]);
			fflush(NULL);
		}
		if (args_info.ptranslate_given == 2){
			printf("Slice address to translate: %i,%i\n",
					args_info.ptranslate_arg[0],args_info.ptranslate_arg[1]);
			fflush(NULL);
		}
	}
}

/*
 * Params:
 * - different modes:
 * 	- physical addressing: -p <blockType 0-3>, <halfAddress 0-1>, <rowAddress 0-31>, <columnAddress 0-255>,<minorAddress 0-127>, <wordAddress 0-127>,<bitAddress 0-31>
 * 	- slice area addressing with various random modes: -s bottomLeftX,bottomLeftY, topRightX,topRightY [-r <randomMode>]
 * 	- translation modes: slice to physical and vice versa: -t<physicalAddress>
 *
 */
int main(int argc, char **argv) {

	handle_commandline(argc,argv);

	if (args_info.paddress_given){
		unsigned int bit_count = args_info.paddress_arg[6]+1;
		if (args_info.full_word_flag) {
			// We will iterate through all 32 bits of a word, so we start with bit zero.
			args_info.paddress_arg[6] = 0;
			bit_count = 32 ;
		}
		for ( int bit = args_info.paddress_arg[6]; bit <bit_count; bit ++){
			/*
			 * INJ_ADDR_L makes 31-0 bits of SEM IP injection_data bus
			 * INJ_ADDR_U makes 35-32 bits
			 */

			uint32_t addr_u = (args_info.paddress_arg[0] << 2) | // block type (2 bits)
							  (args_info.paddress_arg[1] << 1) | // half address (1 bit)
							  (args_info.paddress_arg[2])>> 4;    // row address (highest bit)
			uint32_t addr_l = (args_info.paddress_arg[2]) << 27 |// row address (lower 4 bits)
							  (args_info.paddress_arg[3] << 19) |// column address (8 bits)
							  (args_info.paddress_arg[4] << 12) |// minor address (7 bits)
							  (args_info.paddress_arg[5] << 5) | // word address (7 bits)
							  bit;		  // bit address (5 bits)
			if(args_info.verbose_flag){
				printf("Address to inject fault to: upper 0x%8.8x lower 0x%8.8x\n", addr_u, addr_l);
				xilsem_debug(1);
			}
			fflush(NULL);
			uint32_t my_status ;   // Variable for status register read


			xilsem_init();
			xilsem_ipif_reset();
			if(args_info.verbose_flag){
				xilsem_print_regs();
			}

			xilsem_inject_error(addr_l, addr_u);

			my_status = xilsem_read_status();

			uint32_t busy_wait_count=0;
			while(!(my_status & (1 << XILSEM_INJ_ACK_MASK)) && (my_status & (1 << XILSEM_HB_STATUS_MASK))){
				my_status = xilsem_read_status();
				busy_wait_count++;
			}
			if(args_info.verbose_flag){
				printf("Fault injected. Busy waited %u cycles.\n", busy_wait_count);
			}
		}
		xilsem_exit();
	}

	if (args_info.saddress_given){

	}

	if (args_info.ptranslate_given){
		physical_address_t pa;
		pa = slice2physical((slice_address_t){args_info.ptranslate_arg[0],args_info.ptranslate_arg[1]});
		print_physical_address(pa);
	}

	return 0;
}


#if 0
/*
 * Old main,  has roots in standalone microblaze microcontroller implementation
 */
int main()
{
	int i;
	int uartrcvdata;
    printf("xilsem_err_inj v0.1\n");

    physical_address_t pa;
    slice_address_t sa = tuo_area.bottom_left;
    for(i=24; i<30; i++){
    	pa = slice2physical(sa);
    	print_physical_address(pa);
    	sa.x++;
    }

    exit(0);


    xilsem_init();
    xilsem_print_regs();

    printf("Resetting IPIF...\n");
    xilsem_ipif_reset();

    printf("Press 'd' for idle mode\n"
           "Press 'n' for nop cmd\n"
           "Press 'o' for observation cmd\n"
           //"Press 'g' for led status\n"
           "Press 'r' for sem reset\n"
           "Press 'i' for error injection cmd\n !! BEWARE OF LONG INJECTION LOOP"
           "Press 'q' to quit\n");

    while(1)
    {
    	uartrcvdata = getchar(); // Wait for key input
   		printf("got %x\n\r",uartrcvdata);
    	if(uartrcvdata == 'r') {
    		xilsem_reset();
    		addr1 = INJ_ADDR_L;
    	}
    	//else if(uartrcvdata == 'g'){
    	//	printf("GPIO Value: 0x%lx\n\r",read_gpio1());
    	//}
    	else if(uartrcvdata == 'n'){
            xilsem_nop();
    	}
    	else if(uartrcvdata == 'd'){
    		xilsem_nop();
    	    xilsem_idle();
    	}
    	else if(uartrcvdata == 'o'){
    		xilsem_nop();
    	    xilsem_obs();
    	}
    	//else if(uartrcvdata == 's'){
        //	printf("Status Reg : 0x%lx\n\r",read_status());

    	//}
    	else if(uartrcvdata == 'i'){
    	    xilsem_nop();
    	    xilsem_idle();
    	    xilsem_nop();
    	    printf("INJECTION iterations i: %i Start on key press \n\r",INJ_LOOP);
    	    uartrcvdata = getchar(); // Wait for key input

    	    for (i=0;i < INJ_LOOP; i++)
    	    {
    	    	printf("iteration i: %i addr1 :0x%x\n\r",i,addr1);
    	        xilsem_inj_addr(addr1,addr2);
    	        xilsem_nop();
    	        xilsem_inj();
    	        //printf("Status Reg: 0x%lx\n\r",read_status());
    	        //printf("GPIO Value: 0x%lx\n\r",read_gpio1());
    	        my_status = xilsem_read_status();
    	        while(!(my_status & (1 << XILSEM_INJ_ACK_MASK)) && (my_status & (1 << XILSEM_HB_STATUS_MASK)))
    	        {
    	        	//printf("Wait\n");
    	        	my_status = xilsem_read_status();
    	        }
    	        addr1++;
    	        //x=0;
    	        //printf("Status Reg: 0x%lx\n\r",read_status());
    	        //while(x < 6000000)
    	        //{
    	         //   x++;
    	        //}

    	     }
    	     printf("INJECTION DONE \n\r");
    	}
    	else if (uartrcvdata == 'q'){
    		xilsem_exit();
    		exit(0);
    	}
    	else {
        xilsem_nop();
    	}
     }
    return 0;
}
#endif
