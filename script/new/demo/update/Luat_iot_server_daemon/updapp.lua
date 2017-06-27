require"update"
module(...,package.seeall)

local function upevt(ind,para)
	--服务器有新版本
	if ind == "NEW_VER_IND" then
		--允许下载新版本
		para(true)
	--下载结束
	elseif ind == "UP_END_IND" then
		sys.restart("updapp end")
	end
end

local procer =
{
	UP_EVT = upevt,
}

sys.regapp(procer)
sys.timer_start(sys.restart,300000,"updapp timeout")
