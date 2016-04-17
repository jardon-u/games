#!/bin/bash

pushd $1
zip -9 -q -r ../$1.love .
popd
