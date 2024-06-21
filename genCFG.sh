#!/bin/bash -e

# 1.编译kanalyzer and IRDumper ------------------------------------------------------------------

# 下载LLVM version: 15.0.0
ROOT=$(pwd)
if [ ! -d "llvm-project" ]; then
  git clone git@github.com:llvm/llvm-project.git
fi
cd $ROOT/llvm-project
git checkout e758b77161a7

if [ ! -d "build" ]; then
  mkdir build
fi
cd build
cmake -DLLVM_TARGET_ARCH="X86" \
			-DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64" \
			-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
			-DCMAKE_BUILD_TYPE=Release \
			-DLLVM_ENABLE_PROJECTS="clang;lldb" \
			-G "Unix Makefiles" \
			../llvm

make -j6

if [ ! -d "$ROOT/llvm-project/prefix" ]; then
  mkdir $ROOT/llvm-project/prefix
fi

cmake -DCMAKE_INSTALL_PREFIX=$ROOT/llvm-project/prefix -P cmake_install.cmake

# 修改mlta/src/lib/Config.h文件内的linux源目录文件
# define SOURCE_CODE_PATH "/path/to/linux"
cd $ROOT && make
cd IRDumper && make


# 2.构建bc文件 ----------------------------------------------------------------------------

# linux源文件绝对路径
KERNEL_SRC="/home/vscode/linux-5.1"

cd $ROOT
IRDUMPER="$(pwd)/IRDumper/build/lib/libDumper.so"
CLANG="$(pwd)/llvm-project/prefix/bin/clang"
KANALYZER="$ROOT/build/lib/kanalyzer"
CONFIG="allnoconfig"
NEW_CMD="\n\n\
KBUILD_USERCFLAGS += -Wno-error -g -Xclang -no-opaque-pointers -Xclang -flegacy-pass-manager -Xclang -load -Xclang $IRDUMPER\nKBUILD_CFLAGS += -Wno-error -g -Xclang -no-opaque-pointers -Xclang -flegacy-pass-manager -Xclang -load -Xclang $IRDUMPER"

# 生成makefile的back文件，防止污染原makefile文件
cd $KERNEL_SRC
make clean
if [ ! -f "Makefile.bak" ]; then
  cp Makefile Makefile.bak
fi

# 打印信息
echo $NEW_CMD >IRDumper.cmd
cat Makefile.bak IRDumper.cmd >Makefile

# 构建linux的config文件
make $CONFIG

# 构建linux的bc文件
make CC=$CLANG -j`nproc` -k -i

# 创建bc.list，用于存放所有的bc文件路径
cd $ROOT
if [ -f "$ROOT/bc.list" ]; then
  rm bc.list
fi
touch bc.list

# 把所有的bc文件的路径放入到bc.list
find $KERNEL_SRC -name "*.bc" > bc.list


# 3.使用kanalyzer分析bc文件，结果放在result.txt  --------------------------------------

$KANALYZER @bc.list &> result.txt
