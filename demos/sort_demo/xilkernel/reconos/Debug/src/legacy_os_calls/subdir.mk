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
	mb-gcc -DRECONOS_OS_xilkernel -DRECONOS_ARCH_microblaze -DRECONOS_MMU_false -DRECONOS_MINIMAL -Wall -O0 -g3 -c -fmessage-length=0 -D __XMK__ -I../../sort_demo_bsp/microblaze_0/include -mlittle-endian -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.b -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


