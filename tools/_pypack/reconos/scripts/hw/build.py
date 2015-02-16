import reconos.utils.shutil2 as shutil2
import reconos.utils.preproc as preproc

import logging
import argparse
import subprocess

log = logging.getLogger(__name__)

def get_cmd(prj):
	return "build_hw"

def get_call(prj):
	return build_xil_ise

def get_parser(prj):
	parser = argparse.ArgumentParser("build_hw", description="""
		Builds the hardware project and generates a bitstream to
		be downloaded to the FPGA.
		""")
	return parser

def build_xil_ise(args):
	prj = args.prj

	try:
		shutil2.chdir(prj.hwdir)
	except:
		log.error("hardware directory '" + prj.hwdir + "' not found")
		return
	
	subprocess.call("""
	  source /opt/Xilinx/""" + prj.ise + """/ISE_DS/settings64.sh;
	  echo -e "run hwclean\nrun netlist\nexit\n" | xps -nw system""",
	  shell=True)

	print()
	shutil2.chdir(prj.dir)