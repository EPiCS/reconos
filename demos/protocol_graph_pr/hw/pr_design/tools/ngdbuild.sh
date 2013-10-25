#!/bin/bash
  
ngdbuild -sd ../../syn/static -sd ../../syn/$1  -uc ../../data/system.ucf ../../syn/static/system.ngc system.ngd

