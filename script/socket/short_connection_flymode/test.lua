module(...,package.seeall)

--[[
此例子为短连接，发送数据后，进入飞行模式，然后定时退出飞行模式再发送数据，如此循环
功能需求：
1、连接后台发送位置包"loc data\r\n"到后台，无论发送成功或者失败都进入飞行模式；
2、进入飞行模式20分钟后，退出飞行模式，然后继续第1步
循环以上2个步骤
2、收到后台的数据时，在rcv函数中打印出来
测试时请搭建自己的服务器，并且修改下面的PROT，ADDR，PORT 
]]

local ssub,schar,smatch,sbyte = string.sub,string.char,string.match,string.byte
--测试时请搭建自己的服务器
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","www.test.com",6500
local linksta 
--是否成功连接过服务器
local hasconnected
--开机后如果一次也没有连接上后台，会有如下异常处理
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
	misc.setflymode(false)
	--if linksta then
		if not snd("loc data\r\n","LOCRPT")	then locrptcb({data="loc data\r\n",para="LOCRPT"},false) end	
	--end
end

--位置包发送回调
--进入飞行模式，10秒后再退出飞行模式，连接后台发送数据
function locrptcb(item,result)
	print("locrptcb",linksta)
	--if linksta then
		linkapp.sckdisc(SCK_IDX)
		link.shut()
		misc.setflymode(true)
		sys.timer_start(locrpt,1200000)
	--end
end

local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="LOCRPT" then
		locrptcb(item,result)
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
	print("ntfy",evt,result,item,hasconnected)
	--连接结果
	if evt == "CONNECT" then
		reconning = false
		--连接成功
		if result then
			reconncnt,reconncyclecnt,linksta = 0,0,true
			--停止重连定时器
			sys.timer_stop(reconn)
			--开机后第一次连接成功
			if not hasconnected then
				hasconnected = true
				--发送位置包到后台
				locrpt()				
			end
		--连接失败
		else
			if not hasconnected then
				--5秒后重连
				sys.timer_start(reconn,RECONN_PERIOD*1000)
			else				
				sndcb({para="LOCRPT"},false)
			end			
		end	
	--数据发送结果
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
	--连接被动断开
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		--补充自定义功能代码
	--连接主动断开
	elseif evt == "DISCONNECT" then
		linksta = false				
	end
	--其他错误处理
	if smatch((type(result)=="string") and result or "","ERROR") then
		sndcb({para="LOCRPT"},false)
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
