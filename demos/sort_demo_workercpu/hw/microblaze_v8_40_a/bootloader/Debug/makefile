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
bootloader.elf.size \

ELFCHECK += \
bootloader.elf.elfcheck \


# All Target
all: bootloader.elf secondary-outputs

# Tool invocations
bootloader.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -nostartfiles -Wl,-T -Wl,../src/lscript.ld -L../../standalone_bsp_0/worker_0/lib -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -Wl,--no-relax -Wl,--gc-sections -o "bootloader.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

bootloader.elf.size: bootloader.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size bootloader.elf  |tee "bootloader.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

bootloader.elf.elfcheck: bootloader.elf
	@echo 'Invoking: Xilinx ELF Check'
	elfcheck bootloader.elf -hw ../../edk_worker_hw_platform_0/system.xml -pe worker_0  |tee "bootloader.elf.elfcheck"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) bootloader.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
