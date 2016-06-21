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
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -Os -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a_backup/libreconos/src" -c -fmessage-length=0 -I../../standalone_bsp_0/worker_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.s
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc assembler'
	mb-as  -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


