module(...,package.seeall)

--[[
功能需求：
1、第奇数次来电呼入，自动拒接
2、第偶数次来电呼入，自动接听，接听后10秒钟，如果通话仍然存在，则主动挂断
3、开机1分钟后主动呼叫10086，接通后10秒钟，如果通话仍然存在，则主动挂断
]]


local incomingIdx = 1

local function print(...)
	_G.print("test",...)
end

local function connected(id)
	print("connected:"..(id or "nil"))
	sys.timer_start(cc.hangup,10000,"AUTO_DISCONNECT")
end

local function disconnected(id)
	print("disconnected:"..(id or "nil"))
	sys.timer_stop(cc.hangup,"AUTO_DISCONNECT")
end

local function incoming(id)
	print("incoming:"..(id or "nil"))
	if incomingIdx%2==0 then
		cc.accept()
	else
		cc.hangup()
	end	
	incomingIdx = incomingIdx+1
end

local procer =
{
	CALL_INCOMING = incoming, --来电时，lib中的cc.lua会调用sys.dispatch接口抛出CALL_INCOMING消息
	CALL_DISCONNECTED = disconnected,	--通话结束后，lib中的cc.lua会调用sys.dispatch接口抛出CALL_DISCONNECTED消息
}

--下面两行代码是注册消息处理函数的两种方式
--二者的区别是消息处理函数接收到的参数不同
--第一种方式的第一个参数是消息ID
--第二种方式的第一个参数是消息ID后的自定义参数
--请参考incoming，connected，disconnected中的打印
sys.regapp(connected,"CALL_CONNECTED") --建立通话后，lib中的cc.lua会调用sys.dispatch接口抛出CALL_CONNECTED消息
sys.regapp(procer)

--设置mic增益
audio.setmicrophonegain(7)

--1分钟后呼叫10086
sys.timer_start(cc.dial,60000,"10086")

