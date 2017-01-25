module(...,package.seeall)

--[[
功能需求：
uart按照帧结构接收外围设备的输入，收到正确的指令后，回复ASCII字符串

帧结构如下：
帧头：1字节，0x01表示扫描指令，0x02表示控制GPIO命令，0x03表示控制端口命令
帧体：字节不固定，跟帧头有关
帧尾：1字节，固定为0xC0

收到的指令帧头为0x01时，回复"CMD_SCANNER\r\n"给外围设备
收到的指令帧头为0x02时，回复"CMD_GPIO\r\n"给外围设备
收到的指令帧头为0x03时，回复"CMD_PORT\r\n"给外围设备
收到的指令帧头为其余数据时，回复"CMD_ERROR\r\n"给外围设备
]]



local UART_ID = 1
local CMD_SCANNER,CMD_GPIO,CMD_PORT,FRM_TAIL = 1,2,3,string.char(0xC0)
local rdbuf = ""

local function print(...)
	_G.print("test",...)
end

local function parse(data)
	if not data then return end	
	
	local tail = string.find(data,string.char(0xC0))
	if not tail then return false,data end	
	local cmdtyp = string.byte(data,1)
	local body,result = string.sub(data,2,tail-1)
	
	print("parse",common.binstohexs(data),cmdtyp,common.binstohexs(body))
	
	if cmdtyp == CMD_SCANNER then
		write("CMD_SCANNER")
	elseif cmdtyp == CMD_GPIO then
		write("CMD_GPIO")
	elseif cmdtyp == CMD_PORT then
		write("CMD_PORT")
	else
		write("CMD_ERROR")
	end
	
	return true,string.sub(data,tail+1,-1)	
end

--请参考功能需求，分析此函数
local function proc(data)
	if not data or string.len(data) == 0 then return end
	rdbuf = rdbuf..data	
	
	local result,unproc
	unproc = rdbuf
	while true do
		result,unproc = parse(unproc)
		if not unproc or unproc == "" or not result then
			break
		end
	end

	rdbuf = unproc or ""
end

--底层core中，串口收到数据时：
--如果接收缓冲区为空，则会以中断方式通知Lua脚本收到了新数据；
--如果接收缓冲器不为空，则不会通知Lua脚本
--所以Lua脚本中收到中断读串口数据时，每次都要把接收缓冲区中的数据全部读出，这样才能保证底层core中的新数据中断上来，此read函数中的while语句中就保证了这一点
local function read()
	local data = ""
	while true do		
		data = uart.read(UART_ID,"*l",0)
		if not data or string.len(data) == 0 then break end
		print("read",data,common.binstohexs(data))
		proc(data)
	end
end

--通过串口发送数据到外围设备
function write(s)
	print("write",s)
	uart.write(UART_ID,s.."\r\n")	
end

--保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("test")休眠，不会进入低功耗休眠状态
--在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("test")后，在不需要串口时调用pm.sleep("test")
pm.wake("test")
--注册串口的数据接收函数，串口收到数据后，会以中断方式，调用read接口读取数据
sys.reguart(UART_ID,read)
--配置并且打开串口
uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1,2)


