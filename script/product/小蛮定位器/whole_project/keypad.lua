module(...,package.seeall)

local curkey
local KEY_LONG_PRESS_TIME_PERIOD = 3000
KEY_SOS = "SOS"
local keymap = {["12"] = KEY_SOS}
local sta = "IDLE"

local function keylongpresstimerfun ()
	if curkey then
		sys.dispatch("MMI_KEYPAD_LONGPRESS_IND",curkey)
		sta = "LONG"
	end
end

local function stopkeylongpress()
	curkey = nil
	sys.timer_stop(keylongpresstimerfun)
end

local function startkeylongpress(key)
	stopkeylongpress()
	curkey = key
	sys.timer_start(keylongpresstimerfun,KEY_LONG_PRESS_TIME_PERIOD)
end

local function keymsg(msg)
	print("keypad.keymsg",msg.key_matrix_row,msg.key_matrix_col)
	local key = keymap[msg.key_matrix_row..msg.key_matrix_col]
	if key then
		if msg.pressed then
			sta = "PRESSED"
			startkeylongpress(key)			
		else
			stopkeylongpress()
			if sta == "PRESSED" then
				sys.dispatch("MMI_KEYPAD_IND",key)
			end
			sta = "IDLE"
		end
	end
end

local fivetap = 0

local function resetfivetap()
	fivetap = 0
end

local function keyind()
	fivetap = fivetap+1
	if fivetap >= 5 then
		resetfivetap()
		sys.timer_stop(resetfivetap)
		sys.dispatch("MMI_KEYPAD_FIVETAP_IND")
	else
		sys.timer_start(resetfivetap,1000)
	end
	return true
end

sys.regmsg(rtos.MSG_KEYPAD,keymsg)
sys.regapp(keyind,"MMI_KEYPAD_IND")
rtos.init_module(rtos.MOD_KEYPAD,0,0x04,0x02)
