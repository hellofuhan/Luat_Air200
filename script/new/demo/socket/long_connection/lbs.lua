module(...,package.seeall)
require"dbg"
dbg.setup("UDP","ota.airm2m.com",9072)

--是否查询GPS位置字符串信息
local qryaddr

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上test前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("lbs",...)
end

--[[
函数名：qrygps
功能  ：查询GPS位置请求
参数  ：无
返回值：无
]]
local function qrygps()
	dbg.saverr("dbg.saverr")
end


--20秒后去查询经纬度，查询结果通过回调函数getgps返回
sys.timer_loop_start(qrygps,20000)
