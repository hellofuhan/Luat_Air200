module(...,package.seeall)

local ing,rcdlen,rcdsta,rcdtyp--rcdtyp 0实时录音（录完上报后台） 1：本地拾音，录完不上报后台
local RCD_ID,RCD_FILE,RCD_SPLITSIZE = 1,"/RecDir/rec001",1002
local seq,unitlen,way,total,cur=0,1024,0
local buf={}

local function print(...)
	_G.print("rcd",...)
end

local function start()
	print("start",ing,rcdlen)
	ing = true
	os.remove(RCD_FILE)
	audio.beginrecord(RCD_ID,rcdlen*1000)
end

--[[local function stoprcd()
	print("stoprcd")
	audio.endrecord(RCD_ID)
	rcdendind(true)
end]]

local function rcdcnf(suc)
	print("rcdcnf",suc,rcdsta)
	if suc and not rcdsta then
		rcdsta = "RCDING"
	end
	return true
end

function getrcddata(s,idx)
	local f,rt = io.open(RCD_FILE,"rb")
	if not f then print("getrcddata can not open file",f) return "" end
	if not f:seek("set",(idx-1)*unitlen) then print("getfdata seek err") return "" end
	rt = f:read(unitlen)
	f:close()
	print("getrcddata",string.len(rt),s,idx)
	return rt or ""
end

local function getrcdinf()
	local f,rt = io.open(RCD_FILE,"rb")
	if not f then print("getrcdinf can not open file",f) return nil,0,0 end
	local size = f:seek("end")
	if not size or size == 0 then print("getrcdinf seek err") return nil,0,0 end
	f:close()
	seq = (seq+1>255) and 0 or (seq+1)
	total,cur = (size-1)/unitlen+1,1
	print("getrcdinf",size,seq,total,cur)
	return seq,(size-1)/unitlen+1,1
end


local function rcdendind(suc)
	print("rcdendind",suc,rcdsta)
	--sys.timer_stop(stoprcd)
	if suc and rcdsta=="RCDING" then
		rcdsta="RCDRPT"  
		collectgarbage()
		getrcdinf()
		sys.dispatch("SND_QRYRCD_REQ",seq,way,total,cur,rcdlen,getrcddata(seq,cur))	
		print("rcdendind",suc,rcdsta,seq,total,cur,rcdlen)
	else
		os.remove(RCD_FILE)
		ing,rcdlen,rcdsta = nil
	end
	return true
end


local function rcdind(length,typ)
	print("rcdind",length,ing)
	rcdtyp = typ
	if typ ~= 0 then return print("rcdind can not support local record ") end
	if length <= 0 then print("rcdind length can not be 0") return end
	if ing then
		table.insert(buf,{length,typ})
	else
		--if length and (length > 5000 or length < 0) then length = 5000 end
		rcdlen = (length or 5000)/1000
		start()
	end
	return true
end

local function sndcnf(res,s,c)
	print("sndcnf",res,s,c,seq,cur,total)    
	if res and tonumber(s)==seq and tonumber(c)== cur then
		cur = cur+1
		print("sndcnf111",res,s,c,seq,cur,total)   
		if cur<=total then
			print("sndcnf222",res,s,c,seq,cur,total)   
			sys.dispatch("SND_QRYRCD_REQ",seq,way,total,cur,rcdlen,getrcddata(seq,cur))  
			return true
		end 
	end
	os.remove(RCD_FILE)
	cur,total,ing,rcdlen,rcdsta = nil
	if #buf>0 then
		local rcdinfo=table.remove(buf,1)
		rcdind(rcdinfo[1],rcdinfo[2])
	end
end

local procer = {
	QRY_RCD_IND = rcdind,
	AUDIO_RECORD_CNF = rcdcnf,
	AUDIO_RECORD_IND = rcdendind,
	SND_QRYRCD_CNF=sndcnf,
}
sys.regapp(procer)
