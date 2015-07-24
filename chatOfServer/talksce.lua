local skynet = require "skynet"
--local redis = require "redis"
--local mysql = require "mysql"
local netpack = require "netpack"
local socket = require "socket"
require "pack"
local bpack=string.pack
local bunpack=string.unpack

local CMD = {}
local protobuf = {}
local auto_id=0
local talk_users={}
local client_fds={}

function print_r(table,str,r,k,n)
	local str =  str or ' '--分割符号
	local n =  n or 0--分割符号数量
	local k =  k or ''--KEY值
	local r =  r or false--是否返回，否则为打印
	
	local tab = ''	
	local val_str = ''

	tab = string.rep(str,n)
	
	if type(table) == "table" then
		n=n+1
		val_str = val_str..tab..k.."={"		
		for k,v in pairs(table) do
			if type(v) == "table" then
				val_str = val_str.."\n"..print_r(v,str,true,k,n)
			else
				val_str = val_str..k..'='..tostring(v)..','
			end
		end
		if string.sub(val_str,-1,-1) == "," then
			val_str = string.sub(val_str,1,-2)
			val_str = val_str..' '.."}"
		else
			val_str = val_str.."\n"..tab..' '.."}"
		end
	else
		val_str = val_str..tab..k..tostring(table)
	end
	
	if r then
		return val_str
	else
		print(val_str)
	end
end
--

function CMD.createUser(client_fd,talk_create)
	print("*****talkbox****CMD.createUser**************")
	print(talk_create)
	local createUserInfo = protobuf.decode("talkbox.talk_create",talk_create)
	print(createUserInfo.name)
	print("**开始解析**")
	if createUserInfo==false then
		print("***解析失败***")
		return protobuf.encode("talkbox.talk_result",{id=1})--解析protocbuf错误
	end
	ok, result = pcall(skynet.call,"talkmysql", "lua", "mysqlCreate", client_fd, msg001)
	print(ok)

	--新内容测试
	strd = protobuf.encode("talkbox.talk_itemuse",
	{
		itemNo = result[1][1]["id"],
		itemName = result[1][1]["username"],
	})
	local strd2 = protobuf.decode("talkbox.talk_itemuse",strd)

	--判断用户名
	if isUser(createUserInfo.name) then
	  print("已经存在该用户")
		--return strd
		--return protobuf.encode("talkbox.talk_result",{id=2})--已经存在该名字
		yang = "yyyyyyy"
		return protobuf.encode("talkbox.talk_itemuse",{itemNo=2,itemName="sssss",})
	end
	
	auto_id=auto_id+1
	print("添加用户名****")
	local userInfo = {
		userid = auto_id,
		name = createUserInfo.name,
	}
	print("用户id:", userInfo.userid)
	print("用户名:",userInfo.name)

	--将数据加密
	local data_UserInfo = protobuf.encode("talkbox.talk_create", userInfo)

	talk_users[userInfo.userid]=userInfo
	--老用户
	for userid in pairs(client_fds) do
		local new_users = protobuf.encode("talkbox.talk_users",{['users']={userInfo}})
    		local msgg=bpack(">hiz",1,1002,new_users)
    		local nex = string.len(msgg)
    		local msggx=bpack(">hhiz",nex,1,1002,new_users)
		print("--发送给老用户--")
		return strd;
		--socket.write(client_fds[userid], msggx)
		--socket.write(client_fds[userid], netpack.pack(skynet.pack(1,1002,new_users)))
	end
	--新用户
	print("--发送给新用户-")
	client_fds[userInfo.userid]=client_fd;
  	local msgg=bpack(">hiz",1,1002,data_UserInfo)
  	local nex = string.len(msgg)
  	local msggx=bpack(">hhiz",nex,1,1002,data_UserInfo)
	--socket.write(client_fds[userInfo.userid], msggx)
	--return protobuf.encode("talkbox.talk_result",{id=0})
	return strd;
end

function CMD.sentMsg(talk_message)
	local message = protobuf.decode("talkbox.talk_message",talk_message)
	
	if message==false then
		return protobuf.encode("talkbox.talk_result",{id=3})--解析protocbuf错误
	end
	
	if message.touserid==-1 then
		for userid in pairs(client_fds) do
			socket.write(client_fds[userid], netpack.pack(skynet.pack(1,1010,talk_message)))
		end
	else
		socket.write(client_fds[message.touserid], netpack.pack(skynet.pack(1,1010,talk_message)))
	end
	
	return protobuf.encode("talkbox.talk_result",{id=4})
end

function CMD.getUsers(msg)
	local users={}
	for userid in pairs(talk_users) do
		table.insert(users,talk_users[userid])
	end

	return protobuf.encode("talkbox.talk_users",{['users']=users})
end
--用户断开
function CMD.rmUser(client_fd)
	for userid in pairs(client_fds) do
		
		if client_fds[userid]==client_fd then
			for userid2 in pairs(client_fds) do
				socket.write(client_fds[userid2], netpack.pack(skynet.pack(1,1011,protobuf.encode("talkbox.talk_result",{id=userid}))))
			end
			
			talk_users[userid]=nil
			client_fds[userid]=nil
			
		end
	end
end

function isUser(name)
	print("判断用户名是否存在")
	for userid in pairs(talk_users) do
		if talk_users[userid].name==name then
		  print("用户名存在")
			return true
		end
	end
	print("用户名不存在")
	return false
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		
		skynet.ret(skynet.pack(f(...)))
	end)

	protobuf = require "protobuf"
	
	local player_data = io.open("chatOfServer/res/skynet.pb","rb")
	local buffer = player_data:read "*a"
	player_data:close()
	protobuf.register(buffer)
	
	skynet.register "talkbox"
end)
