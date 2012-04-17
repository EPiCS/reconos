#include <errno.h>

#include "plugin.h"
#include "loader.h"

static struct plugin_instance *table[MAX_PLUGINS] = {0};
static int count = 0;

int register_plugin_instance(struct plugin_instance *pi)
{
	if (!pi->name || !pi->basename || pi->type == TYPE_INVALID ||
	    !pi->fetch || pi->schedule_int == 0)
		return -EINVAL;
	if (count + 1 > MAX_PLUGINS)
		return -ENOMEM;
}

void unregister_plugin_instance(struct plugin_instance *pi)
{
}
