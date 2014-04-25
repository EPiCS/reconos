#include <stdio.h>
#include <stdlib.h>

void exit_usage(const char * s)
{
	fprintf(stderr,"Usage: %s <name>\n\n- read input from stdin\n- write output to stdout\n- <name> is name of c array\n",s);
	exit(1);
}

unsigned int reverse_endian(unsigned int w)
{
	unsigned int r = 0;
	char * alias_w = (char*)(&w);
	char * alias_r = (char*)(&r);

	alias_r[0] = alias_w[3];
	alias_r[1] = alias_w[2];
	alias_r[2] = alias_w[1];
	alias_r[3] = alias_w[0];

	return r;
}


int main(int argc, char ** argv)
{
	unsigned int data;
	int res,i;

	if(argc != 2) exit_usage(argv[0]);

	printf("const unsigned int %s[] = {\n",argv[1]);

	i = 0;
	while(1){
		res = fread(&data,4,1,stdin);
		if(res == 0){
			if(feof(stdin)) break;
			fprintf(stderr,"ERROR: input length must be multiple of 4\n");
			exit(2);
		}

		data = reverse_endian(data);

		if(i == 0) printf("\t 0x%08X",data);
		else printf(",0x%08X",data);

		if(i % 8 == 7)	printf("\n\t");
		i++;
	}	

	printf("\n};\n\nunsigned int %s_size = %d;\n\n",argv[1],i);

	return 0;
} 

