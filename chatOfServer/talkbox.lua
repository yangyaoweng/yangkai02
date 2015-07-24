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

--解压函数
function unzipServer(text)
    print(type(text))
    print(text)
    local nextPos2,version   = bunpack(text,">h")
    local nextPos3,messageId = bunpack(text,">i",nextPos2)
    local nextPos4,msg1  = bunpack(text,">z",nextPos3)
    print(version,messageId,msg1)
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

--1进入游戏场景/用户登录
function CMD.createSecInterface(client_fd,talk_create)
  print("*****talkbox****CMD.createSecInterface进入游戏登录**************")
    local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--    local talk_create = {
--      name = "12",
--      passwords = "12",
--    }
  ok, nokey,result = pcall(skynet.call,"loginServer", "lua", "mysqlServer01", client_fd, mapUserInfo.msg)
  local createuser={}
  if(nokey.row_key == "yes") then
    createuser = protobuf.encode("talkbox.talk_result_msg", { msg = result} )
    return 2000,createuser
  elseif (nokey == "ok") then
    createuser = protobuf.encode("talkbox.talk_result_msg", { msg = result} )
    return 2001,createuser
  else
    print("用户没有宠物")
    createuser = protobuf.encode("talkbox.talk_result_msg", {msg = result})
    return 2010,createuser
  end
  print("---------------------------")
end

--1.1进入游戏场景/
function CMD.createSecInterface01(client_fd,talk_create)
  print("*****talkbox****CMD.createSecInterface进入游戏登录**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--    local talk_login = {
--      dbrkey = "33:12",
--      userId = 33,
--      roleopen = "33:12:20",
--    }
  ok, nokey,result = pcall(skynet.call,"loginServer", "lua", "loginServer0101", client_fd, mapUserInfo.msg)
  local createuser={}
  if nokey == "yes" then
    createuser = protobuf.encode("talkbox.talk_result_msg", { msg = result} )
    return 2005,createuser
  elseif onkey == "no" then
    print("用户没有正常登录")
    createuser = protobuf.encode("talkbox.talk_result", result)
    return 2999,createuser
  end
  print("---------------------------")
end

--1.1.1进入游戏场景/
function CMD.createSecInterface02(client_fd,talk_create)
  print("*****talkbox****CMD.createSecInterface进入游戏登录**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--    local talk_login = {
--      dbrkey = "33:12",
--      userId = 33,
--      roleopen = "33:12:20",
--    }
  ok, nokey,result = pcall(skynet.call,"loginServer", "lua", "loginServer0102", client_fd, mapUserInfo.msg)
  local createuser={}
  if nokey == "yes" then
    createuser = protobuf.encode("talkbox.talk_result_msg", { msg = result} )
    return 2006,createuser
  elseif onkey == "no" then
    print("用户没有正常登录")
    createuser = protobuf.encode("talkbox.talk_result", result)
    return 2999,createuser
  end
  print("---------------------------")
end

--1.2创建临时用户后/创建宠物
function CMD.createPet01(client_fd,talk_create)
  print("*****talkbox****CMD.createSecInterface进入游戏创建宠物**************")
  --得到用户数据
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_login = {
--    name = "Bob",
--    passwords = "123",
--    roles = 1,
--  }
  --用户创建过程
  ok, result = pcall(skynet.call,"loginServer", "lua", "mysqlCreateROle02", client_fd, mapUserInfo.msg)
  local createRole={}
  createRole = protobuf.encode("talkbox.talk_result", result)
  return 2020,createRole
end

--2宝气值界面
function CMD.tardInterface02(client_fd,talk_create)
  print("*****talkbox****7.2领取奖励**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  --local createUserInfo = protobuf.decode("talkbox.talk_friendaddr",talk_create)
  --print(createUserInfo.id)
  ok,onkey,result = pcall(skynet.call,"loginServer", "lua", "treaServer0102", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2012,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--3.1弹出的关卡信息
function CMD.PopUpPoint031(client_fd,talk_create)
  print("*****talkbox****CMD.1弹出关卡信息**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_create = {
--    dbrkey = "33:12",
--    pass = 315,
--  }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "mysqlSelectMap031", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg",  { msg = result} )
    return 2031,mapTable
  elseif onkey == "ok" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg",{ msg = result} )
    return 2131, mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 902})
    return 2999, mapTable
  end
