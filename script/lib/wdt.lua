--[[
模块名称：硬件看门狗
模块功能：支持硬件看门狗功能
模块最后修改时间：2017.02.16
设计文档参考 doc\小蛮GPS定位器相关文档\Watchdog descritption.doc
]]

module(...,package.seeall)

local RST_SCMWD_PIN = pio.P0_6
local WATCHDOG_PIN = pio.P0_5

local scm_active,get_scm_cnt = true,20

local function getscm()
	get_scm_cnt = get_scm_cnt - 1
	if get_scm_cnt > 0 then
		sys.timer_start(getscm,100)
	else
		get_scm_cnt = 20
		if not scm_active then
			pio.pin.setval(0,RST_SCMWD_PIN)
			sys.timer_start(pio.pin.setval,100,1,RST_SCMWD_PIN)
			print("wdt reset 153b")
			scm_active = true
		end
	end

	if pio.pin.getval(WATCHDOG_PIN) == 0 then
		scm_active = true
		print("wdt scm_active = true")
	end
end

local function feedend()
	pio.pin.close(WATCHDOG_PIN)
	pio.pin.setdir(pio.INPUT,WATCHDOG_PIN)
	print("wdt feedend")
	sys.timer_start(getscm,100)
end

local function feed()
	if scm_active then
		scm_active = false
	--[[else
		pio.pin.setval(0,RST_SCMWD_PIN)
		sys.timer_start(pio.pin.setval,100,1,RST_SCMWD_PIN)
		print("wdt reset 153b")]]
	end

	pio.pin.close(WATCHDOG_PIN)
	pio.pin.setdir(pio.OUTPUT,WATCHDOG_PIN)
	pio.pin.setval(0,WATCHDOG_PIN)
	print("wdt feed")

	sys.timer_start(feed,120000)
	sys.timer_start(feedend,2000)
end

--[[
函数名：open
功能  ：打开Air200开发板上的硬件看门狗功能
参数  ：无
返回值：无
]]
function open()
	sys.timer_start(feed,120000)
	pio.pin.setdir(pio.OUTPUT,WATCHDOG_PIN)
	pio.pin.setval(1,WATCHDOG_PIN)
end

pio.pin.setdir(pio.OUTPUT1,RST_SCMWD_PIN)
pio.pin.setval(1,RST_SCMWD_PIN)
