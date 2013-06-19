################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bubblesort.c \
../src/platform.c \
../src/sort_demo.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/bubblesort.o \
./src/platform.o \
./src/sort_demo.o 

C_DEPS += \
./src/bubblesort.d \
./src/platform.d \
./src/sort_demo.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/sdk_workspace/libreconos/src" -c -fmessage-length=0 -Wl,--no-relax -I../../hello_world_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.40.a -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


