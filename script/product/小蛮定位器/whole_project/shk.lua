module(...,package.seeall)

local i2cid,intregaddr = 1,0x1A
local initstr,indcnt1,indcnt2 = "",0,0

local function clrint()
	print("shk.clrint 1")
	if pins.get(pins.GSENSOR) then
		print("shk.clrint 2")
		i2c.read(i2cid,intregaddr,1)
	end
end

local function init2()
	local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x00,0x1B,0xDA,0x1B,0xDA}
	--local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1D,0x06,0x1B,0x1A,0x1B,0x9A}
	--local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x1A,0x1B,0x9A}
	for i=1,#cmd,2 do
		i2c.write(i2cid,cmd[i],cmd[i+1])
		print("shk.init2",string.format("%02X",cmd[i]),string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))))
		initstr = initstr..","..(string.format("%02X",cmd[i]) or "nil")..":"..(string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))) or "nil")
	end
	clrint()
end

local function checkready()
	local s = i2c.read(i2cid,0x1D,1)
	print("shk.checkready",s,(s and s~="") and string.byte(s) or "nil")
	if s and s~="" then
		if bit.band(string.byte(s),0x80)==0 then
			init2()
			return
		end
	end
	sys.timer_start(checkready,1000)
end

local function init()
	local i2cslaveaddr = 0x0E
	if i2c.setup(i2cid,i2c.SLOW,i2cslaveaddr) ~= i2c.SLOW then
		print("shk.init fail")
		initstr = "fail"
		return
	end
	i2c.write(i2cid,0x1D,0x80)
	sys.timer_start(checkready,1000)
end

function getdebugstr()
	return initstr..";".."indcnt1:"..indcnt1..";".."indcnt2:"..indcnt2
end

local function ind(id,data)
	print("shk.ind",id,data)
	if data then
		indcnt1 = indcnt1 + 1
	else
		indcnt2 = indcnt2 + 1
	end	
	if id == string.format("PIN_%s_IND",pins.GSENSOR.name) then
		if data then
			clrint()
			print("shk.ind DEV_SHK_IND")
			sys.dispatch("DEV_SHK_IND")
		end
	end
end

sys.regapp(ind,string.format("PIN_%s_IND",pins.GSENSOR.name))
init()
sys.timer_loop_start(clrint,30000)
