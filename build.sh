#!/bin/sh
rm -r build
mkdir build
for i in ./trunk/SdlGraph*.pp; do
	fpc -O2 -FE./build $i
done
for i in ./examples/test*.pp; do
	fpc -O2 -FE./build $i
done
for i in ./examples/test*.pas; do
	fpc -O2 -FE./build $i
done