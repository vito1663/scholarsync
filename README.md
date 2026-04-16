# ScholarSync

AI 学术阅读器 —— 集文献管理、PDF 阅读、知识库 AI 问答于一体的原生桌面应用。

![Build Windows](https://github.com/YOUR_USERNAME/scholarsync/actions/workflows/build-windows.yml/badge.svg)

## 功能特性

- **文献管理**：本地文件夹管理，自动扫描 PDF，SQLite 元数据存储
- **PDF 阅读**：基于 QtPdf（PDFium）的原生渲染，支持多页滚动、缩放、全文搜索、注释
- **知识库同步**：文件夹一键同步到 RAGFlow 云端知识库，自动向量化
- **AI 问答**：基于 RAGFlow 的 RAG 问答，支持流式输出
- **文件夹监控**：实时监控文件夹变化，自动同步新增文献

## 下载

前往 [Releases](../../releases) 页面下载最新版本：

| 平台 | 文件 |
|------|------|
| Windows 10/11 | `ScholarSync-Windows-x64.zip` |
| Linux x86_64 | `ScholarSync-Linux-x64.zip` |

## 快速开始

### Windows

1. 下载并解压 `ScholarSync-Windows-x64.zip`
2. 安装 [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)（如未安装）
3. 双击 `ScholarSync.exe` 运行
4. 进入**设置**页面，填入 RAGFlow API Key

### Linux

```bash
unzip ScholarSync-Linux-x64.zip
cd ScholarSync_deploy/
sudo apt-get install -y libxcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
  libxcb-render-util0 libxcb-xinerama0 libxcb-xkb1 libxkbcommon-x11-0 libgl1
./run.sh
```

## 从源码编译

### 依赖

- Qt 6.6+ (QtPdf, QtQuick, QtNetwork, QtSql)
- CMake 3.21+
- C++17 编译器（MSVC 2019+ / GCC 11+ / Clang 13+）

### 编译步骤

```bash
git clone https://github.com/YOUR_USERNAME/scholarsync.git
cd scholarsync
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --parallel
```

### Windows（使用 Qt 安装的 CMake）

```powershell
cmake -B build -S . -DCMAKE_PREFIX_PATH="C:/Qt/6.6.3/msvc2019_64" -G "NMake Makefiles"
cmake --build build --config Release
windeployqt --qmldir qml build\ScholarSync.exe
```

## 配置 RAGFlow

在设置页面填入：

| 配置项 | 说明 |
|--------|------|
| API Key | 从 [cloud.ragflow.io](https://cloud.ragflow.io) 获取 |
| Base URL | `https://cloud.ragflow.io`（私有化部署时改为自己的地址） |

## 技术栈

| 层次 | 技术 |
|------|------|
| 桌面端 UI | Qt 6.6 + QML + QtQuick Controls 2 |
| PDF 渲染 | QtPdf（底层 PDFium） |
| 本地数据库 | SQLite（通过 Qt SQL） |
| 网络请求 | Qt Network（QNetworkAccessManager） |
| 云端知识库 | RAGFlow（Apache 2.0） |
| PDF 解析 | MinerU（私有化部署） |

## 开源协议

MIT License
