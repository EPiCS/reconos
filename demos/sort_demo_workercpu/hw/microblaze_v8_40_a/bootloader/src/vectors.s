	.globl _vectors_reset
	.ent _vectors_reset
	.section .vectors.reset
_vectors_reset:
	brai    _start      # 50 <_start1>
	.end _vectors_reset

	.globl _vectors_sw_exception
	.ent _vectors_sw_exception
	.section .vectors.sw_exception
_vectors_sw_exception:
	brai    null_handler    # 618 <_exception_handler>
	.end _vectors_sw_exception

	.globl _vectors_interrupt
	.ent _vectors_interrupt
	.section .vectors.interrupt
_vectors_interrupt:
	brai    null_handler    # 634 <__interrupt_handler>
	.end _vectors_interrupt

	.globl _vectors_hw_exception
	.ent _vectors_hw_exception
	.section .vectors.hw_exception
_vectors_hw_exception:
	brai    null_handler    # 630 <_hw_exception_handler>
	.end _vectors_hw_exception

