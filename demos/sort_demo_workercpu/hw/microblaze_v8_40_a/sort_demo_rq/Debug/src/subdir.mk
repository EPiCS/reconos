################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bubblesort.c \
../src/sort_demo_rq.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/bubblesort.o \
./src/sort_demo_rq.o 

C_DEPS += \
./src/bubblesort.d \
./src/sort_demo_rq.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a_backup/standalone_bsp_0/worker_0/include" -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a_backup/libreconos/src" -c -fmessage-length=0 -mxl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


