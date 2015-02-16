#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS - Toolchain
#   author:       Christoph Rüthing, University of Paderborn
#   description:  A preprocessor parsing source files.
# 
# ======================================================================

import re

#
# Internal method used for replacing each occurence of a generate
# statement in the source file.
#
#   d - dictionary including the used keys
#
def _generate(d):
	def _generate_(m):
		if m.group("key") not in d:
			return ""

		if type(d[m.group("key")]) is bool:
			return m.group("data")

		if type(d[m.group("key")]) is not list:
			return ""

		data = ""
		for i, r in enumerate(d[m.group("key")]):
			l = {"_i" : i}
			l.update(r)

			if m.group("cond") is not None and not eval(m.group("cond"), l):
				continue

			ndata = m.group("data")

			reg = r"<<(?P<key>[A-Za-z0-9_]+)(?:\((?P<join>.*?)\))?>>"
			def repl(m):
				if m.group("key") in l:
					return str(l[m.group("key")]) 
				else:
					return "<<" + m.group("key") + ">>"
			ndata = re.sub(reg, repl, ndata)

			reg = r"<<c(?P<data>.)>>"
			if i < len(d[m.group("key")]) - 1:
				ndata = re.sub(reg, "\g<data>", ndata)
			else:
				ndata = re.sub(reg, "", ndata)

			if ndata.count("\n") > 1:
				ndata += "\n"

			data += ndata

		return data

	return _generate_


#
# Preprocesses the given file using a dictionary containing keys and
# a list of values.
#
#   filepath   - path to the file to preprocess
#   dictionary - dictionary conaining all keys
#   mode       - print or overwrite to print to stdout or overwrite
#
def preproc(filepath, dictionary, mode):
	with open(filepath, "r") as file:
		try:
			data = file.read()
		except:
			return

	if "<<reconos_preproc>>" not in data:
		return
	else:
		data = re.sub(r"<<reconos_preproc>>", "", data)

	reg = r"<<generate for (?P<key>[A-Za-z0-9_]*?)(?:\((?P<cond>.*?)\))?>>\n?(?P<data>.*?)<<end generate>>"
	data = re.sub(reg, _generate(dictionary), data, 0, re.DOTALL)

	reg = r"<<(?P<key>[A-Za-z0-9_]+)>>"
	def repl(m): 
		if m.group("key") in dictionary:
			return str(dictionary[m.group("key")])
		else:
			return "@"
	data = re.sub(reg, repl, data)

	if mode == "print":
		print(data)
	elif mode == "overwrite":
		with open(filepath, "w") as file:
			file.write(data)
	else:
		logging.error("Unknonwn mode")