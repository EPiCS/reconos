################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/main.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/main.o 

C_DEPS += \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O3 -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/sdk_workspace/libreconos/src" -c -fmessage-length=0 -Wl,--no-relax -I../../workercpu_thread/microblaze_1/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.40.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


