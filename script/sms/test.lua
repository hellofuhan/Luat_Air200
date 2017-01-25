module(...,package.seeall)

--[[
功能需求：
收到短信后，读取短信内容和号码，打印出来
然后回复相同的短信内容给发送方
最后删除收到的短信
]]

local function print(...)
	_G.print("test",...)
end

local function handle(num,data,datetime)
	print("handle",num,data,datetime)
	--回复相同内容的短信到发送方
	if num then sms.send(num,common.binstohexs(common.gb2312toucs2be(data))) end
end

local tnewsms = {}

local function readsms()
	if #tnewsms ~= 0 then
		sms.read(tnewsms[1])
	end
end

local function newsms(pos)
	table.insert(tnewsms,pos)
	if #tnewsms == 1 then
		readsms()
	end
end

--result：结果，bool类型
--num：发送方号码，ASCII字符串
--data：短信内容，unicode大端编码的16进制字符串
--pos：存储索引
--datetime：发送日期和时间
--name：发送方号码对应的联系人名称
local function readcnf(result,num,data,pos,datetime,name)
	local d1,d2 = string.find(num,"^([%+]*86)")
	if d1 and d2 then
		num = string.sub(num,d2+1,-1)
	end
	sms.delete(tnewsms[1])
	table.remove(tnewsms,1)
	if data then
		data = common.ucs2betogb2312(common.hexstobins(data))
		handle(num,data,datetime)
	end
	readsms()
end

local function sendcnf(result)
	print("sendcnf",result)
end

local smsapp =
{
	SMS_NEW_MSG_IND = newsms, --收到新短信，sms.lua会抛出SMS_NEW_MSG_IND消息
	SMS_READ_CNF = readcnf, --调用sms.read读取短信之后，sms.lua会抛出SMS_READ_CNF消息
	SMS_SEND_CNF = sendcnf, --调用sms.send发送短信之后，sms.lua会抛出SMS_SEND_CNF消息
}

--注册消息处理函数
sys.regapp(smsapp)
