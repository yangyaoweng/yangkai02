local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"

local sharedata = require "sharedata"
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

--7活动
--7.1每日任务CMD.Daily_Task0701(dbm, dbr, dbrT, client_fd, table_tasks)
function CMD.Daily_Task0701(dbm, dbr, dbrT, client_fd, table_tasks)
   local a = os.clock() 
  --所需数据
  local table_task={
    dbrkey = "33:12",
  }
  local obj =datacenter.get(table_task.dbrkey)
  print("用户角色信息",dump(obj))
  user_names[table_task.dbrkey] =obj
--  local table_task = unserialize(table_tasks)
  --判断是否为当天的数据
  local t7 = os.time() 
  if user_names[table_task.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
  t7 = math.floor(t7 / 86400)
  local time07 = dbr:hmget(table_task.dbrkey,cli_user_t[4],cli_user_t[5])
  print(dump(time07))
  print(t7)
  if tonumber(time07[2]) == t7 then
    print("是当天任务")
  else
    print("不是当天任务清零")
    local timeres07 = dbr:hmset(table_task.dbrkey,cli_user_t[1],0,cli_user_t[2],0,cli_user_t[3],0,cli_user_t[5],t7)
    local timeres0701 = dbr:del(time07[1])
    print("初始化数据",dump(timeres07))
  end
  --得到任务数据
  local res = dbr:hmget(table_task.dbrkey,cli_user_t[1],cli_user_t[2],cli_user_t[3])
  --返回已完成任务和未完成任务
  local luas = "call dailyTask0701("
  luas = luas ..res[1]..dbmL.lc..res[2]..dbmL.lc..res[3]..')'
  print(luas)
  local res = dbm:query(luas)
  print("yes--",dump(res))
  --返回已领取的奖励编号
  local taskS = dbr:exists(time07[1])
  if taskS == true then
    print("已经领取过奖励")
    local taskC = dbr:smembers(time07[1])
    local task01 = {}
    for k,v in pairs(taskC) do
      table.insert(task01,{taskid = v})
    end
    local uddd = { userTack01 =res[1], userTack02 = res[2] ,taskOn = task01 }
    print("数据",dump(uddd))
    local b = os.clock()
    print(b-a)
    return "yes",serialize( {userTack01 = res[1], userTack02 = res[2] ,taskOn = task01 } )
  else
    local uddd = { userTack01 =res[1], userTack02 = res[2] ,taskOn = {} }
    print("数据",dump(uddd))
    print("还未领取过奖励")
    local b = os.clock()
    print(b-a)
    return "yes",serialize( {userTack01 = res[1], userTack02 = res[2] ,taskOn = {} } )
  end
  return "no",{id = 902}
end

--7.2领取奖励 CMD.Daily_Task0702(dbm, dbr, dbrT, client_fd, table_tasks)
function CMD.Daily_Task0702(dbm, dbr, dbrT, client_fd, table_tasks)
  local a = os.clock()
  --所需数据
  local table_task={
    dbrkey = "33:12",
  }
--  local table_task = unserialize(table_tasks)
  if user_names[table_task.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
  --得到任务数据
  local res = dbr:hmget(table_task.dbrkey,cli_user_t[1],cli_user_t[2],cli_user_t[3])
  --返回已完成任务和未完成任务
  local luas = "call dailyTask0702("
  luas = luas ..res[1]..dbmL.lc..res[2]..dbmL.lc..res[3]..')'
  print(luas)
  local res = dbm:query(luas)
  print("领取奖励",dump(res))
  --要领取的奖品初始化
  local taskS2 = {stars = 0,userCurr = 0, usegasValues = 0, diamond=0}
  local taskC = dbr:hget(table_task.dbrkey,cli_user_t[4])
  --奖励统计
  for k,v in pairs(res[1]) do
    if type(v) == "table" then
      if (dbr:sadd(taskC,v.taskId) ) == 1 then
        print("加")
        taskS2.stars = taskS2.stars +v.stars
        taskS2.userCurr = taskS2.userCurr +v.userCurr
        taskS2.usegasValues = taskS2.usegasValues + v.usegasValues
        taskS2.diamond =  taskS2.diamond + v.diamond
      else
        print("已经领取",v.taskId)
      end
    end
  end
  --加给用户
  local taskuser02 = {}
  for k,v in pairs(taskS2) do
    --print(k,v)
    local restask02 = dbr:hincrby(table_task.dbrkey, k,v)
    user_names[table_task.dbrkey][k] = restask02
    taskuser02[k] = restask02;
  end
  datacenter.set(table_task.dbrkey,user_names[table_task.dbrkey])
  print(dump(datacenter.get(table_task.dbrkey)))
  print(dump(taskuser02))
  local b = os.clock()
  print(b-a)
  return "yes",serialize( {taskuser02} )
end

--7.3每日签到CMD.dailyCheck0703(dbm, dbr, dbrT, client_fd, table_task)
function CMD.dailyCheck0703(dbm, dbr, dbrT, client_fd, table_tasks)
--  local table_task={
--    dbrkey = "33:12",
--  }
  local table_task = unserialize(table_tasks)
  if user_names[table_task.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
   --取得今天的日期/比较取得是否连续登录
  local t2 = tonumber(dbr:hget(table_task.dbrkey, "timeOld") )
  --领取奖励/1判断
    local t = os.time() 
    t = math.floor(t / 86400)
   if t == t2 then
    print("今天已经领取")
   else
     print("今天还没有领取")
     local timel
     if t== (t2+1) then
      print("是连续登录")
      timel = dbr:hincrby(table_task.dbrkey, "timeLogin", 1)
      if timel > 14 then
        timel = dbr:hset(table_task.dbrkey, "timeLogin", 1)
        timel = 1
      end
      local times = dbr:hset(table_task.dbrkey, "timeOld", t) --number
     else
      print("不是连续登录")
      local times = dbr:hmset(table_task.dbrkey, "timeOld", t, "timeLogin", 1) --OK
     end
     math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
      --领取奖励/2领取--返回数据为nil不加为0
     local switch = {
      [1] = function (userkey01,t4,dbr) --当连续登录1天
        --领取奖励
        local s = math.random(1,20)
        local h = math.floor(s) + 10
        --local userA = "1:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=1,[3] = 11, [4] =h })
        --邮件字段
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 1." ,{id = 8}
      end,
      [2] = function (userkey01,t4,dbr) --当连续登录2天
        --领取奖励
        local s = math.random(1,20)
        local h = math.floor(s) + 40
        --local userA = "2:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=2,[3] = mailType [11], [4] =h })
        local userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 2.", { id = 8 }
      end,
      [3] = function (userkey01,t4,dbr) --当连续登录3天
        local s = math.random(1,80)
        local h = math.floor(s) + 70
        s = math.random(1,5)
        local h2 = math.floor(s)
        --local userA = "3:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h..mailType[13]..mailType[h2]..mailType[13]..1
        local userA =serialize( {[1] =9,[2]=3,[3] = 11, [4] =h,[5] = h2,[6]= 1 })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 3.", {id = 8 }
      end,
      [4] = function (userkey01,t4,dbr) --当连续登录4天
        local s = math.random(1,40)
        local h = math.floor(s) + 110
        --local userA = "4:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=4,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 4.", {id = 8 }
      end,
      [5] = function (userkey01,t4,dbr) --当连续登录5天
        local s = math.random(1,40)
        local h = math.floor(s) + 160
        --local userA = "5:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=5,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 5.", {id = 8 }
      end,
      [6] = function (userkey01,t4,dbr) --当连续登录6天
        local s = math.random(1,40)
        local h = math.floor(s) + 210
        --local userA = "6:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=6,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 6.", {id = 8 }
      end,
      [7] = function (userkey01,t4,dbr) --当连续登录7天
        local s = math.random(1,240)
        local h = math.floor(s) + 260
        s = math.random(1,5)
        local h2 = math.floor(s) 
        --local userA = "7:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h..mailType[13]..mailType[h2]..mailType[13]..3
        local userA =serialize( {[1] =9,[2]=7,[3] = 11, [4] =h,[5] =h2,[6] = 3  })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        
        return "case 7.",{id = 8 }
      end,
      [8] = function (userkey01,t4,dbr) --当连续登录8天
        local s = math.random(1,40)
        local h = math.floor(s) + 310
        --local userA = "8:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=8,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 8.", {id = 8 }
      end,
      [9] = function (userkey01,t4,dbr) --当连续登录9天
        local s = math.random(1,40)
        local h = math.floor(s) + 360
        --local userA = "9:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=9,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 9.", {id = 8 }
      end,
      [10] = function (userkey01,t4,dbr) --当连续登录10天
        local s = math.random(1,90)
        local h = math.floor(s) + 410
        s = math.random(1,5)
        local h2 = math.floor(s) 
        --local userA = "10:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h..mailType[13]..mailType[h2]..mailType[13]..2
        local userA =serialize( {[1] =9,[2]=10,[3] = 11, [4] =h ,[5] = h2,[6] = 2})
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 10.", {id = 8 }
      end,
      [11] = function (userkey01,t4,dbr) --当连续登录11天
        local s = math.random(1,40)
        local h = math.floor(s) + 460
        --local userA = "11:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=11,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 11.", {id = 8 }
      end,
      [12] = function (userkey01,t4,dbr) --当连续登录12天
        local s = math.random(1,40)
        local h = math.floor(s) + 510
       --local userA = "12:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=12,[3] = 11, [4] =h })
        local userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 12.",{id = 8 }
      end, 
      [13] = function (userkey01,t4,dbr) --当连续登录13天
        local s = math.random(1,40)
        local h = math.floor(s) + 560
       -- local userA = "13:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h
        local userA =serialize( {[1] =9,[2]=13,[3] = 11, [4] =h })
        local  userB = dbr:rpush(t4, userA)
        print("dd",userA)
        return "case 13.", {id = 8 }
      end,
      [14] = function (userkey01,t4,dbr) --当连续登录14天
        local s = math.random(1,390)
        local h = math.floor(s) + 610
        local userA = {[1] =9,[2]=14,[3] =11,[4] =h}
        local k =1
        for i = 5 ,13,2 do
          --userC = userC..mailType[13]..mailType[i]..mailType[13]..1
          userA[i] = k
          userA [i+1] = 1
          k = k+1
        end
        --local userA = "14:|"..mailType[9]..mailType[13]..mailType[11]..mailType[13]..h..userC
        local userC = serialize(userA)
        local  userB = dbr:rpush(t4, userC)
        print("dd",userC)
        return "case 14.",{id = 8 }
      end, 
     }
     --领取奖励判断
     local t3 = tonumber(dbr:hget(table_task.dbrkey, cli_user_t[7]) )
     local t4 = dbr:hget(table_task.dbrkey,cli_user_t[8])
     local f = switch[t3]
     print(type(f))
     if (f) then
        local st,s = f(table_task.dbrkey,t4,dbr)
        print(type(s))
        print(st,s)
      else
        print("no");
      end
   end
   local t2 = tonumber(dbr:hget(table_task.dbrkey, cli_user_t[7]) )
   local luas = "call taskDaliy0703("
   luas = luas ..t2..')'
   local res = dbm:query(luas)
   print(dump(res))
   return "yes", {timeOld = t2, mail = res[1]}
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
--Daily_Task0701(dbm, dbr, dbrT)
--Daily_Task0702(dbm, dbr, dbrT)
	
	skynet.register "dailyTask"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



