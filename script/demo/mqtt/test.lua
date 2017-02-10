module(...,package.seeall)

--[[
测试时请搭建自己的服务器，并且修改下面的PROT，ADDR，PORT 
]]

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--测试时请搭建自己的服务器
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","www.test.com",1884
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
--KEEP_ALIVE_TIME：mqtt保活时间
--rcvs：从后台收到的数据
local KEEP_ALIVE_TIME,rcvs = 600,""

--[[
目前只支持QoS=0和QoS=1，不支持QoS=2
topic、client identifier、user、password只支持ascii字符串

功能如下：
1、终端订阅了"/v1/device/"..misc.getimei().."/devparareq/+"和"/v1/device/"..misc.getimei().."/deveventreq/+"两个主题，参考函数mqttsubdata
2、连接上后台后，终端每隔1分钟分别会发送一个qos为0和1的PUBLISH报文，参考loc0snd和loc1snd
]]

local function print(...)
	_G.print("test",...)
end

--MQTT CONNECT报文中password字段用到的加密算法
local function enpwd(s)
	local tmp,ret,i = 0,""
	for i=1,string.len(s) do
		tmp = bit.bxor(tmp,string.byte(s,i))
		if i % 3 == 0 then
			ret = ret..schar(tmp)
			tmp = 0
		end
	end
	return common.binstohexs(ret)
end

--终端发送MQTT CONNECT报文后，把数据保存起来，如果超时10秒中没有收到CONNACK或者CONNACK返回失败，则会重发CONNECT报文
--重发的触发开关在mqttdup.lua中
function mqttconncb(result,data)
	mqttdup.ins(tmqttpack["MQTTCONN"].mqttduptyp,data)
end

--封装MQTT CONNECT报文数据
function mqttconndata()
	return mqtt.pack(mqtt.CONNECT,KEEP_ALIVE_TIME,misc.getimei(),misc.getimei(),enpwd(misc.getimei()))
end

--终端发送MQTT SUBSCRIBE报文后，把数据保存起来，如果超时10秒中没有收到SUBACK，则会重发SUBSCRIBE报文
--重发的触发开关在mqttdup.lua中
function mqttsubcb(result,v)
	mqttdup.ins(tmqttpack["MQTTSUB"].mqttduptyp,mqtt.pack(mqtt.SUBSCRIBE,v),v.seq)
end

--封装MQTT SUBSCRIBE报文数据
function mqttsubdata()
	return mqtt.pack(mqtt.SUBSCRIBE,{topic={"/v1/device/"..misc.getimei().."/devparareq/+", "/v1/device/"..misc.getimei().."/deveventreq/+"}})
end

--终端发送MQTT DICONNECT报文后，关闭socket连接
function mqttdiscb(result,v)
	linkapp.sckdisc(SCK_IDX)
end

--封装MQTT DISCONNECT报文数据
function mqttdiscdata()
	return mqtt.pack(mqtt.DISCONNECT)
end

--发送MQTT DISCONNECT报文
local function disconnect()
	mqttsnd("MQTTDISC")
end

--封装MQTT PINGREQ报文数据
function mqttpingreqdata()
	return mqtt.pack(mqtt.PINGREQ)
end

--发送MQTT PINGREQ报文
--然后启动定时器：如果保活时间+30秒内，没有收到pingrsp，则发送MQTT DISCONNECT报文
local function pingreq()
	mqttsnd("MQTTPINGREQ")
	if not sys.timer_is_active(disconnect) then
		sys.timer_start(disconnect,(KEEP_ALIVE_TIME+30)*1000)
	end
end

--启动定时器，60秒后再次发送qos为0的PULISH报文
function mqttpubloc0cb(result,v)
	sys.timer_start(loc0snd,60000)
end

--封装qos为0的MQTT PUBLISH报文数据
function mqttpubloc0data()
	return mqtt.pack(mqtt.PUBLISH,{qos=0,topic="/v1/device/"..misc.getimei().."/devdata",payload="loc data0"})
end

--发送qos为0的MQTT PUBLISH报文
function loc0snd()
	mqttsnd("MQTTPUBLOC0")
end

