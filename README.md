# Generate accurate CFG of Linux Kernel by mlta

Before all, Download the linux kernel source.

Make sure the path to kernel souce in `src/lib/Config.h` is correct.

define SOURCE_CODE_PATH "/home/vscode/linux-5.1"

## Experiment Environment
```sh
sudo apt install cmake
sudo apt install g++-10
sudo apt install g++
```
+ VMWare虚拟机
+ Ubuntu 22.02 LTS
+ Linux Kenel 5.1
  +  sudo apt install flex
  +  sudo apt install bison

## Generate the CFG 
```sh 
	$ ./genCFG.sh 
```
