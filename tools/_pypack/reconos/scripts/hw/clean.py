import reconos.utils.shutil2 as shutil2

import logging
import argparse
import subprocess

log = logging.getLogger(__name__)

def get_cmd(prj):
	return "clean_hw"

def get_call(prj):
	return clean_xil_ise

def get_parser(prj):
	parser = argparse.ArgumentParser("clean_hw", description="""
		Cleans the hardware project.
		""")
	parser.add_argument("-r", "--remove", help="remove entire hardware directory", action="store_true")
	return parser



def clean_xil_ise(args):
	prj = args.prj
	hwdir = prj.basedir + ".hw"

	if args.remove:
		shutil2.rmtree(hwdir)
	else:
		try:
			shutil2.chdir(hwdir)
		except:
			log.error("hardware directory '" + hwdir + "' not found")
			return
		
		subprocess.call("""
		  source /opt/Xilinx/""" + prj.ise + """/ISE_DS/settings64.sh;
		  echo -e "run clean\nexit\n" | xps -nw system""",
		  shell=True)

		print()
		shutil2.chdir(prj.dir)