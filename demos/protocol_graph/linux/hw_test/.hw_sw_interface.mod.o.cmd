cmd_/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.o := microblaze-unknown-linux-gnu-gcc -Wp,-MD,/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/.hw_sw_interface.mod.o.d  -nostdinc -isystem /opt/crosscompiler/microblaze_v1.0/microblaze-unknown-linux-gnu/bin/../lib/gcc/microblaze-unknown-linux-gnu/4.1.2/include -I/home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include -Iinclude  -include include/generated/autoconf.h -D__KERNEL__ -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -Werror-implicit-function-declaration -Wno-format-security -fno-delete-null-pointer-checks -O2 -ffixed-r31 -mno-xl-soft-div -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.00.a -mxl-multiply-high -mno-xl-soft-mul -fno-stack-protector -fomit-frame-pointer -g -Wdeclaration-after-statement -Wno-pointer-sign -I/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/../../../../linux/reconos/libreconos-ks  -D"KBUILD_STR(s)=\#s" -D"KBUILD_BASENAME=KBUILD_STR(hw_sw_interface.mod)"  -D"KBUILD_MODNAME=KBUILD_STR(hw_sw_interface)" -DMODULE  -c -o /home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.o /home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.c

deps_/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.o := \
  /home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.c \
    $(wildcard include/config/module/unload.h) \
  include/linux/module.h \
    $(wildcard include/config/symbol/prefix.h) \
    $(wildcard include/config/modules.h) \
    $(wildcard include/config/modversions.h) \
    $(wildcard include/config/unused/symbols.h) \
    $(wildcard include/config/generic/bug.h) \
    $(wildcard include/config/kallsyms.h) \
    $(wildcard include/config/smp.h) \
    $(wildcard include/config/tracepoints.h) \
    $(wildcard include/config/tracing.h) \
    $(wildcard include/config/event/tracing.h) \
    $(wildcard include/config/ftrace/mcount/record.h) \
    $(wildcard include/config/constructors.h) \
    $(wildcard include/config/sysfs.h) \
  include/linux/list.h \
    $(wildcard include/config/debug/list.h) \
  include/linux/types.h \
    $(wildcard include/config/uid16.h) \
    $(wildcard include/config/lbdaf.h) \
    $(wildcard include/config/phys/addr/t/64bit.h) \
    $(wildcard include/config/64bit.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/types.h \
  include/asm-generic/types.h \
  include/asm-generic/int-ll64.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/bitsperlong.h \
  include/asm-generic/bitsperlong.h \
  include/linux/posix_types.h \
  include/linux/stddef.h \
  include/linux/compiler.h \
    $(wildcard include/config/sparse/rcu/pointer.h) \
    $(wildcard include/config/trace/branch/profiling.h) \
    $(wildcard include/config/profile/all/branches.h) \
    $(wildcard include/config/enable/must/check.h) \
    $(wildcard include/config/enable/warn/deprecated.h) \
  include/linux/compiler-gcc.h \
    $(wildcard include/config/arch/supports/optimized/inlining.h) \
    $(wildcard include/config/optimize/inlining.h) \
  include/linux/compiler-gcc4.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/posix_types.h \
  include/asm-generic/posix_types.h \
  include/linux/poison.h \
    $(wildcard include/config/illegal/pointer/value.h) \
  include/linux/prefetch.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/processor.h \
    $(wildcard include/config/mmu.h) \
    $(wildcard include/config/kernel/start.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/ptrace.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/setup.h \
    $(wildcard include/config/early/printk.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/registers.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/entry.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/percpu.h \
  include/asm-generic/percpu.h \
    $(wildcard include/config/debug/preempt.h) \
    $(wildcard include/config/have/setup/per/cpu/area.h) \
  include/linux/threads.h \
    $(wildcard include/config/nr/cpus.h) \
    $(wildcard include/config/base/small.h) \
  include/linux/percpu-defs.h \
    $(wildcard include/config/debug/force/weak/per/cpu.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/current.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/cache.h \
  include/linux/stat.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/stat.h \
  include/asm-generic/stat.h \
  include/linux/time.h \
    $(wildcard include/config/arch/uses/gettimeoffset.h) \
  include/linux/cache.h \
    $(wildcard include/config/arch/has/cache/line/size.h) \
  include/linux/kernel.h \
    $(wildcard include/config/preempt/voluntary.h) \
    $(wildcard include/config/debug/spinlock/sleep.h) \
    $(wildcard include/config/prove/locking.h) \
    $(wildcard include/config/ring/buffer.h) \
    $(wildcard include/config/numa.h) \
  /opt/crosscompiler/microblaze_v1.0/microblaze-unknown-linux-gnu/bin/../lib/gcc/microblaze-unknown-linux-gnu/4.1.2/include/stdarg.h \
  include/linux/linkage.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/linkage.h \
  include/linux/bitops.h \
    $(wildcard include/config/generic/find/last/bit.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/bitops.h \
  include/asm-generic/bitops.h \
  include/linux/irqflags.h \
    $(wildcard include/config/trace/irqflags.h) \
    $(wildcard include/config/irqsoff/tracer.h) \
    $(wildcard include/config/preempt/tracer.h) \
    $(wildcard include/config/trace/irqflags/support.h) \
  include/linux/typecheck.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/irqflags.h \
    $(wildcard include/config/xilinx/microblaze0/use/msr/instr.h) \
  include/asm-generic/bitops/__ffs.h \
  include/asm-generic/bitops/ffz.h \
  include/asm-generic/bitops/fls.h \
  include/asm-generic/bitops/__fls.h \
  include/asm-generic/bitops/fls64.h \
  include/asm-generic/bitops/find.h \
    $(wildcard include/config/generic/find/first/bit.h) \
  include/asm-generic/bitops/sched.h \
  include/asm-generic/bitops/ffs.h \
  include/asm-generic/bitops/hweight.h \
  include/asm-generic/bitops/arch_hweight.h \
  include/asm-generic/bitops/const_hweight.h \
  include/asm-generic/bitops/lock.h \
  include/asm-generic/bitops/atomic.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/system.h \
    $(wildcard include/config/debug/fs.h) \
  include/asm-generic/cmpxchg.h \
  include/asm-generic/cmpxchg-local.h \
  include/asm-generic/bitops/non-atomic.h \
  include/asm-generic/bitops/ext2-non-atomic.h \
  include/asm-generic/bitops/le.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/byteorder.h \
  include/linux/byteorder/big_endian.h \
  include/linux/swab.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/swab.h \
  include/asm-generic/swab.h \
  include/linux/byteorder/generic.h \
  include/asm-generic/bitops/ext2-atomic.h \
  include/asm-generic/bitops/minix.h \
  include/linux/log2.h \
    $(wildcard include/config/arch/has/ilog2/u32.h) \
    $(wildcard include/config/arch/has/ilog2/u64.h) \
  include/linux/printk.h \
    $(wildcard include/config/printk.h) \
    $(wildcard include/config/dynamic/debug.h) \
  include/linux/dynamic_debug.h \
  include/linux/jump_label.h \
    $(wildcard include/config/jump/label.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/bug.h \
  include/asm-generic/bug.h \
    $(wildcard include/config/bug.h) \
    $(wildcard include/config/generic/bug/relative/pointers.h) \
    $(wildcard include/config/debug/bugverbose.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/div64.h \
  include/asm-generic/div64.h \
  include/linux/seqlock.h \
  include/linux/spinlock.h \
    $(wildcard include/config/debug/spinlock.h) \
    $(wildcard include/config/generic/lockbreak.h) \
    $(wildcard include/config/preempt.h) \
    $(wildcard include/config/debug/lock/alloc.h) \
  include/linux/preempt.h \
    $(wildcard include/config/preempt/notifiers.h) \
  include/linux/thread_info.h \
    $(wildcard include/config/compat.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/thread_info.h \
  include/linux/stringify.h \
  include/linux/bottom_half.h \
  include/linux/spinlock_types.h \
  include/linux/spinlock_types_up.h \
  include/linux/lockdep.h \
    $(wildcard include/config/lockdep.h) \
    $(wildcard include/config/lock/stat.h) \
    $(wildcard include/config/prove/rcu.h) \
  include/linux/rwlock_types.h \
  include/linux/spinlock_up.h \
  include/linux/rwlock.h \
  include/linux/spinlock_api_up.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/atomic.h \
  include/asm-generic/atomic.h \
  include/asm-generic/atomic-long.h \
  include/linux/math64.h \
  include/linux/kmod.h \
  include/linux/gfp.h \
    $(wildcard include/config/kmemcheck.h) \
    $(wildcard include/config/highmem.h) \
    $(wildcard include/config/zone/dma.h) \
    $(wildcard include/config/zone/dma32.h) \
    $(wildcard include/config/debug/vm.h) \
  include/linux/mmzone.h \
    $(wildcard include/config/force/max/zoneorder.h) \
    $(wildcard include/config/memory/hotplug.h) \
    $(wildcard include/config/sparsemem.h) \
    $(wildcard include/config/compaction.h) \
    $(wildcard include/config/arch/populates/node/map.h) \
    $(wildcard include/config/discontigmem.h) \
    $(wildcard include/config/flat/node/mem/map.h) \
    $(wildcard include/config/cgroup/mem/res/ctlr.h) \
    $(wildcard include/config/no/bootmem.h) \
    $(wildcard include/config/have/memory/present.h) \
    $(wildcard include/config/have/memoryless/nodes.h) \
    $(wildcard include/config/need/node/memmap/size.h) \
    $(wildcard include/config/need/multiple/nodes.h) \
    $(wildcard include/config/have/arch/early/pfn/to/nid.h) \
    $(wildcard include/config/flatmem.h) \
    $(wildcard include/config/sparsemem/extreme.h) \
    $(wildcard include/config/nodes/span/other/nodes.h) \
    $(wildcard include/config/holes/in/zone.h) \
    $(wildcard include/config/arch/has/holes/memorymodel.h) \
  include/linux/wait.h \
  include/linux/numa.h \
    $(wildcard include/config/nodes/shift.h) \
  include/linux/init.h \
    $(wildcard include/config/hotplug.h) \
  include/linux/nodemask.h \
  include/linux/bitmap.h \
  include/linux/string.h \
    $(wildcard include/config/binary/printf.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/string.h \
  include/linux/pageblock-flags.h \
    $(wildcard include/config/hugetlb/page.h) \
    $(wildcard include/config/hugetlb/page/size/variable.h) \
  include/generated/bounds.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/page.h \
    $(wildcard include/config/microblaze/32k/pages.h) \
    $(wildcard include/config/microblaze/16k/pages.h) \
    $(wildcard include/config/microblaze/8k/pages.h) \
    $(wildcard include/config/kernel/base/addr.h) \
  include/linux/pfn.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/asm-compat.h \
  include/linux/const.h \
  include/asm-generic/memory_model.h \
    $(wildcard include/config/sparsemem/vmemmap.h) \
  include/asm-generic/getorder.h \
  include/linux/memory_hotplug.h \
    $(wildcard include/config/memory/hotremove.h) \
    $(wildcard include/config/have/arch/nodedata/extension.h) \
  include/linux/notifier.h \
  include/linux/errno.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/errno.h \
  include/asm-generic/errno.h \
  include/asm-generic/errno-base.h \
  include/linux/mutex.h \
    $(wildcard include/config/debug/mutexes.h) \
  include/linux/rwsem.h \
    $(wildcard include/config/rwsem/generic/spinlock.h) \
  include/linux/rwsem-spinlock.h \
  include/linux/srcu.h \
  include/linux/topology.h \
    $(wildcard include/config/sched/smt.h) \
    $(wildcard include/config/sched/mc.h) \
    $(wildcard include/config/sched/book.h) \
    $(wildcard include/config/use/percpu/numa/node/id.h) \
  include/linux/cpumask.h \
    $(wildcard include/config/cpumask/offstack.h) \
    $(wildcard include/config/hotplug/cpu.h) \
    $(wildcard include/config/debug/per/cpu/maps.h) \
    $(wildcard include/config/disable/obsolete/cpumask/functions.h) \
  include/linux/smp.h \
    $(wildcard include/config/use/generic/smp/helpers.h) \
  include/linux/percpu.h \
    $(wildcard include/config/need/per/cpu/embed/first/chunk.h) \
    $(wildcard include/config/need/per/cpu/page/first/chunk.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/topology.h \
  include/asm-generic/topology.h \
  include/linux/mmdebug.h \
    $(wildcard include/config/debug/virtual.h) \
  include/linux/workqueue.h \
    $(wildcard include/config/debug/objects/work.h) \
    $(wildcard include/config/freezer.h) \
  include/linux/timer.h \
    $(wildcard include/config/timer/stats.h) \
    $(wildcard include/config/debug/objects/timers.h) \
  include/linux/ktime.h \
    $(wildcard include/config/ktime/scalar.h) \
  include/linux/jiffies.h \
  include/linux/timex.h \
  include/linux/param.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/param.h \
  include/asm-generic/param.h \
    $(wildcard include/config/hz.h) \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/timex.h \
  include/asm-generic/timex.h \
  include/linux/debugobjects.h \
    $(wildcard include/config/debug/objects.h) \
    $(wildcard include/config/debug/objects/free.h) \
  include/linux/elf.h \
  include/linux/elf-em.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/elf.h \
  include/linux/kobject.h \
  include/linux/sysfs.h \
  include/linux/kobject_ns.h \
  include/linux/kref.h \
  include/linux/moduleparam.h \
    $(wildcard include/config/alpha.h) \
    $(wildcard include/config/ia64.h) \
    $(wildcard include/config/ppc64.h) \
  include/linux/tracepoint.h \
  include/linux/rcupdate.h \
    $(wildcard include/config/rcu/torture/test.h) \
    $(wildcard include/config/preempt/rcu.h) \
    $(wildcard include/config/no/hz.h) \
    $(wildcard include/config/tree/rcu.h) \
    $(wildcard include/config/tree/preempt/rcu.h) \
    $(wildcard include/config/tiny/rcu.h) \
    $(wildcard include/config/tiny/preempt/rcu.h) \
    $(wildcard include/config/debug/objects/rcu/head.h) \
    $(wildcard include/config/preempt/rt.h) \
  include/linux/completion.h \
  include/linux/rcutiny.h \
  /home/arkeller/Documents/reconos_v3_git_daniel/reconos3/linux/kernel/linux-2.6-xlnx/arch/microblaze/include/asm/module.h \
  include/asm-generic/module.h \
  include/trace/events/module.h \
  include/trace/define_trace.h \
  include/linux/vermagic.h \
  include/generated/utsrelease.h \

/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.o: $(deps_/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.o)

$(deps_/home/arkeller/Documents/epics/git_reconos/reconos/demos/protocol_graph/linux/hw_test/hw_sw_interface.mod.o):
