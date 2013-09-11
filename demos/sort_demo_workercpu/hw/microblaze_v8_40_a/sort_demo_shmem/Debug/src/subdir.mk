################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bubblesort.c \
../src/sort_demo_shmem.c 

LD_SRCS += \
../src/lscript.ld 

OBJS += \
./src/bubblesort.o \
./src/sort_demo_shmem.o 

C_DEPS += \
./src/bubblesort.d \
./src/sort_demo_shmem.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/libreconos/src" -I"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/hello_world_bsp_0/microblaze_0/include" -c -fmessage-length=0 -mxl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


