module(...,package.seeall)
require"cc"
local stat,num,linkshut = "IDLE",{}
local starttm,totaltm,ringtm,cctyp,ccnum,tmtemp--cctyp:0：来电，1：去电

local function checktm()
    tmtemp=tmtemp+1
end

local function addnum(id,val)
	print("ccapp addmun",id,val,stat)
	if val and string.len(val) > 0 and stat == "IDLE" then
		table.insert(num,val)
	end
end

local function dialnum()
	print("ccapp dialnum",#num)
	if #num > 0 then		
		--link.shut()
		--linkshut = true
		if nvm.get("callDmode") then
			audio.setaudiochannel(audiocore.LOUDSPEAKER)
		else
			audio.setaudiochannel(audiocore.AUX_HANDSET)	
		end	
		ccnum = table.remove(num,1)	
		if not cc.dial(ccnum,2000) then dialnum() end
		cctyp,tmtemp=1,0   
		starttm = misc.getclockstr()
		stat = "DIALING"
		sys.timer_start(cc.hangup,40000,"r1")
		sys.timer_loop_start(checktm,1000)
		return true
	end
end

local function connect()
	sys.timer_stop(cc.hangup,"r1")
	stat = "CONNECT"
	num,ringtm = {},tmtemp
	tmtemp=0
	sys.dispatch("CCAPP_CONNECT")
	return true
end

local function disconnect()
	sys.timer_stop(cc.accept)
	sys.timer_stop(cc.hangup,"r1")
	--[[if linkshut then
		linkshut = nil
		link.reset()
	end]]
	sys.timer_stop(checktm)	
	if stat ~= "CONNECT" then
	    ringtm=tmtemp
	    totaltm=0
	else
	    totaltm = tmtemp
	end
	tmtemp=0
	sys.dispatch("CCRPT_REQ",cctyp,ccnum,starttm,ringtm,totaltm)
	print("ccair CCRPT_REQ",cctyp,ccnum,starttm,ringtm,totaltm)
	if not dialnum() then
		stat = "IDLE"
		sys.dispatch("CCAPP_DISCONNECT")
	end
	--sys.restart("restart with cc disconnect") 
	return true
end

local function incoming(typ,num)
	if nvm.get("workmod")=="PWRGPS" then
		cc.hangup()
		return
	end
	if nvm.get("adminum")~="" then
		if num~="" and num~=nil and num~=nvm.get("adminum") then
			cc.hangup()
			return
		end
	end
	--link.shut()
	--linkshut = true
	cctyp,tmtemp,ccnum=0,0,num
	starttm = misc.getclockstr()
	print("ccair incoming",cctyp,ccnum,starttm,ringtm,totaltm)
	if nvm.get("callDmode") then
		audio.setaudiochannel(audiocore.LOUDSPEAKER)
	else
		audio.setaudiochannel(audiocore.AUX_HANDSET)	
	end	
	sys.timer_start(cc.accept,10000)
	sys.timer_loop_start(checktm,1000)
end

sys.regapp(incoming,"CALL_INCOMING")
sys.regapp(connect,"CALL_CONNECTED")
sys.regapp(disconnect,"CALL_DISCONNECTED")
sys.regapp(addnum,"CCAPP_ADD_NUM")
sys.regapp(dialnum,"CCAPP_DIAL_NUM")
audio.setaudiochannel(audiocore.AUX_HANDSET)
audio.setmicrophonegain(7)
