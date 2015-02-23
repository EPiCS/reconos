import reconos.utils.shutil2 as shutil2
import reconos.utils.preproc as preproc

import logging
import argparse
import subprocess

log = logging.getLogger(__name__)

def get_cmd(prj):
	return "build_sw"

def get_call(prj):
	return build

def get_parser(prj):
	parser = argparse.ArgumentParser("build_sw", description="""
		Builds the software project and generates an executable.
		""")
	return parser

def build(args):
	prj = args.prj
	swdir = prj.basedir + ".sw"

	try:
		shutil2.chdir(swdir)
	except:
		log.error("software directory '" + swdir + "' not found")
		return
	
	subprocess.call("make", shell=True)

	print()
	shutil2.chdir(prj.dir)