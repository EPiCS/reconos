################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bubblesort.c \
../src/data.c \
../src/logging.c \
../src/mergesort.c \
../src/platform.c \
../src/sort_demo.c \
../src/timing.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/bubblesort.o \
./src/data.o \
./src/logging.o \
./src/mergesort.o \
./src/platform.o \
./src/sort_demo.o \
./src/timing.o 

C_DEPS += \
./src/bubblesort.d \
./src/data.d \
./src/logging.d \
./src/mergesort.d \
./src/platform.d \
./src/sort_demo.d \
./src/timing.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -I"/home/christoph/Documents/reconos_zynq/reconos_zynq/demos/sort_demo/xilkernel/reconos/include" -c -fmessage-length=0 -D __XMK__ -I../../sort_demo_bsp/microblaze_0/include -mlittle-endian -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.b -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


