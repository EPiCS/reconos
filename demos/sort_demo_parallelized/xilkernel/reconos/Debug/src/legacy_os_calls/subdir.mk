################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/legacy_os_calls/mbox.c \
../src/legacy_os_calls/rqueue.c 

OBJS += \
./src/legacy_os_calls/mbox.o \
./src/legacy_os_calls/rqueue.o 

C_DEPS += \
./src/legacy_os_calls/mbox.d \
./src/legacy_os_calls/rqueue.d 


# Each subdirectory must supply rules for building sources it contributes
src/legacy_os_calls/%.o: ../src/legacy_os_calls/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -DRECONOS_ARCH_microblaze -DRECONOS_MINIMAL -DRECONOS_OS_xilkernel -Wall -O0 -g3 -I"/home/meise/xsdk_projects/xilkernel_bsp_0/microblaze_0/include" -I"/home/meise/xsdk_projects/reconos/include" -c -fmessage-length=0 -D __XMK__ -I../../xilkernel_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