end

--3.8开启关卡
function CMD.StatsPoint038(client_fd,talk_create)
  print("*****talkbox****CMD.8开启关卡**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_create = {
--    dbrkey = "33:12",
--    pass = 315,
--  }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "statsMap038", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg",  { msg = result} )
    return 2038,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result",  result )
    return 2999, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 902})
    return 2999, mapTable
  end
end

--3.2进入关卡
function CMD.OpenPoint0302(client_fd,talk_create)
  print("*****talkbox****CMD.2进入关卡**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  local talk_login = {
      dbrkey = "33:12",
      pass = 315,
      engame = "yes",
    }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "redisSelectMap0302", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
     local openTable = protobuf.encode("talkbox.talk_result_msg", {msg = result})
    return 2032,openTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 999})
    return 2999, mapTable
  end
end
--3.3进入游戏状态
function CMD.OpenPoint033(client_fd,talk_create)
  print("*****talkbox****CMD.3进入游戏状态**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
    --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--      trapstr = "3:8",
--      pos = "3:8",
--    }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "mysqlSelectMap033", client_fd, mapUserInfo.msg)
  --交互成功
  if onkey=="yes" then
    print("处理")
    local openTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2033,openTable
  --游戏结束失败
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg",  {msg = result} )
    return 2133, mapTable
  --游戏结束/宝藏挖完
  elseif onkey == "ok" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2133, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 999})
    return 2999, mapTable
  end
end
--3.4重生
function CMD.OpenPoint034(client_fd,talk_create)
  print("*****talkbox****CMD.4重生**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
    --得到用户数据
    local talk_login = {
      dbrkey = "33:12",
   }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "luaSelectMap034", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print("处理")
    local openTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2034,openTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result})
    return 2134, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 999})
    return 2999, mapTable
  end
end

--3.5游戏中购买钻石
function CMD.OpenPoint035(client_fd,talk_create)
  print("*****talkbox****CMD.5游戏中购买钻石**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
    --得到用户数据
    local talk_login = {
      dbrkey = "33:12",
   }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "luaSelectMap035", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print("处理")
    local openTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2035,openTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2135, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 999})
    return 2999, mapTable
  end
end

--3.6失败的结算
function CMD.OpenPoint036(client_fd,talk_create)
  print("*****talkbox****CMD.6失败的结算**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
    --得到用户数据
    local talk_login = {
      dbrkey = "33:12",
   }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "luaSelectMap036", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print("处理")
    local openTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2036,openTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2136, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 999})
    return 2999, mapTable
  end
end

