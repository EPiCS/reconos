import reconos.utils.shutil2 as shutil2
import reconos.utils.preproc as preproc

import logging
import argparse

log = logging.getLogger(__name__)

def get_cmd(prj):
	return "export_sim"

def get_call(prj):
	return export_xil_ise

def get_parser(prj):
	parser = argparse.ArgumentParser("export_sim", description="""
		Creates a testbench to simulate a single hardware thread.
		""")
	parser.add_argument("thread", help="ReconOS thread to create testbench for")
	parser.add_argument("-l", "--link", help="link sources instead of copying", action="store_true")
	parser.add_argument("simdir", help="alternative export directory", nargs="?")
	return parser

def export_xil_ise(args):
	prj = args.prj
	simdir = args.simdir if args.simdir is not None else prj.basedir + ".sim"

	log.info("Generating testbench for thread " + args.thread + " to '" + simdir + "'")

	threads = [_ for _ in prj.threads if _.name == args.thread]
	if (len(threads) == 1):
		thread = threads[0]
		thread_src = shutil2.join(prj.dir, "src", thread.hwsource)
		thread_dst = shutil2.join(simdir, "threads", thread.hwsource)
	else:
		log.info("Thread '" + args.thread  + "' not found")
		return

	dictionary = {}
	dictionary["THREAD_SRCS"] = []
	for f in shutil2.listfiles(thread_src, rec=True, ext=".vhd"):
		d = {}
		d["Path"] = shutil2.join("threads", thread.hwsource, f)
		dictionary["THREAD_SRCS"].append(d)
	dictionary["Thread"] = thread.get_corename()


	log.info("Copying reference design to project folder ...")
	shutil2.mkdir(simdir)
	shutil2.copytree(prj.get_simref(), simdir, followlinks=True)

	log.info("Copying thread to testbench ...")
	shutil2.mkdir(shutil2.join(simdir, "threads"))
	if args.link:
		shutil2.symlink(thread_src, thread_dst)
	else:
		shutil2.mkdir(thread_dst)
		shutil2.copytree(thread_src, thread_dst)

	log.info("Generating testbench ...")
	def pp(f): return preproc.preproc(f, dictionary, "overwrite")
	shutil2.walk(simdir, pp)


	# dictionary["NUM_SLOTS"] = len(prj.slots)
	# dictionary["NUM_CLOCKS"] = len(prj.clocks)
	# dictionary["SYSCLK"] = prj.clock.id
	# dictionary["SYSRST"] = "SYSRESET"
	# dictionary["SLOTS"] = []
	# for s in prj.slots:
	# 	d = {}
	# 	d["HwtCoreName"] = s.threads[0].get_corename()
	# 	d["HwtCoreVersion"] = s.threads[0].get_coreversion()
	# 	d["Id"] = s.id
	# 	d["Clk"] = s.clock.id
	# 	d["Async"] = "sync" if s.clock == prj.clock else "async"
	# 	dictionary["SLOTS"].append(d)
	# dictionary["CLOCKS"] = []
	# for c in prj.clocks:
	# 	d = {}
	# 	d["Id"] = c.id
	# 	d["ReqFreqKHz"] = c.freq / 1000
	# 	param = c.get_pllparam(800000000, 1600000000, 100000000)
	# 	d["ActFreqKHz"] = param[2] / 1000
	# 	d["M"] = param[0]
	# 	d["O"] = param[1]

	# 	dictionary["CLOCKS"].append(d)
	# dictionary["RESOURCES"] = []
	# i = 0
	# for t in prj.threads:
	# 	for r in t.resources:
	# 		d = {}
	# 		d["FqnUpper"] = (t.name + "_" + r.group + "_" + r.name).upper()
	# 		d["Id"] = i
	# 		d["HexId"] = "%08x" % i
	# 		dictionary["RESOURCES"].append(d)
	# 		i += 1

	# log.info("Copying reference design to project folder ...")
	# shutil2.mkdir(hwdir)
	# shutil2.copytree(prj.get_hwref(), hwdir, followlinks=True)

	# log.info("Copying pcores ...")
	# shutil2.mkdir(shutil2.join(hwdir, "pcores"))
	# shutil2.copytree(shutil2.join(prj.repo, "pcores"),
	#                  shutil2.join(hwdir, "pcores"),
	#                  followlinks=True);

	# log.info("Linking sources ...")
	# for t in prj.threads:
	# 	thread = shutil2.join(prj.dir, "src", t.hwsource)
	# 	if args.link:
	# 		shutil2.symlink(thread, shutil2.join(hwdir, "pcores", t.hwsource))
	# 	else:
	# 		shutil2.mkdir(shutil2.join(hwdir, "pcores", t.hwsource))
	# 		shutil2.copytree(thread, shutil2.join(hwdir, "pcores", t.hwsource))

	# log.info("Generating project ...")
	# def pp(f): return preproc.preproc(f, dictionary, "overwrite")
	# shutil2.walk(hwdir, pp)
