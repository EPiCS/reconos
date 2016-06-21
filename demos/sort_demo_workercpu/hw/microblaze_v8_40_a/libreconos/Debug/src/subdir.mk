################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
O_SRCS += \
../src/reconos.o 

C_SRCS += \
../src/reconos.c 

OBJS += \
./src/reconos.o 

C_DEPS += \
./src/reconos.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a_backup/standalone_bsp_0/worker_0/include" -c -fmessage-length=0 -I../../standalone_bsp_0/worker_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


