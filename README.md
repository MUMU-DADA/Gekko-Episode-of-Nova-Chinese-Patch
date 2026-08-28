# Gekko Episode of Nova Chinese Patch Archive

本目录保存汉化补丁的开发资料，不参与游戏运行。

## 运行目录中保留的文件

`BepInEx/plugins` 中的 `GekkoNovaPatch.dll` 和全部 `GekkoNova_*.tsv` 是运行时补丁文件，必须留在原位置。BepInEx 核心文件、游戏本体和 `*_Data` 目录也未移动。

运行时补丁的归档副本位于 `RuntimePatch/`。该目录是交付/备份副本；游戏实际加载的文件仍在 `BepInEx/plugins`。

## 归档内容

- `Tools/`：文本提取、校验、构建脚本和插件源码
- `TranslationWork/`：候选文本、工作说明和基础译表
- `Installers/`：BepInEx x86/x64 压缩包
- `BuildCache/`：构建时生成的 `.dotnet_home` 缓存
- `RuntimePatch/`：当前 DLL 和全部运行时译表的归档副本
- `Release/`：可直接解压到干净游戏根目录的发布 ZIP

## 重新构建

脚本保存在归档目录内，已支持从归档位置自动定位游戏根目录。重新构建时运行：

```powershell
.\TranslationPatch_Archive\Tools\BuildPatch.ps1
```

本次归档没有删除任何文件。
