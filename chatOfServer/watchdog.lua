package.path = "./chatOfServer/?.lua;" .. package.path

local skynet = require "skynet"
local netpack = require "netpack"
local proto = require "proto"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local addrs = {}


--1.1当判断为新的连接转到这里
function SOCKET.open(fd, addr)
	print("连接成功********")
	print(string.format("[watchdog]: a new client connecting fd( %d ) address( %s )", fd, addr))
	skynet.error("New client from成功连接 : " .. addr,fd)
	local stds = string.find(addr,':')
	local strd = string.sub(addr,0,stds-1)
--  if addrs[strd] ~= nil then
--      print("释放")
--      close_agent02(fd)
--  else
    addrs[strd] = 1
    --启动服务
    agent[fd] = skynet.newservice("agent")
    --skynet.call(gate, "lua", "accpet", fd)
    skynet.call(agent[fd], "lua", "start", gate, fd, proto)
--  end
end
--这里用于用户断开连接
local function close_agent(fd)
	print("***watchdog/close_agent***",fd)
	local a = agent[fd]
	if a then
		skynet.kill(a)
		agent[fd] = nil
		--添加代码
		ok, result = pcall(skynet.call,"loginServer", "lua", "rmUser", fd)--断开连接是处理用户
	end
end

local function close_agent02(fd)
  print("***watchdog/close_agent***",fd)
end
--用户正常退出
function SOCKET.close(fd)
	print("***watchdog/socket close***",fd)
	print("**当用户退出后清除数据**")
	print("**在退出前保存数据**")
	print("**安全退出**")
	close_agent(fd)
end
--用户异常退出
function SOCKET.error(fd, msg)
	print("***watchdog/socket error***",fd, msg)
	print("***watchdog/socket close***",fd)
	print("**当用户退出后清除数据**")
	print("**在退出前保存数据**")
	print("**安全退出**")
	close_agent(fd)
end

function SOCKET.data(fd, msg)
	print("***watchdog/SOCKET.data***")
end
--开始调用函数启动服务
function CMD.start(conf)
	print("当新的连接完成后到这里调用")
	print("***watchdog/CMD.start启动服务***")
	skynet.call(gate, "lua", "open" , conf)
end


--加载启动的服务
--function(session, source, cmd, subcmd, ...)
--(唯一标示,源,消息类型,调用函数)
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		--得到消息的类型

		print(session,source,cmd,"*****",subcmd)
		print("***判断服务类别***")
		--每当有连接进来的第二步进行消息的判断
		if cmd == "socket" then
			--调用指定的函数
			--addrs[source] = 1
			print("都进入")
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			print("当启动服务的时候完成注册")
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
	print("watchdog.start")
	gate = skynet.newservice("gate")
end)
print("***加载完成watchdog文件***")
