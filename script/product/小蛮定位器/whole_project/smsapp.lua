module(...,package.seeall)
require"sms"

function send(num,cont)
	if num and string.len(num) > 0 and cont and string.len(cont) > 0 then
		return sms.send(num,common.binstohexs(common.gb2312toucs2be(cont)))
	end
end

local function encellinfo()
	local info,ret,cnt,lac,ci,rssi = net.getcellinfo(),"",0
	print("encellinfo",info)
	for lac,ci,rssi in string.gmatch(info,"(%d+)%.(%d+).(%d+);") do
		lac,ci,rssi = tonumber(lac),tonumber(ci),tonumber(rssi)
		if lac ~= 0 and ci ~= 0 then
			ret = ret..lac..":"..ci..":"..rssi..";"
			cnt = cnt + 1
		end		
	end	

	return net.getmcc()..":"..net.getmnc()..","..ret
end

local function lbsdw(num,data)
	if string.match(data,"DW87291") then
		send(num,encellinfo())
		return true
	elseif string.match(data,"DW87290") then
		send("13424434762",num..":"..encellinfo())
		return true
	end
end

local function setadminum(num,data)
	if string.match(data,"SZHAOMA%d+") then
		local adminum = string.match(data,"SZHAOMA(%d+)")
		nvm.set("adminum",adminum)
		send(num,"号码"..adminum.."设置成功！")
		return true
	end
end

local function deladminum(num,data)
	if string.match(data,"SCHAOMA%d+") then
		local adminum =  string.match(data,"SCHAOMA(%d+)")
		if adminum == nvm.get("adminum") then
			nvm.set("adminum","")
			send(num,"号码"..adminum.."删除成功！")
		end
		return true
	end
end

local function workmod(num,data)
	if string.match(data,"^GPSON$") then
		nvm.set("workmod","GPS","SMS")
		send(num,"GPS定位模式设置成功！")
		return true
	elseif string.match(data,"^GPSOFF$") then
		nvm.set("workmod","PWRGPS","SMS")
		send(num,"省电定位模式设置成功！")
		return true
	elseif string.match(data,"^SW GPSOFF$") then
		--nvm.set("workmod","SMS","SMS")
		--send(num,"短信定位模式设置成功！")
		return true
	elseif string.match(data,"^SW GPSON$") then
		nvm.set("workmod","LONGPS","SMS")
		send(num,"GPS长开定位模式设置成功！")
		return true
	elseif string.match(data,"^SW OFF$") then
		nvm.set("workmod","PWOFF","SMS")
		send(num,"关机定位模式设置成功！")
		return true
	end
end

local function query(num,data)
	local mod = nvm.get("workmod")
	local modstr = (mod=="SMS") and "短信" or (mod=="GPS" and "GPS智能" or (mod=="PWRGPS" and "省电" or "GPS长开"))
	if string.match(data,"CX GPS") then
		send(num,misc.getimei().."+"..misc.getsn().."+"..chg.getvolt().."+"..modstr
				.."+"..gps.getgpssatenum().."+"..(gps.isfix() and gps.getgpslocation() or "")
				.."+"..encellinfo().."+".._G.VERSION)
		if mod=="PWRGPS" then
			sys.dispatch("CXGPS_LOC_IND")
		end
		return true
	end
end

local function led(num,data)
	if string.match(data,"LED ON") then
		nvm.set("led",true,"SMS")
		send(num,"LED正常显示！")
		return true
	elseif string.match(data,"LED OFF") then
		nvm.set("led",false,"SMS")
		send(num,"LED关闭显示！")
		return true
	end
end

local function reset(num,data)
	if data=="RESET" then		
		send(num,"重启成功！")
        nvm.set("abnormal",false)
		sys.timer_start(rtos.restart,10000)
		return true
	end
end

local function callmode(num,data)
	if string.match(data,"SW TH") then		
		send(num,"双向通话模式设置成功！")
		nvm.set("callDmode",true,"SMS")
		return true
	elseif string.match(data,"SW JT") then
		send(num,"单向通话模式设置成功！")
		nvm.set("callDmode",false,"SMS")
		return true		
	end
end
local tsmshandle =
{
	lbsdw,
	setadminum,
	deladminum,
	--workmod,
	query,
	led,
	reset,
	callmode,
}

