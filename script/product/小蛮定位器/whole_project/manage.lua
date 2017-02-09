module(...,package.seeall)

GUARDFNC,HANDLEPWRFNC,MOTORPWRFNC,RMTPWRFNC,BUZZERFNC = true,false,false,false,false

local lastyp,lastlng,lastlat,lastmlac,lastmci,lastlbs2 = "","","","","",""
local sta = "MOV"

function setlastgps(lng,lat)
	lastyp,lastlng,lastlat = "GPS",lng,lat
	nvm.set("lastlng",lng,nil,false)
	nvm.set("lastlat",lat)
end

function getlastgps()
	return nvm.get("lastlng"),nvm.get("lastlat")
end

function isgpsmove(lng,lat)
	--[[if nvm.get("workmod") ~= "GPS" then return true end
	if lastlng=="" or lastlat=="" or lastyp~="GPS" then return true end
	local dist = gps.diffofloc(lat,lng,lastlat,lastlng)
	print("isgpsmove",lat,lng,lastlat,lastlng,dist)
	return dist >= 15*15 or dist < 0]]
	return true
end

function setlastlbs1(lac,ci,flg)
	lastmlac,lastmci = lac,ci
	if flg then lastyp = "LBS1" end
end

function islbs1move(lac,ci)
	--[[if nvm.get("workmod") ~= "GPS" then return true end
	return lac ~= lastmlac or ci ~= lastmci]]
	return true
end

function setlastlbs2(v,flg)
	lastlbs2 = v
	if flg then lastyp = "LBS2" end
end

function islbs2move(v)
	--[[if nvm.get("workmod") ~= "GPS" then return true end
	if lastlbs2 == "" then return true end
	local oldcnt,newcnt,subcnt,chngcnt,laci = 0,0,0,0
	
	for laci in string.gmatch(lastlbs2,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		oldcnt = oldcnt + 1
	end
	
	for laci in string.gmatch(v,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		newcnt = newcnt + 1
		if not string.match(lastlbs2,laci) then chngcnt = chngcnt + 1 end
	end
	
	if oldcnt > newcnt then chngcnt = chngcnt + (oldcnt-newcnt) end
	local move = chngcnt*100/(newcnt>oldcnt and newcnt or oldcnt)
	print("islbs2move",lastlbs2,v,move)
	return move >= 50]]
	return true
end

function getlastyp()
	return lastyp
end

function resetlastloc()
	lastyp,lastlng,lastlat,lastmlac,lastmci,lastlbs2 = "","","","","",""
end

local function chgind(evt,val)
	print("manage chgind",nvm.get("workmod"),evt,val)
    if evt == "BAT_LOW" and val then
        sys.dispatch("REQ_PWOFF","BAT_LOW")
    end
	return true
end

local function handle_silsta()
    print("manage handle_silsta ",sta)
    if sta ~= "SIL" then
        sta = "SIL"
        sys.dispatch("STA_CHANGE",sta)
    end
    return true
end

local function handle_movsta()
    print("manage handle_movsta ",sta)
    if sta ~= "MOV" then
        sta = "MOV"
        sys.dispatch("STA_CHANGE",sta)
        sys.timer_start(handle_silsta,_G.STA_SIL_VALIDSHK_CNT*_G.STA_SIL_VALIDSHK_FREQ*1000)
    end
    return true
end

local function sta_change(sta)
    local mod = nvm.get("workmod")
    print("manage sta_change mod",mod,sta)
    --workmodind()
    return true
end

local function shkind()
    sys.timer_stop(handle_silsta)
    sys.timer_start(handle_silsta,_G.STA_SIL_VALIDSHK_CNT*_G.STA_SIL_VALIDSHK_FREQ*1000)
    return true
end

function getmovsta()
    return sta
end

local hassim=true
local function simind(para)
	print("simind p",para)
	if para == "NIST" then
        if hassim then
            nvm.set("abnormal",true)
            sys.timer_start(sys.restart,300000,"power on without sim")
        end
        hassim=false
    elseif para == "RDY" then
        hassim=true
        sys.timer_stop(sys.restart,"power on without sim")
    end

	return true
end

function issimexist()
	return hassim
end

local procer =
{
	DEV_CHG_IND = chgind,
	SIM_IND = simind,
	DEV_SHK_IND = shkind,
    STA_MOV_VALIDSHK_IND = handle_movsta,
    --STA_CHANGE = sta_change,
}

sys.regapp(procer)
sys.timer_start(handle_silsta,_G.STA_SIL_VALIDSHK_CNT*_G.STA_SIL_VALIDSHK_FREQ*1000)
