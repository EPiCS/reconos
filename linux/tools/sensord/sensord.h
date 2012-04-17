/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef SENSORD_H
#define SENSORD_H

#define __init			/* unimplemented */
#define __exit			/* unimplemented */

#define plugin_init(fn)		int plugin_init_fn(void) { return (fn)(); }
#define plugin_exit(fn)		void plugin_exit_fn(void) { (fn)(); }

#define PLUGIN_LICENSE(x)	/* unimplemented */
#define PLUGIN_AUTHOR(x)	/* unimplemented */
#define PLUGIN_DESC(x)		/* unimplemented */

#endif /* SENSORD_H */
