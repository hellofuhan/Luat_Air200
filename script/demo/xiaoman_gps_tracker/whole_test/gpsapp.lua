--[[
模块名称：“GPS应用”控制
模块功能：配置GPS，并发处理多个“GPS应用”的打开和关闭
模块最后修改时间：2017.02.16
]]

module(...,package.seeall)
require"gps"
require"agps"

--“GPS应用”：指的是使用GPS功能的一个应用
--例如，假设有如下3种需求，要打开GPS，则一共有3个“GPS应用”：
--“GPS应用1”：每隔1分钟打开一次GPS
--“GPS应用2”：设备发生震动时打开GPS
--“GPS应用3”：收到一条特殊短信时打开GPS
--只有所有“GPS应用”都关闭了，才会去真正关闭GPS

--[[
每个“GPS应用”打开或者关闭GPS时，最多有4个参数，其中 GPS工作模式和“GPS应用”标记 共同决定了一个唯一的“GPS应用”：
1、GPS工作模式(必选)
2、“GPS应用”标记(必选)
3、GPS开启最大时长[可选]
4、回调函数[可选]
例如gpsapp.open(gpsapp.TIMERORSUC,{cause="TEST",val=120,cb=testgpscb})
gpsapp.TIMERORSUC为GPS工作模式，"TEST"为“GPS应用”标记，120秒为GPS开启最大时长，testgpscb为回调函数
]]


--[[
GPS工作模式，共有如下3种
1、DEFAULT
   (1)、打开后，GPS定位成功时，如果有回调函数，会调用回调函数
   (2)、使用此工作模式调用gpsapp.open打开的“GPS应用”，必须调用gpsapp.close才能关闭
2、TIMERORSUC
   (1)、打开后，如果在GPS开启最大时长到达时，没有定位成功，如果有回调函数，会调用回调函数，然后自动关闭此“GPS应用”
   (2)、打开后，如果在GPS开启最大时长内，定位成功，如果有回调函数，会调用回调函数，然后自动关闭此“GPS应用”
   (3)、打开后，在自动关闭此“GPS应用”前，可以调用gpsapp.close主动关闭此“GPS应用”，主动关闭时，即使有回调函数，也不会调用回调函数
3、TIMER
   (1)、打开后，在GPS开启最大时长时间到达时，无论是否定位成功，如果有回调函数，会调用回调函数，然后自动关闭此“GPS应用”
   (2)、打开后，在自动关闭此“GPS应用”前，可以调用gpsapp.close主动关闭此“GPS应用”，主动关闭时，即使有回调函数，也不会调用回调函数
]]
DEFAULT,TIMERORSUC,TIMER = 0,1,2

--“GPS应用”表
local tlist = {}

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上gpsapp前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("gpsapp",...)
end

--[[
函数名：delitem
功能  ：从“GPS应用”表中删除一项“GPS应用”，并不是真正的删除，只是设置一个无效标志
参数  ：
		mode：GPS工作模式
		para：
			para.cause：“GPS应用”标记
			para.val：GPS开启最大时长
			para.cb：回调函数
返回值：无
]]
local function delitem(mode,para)
	local i
	for i=1,#tlist do
		--标志有效 并且 GPS工作模式相同 并且 “GPS应用”标记相同
		if tlist[i].flag and tlist[i].mode == mode and tlist[i].para.cause == para.cause then
			--设置无效标志
			tlist[i].flag,tlist[i].delay = false
			break
		end
	end
end

--[[
函数名：additem
功能  ：新增一项“GPS应用”到“GPS应用”表
参数  ：
		mode：GPS工作模式
		para：
			para.cause：“GPS应用”标记
			para.val：GPS开启最大时长
			para.cb：回调函数
返回值：无
]]
local function additem(mode,para)
	--删除相同的“GPS应用”
	delitem(mode,para)
	local item,i,fnd = {flag = true, mode = mode, para = para}
	--如果是TIMERORSUC或者TIMER模式，初始化GPS工作剩余时间
	if mode == TIMERORSUC or mode == TIMER then item.para.remain = para.val end
	for i=1,#tlist do
		--如果存在无效的“GPS应用”项，直接使用此位置
		if not tlist[i].flag then
			tlist[i] = item
			fnd = true
			break
		end
	end
	--新增一项
	if not fnd then table.insert(tlist,item) end
end

local function isexisttimeritem()
	local i
	for i=1,#tlist do
		if tlist[i].flag and (tlist[i].mode == TIMERORSUC or tlist[i].mode == TIMER or tlist[i].para.delay) then return true end
	end
end

