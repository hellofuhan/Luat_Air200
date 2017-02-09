require"sys"
module(...,package.seeall)

local inf = {}
local tcap =
{
	[1] = {cap=100,volt=4200},
	[2] = {cap=90,volt=4060},
	[3] = {cap=80,volt=3980},
	[4] = {cap=70,volt=3920},
	[5] = {cap=60,volt=3870},
	[6] = {cap=50,volt=3820},
	[7] = {cap=40,volt=3790},
	[8] = {cap=30,volt=3770},
	[9] = {cap=20,volt=3740},
	[10] = {cap=10,volt=3680},
	[11] = {cap=5,volt=3500},
	[12] = {cap=0,volt=3400},
}


local function getcap(volt)
	if not volt then return 50 end
	if volt >= tcap[1].volt then return 100 end
	if volt <= tcap[#tcap].volt then return 0 end
	local idx,val,highidx,lowidx,highval,lowval = 0
	for idx=1,#tcap do
		if volt == tcap[idx].volt then
			return tcap[idx].cap
		elseif volt < tcap[idx].volt then
			highidx = idx
		else
			lowidx = idx
		end
		if highidx and lowidx then
			return (volt-tcap[lowidx].volt)*(tcap[highidx].cap-tcap[lowidx].cap)/(tcap[highidx].volt-tcap[lowidx].volt) + tcap[lowidx].cap
		end
	end
end

local function proc(msg)
	if msg then	
		print("chg proc",msg.charger,msg.state,msg.level,msg.voltage)
		if msg.level == 255 then return end
		setcharger(msg.charger)
		if inf.state ~= msg.state then
			inf.state = msg.state
			sys.dispatch("DEV_CHG_IND","CHG_STATUS",getstate())
		end
		
		inf.vol = msg.voltage
		inf.lev = getcap(msg.voltage)
		local flag = (islowvolt() and getstate() ~= 1)
		if inf.low ~= flag then
			if (inf.low and (getstate()==1)) or flag then
				inf.low = flag
				sys.dispatch("DEV_CHG_IND","BAT_LOW",flag)
			end
			--[[inf.low = flag
			sys.dispatch("DEV_CHG_IND","BAT_LOW",flag)]]
		end		
		
		local flag = (islow1volt() and getstate() ~= 1)
		if inf.low1 ~= flag then
			if (inf.low1 and (getstate()==1)) or flag then
				inf.low1 = flag
				sys.dispatch("DEV_CHG_IND","BAT_LOW1",flag)
			end
		end	
		
		if inf.lev == 0 and not inf.chg then
			if not inf.poweroffing then
				inf.poweroffing = true
				sys.timer_start(sys.dispatch,30000,"REQ_PWOFF","BAT_LOW")
			end
		elseif inf.poweroffing then
			sys.timer_stop(sys.dispatch,"REQ_PWOFF","BAT_LOW")
			inf.poweroffing = false
		end
	end
end

local function init()	
	inf.vol = 3800
	inf.lev = 50
	inf.chg = false
	inf.state = false
	inf.poweroffing = false
	
	inf.lowvol = 3500
	inf.lowlev = 10
	inf.low = false
	inf.low1vol = _G.LOWVOLT_FLY
	inf.low1 = false
	
	local para = {}
	para.batdetectEnable = 0
	para.currentFirst = 200
	para.currentSecond = 100
	para.currentThird = 50
	para.intervaltimeFirst = 180
	para.intervaltimeSecond = 60
	para.intervaltimeThird = 30
	para.battlevelFirst = 4100
	para.battlevelSecond = 4150
	para.pluschgctlEnable = 1
	para.pluschgonTime = 5
	para.pluschgoffTime = 1
	pmd.init(para)
end

function getcharger()
	return inf.chg
end

function setcharger(f)
	if inf.chg ~= f then
		inf.chg = f
		sys.dispatch("DEV_CHG_IND","CHARGER",f)
	end
end

function getvolt()
	return inf.vol
end

function getlev()
	if inf.lev == 255 then inf.lev = 95 end
	return inf.lev
end

function getstate()
	return inf.state
end

function islow()
	return inf.low
end

function islow1()
	return inf.low1
end

function islowvolt()
	return inf.vol<=inf.lowvol
end

function islow1volt()
	return inf.vol<=inf.low1vol
end

sys.regmsg(rtos.MSG_PMD,proc)
init()