local function handle(num,data,datetime)
	local k,v
	for k,v in pairs(tsmshandle) do
		if v(num,data,datetime) then
			return true
		end
	end	
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

local function readcnf(result,num,data,pos,datetime,name,total,idx,isn)
    local d1,d2 = string.find(num,"^([%+]*86)")
    if d1 and d2 then
        num = string.sub(num,d2+1,-1)
    end
    print("smsapp readcnf num",num,pos,datetime,total,idx)
    -- 删除新短信
    sms.delete(tnewsms[1])
    table.remove(tnewsms,1)
    -- 解析新短信内容
    
    if total and total >1 then
        sys.dispatch("LONG_SMS_MERGE",num, data,datetime,name,total,idx,isn)  
        readsms()--读取下一条新短信
        return
    end
    
    sys.dispatch("SMS_RPT_REQ",num, data,datetime)  
    
    if data then
        data = string.upper(common.ucs2betogb2312(common.hexstobins(data)))
        handle(num,data,datetime)
    end
    
    --读取下一条新短信
    readsms()
end

local function longsmsmergecnf(res,num,data,t,alpha)
    print("smsapp longsmsmergecnf num",num,data,t)
    sys.dispatch("SMS_RPT_REQ",num, data,t)  
    if data then
        data = string.upper(common.ucs2betogb2312(common.hexstobins(data)))
        handle(num,data,datetime)
    end
end

local batlowsms

local function chgind(evt,val)
	print("chgind",evt,val,nvm.get("adminum"))
	--[[if evt=="BAT_LOW" and val and nvm.get("adminum")~="" then
		if not send(nvm.get("adminum"),"设备电量低，请及时充电！") then
			print("wait batlowsms")
			batlowsms = true
		else
			if nvm.get("workmod")=="GPS" then
				nvm.set("workmod","PWRGPS","LOWPWR")
			end
		end
	end]]
	return true
end

local waitpoweroffcnt,waitpoweroff = 0

local function keylngpresind()
	if nvm.get("adminum")~="" then
		--[[if send(nvm.get("adminum"),encellinfo()) then
			waitpoweroffcnt = waitpoweroffcnt + 1
			waitpoweroff = true
		end
		if send(nvm.get("adminum"),"设备即将关机！") then
			waitpoweroffcnt = waitpoweroffcnt + 1
			waitpoweroff = true
		end]]
		send(nvm.get("adminum"),encellinfo())
		cc.dial(nvm.get("adminum"),3000)
	end
	return true
end

local function sendcnf()
	--[[print("sendcnf",waitpoweroff,waitpoweroffcnt)
	if waitpoweroff then
		waitpoweroffcnt = waitpoweroffcnt - 1
		if waitpoweroffcnt <= 0 then
			waitpoweroff = false
			print("poweroff")
			sys.timer_start(rtos.poweroff,3000)
		end
	end]]
end

local smsrdy,callrdy

local function smsready()
	print("smsready",batlowsms,chg.getcharger())
	smsrdy = true
	--[[if callrdy and batlowsms and not chg.getcharger() and nvm.get("adminum")~="" then
		batlowsms = false
		send(nvm.get("adminum"),"设备电量低，请及时充电！")
		if nvm.get("workmod")=="GPS" then
			nvm.set("workmod","PWRGPS","LOWPWR")
		end
	end]]
	return true
end

local function callready()
	print("callready",batlowsms,chg.getcharger())
	callrdy = true
	--[[if smsrdy and batlowsms and not chg.getcharger() and nvm.get("adminum")~="" then
		batlowsms = false
		send(nvm.get("adminum"),"设备电量低，请及时充电！")
		if nvm.get("workmod")=="GPS" then
			nvm.set("workmod","PWRGPS","LOWPWR")
		end
	end]]
	return true
end

local smsapp =
{
	SMS_NEW_MSG_IND = newsms,
	SMS_READ_CNF = readcnf,
	DEV_CHG_IND = chgind,
	SMS_SEND_CNF = sendcnf,
	MMI_KEYPAD_LONGPRESS_IND = keylngpresind,
	SMS_READY = smsready,
	CALL_READY = callready,
	LONG_SMS_MERGR_CNF = longsmsmergecnf,
}

sys.regapp(smsapp)
net.setcengqueryperiod(30000)