local function timerfunc()
	local i
	for i=1,#tlist do
		print("timerfunc@"..i,tlist[i].flag,tlist[i].mode,tlist[i].para.cause,tlist[i].para.val,tlist[i].para.remain,tlist[i].para.delay,tlist[i].para.cb)
		if tlist[i].flag then
			local rmn,dly,md,cb = tlist[i].para.remain,tlist[i].para.delay,tlist[i].mode,tlist[i].para.cb
			if rmn and rmn > 0 then
				tlist[i].para.remain = rmn - 1
			end
			if dly and dly > 0 then
				tlist[i].para.delay = dly - 1
			end
			
			rmn = tlist[i].para.remain
			if gps.isfix() and md == TIMER and rmn == 0 and not tlist[i].para.delay then
				tlist[i].para.delay = 1
			end
			
			dly = tlist[i].para.delay
			if gps.isfix() then
				if dly and dly == 0 then
					if cb then cb(tlist[i].para.cause) end
					if md == DEFAULT then
						tlist[i].para.delay = nil
					else
						close(md,tlist[i].para)
					end
				end
			else
				if rmn and rmn == 0 then
					if cb then cb(tlist[i].para.cause) end
					close(md,tlist[i].para)
				end
			end			
		end
	end
	if isexisttimeritem() then sys.timer_start(timerfunc,1000) end
end

--[[
函数名：gpsstatind
功能  ：处理GPS定位成功的消息
参数  ：
		id：GPS消息id
		evt：GPS消息类型
返回值：无
]]
local function gpsstatind(id,evt)
	--定位成功的消息
	if evt == gps.GPS_LOCATION_SUC_EVT then
		local i
		for i=1,#tlist do
			print("gpsstatind@"..i,tlist[i].flag,tlist[i].mode,tlist[i].para.cause,tlist[i].para.val,tlist[i].para.remain,tlist[i].para.delay,tlist[i].para.cb)
			if tlist[i].flag then
				if tlist[i].mode ~= TIMER then
					tlist[i].para.delay = 1
					if tlist[i].mode == DEFAULT then
						if isexisttimeritem() then sys.timer_start(timerfunc,1000) end
					end
				end				
			end			
		end
	end
	return true
end

--[[
函数名：forceclose
功能  ：强制关闭所有“GPS应用”
参数  ：无
返回值：无
]]
function forceclose()
	local i
	for i=1,#tlist do
		if tlist[i].flag and tlist[i].para.cb then tlist[i].para.cb(tlist[i].para.cause) end
		close(tlist[i].mode,tlist[i].para)
	end
end

--[[
函数名：close
功能  ：关闭一个“GPS应用”
参数  ：
		mode：GPS工作模式
		para：
			para.cause：“GPS应用”标记
			para.val：GPS开启最大时长
			para.cb：回调函数
返回值：无
]]
function close(mode,para)
	assert((para and type(para) == "table" and para.cause and type(para.cause) == "string"),"gpsapp.close para invalid")
	print("ctl close",mode,para.cause,para.val,para.cb)
	--删除此“GPS应用”
	delitem(mode,para)
	local valid,i
	for i=1,#tlist do
		if tlist[i].flag then
			valid = true
		end		
	end
	--如果没有一个“GPS应用”有效，则关闭GPS
	if not valid then gps.closegps("gpsapp") end
end

--[[
函数名：open
功能  ：打开一个“GPS应用”
参数  ：
		mode：GPS工作模式
		para：
			para.cause：“GPS应用”标记
			para.val：GPS开启最大时长
			para.cb：回调函数
返回值：无
]]
function open(mode,para)
	assert((para and type(para) == "table" and para.cause and type(para.cause) == "string"),"gpsapp.open para invalid")
	print("ctl open",mode,para.cause,para.val,para.cb)
	--如果GPS定位成功
	if gps.isfix() then
		if mode ~= TIMER then
			--执行回调函数
			if para.cb then para.cb(para.cause) end
			if mode == TIMERORSUC then return end			
		end
	end
	additem(mode,para)
	--真正去打开GPS
	gps.opengps("gpsapp")
	--启动1秒的定时器
	if isexisttimeritem() and not sys.timer_is_active(timerfunc) then
		sys.timer_start(timerfunc,1000)
	end
end

--[[
函数名：isactive
功能  ：判断一个“GPS应用”是否处于激活状态
参数  ：
		mode：GPS工作模式
		para：
			para.cause：“GPS应用”标记
			para.val：GPS开启最大时长
			para.cb：回调函数
返回值：激活返回true，否则返回nil
]]
function isactive(mode,para)
	assert((para and type(para) == "table" and para.cause and type(para.cause) == "string"),"gpsapp.isactive para invalid")
	local i
	for i=1,#tlist do
		if tlist[i].flag and tlist[i].mode == mode and tlist[i].para.cause == para.cause then
			return true
		end
	end
end

--UART2外接UBLOX GPS模块
gps.initgps(nil,nil,true,1000,2,9600,8,uart.PAR_NONE,uart.STOP_1)
sys.regapp(gpsstatind,gps.GPS_STATE_IND)
