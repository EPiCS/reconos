#include <stdio.h>


int main(){
	char *tmp;
	int a [10];
	FILE *fp;
	char line[80];
	int old_value, new_value, diff = 0;
	fp = fopen("/proc/stat", "r");
	fgets(line, 80, fp); 
	fclose(fp);
	sscanf(line + 6, "%d %d %d %d %d %d %d %d %d %d", &a[0],&a[1],&a[2],&a[3],&a[4],&a[5],&a[6],&a[7],&a[8],&a[9]);
	printf("element %d\n", a[3]);
	old_value = a[3];
	
	while(1){
		sleep(1);
		fp = fopen("/proc/stat", "r");
		fgets(line, 80, fp); 
		fclose(fp);
		sscanf(line + 6, "%d %d %d %d %d %d %d %d %d %d", &a[0],&a[1],&a[2],&a[3],&a[4],&a[5],&a[6],&a[7],&a[8],&a[9]);
		printf("element %d\n", a[3]);
		new_value = a[3];
		diff = new_value - old_value;
		printf("diff = %d\n", diff);
		old_value = new_value;

		if (diff < 30 ){ //cpu heavily occupied
			
		}
		if (diff > 70){ 
		}
	}

	
	
	
	return 0;

}
