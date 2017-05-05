module(...,package.seeall)
require"lbsloc"

--[[
第一次使用基站获取经纬度的功能，必须按照以下步骤操作：
1、打开Luat物联云平台前端页面：https://iot.openluat.com/
2、注册用户
3、注册用户之后，创建一个新项目
4、创建新项目之后，进入项目
5、进入项目后，点击左边的项目信息，右边会出现信息内容，找到ProductKey：把ProductKey的内容，赋值给本文件中的ProductKey变量
6、查询一下设备的IMEI，最好是开机在trace中搜索CGSN，CGSN的下面就有设备的IMEI
7、在第5步的页面，点击左边的设备管理，然后再点击右边的添加设备，在弹出框中：设备名称随便输，设备IMEI就输入第6步获得的IMEI
以后的其他设备再使用此功能时，重复上面的第6步和第7步即可
]]

--用户必须根据自己的项目信息，修改这个变量的值
local ProductKey = "v32xEAKsGTIEQxtqgwCldp5aPlcnPs3K"

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上test前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("test",...)
end

--经纬度格式为031.2425864	121.4736522
local function getgps(result,lat,lng)
	print("getgps",result,lat,lng)
	--获取经纬度成功
	if result==0 then
	--失败
	else
	end
	sys.timer_start(lbsloc.request,20000,getgps)
end

lbsloc.setup(ProductKey)
--20秒后去查询经纬度，查询结果通过回调函数getgps返回
sys.timer_start(lbsloc.request,20000,getgps)
