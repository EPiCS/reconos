################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
ELFSIZE += \
sort_demo_parallelized.elf.size \

ELFCHECK += \
sort_demo_parallelized.elf.elfcheck \


# All Target
all: sort_demo_parallelized.elf secondary-outputs

# Tool invocations
sort_demo_parallelized.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -L"/home/meise/xsdk_projects/sort_demo_bsp/microblaze_0/lib" -L"/home/meise/xsdk_projects/reconos/Debug" -Wl,-T -Wl,../src/lscript.ld -L../../sort_demo_bsp/microblaze_0/lib -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -Wl,--gc-sections -o "sort_demo_parallelized.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

sort_demo_parallelized.elf.size: sort_demo_parallelized.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size sort_demo_parallelized.elf  |tee "sort_demo_parallelized.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

sort_demo_parallelized.elf.elfcheck: sort_demo_parallelized.elf
	@echo 'Invoking: Xilinx ELF Check'
	elfcheck sort_demo_parallelized.elf -hw ../../sort_demo_hw/system.xml -pe microblaze_0  |tee "sort_demo_parallelized.elf.elfcheck"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) sort_demo_parallelized.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
