	Lua Development Tools(LDT) is about providing Lua developers with an IDE providing the user
experience developers expect from any other tool dedicated to a static programming language.
	Like many other dynamic languages, Lua is so flexible that it is hard to analyze enough to
provide relevant and powerful tooling.
	LDT is using Metalua, to analyze Lua source code and provide nice user assistance.
	LDT is an Open Source tool, licensed under the EPL.
	
	To flexibly debug LUA, AirM2M develop a middleware, AMWatchDll.
	
	1) Install JDK
	   Java SE Development Kit(JDK):
	     www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
	   
	   The latest JDK:
	     Windows x86(32-bit), 'jdk-8u121-windows-i586.exe'
	     Windows x64(64-bit), 'jdk-8u121-windows-x64.exe'
	
	2) Download Lua Development Tools(LDT)
	   www.eclipse.org/ldt/#installation, Windows 32-bit or 64-bit
	   
	3) Download simulator
	   git@github.com:airm2m-open/luat.git
	   AMWatchDll is source code of middleware, sample-script is a project LDT create a 'Lua Project'.
	
	4) Install C Run-Time(CRT) library
		Windows 32-bit, sample-script --> Win32_lib --> 'VC_x86Runtime.exe'
		Windows 64-bit, sample-script --> x64_lib --> 'VC_x64Runtime.exe'
	
	5) Configure LDT's interpreters
		a) Window --> Preferences --> Lua --> Interpreters --> Add
		Windows 32-bit, sample-script --> Win32_lib --> Lua5.1
		Windows 64-bit, sample-script --> x64_lib --> Lua5.1
		
		This interpreter should default interpreter about 'AMWatchDll'.
		
		b) Run --> Run Configurations
		'Launch script' must select 'sample-script\src\init.lua'
		'Runtime Interpreter' must select default interpreter.
		
		c) Run --> Debug Configurations --> Runtime Interpreter
		'Launch script' must select 'sample-script\src\init.lua'
		'Runtime Interpreter' must select default interpreter.
		
		AMWatchDll don't run on Windows XP. you must modify a lua file, 'init.lua':
		Windows 32-bit, The value 'os_type' is 'Win32_lib'.
		Windows 64-bit, The value 'os_type' is 'x64_lib'.
	
	6) Import existing project
		After to create a Workspace, to copy 'sample-script' in Workspace's directory.
	  File --> Import... --> General --> Existing Projects into Workspace
	  
	7) Run/Debug project
	  resources file, 'sample-script\src\ldata', such as .mp3, .bmp, .png and .gif.
	  lua shell, 'sample-script\src\ldata', copy your lua shell in 'ldata'.
	  'AMLuaDebug.log' is log file of 'AMWatchDll' in 'sample-script'.

