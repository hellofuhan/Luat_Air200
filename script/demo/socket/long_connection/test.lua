module(...,package.seeall)

--[[
功能需求：
1、数据网络准备就绪后，连接后台
2、连接成功后，每隔10秒钟发送一次心跳包"heart data\r\n"到后台；每隔20秒钟发送一次位置包"loc data\r\n"到后台
3、与后台保持长连接，断开后主动再去重连，连接成功仍然按照第2条发送数据
4、收到后台的数据时，在rcv函数中打印出来
测试时请搭建自己的服务器，并且修改下面的PROT，ADDR，PORT 

此例子为长连接，只要是软件上能够检测到的网络异常，可以自动去重新连接；
有时会出现检测不到的异常，对于这种情况，我们一般按照如下方式处理，设置一个心跳包，每隔A时间发送一次到后台，后台回复应答，如果连续n倍的A时间都没有收到后台的任何数据，则认为出现了未知的网络异常，此时调用link.shut主动断开，然后自动重连
]]

local ssub,schar,smatch,sbyte = string.sub,string.char,string.match,string.byte
--测试时请搭建自己的服务器
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","www.test.com",6500
--linksta:与后台的socket连接状态
local linksta
--一个连接周期内的动作：如果连接后台失败，会尝试重连，重连间隔为RECONN_PERIOD秒，最多重连RECONN_MAX_CNT次
--如果一个连接周期内都没有连接成功，则等待RECONN_CYCLE_PERIOD秒后，重新发起一个连接周期
--如果连续RECONN_CYCLE_MAX_CNT次的连接周期都没有连接成功，则重启软件
local RECONN_MAX_CNT,RECONN_PERIOD,RECONN_CYCLE_MAX_CNT,RECONN_CYCLE_PERIOD = 3,5,3,20
--reconncnt:当前连接周期内，已经重连的次数
--reconncyclecnt:连续多少个连接周期，都没有连接成功
--一旦连接成功，都会复位这两个标记
--reconning:是否在尝试连接
local reconncnt,reconncyclecnt,reconning = 0,0

local function print(...)
	_G.print("test",...)
end

function snd(data,para,pos,ins)
	return linkapp.scksnd(SCK_IDX,data,para,pos,ins)
end


--发送位置包数据到后台
function locrpt()
	print("locrpt",linksta)
	if linksta then
		snd("loc data\r\n","LOCRPT")		
	end
end

--位置包发送回调
--启动定时器，20秒钟后再次发送位置包
function locrptcb(item,result)
	print("locrptcb",linksta)
	if linksta then
		sys.timer_start(locrpt,20000)
	end
end


--发送心跳包数据到后台
function heartrpt()
	print("heartrpt",linksta)
	if linksta then
		snd("heart data\r\n","HEARTRPT")		
	end
end

--心跳包发送回调
--启动定时器，10秒钟后再次发送心跳包
function heartrptcb(item,result)
	print("heartrptcb",linksta)
	if linksta then
		sys.timer_start(heartrpt,10000)
	end
end

local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="LOCRPT" then
		locrptcb(item,result)
	elseif item.para=="HEARTRPT" then
		heartrptcb(item,result)
	end
end

local function reconn()
	print("reconn",reconncnt,reconning,reconncyclecnt)
	if reconning then return end
	if reconncnt < RECONN_MAX_CNT then		
		reconncnt = reconncnt+1
		link.shut()
		connect(linkapp.NORMAL)
	else
		reconncnt,reconncyclecnt = 0,reconncyclecnt+1
		if reconncyclecnt >= RECONN_CYCLE_MAX_CNT then
			dbg.restart("connect fail")
		end
		sys.timer_start(reconn,RECONN_CYCLE_PERIOD*1000)
	end
end

--socket状态的处理函数
function ntfy(idx,evt,result,item)
	print("ntfy",evt,result,item)
	--连接结果
	if evt == "CONNECT" then
		reconning = false
		--连接成功
		if result then
			reconncnt,reconncyclecnt,linksta = 0,0,true
			--停止重连定时器
			sys.timer_stop(reconn)
			--发送心跳包到后台
			heartrpt()
			--发送位置包到后台
			locrpt()
		--连接失败
		else
			--5秒后重连
			sys.timer_start(reconn,RECONN_PERIOD*1000)
		end	
	--数据发送结果
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
	--连接被动断开
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		sys.timer_stop(heartrpt)
		sys.timer_stop(locrpt)
		reconn()
	--连接主动断开
	elseif evt == "DISCONNECT" then
		linksta = false
		sys.timer_stop(heartrpt)
		sys.timer_stop(locrpt)
		reconn()		
	end
	--其他错误处理，断开数据链路，重新连接
	if smatch((type(result)=="string") and result or "","ERROR") then
		link.shut()
	end
end

--socket接收数据的处理函数
function rcv(id,data)
	print("rcv",data)
end

--创建到后台服务器的连接
--如果数据网络还没有准备好，连接请求会被挂起，等数据网络准备就绪后，自动去连接后台
--ntfy：socket状态的处理函数
--rcv：socket接收数据的处理函数
function connect(cause)	
	linkapp.sckconn(SCK_IDX,cause,PROT,ADDR,PORT,ntfy,rcv)
	reconning = true
end

connect(linkapp.NORMAL)
