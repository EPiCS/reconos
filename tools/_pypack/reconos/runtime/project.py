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
#   description:  Representation of a ReconOS project.
# 
# ======================================================================

import reconos.utils.shutil2 as shutil2

import logging
import configparser
import re

log = logging.getLogger(__name__)

#
# Class representing a clock in the project.
#
class Clock:
	_id = 0

	def __init__(self, name, source, freq):
		self.id = Resource._id
		Resource._id += 1
		self.name = name
		self.source = source
		self.freq = freq

	def get_pllparam(self, vcomin, vcomax, infreq):
		dfmin = 1000000000
		for m in range(vcomin // infreq, vcomax // infreq + 1):
			for o in range(1, 101):
				if dfmin > abs(self.freq - infreq * m // o):
					dfmin = abs(self.freq - infreq * m // o)
					mopt = m
					oopt = o

		return (mopt, oopt, infreq * mopt // oopt)

	def __str__(self):
		return "Clock '" + self.name + "'"

	def __repr__(self):
		return "'" + self.name + "' (" + str(self.id) + ")"

#
# Class representing a resource in the project.
#
class Resource:
	_id = 0

	def __init__(self, name, type_, args, group):
		self.id = Resource._id
		Resource._id += 1
		self.name = name
		self.type = type_
		self.args = args
		self.group = group

	def __str__(self):
		return "Resource '" + self.name + "'"

	def __repr__(self):
		return "'" + self.name + "' (" + str(self.id) + ")"

#
# Class representing a slot in the project.
#
class Slot:
	def __init__(self, name, id_, clock):
		self.name = name
		self.id = id_
		self.clock = clock
		self.threads = []

	def __str__(self):
		return "Slot '" + self.name + "' (" + str(self.id) + ")"

	def __repr__(self):
		return "'" + self.name + "' (" + str(self.id) + ")"

#
# Class representing a thread in the project.
#
class Thread:
	_id = 0

	def __init__(self, name, slots, hw, sw, res):
		self.Id = Thread._id
		Thread._id += 1
		Thread.name = name
		Thread.slots = slots
		Thread.hwsource = hw
		Thread.swsource = sw
		Thread.resources = res

	def get_corename(self):
		reg = r"(?P<name>[a-zA-Z0-9_]*)_(?P<vers>v[0-9]+_[0-9]{2}_[a-z])"
		return re.search(reg, self.hwsource).group("name")

	def get_coreversion(self):
		reg = r"(?P<name>[a-zA-Z0-9_]*)_(?P<vers>v[0-9]+_[0-9]{2}_[a-z])"
		return re.search(reg, self.hwsource).group("vers").replace("_", ".")[1:]

	def get_swentry(self):
		if self.swsource is None or self.swsource == "":
			return "swt_idle"

		reg = r"(?P<name>[a-zA-Z0-9_]*)_(?P<vers>v[0-9]+_[0-9]{2}_[a-z])"
		return re.search(reg, self.swsource).group("name")

	def __str__(self):
		return "Thread '" + self.name + "' (" + str(self.id) + ")"

	def __repr__(self):
		return "'" + self.name + "' (" + str(self.id) + ")"


#
# Class representing a project and providing different functionality
# for performing all relevant tasks.
#
class Project:

	#
	# Initialization of a new project.
	#
	def __init__(self, repo=None):
		self.clocks = []
		self.resources = []
		self.slots = []
		self.threads = []

		self.dir = ""
		self.name = ""
		self.board = ""
		self.refdesign = ""
		self.os = ""
		self.ise = ""
		self.clock = None
		self.cflags = ""
		self.ldflags = ""



		if repo is not None and shutil2.isdir(repo):
			self.repo = repo
		elif shutil2.environ("RECONOS"):
			self.repo = shutil2.environ("RECONOS")
		else:
			log.error("ReconOS repository not found")

	def get_hwref(self):
		os = str(self.os)
		board = "_".join(self.board)
		refdesign = self.refdesign
		ise = self.ise

		ref = "zynq_" + os + "_" + board + "_" + refdesign + "_" + ise
		return shutil2.join(self.repo, "designs", ref)

	def get_swref(self):
		os = str(self.os)

		return shutil2.join(self.repo, os, "project")

	def get_simref(self):
		return shutil2.join(self.repo, "testbench")


	#
	# Opens a project by parsing the project file.
	#
	#   filepath - path to the project file (*.cfg)
	#
	def open(self, filepath):
		self.clocks = []
		self.resources = []
		self.slots = []
		self.threads = []
		self.file = shutil2.abspath(filepath)
		self.dir = shutil2.dirname(self.file)
		self.basedir = shutil2.trimext(self.file)
		#self.hwdir = shutil2.trimext(self.file) + ".hw"
		#self.swdir = shutil2.trimext(self.file) + ".sw"

		cfg = configparser.RawConfigParser()
		cfg.optionxform = str
		ret = cfg.read(filepath)
		if not ret:
			log.error("Config file '" + filepath + "' not found")
			return

		self._parse_project(cfg)

	#
	# Internal method parsing the project from the project file.
	#
	#   cfg - configparser referencing the project file
	#
	def _parse_project(self, cfg):
		self.name = cfg.get("General", "Name")
		self.board = re.split(r"[, ]+", cfg.get("General", "TargetBoard"))
		self.refdesign = cfg.get("General", "ReferenceDesign")
		self.os = cfg.get("General", "TargetOS")
		self.ise = cfg.get("General", "TargetISE")
		if cfg.has_option("General", "CFlags"):
			self.cflags = cfg.get("General", "CFlags")
		else:
			self.cflags = ""
		if cfg.has_option("General", "LdFlags"):
			self.ldflags = cfg.get("General", "LdFlags")
		else:
			self.ldflags = ""
		log.debug("Found project '" + str(self.name) + "' (" + str(self.board) + "," + str(self.os) + ")")

		self._parse_clocks(cfg)
		self._parse_resources(cfg)
		self._parse_slots(cfg)
		self._parse_threads(cfg)

		clock = [_ for _ in self.clocks if _.name == cfg.get("General", "SystemClock")]
		if not clock:
			log.error("Clock not found")
		self.clock = clock[0]

	#
	# Internal method parsing the clocks from the project file.
	#
	#   cfg - configparser referencing the project file
	#
	def _parse_clocks(self, cfg):
		for c in [_ for _ in cfg.sections() if _.startswith("Clock")]:
			match = re.search(r"^.*@(?P<name>.+)", c)
			if match is None:
				log.error("Clock must have a name")

			name = match.group("name")
			source = cfg.get(c, "ClockSource")
			freq = cfg.getint(c, "ClockFreq")

			log.debug("Found clock '" + str(name) + "' (" + str(source) + "," + str(freq / 1000000) + " MHz)")

			clock = Clock(name, source, freq)
			self.clocks.append(clock)

	#
	# Internal method parsing the resources from the project file.
	#
	#   cfg - configparser referencing the project file
	#
	def _parse_resources(self, cfg):
		for c in [_ for _ in cfg.sections() if _.startswith("ResourceGroup")]:
			match = re.search(r"^.*@(?P<name>.+)", c)
			if match is None:
				log.error("Resources must have a name")

			group = match.group("name")

			for r in cfg.options(c):
				match = re.split(r"[, ]+", cfg.get(c, r))

				log.debug("Found resource '" + str(r) + "' (" + str(match[0]) + "," + str(match[1:]) + "," + str(group) + ")")
			
				resource = Resource(r, match[0], match[1:], group)
				self.resources.append(resource)

	#
	# Internal method parsing the slots from the project file.
	#
	#   cfg - configparser referencing the project file
	#
	def _parse_slots(self, cfg):
		for s in [_ for _ in cfg.sections() if _.startswith("HwSlot")]:
			match = re.search(r"^.*@(?P<name>.*)\((?P<start>[0-9]*):(?P<end>[0-9]*)\)", s)
			if match is None:
				r = range(0)
			else:
				r = range(int(match.group("start")), int(match.group("end")) + 1)

			name = match.group("name")
			id_ = cfg.getint(s, "Id")
			clock = [_ for _ in self.clocks if _.name == cfg.get(s, "Clock")]
			if not clock:
				log.error("Clock not found")

			for i in r:
				log.debug("Found slot '" + str(name) + "(" + str(i) + ")" + "' (" + str(id_) + "," + str(clock[0]) + ")")

				slot = Slot(name + "(" + str(i) + ")", id_ + i, clock[0])
				self.slots.append(slot)

	#
	# Internal method parsing the threads from the project file.
	#
	#   cfg - configparser referencing the project file
	#
	def _parse_threads(self, cfg):
		for t in [_ for _ in cfg.sections() if _.startswith("ReconosThread")]:
			match = re.search(r"^.*@(?P<name>.+)", t)
			if match is None:
				log.error("Thread must have a name")

			name = match.group("name")
			slots = cfg.get(t, "Slot")
			slots = slots.replace("(", "\\(")
			slots = slots.replace(")", "\\)")
			slots = slots.replace(",", "|")
			slots = slots.replace("*", ".*")
			slots = [_ for _ in self.slots if re.match(slots, _.name) is not None]
			if cfg.has_option(t, "HwSource"):
				hw = cfg.get(t, "HwSource")
			else:
				hw = None
				log.error("No HwSource found")
			if cfg.has_option(t, "SwSource"):
				sw = cfg.get(t, "SwSource")
			else:
				sw = None
			if cfg.has_option(t, "ResourceGroup"):
				res = [_ for _ in self.resources if _.group == cfg.get(t, "ResourceGroup")]
				if not res:
					log.error("ResourceGroup not found")
			else:
				res = []

			log.debug("Found thread '" + str(name) + "' (" + str(slots) + "," + str(hw) + "," + str(sw) + "," + str(res) + ")")

			thread = Thread(name, slots, hw, sw, res)
			for s in slots: s.threads.append(thread)
			self.threads.append(thread)