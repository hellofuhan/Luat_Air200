module(...,package.seeall)
require"config"

package.path = "/?.lua;"..package.path

--默认参数配置存储在config.lua中
--实时参数配置存储在para.lua中
local configname,paraname,para = "/lua/config.lua","/para.lua"

local function print(...)
	_G.print("nvm",...)
end

--恢复出厂设置
--把config.lua文件内容复制到para.lua中
function restore()
	local fpara,fconfig = io.open(paraname,"wb"),io.open(configname,"rb")
	fpara:write(fconfig:read("*a"))
	fpara:close()
	fconfig:close()
	para = config
end

local function serialize(pout,o)
	if type(o) == "number" then
		pout:write(o)
	elseif type(o) == "string" then
		pout:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		pout:write(tostring(o))
	elseif type(o) == "table" then
		pout:write("{\n")
		for k,v in pairs(o) do
			if type(k) == "number" then
				pout:write(" [", k, "] = ")
			elseif type(k) == "string" then
				pout:write(" [\"", k,"\"] = ")
			else
				error("cannot serialize table key " .. type(o))
			end
			serialize(pout,v)
			pout:write(",\n")
		end
		pout:write("}\n")
	else
		error("cannot serialize a " .. type(o))
	end
end

local function upd()
	for k,v in pairs(config) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			if para[k] == nil then
				para[k] = v
			end			
		end
	end
end

local function load()
	local f = io.open(paraname,"rb")
	if not f or f:read("*a") == "" then
		if f then f:close() end
		restore()
		return
	end
	f:close()
	
	f,para = pcall(require,"para")
	if not f then
		restore()
		return
	end
	upd()
end

local function save(s)
	if not s then return end
	local f = io.open(paraname,"wb")

	f:write("module(...)\n")

	for k,v in pairs(para) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			f:write(k, " = ")
			serialize(f,v)
			f:write("\n")
		end
	end

	f:close()
end

--设置某个参数的值
--k：参数名
--v：将要设置的新值
--r：设置原因，只有传入了有效参数，并且v的新值和旧值发生了改变，才会抛出TPARA_CHANGED_IND消息
--s：是否需要写入到文件系统中，false不写入，其余的都写入
function set(k,v,r,s)
	local bchg
	if type(v) == "table" then
		for kk,vv in pairs(para[k]) do
			if vv ~= v[kk] then bchg = true break end
		end
	else
		bchg = (para[k] ~= v)
	end
	print("set",bchg,k,v,r,s)
	if bchg then		
		para[k] = v
		save(s or s==nil)
		if r then sys.dispatch("PARA_CHANGED_IND",k,v,r) end
	end
	return true
end

--设置table类型的参数中的某一项的值
--k：table参数名
--kk：table参数中的键值
--v：将要设置的新值
--r：设置原因，只有传入了有效参数，并且v的新值和旧值发生了改变，才会抛出TPARA_CHANGED_IND消息
--s：是否需要写入到文件系统中，false不写入，其余的都写入
function sett(k,kk,v,r,s)
	if para[k][kk] ~= v then
		para[k][kk] = v
		save(s or s==nil)
		if r then sys.dispatch("TPARA_CHANGED_IND",k,kk,v,r) end
	end
	return true
end

--把参数从内存写到文件中
function flush()
	save(true)
end

--读取参数值
--k：参数名
function get(k)
	if type(para[k]) == "table" then
		local tmp = {}
		for kk,v in pairs(para[k]) do
			tmp[kk] = v
		end
		return tmp
	else
		return para[k]
	end
end

--读取table类型的参数中的某一项的值
--k：table参数名
--kk：table参数中的键值
function gett(k,kk)
	return para[k][kk]
end

--初始化配置文件，从文件中把参数读取到内存中
load()
