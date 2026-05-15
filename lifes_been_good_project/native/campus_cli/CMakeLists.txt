cmake_minimum_required(VERSION 3.10)
project(campus_cli)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 1. 搜集源码
set(MAIN_SRC campus_cli.c)
file(GLOB_RECURSE FEATURE_SRCS "../features/*.cpp")

# 2. 关键：删除之前所有的 add_definitions 或 set_source_files_properties 宏定义
# 让我们回归正常编译，不搞宏替换

include_directories("../features")

# 3. 核心：给链接器下达“允许重复定义”的死命令
# 这样当它发现 features 里的 main 时，会报警告但不会停止，最终保留主程序的入口
if(UNIX)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--allow-multiple-definition")
endif()

# 4. 生成可执行文件
add_executable(campus_cli ${MAIN_SRC} ${FEATURE_SRCS})

find_package(Threads REQUIRED)
target_link_libraries(campus_cli PRIVATE Threads::Threads)
