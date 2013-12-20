################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/arch/arch_microblaze_linux.c \
../src/arch/arch_microblaze_xilkernel.c \
../src/arch/arch_zynq_linux.c 

OBJS += \
./src/arch/arch_microblaze_linux.o \
./src/arch/arch_microblaze_xilkernel.o \
./src/arch/arch_zynq_linux.o 

C_DEPS += \
./src/arch/arch_microblaze_linux.d \
./src/arch/arch_microblaze_xilkernel.d \
./src/arch/arch_zynq_linux.d 


# Each subdirectory must supply rules for building sources it contributes
src/arch/%.o: ../src/arch/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -DRECONOS_OS_xilkernel -DRECONOS_ARCH_microblaze -DRECONOS_MMU_false -DRECONOS_MINIMAL -Wall -O0 -g3 -c -fmessage-length=0 -D __XMK__ -I../../sort_demo_bsp/microblaze_0/include -mlittle-endian -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.b -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


