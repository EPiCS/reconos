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
sort_demo.elf.size \

ELFCHECK += \
sort_demo.elf.elfcheck \


# All Target
all: sort_demo.elf secondary-outputs

# Tool invocations
sort_demo.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo Building target: $@
	@echo Invoking: MicroBlaze gcc linker
	mb-gcc -Wl,--no-relax -L"/home/meise/git/reconos_epics/demos/sort_demo_workercpu/hw/microblaze_v8_40_a/libreconos/src" -Wl,-T -Wl,../src/lscript.ld -L../../hello_world_bsp_0/microblaze_0/lib -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v8.40.a -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -o"sort_demo.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo Finished building target: $@
	@echo ' '

sort_demo.elf.size: sort_demo.elf
	@echo Invoking: MicroBlaze Print Size
	mb-size sort_demo.elf  |tee "sort_demo.elf.size"
	@echo Finished building: $@
	@echo ' '

sort_demo.elf.elfcheck: sort_demo.elf
	@echo Invoking: Xilinx ELF Check
	elfcheck sort_demo.elf -hw ../../edk_worker_hw_platform/system.xml -pe microblaze_0  |tee "sort_demo.elf.elfcheck"
	@echo Finished building: $@
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) sort_demo.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
