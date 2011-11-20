#!/bin/bash
cd "$(dirname -- "$0")"
make clean; make && cp physics_bullet.so ../../
