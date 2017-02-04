module(...,package.seeall)

--[[
此文件是QoS为1的publish报文重发处理管理模块
发送publish报文后，如果DUP_TIME内没收到puback，则会自动重发，最多重发DUP_CNT次，如果都没收到puback，则不再重发，抛出MQTT_DUP_FAIL消息，然后丢弃该报文
]]
local DUP_TIME,DUP_CNT,tlist = 10,3,{}
local slen = string.len

local function print(...)
	_G.print("mqttdup",...)
end

local function timerfnc()
	print("timerfnc")
	for i=1,#tlist do
		print(i,tlist[i].tm)
		if tlist[i].tm > 0 then
			tlist[i].tm = tlist[i].tm-1
			if tlist[i].tm == 0 then
				sys.dispatch("MQTT_DUP_IND",tlist[i].dat)
			end
		end
	end
end

local function timer(start)
	print("timer",start,#tlist)
	if start then
		if not sys.timer_is_active(timerfnc) then
			sys.timer_loop_start(timerfnc,1000)
		end
	else
		if #tlist == 0 then sys.timer_stop(timerfnc) end
	end
end

function ins(typ,dat,seq)
	print("ins",typ,(slen(dat or "") > 200) and "" or common.binstohexs(dat),seq or "nil" or common.binstohex(seq))
	table.insert(tlist,{typ=typ,dat=dat,seq=seq,cnt=DUP_CNT,tm=DUP_TIME})
	timer(true)
end

function rmv(typ,dat,seq)
	print("rmv",typ or getyp(seq),(slen(dat or "") > 200) and "" or common.binstohexs(dat),seq or "nil" or common.binstohex(seq))
	for i=1,#tlist do
		if (not typ or typ == tlist[i].typ) and (not dat or dat == tlist[i].dat) and (not seq or seq == tlist[i].seq) then
			table.remove(tlist,i)
			break
		end
	end
	timer()
end

function rmvall()
	tlist = {}
	timer()
end

function rsm(s)
	for i=1,#tlist do
		if tlist[i].dat == s then
			tlist[i].cnt = tlist[i].cnt - 1
			if tlist[i].cnt == 0 then
				sys.dispatch("MQTT_DUP_FAIL",tlist[i].typ,tlist[i].seq)
				rmv(nil,s) 
				return 
			end
			tlist[i].tm = DUP_TIME			
			break
		end
	end
end

function getyp(seq)
	for i=1,#tlist do
		if seq and seq == tlist[i].seq then
			return tlist[i].typ
		end
	end
end
