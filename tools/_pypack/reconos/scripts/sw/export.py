import reconos.utils.shutil2 as shutil2
import reconos.utils.preproc as preproc

import logging
import argparse

log = logging.getLogger(__name__)

def get_cmd(prj):
	return "export_sw"

def get_call(prj):
	return export_xil_ise

def get_parser(prj):
	parser = argparse.ArgumentParser("export_hw", description="""
		Exports the software project and generates all necessary files.
		""")
	parser.add_argument("-l", "--link", help="link sources instead of copying", default=False, action="store_true")
	return parser

def export_xil_ise(args):
	prj = args.prj
	swdir = prj.basedir + ".sw"

	logging.info("Export software to project directory '" + prj.dir + "'")

	dictionary = {}
	dictionary["NUM_SLOTS"] = len(prj.slots)
	dictionary["NAME"] = prj.name.lower()
	dictionary["OS"] = prj.os.lower()
	dictionary["BOARD"] = "_".join(prj.board)
	dictionary["CFLAGS"] = prj.cflags
	dictionary["LDFLAGS"] = prj.ldflags
	dictionary["THREADS"] = []
	dictionary["SWDIR"] = swdir
	for t in prj.threads:
		d = {}
		d["Name"] = t.name.lower()
		d["Slots"] = ",".join([str(_.id) for _ in t.slots])
		d["SlotCount"] = len(t.slots)
		d["Resources"] = ",".join([("&" + t.name + "_" + _.group + "_" + _.name).lower() + "_res" for _ in t.resources])
		d["ResourceCount"] = len(t.resources)
		d["SwEntry"] = t.get_swentry()
		dictionary["THREADS"].append(d)
	dictionary["RESOURCES"] = []
	i = 0
	for t in prj.threads:
		for r in t.resources:
			d = {}
			d["FqnUpper"] = (t.name + "_" + r.group + "_" + r.name).upper()
			d["FqnLower"] = (t.name + "_" + r.group + "_" + r.name).lower()
			d["FqnLowerRes"] = (t.name + "_" + r.group + "_" + r.name + "_res").lower()
			d["Id"] = i
			d["HexId"] = "%08x" % i
			d["Type"] = r.type
			d["TypeUpper"] = r.type.upper()
			d["Args"] = ", ".join(r.args)
			dictionary["RESOURCES"].append(d)
			i += 1

	logging.info("Copying reference design to project folder ...")
	shutil2.mkdir(swdir)
	shutil2.copytree(prj.get_swref(), swdir, followlinks=True)

	logging.info("Linking sources ...")
	if args.link:
		shutil2.linktree(shutil2.join(prj.dir, "src/application"), swdir)
	else:
		shutil2.copytree(shutil2.join(prj.dir, "src/application"), swdir)

	for t in prj.threads:
		if t.swsource is None or t.swsource == "":
			continue

		thread = shutil2.join(prj.dir, "src", t.swsource)
		if args.link:
			shutil2.symlink(thread, shutil2.join(swdir, t.swsource))
		else:
			shutil2.mkdir(shutil2.join(swdir, t.swsource))
			shutil2.copytree(thread, shutil2.join(swdir, t.swsource))

	logging.info("Generating project ...")
	dictionary["REPO_REL"] = shutil2.relpath(prj.repo, swdir)
	dictionary["OBJS"] = [{"Source": shutil2.trimext(_) + ".o"}
	                       for _ in shutil2.listfiles(swdir, True, ".c")]

	def pp(f): return preproc.preproc(f, dictionary, "overwrite")
	shutil2.walk(swdir, pp)