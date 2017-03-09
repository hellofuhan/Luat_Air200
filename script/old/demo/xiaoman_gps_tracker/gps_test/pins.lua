--[[
模块名称：GPIO
模块功能：GPIO配置和操作
模块最后修改时间：2017.02.16
]]

module(...,package.seeall)

--虽然GSENSOR这个脚支持中断，但是中断会唤醒系统，增加功耗
--所以配置为输入方式，在gsensor.lua中去轮询此引脚状态
GSENSOR = {name="GSENSOR",pin=pio.P0_3,dir=pio.INPUT,valid=0}
WATCHDOG = {pin=pio.P0_14,init=false,valid=0}
RST_SCMWD = {pin=pio.P0_12,defval=true,valid=1}

local allpin = {GSENSOR,RST_SCMWD}

--[[
函数名：get
功能  ：读取输入或中断型引脚的电平状态
参数  ：  
        p： 引脚的名字
返回值：如果引脚的电平和引脚配置的valid的值一致，返回true；否则返回false
]]
function get(p)
	if p.get then return p.get(p) end
	return pio.pin.getval(p.pin) == p.valid
end

--[[
函数名：set
功能  ：设置输出型引脚的电平状态
参数  ：  
        bval：true表示和配置的valid值一样的电平状态，false表示相反状态
		p： 引脚的名字
返回值：无
]]
function set(bval,p)
	p.val = bval

	if not p.inited and (p.ptype == nil or p.ptype == "GPIO") then
		p.inited = true
		pio.pin.setdir(p.dir or pio.OUTPUT,p.pin)
	end

	if p.set then p.set(bval,p) return end

	if p.ptype ~= nil and p.ptype ~= "GPIO" then print("unknwon pin type:",p.ptype) return end

	local valid = p.valid == 0 and 0 or 1 -- 默认高有效
	local notvalid = p.valid == 0 and 1 or 0
	local val = bval == true and valid or notvalid

	if p.pin then pio.pin.setval(val,p.pin) end
end

--[[
函数名：setdir
功能  ：设置引脚的方向
参数  ：  
        dir：pio.OUTPUT、pio.OUTPUT1、pio.INPUT或者pio.INT，详细意义参考本文件上面的“dir值定义”
		p： 引脚的名字
返回值：无
]]
function setdir(dir,p)
	if p and p.ptype == nil or p.ptype == "GPIO" then
		if not p.inited then
			p.inited = true
		end
		if p.pin then
			pio.pin.close(p.pin)
			pio.pin.setdir(dir,p.pin)
			p.dir = dir
		end
	end
end

--[[
函数名：init
功能  ：初始化allpin表中的所有引脚
参数  ：无  
返回值：无
]]
function init()
	for _,v in ipairs(allpin) do
		if v.init == false then
			-- 不做初始化
		elseif v.ptype == nil or v.ptype == "GPIO" then
			v.inited = true
			pio.pin.setdir(v.dir or pio.OUTPUT,v.pin)
			if v.dir == nil or v.dir == pio.OUTPUT then
				set(v.defval or false,v)
			elseif v.dir == pio.INPUT or v.dir == pio.INT then
				v.val = pio.pin.getval(v.pin) == v.valid
			end
		elseif v.set then
			set(v.defval or false,v)
		end
	end
end

--[[
函数名：intmsg
功能  ：中断型引脚的中断处理程序，会抛出一个逻辑中断消息给其他模块使用
参数  ：  
        msg：table类型；msg.int_id：中断电平类型，cpu.INT_GPIO_POSEDGE表示高电平中断；msg.int_resnum：中断的引脚id
返回值：无
]]
local function intmsg(msg)
	local status = 0

	if msg.int_id == cpu.INT_GPIO_POSEDGE then status = 1 end

	for _,v in ipairs(allpin) do
		if v.dir == pio.INT and msg.int_resnum == v.pin then
			v.val = v.valid == status
			sys.dispatch(string.format("PIN_%s_IND",v.name),v.val)
			return
		end
	end
end
--注册引脚中断的处理函数
sys.regmsg(rtos.MSG_INT,intmsg)
--初始化本模块配置的所有引脚
init()
