module(...,package.seeall)

local function print(...)
	_G.print("shkmng",...)
end

local tick = 0

local function timerfnc()
	tick = tick+1
end

local tshkapp = 
{
	["GPSMOD_OPN_SCK"] = {flg={},idx=0,cnt=_G.GPSMOD_OPN_SCK_VALIDSHK_CNT,freq=_G.GPSMOD_OPN_SCK_VALIDSHK_FREQ},
	--["GPSMOD_LOWVOLT_OPN_SCK"] = {flg={},idx=0,cnt=_G.GPSMOD_LOWVOLT_OPN_SCK_VALIDSHK_CNT,freq=_G.GPSMOD_LOWVOLT_OPN_SCK_VALIDSHK_FREQ},
	--["GPSMOD_NOGPS_OPN_SCK"] = {flg={},idx=0,cnt=_G.GPSMOD_NOGPS_OPN_SCK_VALIDSHK_CNT,freq=_G.GPSMOD_NOGPS_OPN_SCK_VALIDSHK_FREQ},
	["GPSMOD_OPN_GPS"] = {flg={},idx=0,cnt=_G.GPSMOD_OPN_GPS_VALIDSHK_CNT,freq=_G.GPSMOD_OPN_GPS_VALIDSHK_FREQ},
	--["GPSMOD_LOWVOLT_OPN_GPS"] = {flg={},idx=0,cnt=_G.GPSMOD_LOWVOLT_OPN_GPS_VALIDSHK_CNT,freq=_G.GPSMOD_LOWVOLT_OPN_GPS_VALIDSHK_FREQ},
	--["GPSMOD_NOGPS_OPN_GPS"] = {flg={},idx=0,cnt=_G.GPSMOD_NOGPS_OPN_GPS_VALIDSHK_CNT,freq=_G.GPSMOD_NOGPS_OPN_GPS_VALIDSHK_FREQ},
	--["PWRMOD_OPN_SCK"] = {flg={},idx=0,cnt=_G.PWRMOD_OPN_SCK_VALIDSHK_CNT,freq=_G.PWRMOD_OPN_SCK_VALIDSHK_FREQ},
	["LONGPSMOD"] = {flg={},idx=0,cnt=_G.LONGPSMOD_VALIDSHK_CNT,freq=_G.LONGPSMOD_VALIDSHK_FREQ},
	["STA_MOV"] = {flg={},idx=0,cnt=_G.STA_MOV_VALIDSHK_CNT,freq=_G.STA_MOV_VALIDSHK_FREQ},
}

local function reset(name)
	local i
	for i=1,tshkapp[name].cnt do
		tshkapp[name].flg[i] = 0
	end
	tshkapp[name].idx = 0
end

local function shkprint(name,suffix)
	local str,i = ""	
	for i=1,tshkapp[name].cnt do
		str = str..","..tshkapp[name].flg[i]
	end
	print(name..suffix,str)
end

local function fnc()
	local k,v
	for k,v in pairs(tshkapp) do
		shkprint(k,"1")
		if v.idx==0 then
			v.flg[1] = tick
			v.idx = 1
		elseif v.idx<v.cnt then
			if ((tick-v.flg[v.idx])>v.freq) and ((tick-v.flg[v.idx])<(v.freq*2)) then
				v.idx = v.idx+1
				if v.idx==v.cnt then
					v.idx = 1
					v.flg[v.cnt-1] = tick
					sys.dispatch(k.."_VALIDSHK_IND")
					print(k.."_VALIDSHK_IND")
				else
					v.flg[v.idx] = tick
				end
			elseif (tick-v.flg[v.idx])>=(v.freq*2) then
				reset(k)
			end
		end
		shkprint(k,"2")
	end	
end

local function shkind()
	fnc()
	return true
end

local function init()
	local k,v
	for k,v in pairs(tshkapp) do
		reset(k)
	end
end

init()
sys.regapp(shkind,"DEV_SHK_IND")
sys.timer_loop_start(timerfnc,1000)
