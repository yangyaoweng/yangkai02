local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local bit32 = require "bit32"
--local protobuf = require "protobuf"
--protobuf.register_file "chatOfServer/res/talkbox.pb"
--p=require("p.core")
require "pack"
local bpack=string.pack
local bunpack=string.unpack
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

local a
function hex(s)
 s=string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
 return s
end
--解压函数
function unzipServer(text)
    --print(type(text))
    --print(text)
    local nextPos2,version   = bunpack(text,">h")
    local nextPos3,messageId = bunpack(text,">i",nextPos2)
    local nextPos4,msg1  = bunpack(text,">z",nextPos3)
    --print(version,messageId,msg1)
    return version,messageId,msg1
end
--压缩函数
function zipServer(version,messageId,msg1)
  local msgg=bpack(">hiz",version,messageId,msg1)
  local nex = string.len(msgg)
  local msggx=bpack(">hhiz",nex,version,messageId,msg1)
    --return version,messageId,msg1
  return msggx
end


function REQUEST:get()
	print("***agent/REQUEST:get()函数***")
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("***agent/REQUEST:set()函数***")
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	print("***agent/REQUEST:handshake函数***")
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

local function request(name, args, response)
	print("***agent/request函数***")
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	print("***agent/send_package函数***")
	local size = #pack
	print("****查看数据情况***",size)
	local package = string.char(bit32.extract(size,8,8)) ..string.char(bit32.extract(size,0,8))..pack
	socket.write(client_fd, package)
end