--3.7道具的使用
function CMD.OpenPoint037(client_fd,talk_create)
  print("*****talkbox****CMD.7道具的使用**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
    --得到用户数据
--  local talk_login = {
--    dbrkey = "33:12",
--    itemOn = 2,
--    pos = "3:8",
--    trapstr = "3:8",
--    state = 2,
--  }
  ok, onkey, result = pcall(skynet.call,"checkBattle", "lua", "itemServerMap0307", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print("处理")
    local openTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2037,openTable
  elseif onkey == "no" then
    print("道具编号有误")
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2137, mapTable
  else
    local mapTable = protobuf.encode("talkbox.talk_result", {id = 999})
    return 2999, mapTable
  end
end


--4.1更换当前角色返回所有角色信息
function CMD.selectRole041(client_fd,talk_create)
  print("*****talkbox****4.1更换当前角色返回所有角色信息**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_updaterole = {
--      dbrkey = "33:12",
--    }
  ok, onkey, result = pcall(skynet.call,"roleServers", "lua", "changeRole041", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg",{msg = result} )
    return 2041,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--4.2更换当前角色onkeyonkeyonkey
function CMD.updateCharacter042(client_fd,talk_create)
  print("*****talkbox****4.2更换当前角色**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    roleopen = "33:12:20",
--  }
  ok, onkey, result = pcall(skynet.call,"roleServers", "lua", "dbrUpdateRole042", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print(result.gateNum)
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2042,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--4.3恢复角色生命值
function CMD.updateLife43(client_fd,talk_create)
  print("*****talkbox****4.3恢复角色生命值**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:20",
--  }
  ok, onkey, result = pcall(skynet.call,"roleServers", "lua", "characterLife043", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2043,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--4.4角色升级
function CMD.updateRole44(client_fd,talk_create)
  print("*****talkbox****4.4角色升级**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:41",
--    openmoney = 2,
--  }
  ok, onkey, result = pcall(skynet.call,"roleServers", "lua", "roleLevel044", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print(result.gateNum)
    local mapTable = protobuf.encode("talkbox.talk_result_msg", { msg = result} )
    return 2044,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--4.5角色快速升级
function CMD.updateRole45(client_fd,talk_create)
  print("*****talkbox****4.5角色快速升级**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:40",
--    levelS = 10,
--    openmoney = 2,
--  }
  ok, onkey, result = pcall(skynet.call,"roleServers", "lua", "roleLevel045", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    print(result.gateNum)
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2045,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--4.6添加用户角色槽
function CMD.updateSole46(client_fd,talk_create)
  print("*****talkbox****4.5角色快速升级**************")
  --用户创建过程
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    openmoney = 2,
--  }
  ok, onkey, result = pcall(skynet.call,"roleServers", "lua", "roleSlot046", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2046,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--5商城
function CMD.updateOpenMall05(client_fd,talk_create)
  print("*****talkbox****5商城**************")
--  local talk_login = {
--    id = 1,
--  }
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  print(type(mapUserInfo.msg))
  ok,onkey,result = pcall(skynet.call,"gameMall", "lua", "openMall05", client_fd, mapUserInfo.msg)
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2050,mapTable
  elseif onkey == "ok" then
     local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2150,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--5.1用户购买角色
function CMD.updateOpenRole051(client_fd,talk_create)
  print("*****talkbox****5.1用户购买角色**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--  local talk_login = {
--    openuser = "33:12",
--    openrole  = 9,            --宠物编号
--    openmoney = 2,       --购买方式
--  }
  ok,onkey,result = pcall(skynet.call,"gameMall", "lua", "openRole051", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2051,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end
--5.2用户购买道具
function CMD.updateOpenItem052(client_fd,talk_create)
  print("*****talkbox****5.1用户购买角色**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--  local talk_login = {
--    openuser = "33:12",
--    openitem  = 1,      --道具编号
--    openNo = 8,           --数量
--    openmoney = 2,    --购买方式
--  }
  ok,onkey,result = pcall(skynet.call,"gameMall", "lua", "openItem052", client_fd,mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2051,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end
--5.3用户购买萌币和星星
function CMD.updateOpenStart053(client_fd,talk_create)
  print("*****talkbox****5.1用户购买角色**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--    local talk_login = {
--    openuser = "33:12",
--    openrole  = 9,
--    openmoney = 2,
--  }
  ok,onkey,result = pcall(skynet.call,"gameMall", "lua", "openStart053", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey=="yes" then
    local mapTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2051,mapTable
  elseif onkey == "no" then
    local mapTable = protobuf.encode("talkbox.talk_result", result)
    return 2999, mapTable
  end
end

--6-1好友1通过id/返回好友信息
function CMD.OpenFriends0601(client_fd,talk_create)
  print("*****talkbox****6好友**************")
  --local talk_login={id = 33}
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
  ok,result = pcall(skynet.call,"addBuddy", "lua", "openFriends0601", client_fd, mapUserInfo.msg)
  local openfriends06 = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
  return 2061,openfriends06
end
--6-2好友2通过邀请id或名字返回数据
function CMD.QueryFriends0602(client_fd,talk_create)
  print("*****talkbox****6邀请好友**************")
 -- local talk_login={name = "32"}
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
  ok,onkey,result = pcall(skynet.call,"addBuddy", "lua", "queryFriends0602", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local openfriends062 = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2062,openfriends062
  else
    local openfriends062 = protobuf.encode("talkbox.talk_result", result)
    return 2999,openfriends062
  end
end
--6-3确定邀请好友
function CMD.DeterFriends0603(client_fd,talk_create)
  print("*****talkbox****6确定邀请好友**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--   local talk_login={
--    purid = 31,
--    puruser = "yangddd",
--    purkey = "yang:001",
--    souid = 33,
--    souuser = "kai001",
--    soukey = "kai001:33",
--  }
  ok,onkey,result = pcall(skynet.call,"addBuddy", "lua", "addsFriends06", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local openfriends061 = protobuf.encode("talkbox.talk_result", result)
    return 2063,openfriends061
  else
    local openfriends061 = protobuf.encode("talkbox.talk_result", result)
    return 2999,openfriends061
  end
end

--6-4是否同意邀请
function CMD.AddFriends0604(client_fd,talk_create)
  print("*****talkbox****6确定邀请好友**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
  --mapUserInfo.msg)
--  local talk_login={
--    nokey = "yes",
--    purid = 31,
--    souid = 33,
--  }
  ok,onkey,result = pcall(skynet.call,"addBuddy", "lua", "AgreedFriends0604", client_fd,mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local openfriends061 = protobuf.encode("talkbox.talk_result", result)
    return 2064,openfriends061
  else
    local openfriends061 = protobuf.encode("talkbox.talk_result", result)
    return 2999,openfriends061
  end
end

--7.1每日任务
function CMD.TaskDaliy0701(client_fd,talk_create)
  print("*****talkbox****7.1每日任务**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  --local createUserInfo = protobuf.decode("talkbox.talk_friendaddr",talk_create)
  --print(createUserInfo.id)
  ok,onkey,result = pcall(skynet.call,"dailyTask", "lua", "Daily_Task0701", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2071,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--7.2领取奖励
function CMD.TaskDaliy0702(client_fd,talk_create)
  print("*****talkbox****7.2领取奖励**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  --local createUserInfo = protobuf.decode("talkbox.talk_friendaddr",talk_create)
  --print(createUserInfo.id)
  ok,onkey,result = pcall(skynet.call,"dailyTask", "lua", "Daily_Task0702", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2072,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--7.3每日签到
function CMD.DaliyCheck0703(client_fd,talk_create)
  print("*****talkbox****7.3每日签到**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  --local createUserInfo = protobuf.decode("talkbox.talk_friendaddr",talk_create)
  --print(createUserInfo.id)
  ok,onkey,result = pcall(skynet.call,"dailyTask", "lua", "daily_Check0703", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2073,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--8.1邮件
function CMD.MailServer0801(client_fd,talk_create)
  print("*****talkbox***8.1邮件**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  --local createUserInfo = protobuf.decode("talkbox.talk_friendaddr",talk_create)
  --print(createUserInfo.id)
  ok,onkey,result = pcall(skynet.call,"mailSelect", "lua", "mailSelect0801", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2081,taskTable
  elseif onkey == "on" then
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2181,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--8.2邮件领取
function CMD.MailServer0802(client_fd,talk_create)
  print("*****talkbox***8.1邮件**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--    mailon = 1,
--  }
  ok,onkey,result = pcall(skynet.call,"mailSelect", "lua", "mailSelect0802", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result", result )
    return 2082,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--9.1月卡
function CMD.GameOnCard0901(client_fd,talk_create)
  print("*****talkbox***8.1邮件**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"monthCardservice", "lua", "onCard0901", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2091,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--9.2领取月卡奖品
function CMD.GameOnCard0902(client_fd,talk_create)
  print("*****talkbox***8.1邮件**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--    cardId = 30,
--  }
  ok,onkey,result = pcall(skynet.call,"monthCardservice", "lua", "onCard0902", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result", result )
    return 2092,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--9.3购买月卡
function CMD.GameOnCard0903(client_fd,talk_create)
  print("*****talkbox***8.1邮件**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"monthCardservice", "lua", "onCard0903", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2093,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--10.1查看排行榜
function CMD.RankingList01(client_fd,talk_create)
  print("*****talkbox***10.1查询排名前20名和本人排名**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"rankingList", "lua", "rankingList01", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2101,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--10.2关卡排行榜
function CMD.RankingList02(client_fd,talk_create)
  print("*****talkbox***10.2关卡排行榜**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"rankingList", "lua", "rankingList02", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2102,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--10.3钻石界面
function CMD.RankingUId03(client_fd,talk_create)
  print("*****talkbox***10.3钻石界面**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"rankingList", "lua", "diamonUId", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2103,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--10.4萌币界面
function CMD.RankingUIc04(client_fd,talk_create)
  print("*****talkbox***10.4萌币界面**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"rankingList", "lua", "diamonUIc", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2104,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--10.5星星界面
function CMD.RankingUIs05(client_fd,talk_create)
  print("*****talkbox***10.5星星界面**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"rankingList", "lua", "diamonUIs", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2105,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end

--10.6宝气界面
function CMD.RankingUIg06(client_fd,talk_create)
  print("*****talkbox***10.6宝气界面**************")
  local mapUserInfo = protobuf.decode("talkbox.talk_result_msg",talk_create)
  print(mapUserInfo.msg)
--  local table_task={
--    dbrkey = "33:12",
--  }
  ok,onkey,result = pcall(skynet.call,"rankingList", "lua", "diamonUIg", client_fd, mapUserInfo.msg)
  --print(result.mallrole[1]["name"])
  if onkey == "yes" then
    local taskTable = protobuf.encode("talkbox.talk_result_msg", {msg = result} )
    return 2106,taskTable
  else
    local taskTable = protobuf.encode("talkbox.talk_result", result)
    return 2999,taskTable
  end
end


----------------------------------------------------------------------------------

--function CMD.createUser(client_fd,talk_create)
--	print("*****talkbox****CMD.createUser**************")
--	print(talk_create)
--	local createUserInfo = protobuf.decode("talkbox.talk_create",talk_create)
--	print(createUserInfo.name)
--	print("**开始解析**")
--	if createUserInfo==false then
--		print("***解析失败***")
--		return protobuf.encode("talkbox.talk_result",{id=1})--解析protocbuf错误
--	end
--	--新内容测试
-- ok, result = pcall(skynet.call,"talkmysql", "lua", "my001", client_fd, msg001)
-- print(ok)
-- 
--	--判断用户名
--	if isUser(createUserInfo.name) then
--	  print("已经存在该用户")
--		--return strd
--		--return protobuf.encode("talkbox.talk_result",{id=2})--已经存在该名字
--		yang = "yyyyyyy"
--		return protobuf.encode("talkbox.talk_itemuse",{itemNo=2,itemName="sssss",})
--	end
--	
--	auto_id=auto_id+1
--	print("添加用户名****")
--	local userInfo = {
--		userid = auto_id,
--		name = createUserInfo.name,
--	}
--	print("用户id:", userInfo.userid)
--	print("用户名:",userInfo.name)
--
--	--将数据加密
--	local data_UserInfo = protobuf.encode("talkbox.talk_create", userInfo)
--
--	talk_users[userInfo.userid]=userInfo
--	--老用户
--	for userid in pairs(client_fds) do
--		local new_users = protobuf.encode("talkbox.talk_users",{['users']={userInfo}})
--    		local msgg=bpack(">hiz",1,1002,new_users)
--    		local nex = string.len(msgg)
--    		local msggx=bpack(">hhiz",nex,1,1002,new_users)
--		print("--发送给老用户--")
--		return strd;
--		--socket.write(client_fds[userid], msggx)
--		--socket.write(client_fds[userid], netpack.pack(skynet.pack(1,1002,new_users)))
--	end
--	--新用户
--	print("--发送给新用户-")
--	client_fds[userInfo.userid]=client_fd;
--  	local msgg=bpack(">hiz",1,1002,data_UserInfo)
--  	local nex = string.len(msgg)
--  	local msggx=bpack(">hhiz",nex,1,1002,data_UserInfo)
--	--socket.write(client_fds[userInfo.userid], msggx)
--	--return protobuf.encode("talkbox.talk_result",{id=0})
--	return strd;
--end

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
--function CMD.rmUser(client_fd)
--	for userid in pairs(client_fds) do
--		
--		if client_fds[userid]==client_fd then
--			for userid2 in pairs(client_fds) do
--				socket.write(client_fds[userid2], netpack.pack(skynet.pack(1,1011,protobuf.encode("talkbox.talk_result",{id=userid}))))
--			end
--			
--			talk_users[userid]=nil
--			client_fds[userid]=nil
--			
--		end
--	end
--end

--function isUser(name)
--	print("判断用户名是否存在")
--	for userid in pairs(talk_users) do
--		if talk_users[userid].name==name then
--		  print("用户名存在")
--			return true
--		end
--	end
--	print("用户名不存在")
--	return false
--end

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
