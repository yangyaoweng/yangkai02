local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"

local datacenter = require "datacenter"

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
-------------redis与mysql组合
--  print(dump(user_names[talk_updaterole.dbrkey]))
--  local obj =datacenter.get(talk_updaterole.dbrkey)
--  print("用户角色信息",dump(obj))
--  user_names[talk_updaterole.dbrkey] =obj
--  
--    datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
--    print(dump(datacenter.get(talk_updaterole.dbrkey)))
------------------------------------------------------------

--8.1邮件 CMD.mailSelect0801(dbm,dbr,dbrT, client_fd, table_tasks)
function CMD.mailSelect0801(dbm,dbr,dbrT, client_fd, table_tasks)
  local a = os.clock()
  local table_task={
    dbrkey = "33:12",
  }
--  local table_task = unserialize(table_tasks)
  local obj =datacenter.get(table_task.dbrkey)
  print("用户角色信息",dump(obj))
  user_names[table_task.dbrkey] =obj
  if user_names[table_task.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
  print("到这里了")
  local mail081 = user_names[table_task.dbrkey][cli_user_t[8]]
  print("2")
  if mail081 == nil then
    print("3")
    local user0801 = dbr:hget(table_task.dbrkey,cli_user_t[8])
    print("4")
    if user0801 == nil then
      return "no",{id = 902}
    end
    user_names[table_task.dbrkey][cli_user_t[8]] = user0801
    print("5",user0801)
    local res = dbr:exists(user0801)
    if res == 0 then
      print("键不存在")
      return "no",{id = 902}
    end
  end
  print("6'")
  print("mail081",user_names[table_task.dbrkey][cli_user_t[8]])
  local user05 = dbr:lrange(user_names[table_task.dbrkey][cli_user_t[8]],0,-1)
  print("键值:",dump(user05))
   local b = os.clock()
   local t = os.time()
   
   print(math.floor(t / 86400))
   print(b-a)
  return "yes" , user05
end

--8.2邮件领取CMD.mailSelect0802(dbm,dbr,dbrT, client_fd, table_task)
function CMD.mailSelect0802(dbm,dbr,dbrT, client_fd, table_tasks)
--  local table_task={
--    dbrkey = "33:12",
--    mailon = 8,
--  }
  local table_task = unserialize(table_tasks)
  --读取邮件/通过邮件编号
  local rest = dbr:lindex(user_names[table_task.dbrkey][cli_user_t[8]],(table_task.mailon-1))
  print("ss",rest)
  --你输入的邮件编号有误
  if rest == nil then
    print("你输入的邮件编号有误")
    return "no",{id = 902}
  end
   --字符转table
  local luaTable = unserialize(rest)
  print(dump(luaTable))
  if luaTable[2] ~= 0 then
    local k = #(luaTable)
    print("增加之前",dump(user_item))
    for i = 3,k,2  do
      print("循环")
      local resk = dbr:hincrby( user_names[table_task.dbrkey][cli_user[2]], mailTable[luaTable[i] ], luaTable[i+1] )
      
      if luaTable[i] > 8 then
        print(luaTable[i])
        user_names[table_task.dbrkey][mailTable[luaTable[i] ] ] =resk
      else
        print(luaTable[i])
        user_item[table_task.dbrkey][mailTable[luaTable[i] ] ] =resk
      end
    end
    luaTable[2] = 0
    local userC = serialize(luaTable)
    local resw = dbr:lset(user_names[table_task.dbrkey][cli_user_t[8]],(table_task.mailon-1),userC)
    print(user_names[table_task.dbrkey][cli_user[6]])
    print("增加之后",dump(user_item))
    return "yes",{id = 8}
  end
  print("已经领取")
  return "no",{id = 902}
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
--	mailSelect0801(dbm,dbr,dbrT)

	
	skynet.register "mailSelect"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



