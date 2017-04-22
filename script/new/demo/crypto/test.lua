module(...,package.seeall)

--加解密算法结果，可对照http://tool.oschina.net/encrypt?type=2进行测试

local slen = string.len

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上aliyuniot前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("test",...)
end

--[[
函数名：base64test
功能  ：base64加解密算法测试
参数  ：无
返回值：无
]]
local function base64test()
	local originstr = "123456crypto.base64_encodemodule(...,package.seeall)sys.timer_start(test,5000)jdklasdjklaskdjklsa"
	local encodestr = crypto.base64_encode(originstr,slen(originstr))
	print("base64_encode",encodestr)
	print("base64_decode",crypto.base64_decode(encodestr,slen(encodestr)))
end

--[[
函数名：hmacmd5test
功能  ：hmac_md5算法测试
参数  ：无
返回值：无
]]
local function hmacmd5test()
	local originstr = "asdasdsadas"
	local signkey = "123456"
	print("hmac_md5",crypto.hmac_md5(originstr,slen(originstr),signkey,slen(signkey)))
end

--[[
函数名：md5test
功能  ：md5算法测试
参数  ：无
返回值：无
]]
local function md5test()
	local originstr = "sdfdsfdsfdsffdsfdsfsdfs1234"
	print("md5",crypto.md5(originstr,slen(originstr)))
end

--[[
函数名：test
功能  ：算法测试入口
参数  ：无
返回值：无
]]
local function test()
	base64test()
	hmacmd5test()
	md5test()
end

sys.timer_start(test,5000)
