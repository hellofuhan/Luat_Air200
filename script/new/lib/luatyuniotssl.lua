--定义模块,导入依赖库
local base = _G
local sys  = require"sys"
local mqttssl = require"mqttssl"
require"aliyuniotauth"
module(...,package.seeall)

--阿里云上创建的key和secret，用户不要修改这两个值，否则无法连接上Luat的云后台
local PRODUCT_KEY,PRODUCT_SECRET = "1000163201","4K8nYcT4Wiannoev"
--mqtt客户端对象,数据服务器地址,数据服务器端口表
local mqttclient,gaddr,gports,gclientid,gusername
--目前使用的gport表中的index
local gportidx = 1
local gconnectedcb,gconnecterrcb,grcvmessagecb

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上luatyuniotssl前缀
参数  ：无
返回值：无
]]
local function print(...)
	base.print("luatyuniotssl",...)
end

--[[
函数名：subackcb
功能  ：MQTT SUBSCRIBE之后收到SUBACK的回调函数
参数  ：
		usertag：调用mqttclient:subscribe时传入的usertag
		result：true表示订阅成功，false或者nil表示失败
返回值：无
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
end

--[[
函数名：sckerrcb
功能  ：SOCKET失败回调函数
参数  ：
		r：string类型，失败原因值
			CONNECT：mqtt内部，socket一直连接失败，不再尝试自动重连
返回值：无
]]
local function sckerrcb(r)
	print("sckerrcb",r,gportidx,#gports)
	if r=="CONNECT" then
		if gportidx<#gports then
			gportidx = gportidx+1
			connect(true)
		else
			sys.restart("luatyuniotssl sck connect err")
		end
	end
end

--[[
函数名：connectedcb
功能  ：MQTT CONNECT成功回调函数
参数  ：无		
返回值：无
]]
local function connectedcb()
	print("connectedcb")
	--订阅主题
	mqttclient:subscribe({{topic="/"..PRODUCT_KEY.."/"..misc.getimei().."/get",qos=0}, {topic="/"..PRODUCT_KEY.."/"..misc.getimei().."/get",qos=1}}, subackcb, "subscribegetopic")
	--注册事件的回调函数，MESSAGE事件表示收到了PUBLISH消息
	mqttclient:regevtcb({MESSAGE=grcvmessagecb})
	if gconnectedcb then gconnectedcb() end
end

--[[
函数名：connecterrcb
功能  ：MQTT CONNECT失败回调函数
参数  ：
		r：失败原因值
			1：Connection Refused: unacceptable protocol version
			2：Connection Refused: identifier rejected
			3：Connection Refused: server unavailable
			4：Connection Refused: bad user name or password
			5：Connection Refused: not authorized
返回值：无
]]
local function connecterrcb(r)
	print("connecterrcb",r)
	if gconnecterrcb then gconnecterrcb(r) end
end


function connect(change)
	if change then
		mqttclient:change("TCP",gaddr,gports[gportidx])
	else
		--创建一个mqttssl client
		mqttclient = mqttssl.create("TCP",gaddr,gports[gportidx])
	end
	--配置遗嘱参数,如果有需要，打开下面一行代码，并且根据自己的需求调整will参数
	--mqttclient:configwill(1,0,0,"/willtopic","will payload")
	--连接mqtt服务器
	mqttclient:connect(gclientid,600,gusername,"",connectedcb,connecterrcb,sckerrcb)
end

--[[
函数名：databgn
功能  ：鉴权服务器认证成功，允许设备连接数据服务器
参数  ：无		
返回值：无
]]
local function databgn(host,ports,clientid,username)
	gaddr,gports,gclientid,gusername = host or gaddr,ports or gports,clientid,username
	gportidx = 1
	connect()
end

local procer =
{
	ALIYUN_DATA_BGN = databgn,
}

sys.regapp(procer)


--[[
函数名：config
功能  ：配置阿里云物联网产品信息和设备信息
参数  ：
		productkey：string类型，产品标识，必选参数
		productsecret：string类型，产品密钥，必选参数
返回值：无
]]
local function config(productkey,productsecret)
	sys.dispatch("ALIYUN_AUTH_BGN",productkey,productsecret)
end

function regcb(connectedcb,rcvmessagecb,connecterrcb)
	gconnectedcb,grcvmessagecb,gconnecterrcb = connectedcb,rcvmessagecb,connecterrcb
end

function publish(payload,qos,ackcb,usertag)
	mqttclient:publish("/"..PRODUCT_KEY.."/"..misc.getimei().."/update",payload,qos,ackcb,usertag)
end

config(PRODUCT_KEY,PRODUCT_SECRET)
