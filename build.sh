#!/bin/bash
rm -r build
mkdir build
for i in ./trunk/SdlGraph*.pp; do
	fpc -FE./build $i
done
for i in ./examples/test*.pp; do
	fpc -FE./build $i
done