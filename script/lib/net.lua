
local base = _G
local string = require"string"
local sys = require "sys"
local ril = require "ril"
local pio = require"pio"
require"sim"
module("net")

local dispatch = sys.dispatch
local req = ril.request
local smatch = string.match
local tonumber,tostring,print = base.tonumber,base.tostring,base.print

local state = "INIT"
local lac,ci,rssi = "","",0
local csqqrypriod,cengqrypriod = 60*1000
local cellinfo,flymode,csqswitch,cengswitch = {}
--ledstate:IDLE,CREG,CGATT,SCK
local ledflg,ledpin,ledvalid,ledcregon,ledcregoff,ledcgatton,ledcgattoff,ledsckon,ledsckoff = false,pio.P0_15,1,300,700,300,1700,100,100
local ledstate,ledontime,ledofftime,usersckconnect = "IDLE",0,0

local function creg(data)
	local p1,s
	_,_,p1 = string.find(data,"%d,(%d)")
	if p1 == nil then
		_,_,p1 = string.find(data,"(%d)")
		if p1 == nil then
			return
		end
	end

	if p1 == "1" or p1 == "5" then
		s = "REGISTERED"
	else
		s = "UNREGISTER"
	end

	if s ~= state then
		if not cengqrypriod and s == "REGISTERED" then
			setcengqueryperiod(60000)
		else
			cengquery()
		end
		state = s
		dispatch("NET_STATE_CHANGED",s)
		procled()
	end

	if state == "REGISTERED" then
		p2,p3 = string.match(data,"\"(%x+)\",\"(%x+)\"")
		if lac ~= p2 or ci ~= p3 then
			lac = p2
			ci = p3
			dispatch("NET_CELL_CHANGED")
		end
	end
end

local function resetcellinfo()
	local i
	cellinfo.cnt = 11
	for i=1,cellinfo.cnt do
		cellinfo[i] = {}
		cellinfo[i].mcc,cellinfo[i].mnc = nil
		cellinfo[i].lac = 0
		cellinfo[i].ci = 0
		cellinfo[i].rssi = 0
		cellinfo[i].ta = 0
	end
end

local function ceng(data)
	if string.find(data,"%+CENG:%d+,\".+\"") then
		local id,rssi,lac,ci,ta,mcc,mnc
		id = string.match(data,"%+CENG:(%d)")
		id = tonumber(id)
		if id == 0 then
			rssi,mcc,mnc,ci,lac,ta = string.match(data, "%+CENG:%d,\"%d+,(%d+),%d+,(%d+),(%d+),%d+,(%d+),%d+,%d+,(%d+),(%d+)\"")
		else
			rssi,mcc,mnc,ci,lac,ta = string.match(data, "%+CENG:%d,\"%d+,(%d+),(%d+),(%d+),%d+,(%d+),(%d+)\"")
		end
		if rssi and ci and lac and mcc and mnc then
			if id == 0 then
				resetcellinfo()
			end
			cellinfo[id+1].mcc = mcc
			cellinfo[id+1].mnc = mnc
			cellinfo[id+1].lac = tonumber(lac)
			cellinfo[id+1].ci = tonumber(ci)
			cellinfo[id+1].rssi = (tonumber(rssi) == 99) and 0 or tonumber(rssi)
			cellinfo[id+1].ta = tonumber(ta or "0")
			if id == 0 then
				dispatch("CELL_INFO_IND",cellinfo)
			end
		end
	end
end

local function neturc(data,prefix)
	if prefix == "+CREG" then
		csqquery() -- 收到网络状态变化时,更新一下信号值
		creg(data)
	elseif prefix == "+CENG" then
		ceng(data)
	end
end

function getstate()
	return state
end

function getmcc()
	return cellinfo[1].mcc or sim.getmcc()
end

function getmnc()
	return cellinfo[1].mnc or sim.getmnc()
end

function getlac()
	return lac
end

function getci()
	return ci
end

function getrssi()
	return rssi
end

function getcell()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].ci.."."..cellinfo[i].rssi.."."
		end
	end
	return ret
end

function getcellinfo()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].lac.."."..cellinfo[i].ci.."."..cellinfo[i].rssi..";"
		end
	end
	return ret
end

function getcellinfoext()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].mcc and cellinfo[i].mnc and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].mcc.."."..cellinfo[i].mnc.."."..cellinfo[i].lac.."."..cellinfo[i].ci.."."..cellinfo[i].rssi..";"
		end
	end
	return ret
end

function getta()
	return cellinfo[1].ta
end

function startquerytimer() end

local function simind(para)
	if para ~= "RDY" then
		state = "UNREGISTER"
		dispatch("NET_STATE_CHANGED",state)
	end
	if para == "NIST" then
		sys.timer_stop(queryfun)
	end
	return true
end

local function flyind(para)
	if flymode~=para then
		flymode = para
		procled()
	end
	if not para then
		startcsqtimer()
		startcengtimer()
		neturc("2","+CREG")
	end
	return true
end

local function workmodeind(para)
	startcengtimer()
	startcsqtimer()
	return true
