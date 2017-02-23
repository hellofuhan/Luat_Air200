
### 合宙开源项目core+lua开发一般步骤
如果用户手上已经有合宙Air200模块开发板或小蛮GPS定位器，此时就具备实体开发调试的基本条件了。

#### 第一步:clone 合宙开源库luat到本地电脑
可以从github克隆，也可以从群文件，百度网盘，开源社区下载。  

开源资料包架构如下：  

\core是模块基础软件，支持Lua的运行。内含合宙自己开发的Lua扩展库（位于\core\cust_src\elua\modules\src），扩展库文档位于\doc目录中。

\script是合宙范例LUA脚本，其中：  
\product\小蛮GPS定位器\whole_project 是一款已经商用的GPS定位器软件，可以下到合宙小蛮GPS定位器（是基于Air200开发的）中运行。

\demo下timer、 UART 等是各种应用例程，可下载到合宙EVB板中运行。合宙EVB开发板对应的硬件参考和Air200相关的AT命令位于\doc\Air200模块相关文档。 

\lib 是demo，product以及所有用户脚本都需要用到的库文件，这些库文件将经常使用的AT命令以函数形式封装，方便用户使用。

\tools目录下放了一些用户开发用到的工具。其中：  

LuaForWindows 是一款Lua代码编辑和语法检查工具。它的使用方法请参考附带的安装使用说明以及\doc\模块LUA程序设计指南 这篇文档。  

CSDTK Cygwin 是合宙Lua开源项目编译调试环境。安装完成后，用户将具备core编译环境Cygwin和模块trace打印工具cool watcher。   

LuaDB合并及下载工具是下载lod文件和用户Lua脚本到模块的工具软件。
 
RDA平台trace工具是一款轻型的trace打印工具。

#### 第二步：安装合宙Lua开源项目编译调试环境Cygwin
CSDTK Cygwin 是合宙Lua开源项目编译调试环境。安装完成后，用户将具备core编译环境Cygwin和模块trace打印工具cool watcher。    

安装文件的下载以及安装使用文档，请点开合宙百度网盘和开源社区 -> tools ，以及QQ群201848376的群文件->合宙GPRS模块Air200资源包---最新上传。

#### 第三步：修改、编译基础软件lod
core是支持Lua运行的模块基础软件。编辑修改core代码后，需要编译生成lod文件。具体编译方法如下：

1. 点击 启动菜单->Cygwin-> Cygwin bash shell，运行之
2. 用cd命令进入 \core 目录，输入 ./cust_build.sh，回车
3. 编译成功后，在\core\hex会有一个子目录，lod文件（形式如：SW\_V0001\_Air200\_LUA\_B3887.lod）就放在子目录里
4. 注意：
 -  我们在\core下已经放了一个编译好的lod文件，如果自开发用户不想修改core下的代码，可以直接使用我们提供的lod。
 -  下载lod+lua到模块的时候，如果\core目录下的代码，用户本次未做修改，则不需要重新编译，直接使用上次编译的即可。
 -  Cywin对WIN10的支持不太好。请把mount.exe做成兼容模式，给管理员权限。WIN10下Cygwin安装目录尽量不要放在C盘。

#### 第四步：用户编写Lua代码

用户对Lua项目的二次开发，请参考\doc\模块LUA程序设计指南 这篇文档。  
另外我司lib库文件和demo文件都给出了sample代码和详细注释。  
编辑工具可使用我司提供的LuaForWindows。

#### 第五步：LUA代码和lod，合并下载到合宙模块中
用户自己开发的LUA代码和编译生成的lod，需要一起下载到合宙模块中。  
需使用 LuaDB合并及下载工具 进行下载。该工具附带有一个简要的工具使用说明。  
下载地址：合宙百度网盘和开源社区 -> tools 和QQ群201848376群文件->合宙GPRS模块Air200资源包---最新上传。

### 第六步：查看模块trace打印
用户需要查看模块的trace以检查和修改自己的Lua代码。打印trace的工具是cool watcher。
点击 启动菜单-> Coolsand Development ToolKits->CoolWatcher。具体使用方法，请参考coolwather使用说明 这个文档。

用户也可以使用我司发布的一款轻型trace打印工具：RDA平台trace工具。  
下载地址：合宙百度网盘和开源社区 -> tools 和 QQ群201848376群文件->合宙GPRS模块Air200资源包---最新上传。