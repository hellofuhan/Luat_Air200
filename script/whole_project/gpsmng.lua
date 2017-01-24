module(...,package.seeall)

local nogpslockflg,lowvoltlockflg,agpswrflg
local fstopn=true

local function print(...)
	_G.print("gpsmng",...)
end


local function opngps()
	print("opngps",nvm.get("workmod"),agpswrflg,chg.islow1(),chg.islow())
	if nvm.get("workmod")=="GPS" then
        gpsapp.open(gpsapp.TIMER,{cause="GPSMOD",val=_G.GPSMOD_CLOSE_GPS_INVALIDSHK_FREQ+5})
    end
    return true
end

local function fstopngps()
    if fstopn then 
        fstopn=false
        opngps()
        sys.dispatch("GPS_FST_OPN")
    end
    return true
end

local function agpswrsuc()
	print("syy agpswrsuc",agpswrflg,fstopn)
	if not agpswrflg and not fstopn then
		agpswrflg = true
		opngps()--fstopngps()
	end
	return true
end

--[[local function opnlongps()
	print("opnlongps")
	gpsapp.open(gpsapp.DEFAULT,{cause="LONGPSMOD"})
end

local function clslongps()
	print("clslongps")
	gpsapp.close(gpsapp.DEFAULT,{cause="LONGPSMOD"})
end]]

function closegps()
	print("closegps")
	gpsapp.close(gpsapp.TIMER,{cause="GPSMOD"})
end

--[[local function workmodind(s)
	if nvm.get("workmod") ~= "GPS" then
		closegps()
		if nvm.get("workmod") == "LONGPS" then
			opnlongps()
		else
			clslongps()
		end
	else
		if s then opn() end
		clslongps()
	end
end

local function parachangeind(k,v,r)	
	if k == "workmod" then
		workmodind(true)
	end
	return true
end

local function init()	
	if nvm.get("workmod")=="GPS" then
		if rtos.poweron_reason() == rtos.POWERON_KEY or rtos.poweron_reason() == rtos.POWERON_CHARGER then
			opngps()
		end
	elseif nvm.get("workmod")~="LONGPS" then
		if chg.getcharger() then
			nvm.set("workmod","GPS","CHARGER")			
		end
	end
	workmodind()
end]]

local function gpstaind(evt)
	print("gpstaind",evt)
	if evt == gps.GPS_LOCATION_SUC_EVT then
		sys.dispatch("GPS_FIX_SUC")
	end
	return true
end

local function shkind()
	if gpsapp.isactive(gpsapp.TIMER,{cause="GPSMOD"}) then
		opngps()
	end
	return true
end

local procer =
{
	GPSMOD_OPN_GPS_VALIDSHK_IND = opngps,
	LINKAIR_CONNECT_SUC = fstopngps,
	--PARA_CHANGED_IND = parachangeind,
	[gps.GPS_STATE_IND] = gpstaind,
	DEV_SHK_IND = shkind,
	AGPS_WRDATE_SUC = agpswrsuc,
	MMI_KEYPAD_LONGPRESS_IND = opngps,
    MMI_KEYPAD_IND = opngps,
}

--sys.timer_start(agpswrsuc,180000)
sys.regapp(procer)
--init()
