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
sort_demo_shmem.elf.size \

ELFCHECK += \
sort_demo_shmem.elf.elfcheck \


# All Target
all: sort_demo_shmem.elf secondary-outputs

# Tool invocations
sort_demo_shmem.elf: $(OBJS)  $(USER_OBJS)
	@echo Building target: $@
	@echo Invoking: MicroBlaze gcc linker
	mb-gcc -L"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/libreconos/src" -L"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/hello_world_bsp_0/microblaze_0/lib" -mxl-soft-mul -o"sort_demo_shmem.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo Finished building target: $@
	@echo ' '

sort_demo_shmem.elf.size: sort_demo_shmem.elf
	@echo Invoking: MicroBlaze Print Size
	mb-size sort_demo_shmem.elf  |tee "sort_demo_shmem.elf.size"
	@echo Finished building: $@
	@echo ' '

sort_demo_shmem.elf.elfcheck: sort_demo_shmem.elf
	@echo Invoking: Xilinx ELF Check
	elfcheck sort_demo_shmem.elf  |tee "sort_demo_shmem.elf.elfcheck"
	@echo Finished building: $@
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) sort_demo_shmem.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
