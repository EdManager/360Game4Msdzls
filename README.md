# 360游戏大厅For美食大战老鼠

本安装器为 360游戏大厅 的自定义部署版本，基于 Inno Setup 构建；支持标准与自定义两种安装模式，内置多版本 Flash 支持、配置自动适配等特性；内置说明文件包含美食大战老鼠各平台登入链接，以便玩家添加游戏。

---

## 📦 安装功能

- 所有资源打包为单个安装包（.exe）；
- 两种安装模式：
  - ✅ **标准安装**：默认使用 V5 版本大厅 + Flash 25（懒人专属，未支持兼容模式）
  - 🔧 **自定义安装**：可手动选择大厅版本（V5 / V6）、Flash 版本（13 / 25 / 34）
- 自动安装 ActiveX 控件（V5版本勾选启用兼容模式时）；
- 安装前自动结束后台进程、清理残留文件与注册表；
- INI 配置文件自动设置大厅主页取消勾选除小号列表外的选项、游戏窗口只默认显示键鼠记忆与加速功能（默认3倍速）。

---

## 📂 安装路径说明

| 路径 | 说明 |
|------|------|
| `%APPDATA%\360Game5\` | 主程序路径（可自定义） |
| `%APPDATA%\360Game5\data\` | INI 配置与 Flash 运行文件固定位置 |
| `%APPDATA%\360se6` | 特殊文件占位路径 |
| 桌面 | 可选创建快捷方式 |

---

## ⚙️ 安装步骤

1. 运行安装器，选择“标准安装”或“自定义安装”；
2. 若为自定义安装：选择大厅版本、Flash 版本、是否启用兼容模式（仅 V5 支持）；
3. 自动执行以下操作：
   - 结束 `360Game.exe` 进程
   - 清理旧数据文件夹和注册表项
   - 提取并复制公共文件与特定版本文件
   - 安装 Flash DLL / OCX
   - 更新 `360Game.ini` 用户名字段
4. 安装完成后将显示提示，建议选择“查看说明文件”。

---

## 🔁 卸载说明

通过控制面板或卸载程序可移除所有文件与注册表项，包括：

- 游戏大厅主程序；
- Flash 控件及其配置；
- 桌面快捷方式与注册信息。

---

## 🚫 注意事项

- 关闭大厅游戏窗口时可能会被询问“是否添加桌面快捷方式”，请务必选择“取消”，否则会被添加右下角托盘图标，且可能出现更多弹窗；
- Flash 兼容模式适用于 V5 + Flash 13/34 组合，Flash 25 将自动使用 Flash 34 模拟运行。

---

## 🛠️ 开发 & 编译

本项目基于 **Inno Setup 6.4.1 (支持简体中文语言文件)** 编译构建，支持 Unicode 与 Modern UI。

### 使用环境要求
- 建议使用 Inno Setup 汉化版本（支持 `compiler:Default.isl` 与简体中文 UI）；
- 原版 Inno Setup 不包含 `chinese.isl`，请自行配置或参考汉化版环境（非官方提供，用户需自行获取）。

### 编译步骤
1. 使用 Inno Setup Compiler 打开安装脚本（.iss 文件）；
2. 确保文件结构同 [file_structure](file_structure.txt)（示例结构请参考 [root](root) 目录）；
3. 在资源文件中：
- 删除 `360GameLiveUpdate.dll`
- 复制 `360GameIPC.dll`，并重命名为 `360GameLiveUpdate.dll`（用于阻止大厅更新弹窗）
4. 运行编译，生成单文件 EXE 安装包。

---

## 🧪 关于 360Game.ini 的配置说明

大厅程序会自动生成 `360Game.ini` 配置文件，建议使用官方版本手动打开程序一次，并完成以下设置：

1. 在主页设置窗口中取消勾选除 `默认显示小号列表` 外的所有基本设置，并在代理设置中选择 `不使用代理服务器`；
2. 在任意游戏窗口中切换为极速模式，并在工具栏管理中取消除键鼠记忆和变速外的功能显示（需默认显示工具栏，推荐自定义变速速度为 `3.00x` ）；
3. 设置完成后，彻底关闭大厅程序；
4. 配置文件位于 `%APPDATA%\360Game5\data\360Game.ini`，可备份用于后续自动部署；
5. 将配置文件中的 npflash 路径设置为 `C:\Users\Administrator\AppData\Roaming\360Game5\data\NPSWF.dll`，同理将 axflash 定义至相同位置下文件 `Flash.ocx`。

⚠️ 本项目不会提供该 `.ini` 文件本体，如需预配置，请参考上述方式生成。

