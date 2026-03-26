# LBG 终极跨平台编译脚本
BIN_DIR = ../bin
LINUX_DIR = $(BIN_DIR)/linux
WIN_DIR = $(BIN_DIR)/windows
AND_DIR = $(BIN_DIR)/android

CC_LIN_ = clang
CC_WIN_ = x86_64-w64-mingw32-gcc
# 指定为你刚才看到的 35 版本
CC_AND_ = /opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android35-clang

CFLAGS = -O3 -Wall
SRCS = find.c insert.c backup.c get_count.c delete.c

all: linux windows android

linux:
	@mkdir -p $(LINUX_DIR)
	@for f in $(SRCS); do $(CC_LIN_) $(CFLAGS) $$f -o $(LINUX_DIR)/$${f%.c}.so; done
	@echo "  Linux 编译完成"

windows:
	@mkdir -p $(WIN_DIR)
	@for f in $(SRCS); do $(CC_WIN_) $(CFLAGS) $$f -o $(WIN_DIR)/$${f%.c}.exe; done
	@echo "  Windows 编译完成"

android:
	@mkdir -p $(AND_DIR)
	@for f in $(SRCS); do $(CC_AND_) $(CFLAGS) $$f -o $(AND_DIR)/$${f%.c}.bin; done
	@echo "  Android ARM64 编译完成"

clean:
	rm -rf $(BIN_DIR)

.PHONY: all linux windows android clean