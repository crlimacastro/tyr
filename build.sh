#!/bin/sh

cd odin-imgui
python build.py
cd ..
odin build examples/hellope_tyr -debug
