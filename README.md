# luat
合宙AirM2M open source project

## 合宙开源项目用户开发一般步骤
如果用户手上已经有合宙标准模块开发板或客户用合宙标准模块Air200开发的自己的板子，此时就具备实体开发调试的基本条件了。

### 第一步:编写lua代码
从github clone合宙开源代码到本地电脑，并进行自开发。

\core是模块基础软件，支持AT命令的解析和lua的运行。内含合宙自己开发的lua扩展库（位于\core\cust_src\elua\modules\src），扩展库文档位于\doc目录中。

\script是合宙范例LUA脚本，whole_project 是一款已经商用的定位器，可以下到合宙Air200 EVB开发板中运行。合宙EVB开发板对应的硬件参考和AT命令位于\doc\Air200。 timer、 UART 等是针对各单个应用或功能的示例代码。 lib 是所有用户脚本都需要用到的库文件，这些常用的库文件将AT命令以函数形式封装，方便用户使用。

用户在开发中所用LUA编辑工具lua5.1 for Windows以及合宙开源lua项目的开发步骤，请参考\doc\模块LUA程序设置指南 这篇文档。
luaforWindows 5.1 放在合宙百度云盘http://pan.baidu.com/s/1eSxFHrs -> tools 和合宙开源社区 www.openluat.com -> Air200模块技术开发 -> tools。

### 第二步：安装合宙lua开源项目编译调试环境Cygwin
CSDTK Cygwin 是合宙lua开源项目编译调试环境。安装文件以及安装方法，请点开合宙云盘和开源社区 -> tools-> CSDTK 。

CSDTK3.7_Cygwin安装完成后，用户将具备编译环境Cygwin和模块trace打印工具cool watcher.

### 第三步：编译基础软件lod
lod是支持lua运行的模块基础软件。具体编译方法：

1. 点击 启动菜单->Cygwin-> Cygwin bash shell，运行之
2. 用cd命令进入 \core 目录，输入 ./cust_build.sh，回车
3. 编译成功后，在\core\hex会有一个子目录，lod文件（形式如：SW\_V0001\_Air200\_LUA\_B3887.lod）就放在子目录里
4. 注意： 如果\core目录下的代码，用户未做修改，则这一步只需执行一次。

### 第四步：合并用户自己开发的LUA代码和第三步生成的lod，并下载到合宙模块中
请点开/tools/LuaDB 目录，下载LuaDB合并及下载工具.zip，解压后，无需安装，直接运行download.exe。压缩包内有一个简要的工具使用说明。
这个下载工具需要将 lod + 用户脚本 + lib文件 合并下载到合宙模块中。

### 第五步：看模块trace打印
用户需要查看模块的trace以检查和修改自己的lua代码。打印trace的工具是cool watcher。
点击 启动菜单-> Coolsand Development ToolKits->CoolWatcher。具体使用方法，请参考\tools\CSDTK\coolwather使用说明 这个文档。
