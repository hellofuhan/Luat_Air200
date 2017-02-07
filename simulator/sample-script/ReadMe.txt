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
	   AMWatchDll is source code of middleware, sample-script is a project that it is created a 'Lua Project'
  by LDT.
	
	4) Install C Run-Time(CRT) library
		Windows 32-bit, sample-script --> Win32_lib --> 'VC_x86Runtime.exe'
		Windows 64-bit, sample-script --> x64_lib --> 'VC_x64Runtime.exe'
		
	5) Import existing project
		At first, you would create own Workspace, then to import sample-script.
	  File --> Import... --> General --> Existing Projects into Workspace --> root directory of sample-script.
	
	6) Configure LDT's interpreters
		AirM2M have modified lua's interpreter, so LDT's default interpreter must be changed to customized
  interpreter.
		a) Window --> Preferences --> Lua --> Interpreters --> Add
		'Interpreter executable' is full path of interpreter.
		Windows 32-bit, sample-script --> Win32_lib --> Lua5.1 --> lua5.1.exe
		Windows 64-bit, sample-script --> x64_lib --> Lua5.1 --> lua5.1.exe
		
		This interpreter is default interpreter of 'AMWatchDll', so to check it on its check-box.
		
		b) Run --> Run Configurations
		Press the 'New' button to create a run configuration of 'Lua Application'.
		'Launch script' must select 'sample-script\src\init.lua'
		'Runtime Interpreter' must select default interpreter.
		
		c) Run --> Debug Configurations --> Runtime Interpreter
		Press the 'New' button to create a debug configuration of 'Lua Application'.
		'Launch script' must select 'sample-script\src\init.lua'
		'Runtime Interpreter' must select default interpreter.
		
		AMWatchDll can't run on Windows XP. you must modify a lua file according to OS architecture, 'init.lua':
		Windows 32-bit, The value 'os_type' is 'Win32_lib'.
		Windows 64-bit, The value 'os_type' is 'x64_lib'.
 
	7) Run/Debug project
	  resources file, 'sample-script\src\ldata', such as .mp3, .bmp, .png and .gif.
	  lua shell, 'sample-script\src\lua', copy your lua shell in 'lua'.
	  'AMLuaDebug.log' is log file of 'AMWatchDll' in 'sample-script'.
	  
	  so far, Debug project can't run, we shall update build-in middleware.

