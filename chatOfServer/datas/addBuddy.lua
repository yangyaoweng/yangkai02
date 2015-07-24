local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"

local sharedata = require "sharedata"

require "gameG"

local CMD = {}
local client_fds={}
------------redis
local conf = {
	host = "127.0.0.1" ,
	port = 6379 ,
	db = 0
}
local confTM ={
  host = "127.0.0.1" ,
  port = 6379 ,
  db = 1
} 
------------------------------------------------------------

--6.1好友信息 CMD.openFriends0601(dbm, dbr, dbrT,client_fd,talk_logins)
function CMD.openFriends0601(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock() 
  --查询好友表/
  local talk_login={id = 33}
--  local talk_login = unserialize(talk_logins)
  print("dddddddddddd",talk_login.id)
  local luas = "call openFriends07("
  luas = luas ..talk_login.id..')'
  local res = dbm:query(luas)
  local userd ={}
  for k,v in pairs(res[1]) do
    if type(v) == "table" then
      print("好友名:",v["purName"],v["friKey"])
      local users = dbr:hmget(v["friKey"],cli_user[1], cli_user[3],cli_user[5],cli_user[9],cli_user[11])
      table.insert(userd,{userId=users[1],purName = v["purName"],gasNo = users[2],usegasValues = users[3],pass = users[4],start = users[5]})
    end
  end
  local userf = {}
  userf.friends = userd
  userf.addfriend = res[2]
  local b = os.clock()
  print(b-a)
  print("userd--",dump(userf))
  return serialize(userf)
end

--6-2好友查询 CMD.queryFriends0602(dbm, dbr, dbrT,client_fd,talk_login)
function CMD.queryFriends0602(dbm, dbr, dbrT,client_fd,talk_login)
  local talk_login={name = "32"}
  --查询好友表/
--  local talk_login = unserialize(talk_logins)
  print("dddddddddddddd",talk_login.name)
  local luas = ""
  local n = tonumber(talk_login.name);
  if n then
   -- n就是得到数字
    luas = luas .."call queryFriends06("..n..')'
  else
   -- 转数字失败,不是数字, 这时n == nil
   luas = luas .."call queryFriends061("..dbmL.lr..talk_login.name..dbmL.lr..')'
  end
  local res = dbm:query(luas)
  print("userd--",dump(res))
  if res[1][1]["row_key"] == "yes" then
    local userdb = {}
    print("用户存在")
    userdb = res[2][1]
    print(dump(userdb))
    return "yes",serialize(userdb)
  else
    print("用户不存在")
    return "no",{id = 120}
  end
end

--6-3确定邀请好友
function CMD.addsFriends06(dbm, dbr, dbrT,client_fd,talk_logins)
  --查询好友表/
--  local talk_login={
--    purid = 31,
--    puruser = "yangddd",
--    purkey = "yang:001",
--    souid = 33,
--    souuser = "kai001",
--    soukey = "kai001:33",
--  }
  local talk_login = unserialize(talk_logins)
  local luas = "call addFriends062("
  luas = luas ..talk_login.purid..dbmL.lcz..talk_login.puruser..dbmL.lz..talk_login.purkey..dbmL.lz2..talk_login.souid..dbmL.lcz..talk_login.souuser..dbmL.lz..talk_login.soukey..dbmL.lr..')'
  print(luas)
  local res = dbm:query(luas)
  print("openMall--",dump(res))
  if res[1][1]["row_key"] == 0 then
    print("用户已经添加")
    return "no",{id = 121}
  else
    print("用户添加成功")
    return "yes",{id = 8}
  end
  
end
--6-4同意被邀请
function CMD.AgreedFriends0604(dbm, dbr, dbrT,client_fd,talk_logins)
  --查询邀请表/
--    local talk_login={
--    nokey = "yes",
--    purid = 31,
--    souid = 33,
--  }
  local talk_login = unserialize(talk_logins)
  local luas = "call addFriends063("
  luas = luas ..dbmL.lr..talk_login.nokey..dbmL.lz2..talk_login.purid..dbmL.lc..talk_login.souid..')'
  print(luas)
  local res = dbm:query(luas)
  print("openMall--",dump(res))
  if res[1][1]["row_key"] == 1 then
    print("同意邀请")
    return "yes",{id = 9}
  elseif res[1][1]["row_key"] ==2 then
    print("没有消息")
    return "no",{id = 123}
  else
    print("未同意邀请")
    return "no",{id = 124}
  end
  
end

--------------------------------------------------------------------------
skynet.start(function()
	local dbm=mysql.connect{
		host="127.0.0.1",
		port=3306,
		database="skynet",
		user="root",
		password="root",
		max_packet_size = 1024 * 1024
	}
	if not dbm then
		print("failed to connect")
	end
	--表示连接成功
	print("连接成功")
  	--编码格式
	dbm:query("set names utf8")
	-----redis
	local dbr = redis.connect(conf)
	local dbrT = redis.connect(confTM)
--	ItemsMap(dbm,dbr,dbrT)
--openFriends0601(dbm,dbr,dbrT)
--queryFriends0602(dbm,dbr,dbrT)
--  onCard0901(dbm,dbr,dbrT)

	
	skynet.register "addBuddy"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))

	end)
end)



