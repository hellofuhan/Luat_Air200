module(...,package.seeall)

local function print(...)
	_G.print("sleep",...)
end

local function itvwakesndfail()
	nvm.set("abnormal",true)
	dbg.restart("itvwakesndfail")
end

local function itvwakesndsuc()
	print("itvwakesndsuc")
	sys.timer_stop(itvwakesndfail)
end

local function connsuc()
	if not sys.timer_is_active(itvwakesndfail) then
		sys.timer_start(itvwakesndfail,43200000)
	end
	return true
end

local function wakegps()
	print("wakegps",nvm.get("workmod"))
	nvm.set("gpsleep",false,"gps")
	sys.timer_stop(sys.dispatch,"ITV_GPSLEEP_REQ")
end

local function shkind()
	print("shkind",nvm.get("workmod"),nvm.get("gpsleep")) 
	if nvm.get("gpsleep") then
		sys.timer_start(sys.dispatch,_G.GPSMOD_WAKE_NOSHK_SLEEP_FREQ*1000,"ITV_GPSLEEP_REQ")
	else
		initgps()
	end	
	return true
end

local function parachangeind(k,v,r)	
	print("parachangeind",k)
	if k == "workmod" then
		wakegps()
		initgps()
	end
	return true
end

local function gpsleep()
	print("gpsleep",nvm.get("workmod"))
	nvm.set("gpsleep",true,"gps")
end

local function itvgpslp()
	print("itvgpslp")
	gpsleep()
	sys.timer_stop(sys.dispatch,"ITV_GPSLEEP_REQ")
end

function initgps()
	print("initgps",nvm.get("workmod"),nvm.get("gpsleep"))	
	if not nvm.get("gpsleep") then
		sys.timer_start(gpsleep,_G.GPSMOD_CLOSE_SCK_INVALIDSHK_FREQ*1000)
	else
		sys.timer_stop(gpsleep)
		sys.timer_stop(sys.dispatch,"ITV_GPSLEEP_REQ")
	end	
	return true
end

local function gpsmodopnsck()
	print("gpsmodopnsck")
	initgps()
	wakegps()
	return true
end


local procer = {
	DEV_SHK_IND = shkind,
	GPSMOD_OPN_SCK_VALIDSHK_IND = gpsmodopnsck,
	PARA_CHANGED_IND = parachangeind,
	ITV_GPSLEEP_REQ = itvgpslp,
	ITV_WAKE_SNDSUC = itvwakesndsuc,
	LINKAIR_CONNECT_SUC = connsuc,
}

sys.regapp(procer)
nvm.set("gpsleep",false)
initgps()