--启动定时器，60秒后再次发送qos为1的PULISH报文
--终端发送qos为1的MQTT PUBLISH报文后，把数据保存起来，如果超时10秒中没有收到PUBACK，则会重发该报文
--重发的触发开关在mqttdup.lua中
function mqttpubloc1cb(result,v)
	sys.timer_start(loc1snd,60000)
	mqttdup.ins(tmqttpack["MQTTPUBLOC1"].mqttduptyp,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

--封装qos为1的MQTT PUBLISH报文数据
function mqttpubloc1data()
	return mqtt.pack(mqtt.PUBLISH,{qos=1,topic="/v1/device/"..misc.getimei().."/devdata",payload="loc data1"})
end

--发送qos为1的MQTT PUBLISH报文
function loc1snd()
	mqttsnd("MQTTPUBLOC1")
end

function snd(data,para,pos,ins)
	return linkapp.scksnd(SCK_IDX,data,para,pos,ins)
end

tmqttpack =
{
	MQTTCONN = {sndpara="MQTTCONN",mqttyp=mqtt.CONNECT,mqttduptyp="CONN",mqttdatafnc=mqttconndata,sndcb=mqttconncb},
	MQTTSUB = {sndpara="MQTTSUB",mqttyp=mqtt.SUBSCRIBE,mqttduptyp="SUB",mqttdatafnc=mqttsubdata,sndcb=mqttsubcb},
	MQTTPINGREQ = {sndpara="MQTTPINGREQ",mqttyp=mqtt.PINGREQ,mqttdatafnc=mqttpingreqdata},
	MQTTDISC = {sndpara="MQTTDISC",mqttyp=mqtt.DISCONNECT,mqttdatafnc=mqttdiscdata,sndcb=mqttdiscb},
	MQTTPUBLOC0 = {sndpara="MQTTPUBLOC0",mqttyp=mqtt.PUBLISH,mqttdatafnc=mqttpubloc0data,sndcb=mqttpubloc0cb},
	MQTTPUBLOC1 = {sndpara="MQTTPUBLOC1",mqttyp=mqtt.PUBLISH,mqttdatafnc=mqttpubloc1data,sndcb=mqttpubloc1cb},
}

local function getidbysndpara(para)
	for k,v in pairs(tmqttpack) do
		if v.sndpara==para then return k end
	end
end

function mqttsnd(typ)
	if not tmqttpack[typ] then print("mqttsnd typ error",typ) return end
	local mqttyp = tmqttpack[typ].mqttyp
	local dat,para = tmqttpack[typ].mqttdatafnc()
	
	if mqttyp==mqtt.CONNECT then
		if tmqttpack[typ].mqttduptyp then mqttdup.rmv(tmqttpack[typ].mqttduptyp) end
		if not snd(dat,tmqttpack[typ].sndpara) and tmqttpack[typ].sndcb then
			tmqttpack[typ].sndcb(false,dat)
		end
	elseif mqttyp==mqtt.SUBSCRIBE then
		if tmqttpack[typ].mqttduptyp then mqttdup.rmv(tmqttpack[typ].mqttduptyp) end
		if not snd(dat,{typ=tmqttpack[typ].sndpara,val=para}) and tmqttpack[typ].sndcb then
			tmqttpack[typ].sndcb(false,para)
		end
	elseif mqttyp==mqtt.PINGREQ then
		snd(dat,tmqttpack[typ].sndpara)
	elseif mqttyp==mqtt.DISCONNECT then
		if not snd(dat,tmqttpack[typ].sndpara) and tmqttpack[typ].sndcb then
			tmqttpack[typ].sndcb(false,para)
		end
	elseif mqttyp==mqtt.PUBLISH then
		if typ=="MQTTPUBLOC0" then
			if not snd(dat,tmqttpack[typ].sndpara) and tmqttpack[typ].sndcb then
				tmqttpack[typ].sndcb(false,dat)
			end
		elseif typ=="MQTTPUBLOC1" then
			if not snd(dat,{typ=tmqttpack[typ].sndpara,val=para}) and tmqttpack[typ].sndcb then
				tmqttpack[typ].sndcb(false,para)
			end
		end
		
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
function ntfy(idx,evt,result,item,rspstr)
	print("ntfy",evt,result,item)
	--连接结果
	if evt == "CONNECT" then
		reconning = false
		--连接成功
		if result then
			reconncnt,reconncyclecnt,linksta,rcvs = 0,0,true,""
			--停止重连定时器
			sys.timer_stop(reconn)
			--发送mqtt connect请求
			mqttsnd("MQTTCONN")			
		--连接失败
		else
			--5秒后重连
			sys.timer_start(reconn,RECONN_PERIOD*1000)
		end	
	--数据发送结果
	elseif evt == "SEND" then
		if not result and rspstr and smatch(rspstr,"ERROR") then
			link.shut()
		else
			if item.para then
				if item.para=="MQTTDUP" then
					mqttdupcb(result,item.data)
				else
					local id = getidbysndpara(type(item.para) == "table" and item.para.typ or item.para)
					local val = type(item.para) == "table" and item.para.val or item.data
					print("item.para",type(item.para) == "table",type(item.para) == "table" and item.para.typ or item.para,id)
					if id and tmqttpack[id].sndcb then tmqttpack[id].sndcb(result,val) end
				end
			end
		end
	--连接被动断开
	elseif (evt == "STATE" and result == "CLOSED") or evt == "DISCONNECT" then
		sys.timer_stop(pingreq)
		sys.timer_stop(loc0snd)
		sys.timer_stop(loc1snd)
		mqttdup.rmvall()
		rcvs,linksta,mqttconn = ""
		reconn()			
	end
	--其他错误处理，断开数据链路，重新连接
	if smatch((type(result)=="string") and result or "","ERROR") then
		link.shut()
	end
end

local function connack(packet)
	print("connack",packet.suc)
	if packet.suc then
		mqttconn = true
		mqttdup.rmv(tmqttpack["MQTTCONN"].mqttduptyp)
		
		--订阅主题
		mqttsnd("MQTTSUB")		
	end
end

local function suback(packet)
	print("suback",common.binstohexs(packet.seq))
	mqttdup.rmv(tmqttpack["MQTTSUB"].mqttduptyp,nil,packet.seq)
	loc0snd()
	loc1snd()
end

local function puback(packet)	
	local typ = mqttdup.getyp(packet.seq) or ""
	print("puback",common.binstohexs(packet.seq),typ)
	mqttdup.rmv(nil,nil,packet.seq)
end

local function svrpublish(mqttpacket)
	print("svrpublish",mqttpacket.topic,mqttpacket.seq,mqttpacket.payload)	
	if mqttpacket.qos == 1 then snd(mqtt.pack(mqtt.PUBACK,mqttpacket.seq)) end	
end

local function pingrsp()
	sys.timer_stop(disconnect)
end

mqttcmds = {
	[mqtt.CONNACK] = connack,
	[mqtt.SUBACK] = suback,
	[mqtt.PUBACK] = puback,
	[mqtt.PUBLISH] = svrpublish,
	[mqtt.PINGRSP] = pingrsp,
}

local function datinactive()
    dbg.restart("SVRNODATA")
end

local function checkdatactive()
	sys.timer_start(datinactive,KEEP_ALIVE_TIME*1000*3+30000) --3倍保活时间+半分钟
end

--socket接收数据的处理函数
function rcv(id,data)
	print("rcv",slen(data)>200 and slen(data) or common.binstohexs(data))
	sys.timer_start(pingreq,KEEP_ALIVE_TIME*1000/2)
	rcvs = rcvs..data

	local f,h,t = mqtt.iscomplete(rcvs)

	while f do
		data = ssub(rcvs,h,t)
		rcvs = ssub(rcvs,t+1,-1)
		local packet = mqtt.unpack(data)
		if packet and packet.typ and mqttcmds[packet.typ] then
			mqttcmds[packet.typ](packet)
			if packet.typ ~= mqtt.CONNACK and packet.typ ~= mqtt.SUBACK then
				checkdatactive()
			end
		end
		f,h,t = mqtt.iscomplete(rcvs)
	end
end

--创建到后台服务器的连接
--如果数据网络还没有准备好，连接请求会被挂起，等数据网络准备就绪后，自动去连接后台
--ntfy：socket状态的处理函数
--rcv：socket接收数据的处理函数
function connect(cause)	
	linkapp.sckconn(SCK_IDX,cause,PROT,ADDR,PORT,ntfy,rcv)
	reconning = true
end

function mqttdupcb(result,v)
	mqttdup.rsm(v)
end

local function mqttdupind(s)
	if not snd(s,"MQTTDUP") then mqttdupcb(s) end
end

local function mqttdupfail(t,s)
    
end

local procer =
{
	MQTT_DUP_IND = mqttdupind,
	MQTT_DUP_FAIL = mqttdupfail,
}

sys.regapp(procer)

connect(linkapp.NORMAL)
checkdatactive()