end

function startcsqtimer()
	if not flymode and (csqswitch or sys.getworkmode()==sys.FULL_MODE) then
		csqquery()
		sys.timer_start(startcsqtimer,csqqrypriod)
	end
end

function startcengtimer()
	if cengqrypriod and not flymode and (cengswitch or sys.getworkmode()==sys.FULL_MODE) then
		cengquery()
		sys.timer_start(startcengtimer,cengqrypriod)
	end
end

local function rsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+%u+)")

	if intermediate ~= nil then
		if prefix == "+CSQ" then
			local s = smatch(intermediate,"+CSQ:%s*(%d+)")
			if s ~= nil then
				rssi = tonumber(s)
				rssi = rssi == 99 and 0 or rssi
				dispatch("GSM_SIGNAL_REPORT_IND",success,rssi)
			end
		elseif prefix == "+CENG" then
		end
	end
end

function setcsqqueryperiod(period)
	csqqrypriod = period
	startcsqtimer()
end

function setcengqueryperiod(period)
	if period ~= cengqrypriod then
		if period <= 0 then
			sys.timer_stop(startcengtimer)
		else
			cengqrypriod = period
			startcengtimer()
		end
	end
end

function cengquery()
	if not flymode then
		--if cengswitch or sys.getworkmode()==sys.FULL_MODE then req("AT+CENG?") end
		req("AT+CENG?")
		--req("AT+CREG?")
	end
end

function setcengswitch(v)
	cengswitch = v
	if v and not flymode then startcengtimer() end
end

function csqquery()
	if not flymode --[[and (csqswitch or sys.getworkmode()==sys.FULL_MODE)]] then req("AT+CSQ") end
end

function setcsqswitch(v)
	csqswitch = v
	if v and not flymode then startcsqtimer() end
end

local function ledblinkon()
	--print("ledblinkon",ledstate,ledontime,ledofftime)
	pio.pin.setval(ledvalid==1 and 1 or 0,ledpin)
	if ledstate~="IDLE" then
		sys.timer_start(ledblinkoff,ledontime)
	else
		sys.timer_stop(ledblinkon)
		sys.timer_stop(ledblinkoff)
	end
end

function ledblinkoff()
	--print("ledblinkoff",ledstate,ledontime,ledofftime)
	pio.pin.setval(ledvalid==1 and 0 or 1,ledpin)
	if ledstate~="IDLE" then
		sys.timer_start(ledblinkon,ledofftime)
	else
		sys.timer_stop(ledblinkon)
		sys.timer_stop(ledblinkoff)
	end
end

function procled()
	print("procled",ledflg,ledstate,flymode,usersckconnect,cgatt,state)
	if ledflg then
		local newstate = "IDLE"
		if flymode then
		elseif usersckconnect then
			newstate,newontime,newofftime = "SCK",ledsckon,ledsckoff
		elseif cgatt then
			newstate,newontime,newofftime = "CGATT",ledcgatton,ledcgattoff
		elseif state=="REGISTERED" then
			newstate,newontime,newofftime = "CREG",ledcregon,ledcregoff
		end
		if newstate~=ledstate then
			ledstate,ledontime,ledofftime = newstate,newontime,newofftime
			ledblinkoff()
		end
	end
end

local function usersckind(v)
	print("usersckind",v)
	if usersckconnect~=v then
		usersckconnect = v
		procled()
	end
end

local function cgattind(v)
	print("cgattind",v)
	if cgatt~=v then
		cgatt = v
		procled()
	end
end

function setled(v,pin,valid,cregon,cregoff,cgatton,cgattoff,sckon,sckoff)
	if ledflg~=v then
		ledflg = v
		if v then
			ledpin,ledvalid,ledcregon,ledcregoff = pin or ledpin,valid or ledvalid,cregon or ledcregon,cregoff or ledcregoff
			ledcgatton,ledcgattoff,ledsckon,ledsckoff = cgatton or ledcgatton,cgattoff or ledcgattoff,sckon or ledsckon,sckoff or ledsckoff
			pio.pin.setdir(pio.OUTPUT,ledpin)
			procled()
		else
			sys.timer_stop(ledblinkon)
			sys.timer_stop(ledblinkoff)
			pio.pin.setval(ledvalid==1 and 0 or 1,ledpin)
			pio.pin.close(ledpin)
			ledstate = "IDLE"
		end		
	end
end

local procer =
{
	SIM_IND = simind,
	FLYMODE_IND = flyind,
	SYS_WORKMODE_IND = workmodeind,
	USER_SOCKET_CONNECT = usersckind,
	NET_GPRS_READY = cgattind,
}

sys.regapp(procer)
ril.regurc("+CREG",neturc)
ril.regurc("+CENG",neturc)
ril.regrsp("+CSQ",rsp)
ril.regrsp("+CENG",rsp)
req("AT+CREG=2")
req("AT+CREG?")
req("AT+CENG=1,1")
sys.timer_start(startcsqtimer,8*1000) -- 8秒后查询第一次csq
resetcellinfo()