local function xfs_send(v)
	print("[LOG]",os.date("%m-%d-%Y %X", skynet.time()),"send ok")
	print("**开始***")
	socket.write(client_fd, v)
	 local b = os.clock() 
   print(b-a)
	print("**结束***")
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		print("解析消息包")
		--print(msg)
		return skynet.tostring(msg,sz)
	end,
	dispatch = function (session, address, text)
    local onVer1,messageId, msg001  = unzipServer(text);
		local send = messageId
		--消息的值
		local ok, noage,result
		--消息判断
		a = os.clock() 
		local switch = {
      [1003] = function () --1进入游戏场景
        --1进入游戏场景
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "createSecInterface", client_fd, msg001)
        return ok, noage,result
      end,
      [1005] = function ()   --1.1进入游戏场景
        print("1进入游戏场景")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "createSecInterface01", client_fd, msg001)
        return ok, noage,result
      end,
      [1006] = function ()   --1.1进入游戏场景
        print("1进入游戏场景")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "createSecInterface02", client_fd, msg001)
        return ok, noage,result
      end,
      [1010] = function ()   --1.2创建临时用户后/创建宠物
        print("2创建临时用户后/创建宠物")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "createPet01", client_fd, msg001)
        return ok, noage,result
      end,
      [1012] = function ()   --1.2宝气值界面
        print("1.2宝气值界面")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "tardInterface02", client_fd, msg001)
        return ok, noage,result
      end,
      [1031] = function ()   --3.1弹出的关卡信息
        print("1弹出的关卡信息")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "PopUpPoint031", client_fd, msg001)
        return ok, noage,result
      end,
      [1032] = function ()  --3.2进入关卡
        print("2进入关卡")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint0302", client_fd, msg001)
        return ok, noage,result
      end,
      [1033] = function ()   --3.3进入游戏状态
        print("3进入游戏状态")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint033", client_fd, msg001)
        return ok, noage,result
      end,
      [1034] = function ()   --3.4进入复活
        print("4进入复活")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint034", client_fd, msg001)
        return ok, noage,result
      end,
      [1035] = function ()   --3.5游戏中购买钻石
        print("5游戏中购买钻石")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint035", client_fd, msg001)
        return ok, noage,result
      end,
      [1036] = function ()   --3.6失败的结算
        print("5游戏中购买钻石")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint035", client_fd, msg001)
        return ok, noage,result
      end,
      [1035] = function ()   --3.5游戏中购买钻石
        print("5游戏中购买钻石")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint035", client_fd, msg001)
        return ok, noage,result
      end,
      [1036] = function ()   --3.6失败的结算
        print("6失败的结算")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint036", client_fd, msg001)
        return ok, noage,result
      end,
      [1037] = function ()   --3.7道具的使用
        print("7道具的使用")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenPoint037", client_fd, msg001)
        return ok, noage,result
      end,
      [1038] = function ()   --3.8开启关卡
        print("8使用星星开启关卡")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "StatsPoint038", client_fd, msg001)
        return ok, noage,result
      end,
      [1041] = function ()   --4.1更换当前角色返回所有角色信息/talk_roleUser041s
        print("4.1更换当前角色返回所有角色信息")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "selectRole041", client_fd, msg001)
        return ok, noage,result
      end,
      [1042] = function ()   --4.2更换当前角色/talk_updaterole
        print("4.2更换当前角色")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateCharacter042", client_fd, msg001)
        return ok, noage,result
      end,
      [1043] = function ()   --4.3恢复角色生命值/talk_addlife043c
        print("4.3恢复角色生命值")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateLife43", client_fd, msg001)
        return ok, noage,result
      end,
      [1044] = function ()   --4.4角色升级/talk_updaterole044c
        print("4.4角色升级")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateRole44", client_fd, msg001)
        return ok, noage,result
      end,
      [1045] = function ()   --4.5角色快速升级/updateRole45
        print("4.5角色快速升级")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateRole45", client_fd, msg001)
        return ok, noage,result
      end,
      [1046] = function ()   --4.6添加用户角色槽/updateSole46
        print("4.6添加用户角色槽")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateSole46", client_fd, msg001)
        return ok, noage,result
      end,
      [1050] = function ()    --5商城/updateOpenMall05
        print("进入商城")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateOpenMall05", client_fd, msg001)
        return ok, noage,result
      end,
      [1051] = function ()    --5.1用户购买角色/updateOpenRole051
        print("5.1用户购买角色")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateOpenRole051", client_fd, msg001)
        return ok, noage,result
      end,
      [1052] = function ()    --5.2购买道具/updateOpenItem052
        print("5.2购买道具")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateOpenItem052", client_fd, msg001)
        return ok, noage,result
      end,
      [1053] = function ()    --5.3用户购买萌币和星星/updateOpenStart053
        print("5.3用户购买萌币和星星")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "updateOpenStart053", client_fd, msg001)
        return ok, noage,result
      end,
      [1061] = function ()    --6-1好友1通过id/返回好友信息
        print("加载好友信息")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "OpenFriends0601", client_fd, msg001)
        return ok, noage,result
      end,
      [1062] = function ()   --6-2好友2通过邀请id或名字返回数据
        print("6-2好友2通过邀请id或名字返回数据")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "QueryFriends0602", client_fd, msg001)
        return ok, noage,result
      end,
      [1063] = function ()   --6-3确定邀请好友
        print("6-3确定邀请好友")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "DeterFriends0603", client_fd, msg001)
        return ok, noage,result
      end,
      [1064] = function ()   --6-4是否同意邀请
        print("是否同意邀请")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "AddFriends0604", client_fd, msg001)
        return ok, noage,result
      end,
      [1071] = function ()   --7.1每日任务
        print("1每日任务")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "TaskDaliy0701", client_fd, msg001)
        return ok, noage,result
      end,
      [1072] = function ()   --7.2领取奖励
        print("7.2领取奖励")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "TaskDaliy0702", client_fd, msg001)
        return ok, noage,result
      end,
      [1073] = function ()   --7.3每日签到
        print("7.3每日签到")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "DaliyCheck0703", client_fd, msg001)
        return ok, noage,result
      end,
      [1081] = function ()   --8.1邮件
        print("8.1邮件")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "MailServer0801", client_fd, msg001)
        return ok, noage,result
      end,
       [1082] = function ()   --8.2邮件领取
         print("8.2邮件领取")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "MailServer0802", client_fd, msg001)
        return ok, noage,result
      end,
       [1091] = function ()   --9.1月卡
        print("9.1月卡")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "GameOnCard0901", client_fd, msg001)
        return ok, noage,result
      end,
       [1092] = function ()   --9.2领取月卡奖品
        print("9.2领取月卡奖品")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "GameOnCard0902", client_fd, msg001)
        return ok, noage,result
      end,
       [1093] = function ()    --9.3购买月卡
         print("3购买月卡")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "GameOnCard0903", client_fd, msg001)
        return ok, noage,result
      end,
      [1101] = function ()    --10.1查询排名前20名和本人排名
         print("1查看排行榜")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "RankingList01", client_fd, msg001)
        return ok, noage,result
      end,
      [1102] = function ()    --10.2关卡排行榜
         print("2关卡排行榜")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "RankingList02", client_fd, msg001)
        return ok, noage,result
      end,
      [1103] = function ()    --10.3钻石界面
         print("3钻石界面")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "RankingUId03", client_fd, msg001)
        return ok, noage,result
      end,
      [1104] = function ()    --10.4萌币界面
         print("4萌币界面")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "RankingUIc04", client_fd, msg001)
        return ok, noage,result
      end,
      [1105] = function ()    --10.5星星界面
         print("5星星界面")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "RankingUIs05", client_fd, msg001)
        return ok, noage,result
      end,
      [1106] = function ()    --10.6宝气界面
         print("6宝气界面")
        ok, noage,result = pcall(skynet.call,"talkbox", "lua", "RankingUIg06", client_fd, msg001)
        return ok, noage,result
      end,
--       [1046] = function ()   
--        return ok, noage,result
--      end,  
     }
     --消息运行
     local f = switch[messageId]
     print(type(f))
     if (f) then
        ok, noage,result = f()
        print(ok, noage,result)
        if ok then
          xfs_send( zipServer(1,noage,result) )
        else
          print("[LOG]******",os.date("%m-%d-%Y %X", skynet.time()),"error:")
        end
      else
        xfs_send(skynet.pack(1,0,text.."\0"))
    end
	end
	
}

--3.1连接完成后的发包连接--心跳
function CMD.start(gate, fd, proto)
	print("第一次握手时触发")
	print("***agent/CMD.start***")
	--4.1确定发包格式/sproto.lua
	host = sproto.new(proto.c2s):host "package"
	send_request = host:attach(sproto.new(proto.s2c))
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)
	client_fd = fd
	--4.3指定运行
	skynet.call(gate, "lua", "forward", fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
