#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(){
	//cat bitfiles/partial_ips.bit > /dev/icap0
	FILE *f = fopen("/proc/net/lana/scheduler", "r+");
//	int f = open("/proc/net/lana/scheduler", O_RDONLY)
	char *buf = malloc(120);
	size_t len = 0;
	size_t size = 120;
	char part_1[15] = "cat bitfiles/";
	char part_2[14] = " > /dev/icap0";
	//unlock the kernel
	fwrite(buf, 1, 1, f); 
	rewind(f);

	while(1){
		len = getline(&buf, &size, f);
	//	len = read(f, buf, size);
		if (len < 0){
			perror("getline");
			return -1;
		}
		
		printf("read: %s (len = %d)\n", buf, len);
		if (memcmp(buf, "none", 4) == 0){
			fwrite(buf, 1, 1, f); 
			rewind(f);		
			continue;
		}
		char * command = malloc(30 + len);
		memcpy(command, part_1, 13);
		memcpy(command + 13, buf, len -1);
		memcpy(command + 13 + len - 1, part_2, 14);
		printf("command: %s\n", command);
		if(system(command) == -1){
			perror("system");
			return -1;
		}
		printf("done\n");
		//rewind(f);		

		fwrite(command, 1, 1, f); //doesnt matter what we write, we just let the kernel know that the reconfig is done.
	//	free(buf);
		free(command);
		rewind(f);
		len = 0;		

	}
	free(buf);
	return 1;
}

