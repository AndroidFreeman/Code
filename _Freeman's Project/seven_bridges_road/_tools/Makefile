# _tools/Makefile

CC = clang
CFLAGS = -O3 -Wall
TARGET = ../build/linux/x64/release/bundle/tools/backend_tool
# 兼容调试模式的路径处理
DEBUG_TARGET = ../build/linux/x64/debug/bundle/tools/backend_tool

all:
	@mkdir -p ../build/linux/x64/release/bundle/tools
	@mkdir -p ../build/linux/x64/debug/bundle/tools
	$(CC) $(CFLAGS) backend.c -o $(TARGET)
	$(CC) $(CFLAGS) backend.c -o $(DEBUG_TARGET)
	@echo "LLVM 编译完成: $(TARGET)"

clean:
	rm -f $(TARGET) $(DEBUG_TARGET)