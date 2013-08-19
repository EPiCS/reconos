################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bootloader.c 

LD_SRCS += \
../src/lscript.ld 

S_SRCS += \
../src/init.s \
../src/vectors.s 

OBJS += \
./src/bootloader.o \
./src/init.o \
./src/vectors.o 

C_DEPS += \
./src/bootloader.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -Os -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/empty_application_0/src" -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/libreconos/src" -c -fmessage-length=0 -save-temps -Wl,--no-relax -I../../workercpu_thread/microblaze_1/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.40.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '

src/%.o: ../src/%.s
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc assembler
	mb-as  -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


