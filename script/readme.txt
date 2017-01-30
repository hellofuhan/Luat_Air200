一个完整的项目脚本包含2部分：
1、第1部分是lib目录中的“库脚本”（所有项目都应该使用），
2、第2部分就是用户自己编写的“应用脚本”（例如whole_project、timer、uart等目录下的脚本）
使用LuaDB工具烧写软件时，一定要选择这2部分脚本才能保证正常运行！！！


第1部分：
lib：“库脚本”，请注意：这个目录中的脚本是所有应用使用LuaDB工具下载时都需要包含得！！！


第2部分：
以下所有项目的“应用脚本”都可以在开发板上运行，由于时间有限，部分项目没有仔细测试，运行过程中可能出错，请自行验证，有问题QQ交流，谢谢！
whole_project：是合宙量产的一个项目，有配套的后台以及app支持，app的名字为“时间线”，项目需求以及脚本设计参考《whole_project.docx》
timer：定时器demo项目
uart：串口demo项目
call：语音通话demo项目
nvm：参数存储读写demo项目
sms：短信demo项目
socket\long_connection：基于TCP的socket长连接通信demo项目（UDP使用方式和TCP完全相同）
socket\short_connection：基于TCP的socket短连接通信demo项目（UDP使用方式和TCP完全相同）
socket\short_connection_flymode：基于TCP的socket短连接通信demo项目，会进入飞行模式并且定时退出飞行模式（UDP使用方式和TCP完全相同）
mqtt：mqtt应用demo项目
其余demo项目持续更新中......
