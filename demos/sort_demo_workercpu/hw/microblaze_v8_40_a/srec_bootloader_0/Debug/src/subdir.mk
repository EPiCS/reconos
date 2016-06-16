################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bootloader.c \
../src/platform.c \
../src/srec.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/bootloader.o \
./src/platform.o \
./src/srec.o 

C_DEPS += \
./src/bootloader.d \
./src/platform.d \
./src/srec.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -I../../standalone_bsp_0/worker_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


