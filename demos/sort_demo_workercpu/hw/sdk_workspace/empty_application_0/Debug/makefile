################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include src/subdir.mk
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
empty_application_0.elf.size \

ELFCHECK += \
empty_application_0.elf.elfcheck \


# All Target
all: empty_application_0.elf secondary-outputs

# Tool invocations
empty_application_0.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo Building target: $@
	@echo Invoking: MicroBlaze gcc linker
	mb-gcc -Wl,--no-relax -Wl,-T -Wl,../src/lscript.ld -L../../workercpu_thread/microblaze_1/lib -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.40.a -mno-xl-soft-mul -o"empty_application_0.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo Finished building target: $@
	@echo ' '

empty_application_0.elf.size: empty_application_0.elf
	@echo Invoking: MicroBlaze Print Size
	mb-size empty_application_0.elf  |tee "empty_application_0.elf.size"
	@echo Finished building: $@
	@echo ' '

empty_application_0.elf.elfcheck: empty_application_0.elf
	@echo Invoking: Xilinx ELF Check
	elfcheck empty_application_0.elf -hw ../../edk_worker_hw_platform/system.xml -pe microblaze_1  |tee "empty_application_0.elf.elfcheck"
	@echo Finished building: $@
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) empty_application_0.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
