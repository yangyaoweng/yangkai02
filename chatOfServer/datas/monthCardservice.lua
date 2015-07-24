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

--9.1月卡//月卡编号在购买后自动产生 CMD.onCard0901(dbm,dbr,dbrT, client_fd, table_tasks)
function CMD.onCard0901(dbm,dbr,dbrT, client_fd, table_tasks)
  local a = os.clock()
  local table_task={
    dbrkey = "33:12",
  }
  --local table_task = unserialize(table_tasks)
  local obj =datacenter.get(table_task.dbrkey)
  print("用户角色信息",dump(obj))
  user_names[table_task.dbrkey] =obj
  if user_names[table_task.dbrkey] == nil then
    print("用户还未登录")
    return "no",{id = 902}
  end
 -- sharedata.update(table_task.dbrkey, { a =2 })

  --1判断用户是否购买了月卡
  if  user_names[table_task.dbrkey][cli_user_t[9]] == nil then
    user_names[table_task.dbrkey][cli_user_t[9]] = dbr:hget(user_names[table_task.dbrkey][cli_user[2]],cli_user_t[9])
    print("取得月卡键")
  end
  if  user_names[table_task.dbrkey][cli_user_t[9]] == '1' then
    print("用户还没有购买月卡")
    return "no",{id = 8}
  else
    print("用户已经购买月卡")
    --1.判断月卡数据是否存在
    if user_card[table_task.dbrkey] == nil then
      print("月卡数据不存在")
      local luas = "call cardData09022("
      luas = luas..user_names[table_task.dbrkey][cli_user[1]]..')'
      local res = dbm:query(luas)
      print(dump(res))
      user_card[table_task.dbrkey] = res[1][1]
    else
      print("月卡数据存在")
    end
    --2.判断月卡数据是否过期
    local uc = tonumber(os.date("%y%m%d"))
    print(uc) 
    if user_card[table_task.dbrkey][cli_card[1]] <= uc and  user_card[table_task.dbrkey][cli_card[2]] > uc then
      print("有效")
      local res011 = dbr:exists(user_names[table_task.dbrkey][cli_user_t[9]])
      print(user_names[table_task.dbrkey][cli_user_t[9]])
      --3.通过返回的数字判断是否全部领取了
      if res011 == false then
        print("用户还未领取过")
        return "yes",serialize({})
      else
        print("用户已经领取过")
        local res012 =dbr:smembers(user_names[table_task.dbrkey][cli_user_t[9]]) 
        print(dump(res012))
        local b = os.clock()
        print(b-a)
        return "yes",serialize(res012)
      end
    else
       --3.通过月卡的有效时间判断开始和结束时间
      print("无效过期")
      return "no" ,{id = 9}
    end
    
  end
end

--9.2领取月卡奖品//触发购买信息 CMD.onCard0902(dbm,dbr,dbrT, client_fd, table_tasks)
function CMD.onCard0902(dbm,dbr,dbrT, client_fd, table_tasks)
  local table_task={
    dbrkey = "33:12",
    cardId = 30,
  }
--  local table_task = unserialize(table_tasks)
  if user_names[table_task.dbrkey] == nil then
    print("用户还未登录")
    return "no",{id = 902}
  end
  --1得到奖励数据
  if user_card[table_task.dbrkey] == nil then
    print(" 数据不存在月卡数据异常")
    return "no",{id = 902}
  end
  if table_task.cardId >31 then
    print("输入的日期不对")
    return "no",{id = 902}
  end
  local uc = tonumber(os.date("%y%m%d"))
  if user_card[table_task.dbrkey][cli_card[1]] <= uc and  user_card[table_task.dbrkey][cli_card[2]] > uc then
    print("没有过期")
    print("月卡等级:",user_card[table_task.dbrkey][cli_card[4]])
    print("月卡等级数据是否存在:",card_Item[user_card[table_task.dbrkey][cli_card[4]]][table_task.cardId])
    if card_Item[user_card[table_task.dbrkey][cli_card[4]]][table_task.cardId] == nil then
      print("全局没有这个数据")
      local res090202 = "call cardDatas0902("
      res090202 = res090202..table_task.cardId..dbmL.lc..user_card[table_task.dbrkey][cli_card[4]]..')'
      print(res090202)
      local res090203 = dbm:query(res090202)
      print(dump(res090203))
      if res090203[1][1] == nil then
        print("输入有误")
        return "no",{id = 903}
      end
      card_Item[user_card[table_task.dbrkey][cli_card[4]]][table_task.cardId]=res090203[1][1]
      print("月卡等级数据:",dump(card_Item[user_card[table_task.dbrkey][cli_card[4]]][table_task.cardId]))
    else
      print("全局有这个数据")
    end
    --2标记用户已经领取
    local card01 = dbr:hget(table_task.dbrkey,cli_user_t[9])
    local res090204 = dbr:sadd(card01,table_task.cardId)
    if res090204 == 1 then
      print("可以领取")
      --3给用户发送邮件
      --奖励
      local userA = {[1] =9,[2]=15}
      local l =3
      for k,v in pairs(card_Item[user_card[table_task.dbrkey][cli_card[4]]][table_task.cardId]) do
         userA[l] = cardItemTable[k]
         userA[l+1] = v
         l =l +2
      end
      print(dump(userA))
      local userC = serialize(userA)
      local tmail = dbr:hget(table_task.dbrkey,cli_user_t[8])
      print(tmail)
      local  userB = dbr:rpush(tmail, userC)
      return "yes",{id =8 }
    else
      print("已经领取")
      return "yes",{id = 9}
    end

  else
    print("不可以领取过期")
  end
    
end

--9.3购买月卡//生产键名 CMD.onCard0903(dbm,dbr,dbrT, client_fd, table_task)
function CMD.onCard0903(dbm,dbr,dbrT, client_fd, table_tasks)
--  local table_task={
--    dbrkey = "33:12",
--  }
  local table_task = unserialize(table_tasks)
  local cardVip = 1
  local a = os.clock() 
  if user_names[table_task.dbrkey] == nil then
    print("用户还未登录")
  end
  --1用户购买月卡/时间
  local st = tonumber(os.date("%y%m%d"))
  st = st+100
  local st1 = tonumber(os.date("%y%m%d"))
  --2写入数据库
  local luas = "call cardData0902("
  luas = luas..user_names[table_task.dbrkey][cli_user[1]]..dbmL.lc..st1..dbmL.lc..st..dbmL.lcz..table_task.dbrkey..dbmL.lz2..cardVip..')'
  print(luas)
  local res = dbm:query(luas)
  print("----",dump(res))
  user_card[res[1][1][cli_card[3]]] = res[1][1]
  user_names[table_task.dbrkey][cli_user_t[9]] = res[1][1][cli_card[3]]
  local card093 = dbr:hset(user_names[table_task.dbrkey][cli_user[1]],cli_user_t[9],res[1][1][cli_card[3]])
  print(dump(user_card))
  local b = os.clock()
  print(b-a) 
  return "yes",serialize(user_card[res[1][1][cli_card[3]]])
end

------------------------------------------------------------

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
--  onCard0901(dbm,dbr,dbrT)
--  onCard0902(dbm,dbr,dbrT)

	skynet.register "monthCardservice"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



