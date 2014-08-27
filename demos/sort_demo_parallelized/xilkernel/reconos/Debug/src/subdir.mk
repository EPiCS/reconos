################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/fsl.c \
../src/logging.c \
../src/mbox.c \
../src/reconos.c \
../src/timing.c \
../src/xutils.c 

OBJS += \
./src/fsl.o \
./src/logging.o \
./src/mbox.o \
./src/reconos.o \
./src/timing.o \
./src/xutils.o 

C_DEPS += \
./src/fsl.d \
./src/logging.d \
./src/mbox.d \
./src/reconos.d \
./src/timing.d \
./src/xutils.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -DRECONOS_ARCH_microblaze -DRECONOS_MINIMAL -DRECONOS_OS_xilkernel -Wall -O0 -g3 -I"/home/meise/xsdk_projects/sort_demo_bsp/microblaze_0/include" -I"/home/meise/xsdk_projects/reconos/include" -c -fmessage-length=0 -D __XMK__ -I../../xilkernel_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


