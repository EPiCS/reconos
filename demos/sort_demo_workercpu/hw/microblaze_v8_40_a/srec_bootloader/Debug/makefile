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
srec_bootloader.elf.size \

ELFCHECK += \
srec_bootloader.elf.elfcheck \


# All Target
all: srec_bootloader.elf secondary-outputs

# Tool invocations
srec_bootloader.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../standalone_bsp_0/worker_0/lib -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.50.c -mno-xl-soft-mul -Wl,--no-relax -Wl,--gc-sections -o "srec_bootloader.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

srec_bootloader.elf.size: srec_bootloader.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size srec_bootloader.elf  |tee "srec_bootloader.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

srec_bootloader.elf.elfcheck: srec_bootloader.elf
	@echo 'Invoking: Xilinx ELF Check'
	elfcheck srec_bootloader.elf -hw ../../edk_worker_hw_platform/system.xml -pe worker_0  |tee "srec_bootloader.elf.elfcheck"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) srec_bootloader.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
