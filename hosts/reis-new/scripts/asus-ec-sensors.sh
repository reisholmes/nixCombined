#!/bin/bash
sudo LLVM=true make clean
sudo LLVM=true make modules
sudo LLVM=true make modules_install
sudo LLVM=true make dkms_configure
sudo LLVM=true make dkms
sudo sensors-detect --auto
