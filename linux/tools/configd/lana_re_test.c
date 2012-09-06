#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/ioctl.h>

int main(int argc, char**argv)
{
	char buff[256];
	int i = 100, j, ret, fd;

	fd = open("/dev/lana_re_cfg", O_RDWR);
	if (fd < 0 || argc != 2) {
		perror("open");
		exit(5);
	}

	printf("open done!\n");

	ret = ioctl(fd, -1073477120, argv[argc-1]);
	if (ret < 0) {
		perror("ioctl");
		exit(6);
	}

	printf("ioctl done!\n");

	while (i-- > 0) {
		ret = read(fd, buff, sizeof(buff));
		if (ret < 0) {
			perror("read");
			continue;
		}
		printf("Got: ");
		for (j = 0; j < ret; ++j)
			printf("%02x ", (uint8_t) buff[j]);
		printf("\n");

		ret = write(fd, buff, ret);
		if (ret < 0) {
			perror("write");
			continue;
		}
	}

	close(fd);
	return 0;
}
