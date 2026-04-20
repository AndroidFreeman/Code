# Life's Been Good System

Life's Been Good System 是一个本地化的班级与校园管理应用。项目前端基于 Flutter 构建，底层数据逻辑由 C++ 原生实现，所有核心数据均以纯文本（CSV/JSON）格式保存在本地设备中。

## 技术栈

- 前端：Flutter (Dart)
- 状态管理：Provider
- 后端：C++17 (通过 Native CLI 与前端交互)
- 存储：本地 CSV 与 JSON

## 编译与运行说明

本项目强依赖 C++ 原生模块进行本地数据读写。在运行 Flutter 项目之前，必须先编译 C++ 源码，否则应用将无法正常工作。

### 1. 环境依赖
- Flutter SDK (>=3.5.0)
- C++ 编译工具链 (Windows 需配置 MSVC 或 MinGW，macOS/Linux 需配置 GCC 或 Clang)

### 2. 编译 C++ 模块
进入原生模块目录并执行对应的构建脚本，编译产物会自动存放到所需的 bin 目录下。

Windows 系统 (PowerShell):
```powershell
cd native/features
./build.ps1
```

macOS / Linux 系统 (Shell):
```bash
cd native/features
./build.sh
```

### 3. 运行 Flutter 项目
回到项目根目录，获取依赖并运行：
```bash
flutter pub get
flutter run
```

## 目录结构

- `lib/` : Flutter 业务代码（包含 UI 页面、数据模型、状态管理）
- `native/` : C++ 原生模块源码（包含定制的 CSV 解析与业务判定逻辑）
- `scripts/` : 构建与测试脚本
- `windows/`、`macos/`、`linux/` : 桌面端原生工程文件

这个源码我会放到Github上, 我把这个项目开源.

## Open Source License (GPLv2) 

This project is licensed under the GNU General Public License v2.0 (GPLv2).

Copyright (c) 2026

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

*(Note: This project includes/uses dependencies that are licensed under the MIT License. The MIT License is fully compatible with GPLv2, allowing those components to be integrated into this GPL-licensed project.)*