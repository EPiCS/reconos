/*
 * Lightweight Autonomic Network Architecture
 * Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

#ifndef COMPILER_H
#define COMPILER_H

#ifndef likely
# define likely(x)          __builtin_expect(!!(x), 1)
#endif
#ifndef unlikely
# define unlikely(x)        __builtin_expect(!!(x), 0)
#endif
#ifndef __deprecated
# define __deprecated       /* unimplemented */
#endif
#ifndef unreachable
# define unreachable()      do { } while (1)
#endif
#ifndef barrier
# define barrier()          __sync_synchronize()
#endif
#ifndef bug
# define bug()              __builtin_trap()
#endif
#ifndef mark_unreachable
# define mark_unreachable() __builtin_unreachable()
#endif
#ifndef is_type
# define is_type(x, type)   __builtin_types_compatible_p(typeof(x), (type))
#endif
#ifndef same_type
# define same_type(x, y)    __builtin_types_compatible_p(typeof(x), typeof(y))
#endif
#ifndef __read_mostly
# define __read_mostly      __attribute__((__section__(".data.read_mostly")))
#endif
#ifndef __must_check
# define __must_check       /* unimplemented */
#endif
#ifndef __used
# define __used             /* unimplemented */
#endif
#ifndef __maybe_unused
# define __maybe_unused     /* unimplemented */
#endif
#ifndef __always_unused
# define __always_unused    /* unimplemented */
#endif
#ifndef noinline
# define noinline           __attribute__((noinline))
#endif
#ifndef __always_inline
# define __always_inline    inline
#endif
/*
 * Protected visibility is like default visibility except that it indicates 
 * that references within the defining module will bind to the definition 
 * in that module. That is, the declared entity cannot be overridden by 
 * another module.
 */
#ifndef __protected
# define __protected        __attribute__((visibility("protected")))
#endif
/*
 * Hidden visibility indicates that the entity declared will have a new form 
 * of linkage, which we'll call "hidden linkage". Two declarations of an 
 * object with hidden linkage refer to the same object if they are in the 
 * same shared object.
 */
#ifndef __hidden
# define __hidden           __attribute__((visibility("hidden")))
#endif
/*
 * Internal visibility is like hidden visibility, but with additional 
 * processor specific semantics. Unless otherwise specified by the psABI, 
 * GCC defines internal visibility to mean that a function is never called 
 * from another module. Compare this with hidden functions which, while they 
 * cannot be referenced directly by other modules, can be referenced 
 * indirectly via function pointers. By indicating that a function cannot be 
 * called from outside the module, GCC may for instance omit the load of a 
 * PIC register since it is known that the calling function loaded the 
 * correct value.
 */
#ifndef __internal
# define __internal         __attribute__((visibility("internal")))
#endif
#ifndef max
# define max(a, b)                         \
	({                                 \
		typeof (a) _a = (a);       \
		typeof (b) _b = (b);       \
		_a > _b ? _a : _b;         \
	})
#endif
#ifndef min
# define min(a, b)                         \
	({                                 \
		typeof (a) _a = (a);       \
		typeof (b) _b = (b);       \
		_a < _b ? _a : _b;         \
	})
#endif
#ifndef offsetof
# define offsetof(type, member) ((size_t) &((type *) 0)->member)
#endif
/*
 * Casts a member of a structure out to the containing structure.
 */
#ifndef container_of
# define container_of(ptr, type, member)                              \
	({                                                            \
		const typeof(((type *) 0)->member) * __mptr = (ptr);  \
		(type *) ((char *) __mptr - offsetof(type, member));  \
	})
#endif

#endif /* COMPILER_H */
