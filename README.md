# Luat
Luat = Lua +  AT  
OpenLuat = 合宙AirM2M open source project

百度云盘：https://pan.baidu.com/s/1eSxFHrs

开源社区：www.openluat.com

GitHub：https://github.com/airm2m-open/Luat_Air200

开发套件：https://luat.taobao.com

## 合宙github开源项目Luat介绍

合宙将十年研发成果悉数公开！GPRS模块软件源码公开！

Air200 模块是合宙（AirM2M）推出的第一款开源模块，基于RDA平台，是一款大量出货的成熟的GPRS模块。  

底层软件（也叫基础软件，位于/Luat_Air200/core）用C语言开发完成，支撑Lua的运行。

上层软件用Lua脚本语言来开发实现，位于/Luat_Air200/script。 


## 开源用户须知

我司提供的开源/script代码中，/demo里是各个功能的示例程序，其中xiaoman_gps_tracker下 是一个完整的定位器代码。/lib下是demo以及所有用户代码都需要调用的库文件。

一般用户只需修改我司提供的lua脚本，即可快速完成二次开发，而不会修改core基础软件。这部分用户，请参考：合宙开源项目lua开发须知

注意：还有一部分用户，只需要MCU通过物理串口发送AT命令控制模块，对这部分用户，请购买我司Air200T模块或开发板。