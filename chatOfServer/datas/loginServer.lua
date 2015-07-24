local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"

local Levels = require "Levels"
local sharedata = require "sharedata"
local datacenter = require "datacenter"
require "gameG"

local CMD = {}
--唯一登录用
local client_fds={}
local auto_id=0
local talk_users={}
--全局对战数据
local against_A = {}  --进入系统匹配的用户fds
local against_B = {}  --点击系统匹配的用户
local against_C = {}  --进入对战的用户
local against_L={}    --不同等级的加入到不同的对战匹配
--against_L[0] = {}  
--against_L[1] = {}
--against_L[2] = {}
--against_L[3] = {}
--against_L[4] = {}
--against_L[5] = {}

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
function useronline(client_fd,dbrkey,names)
  auto_id=auto_id+1
  print("添加用户名****")
  local userInfo = {
    userid = auto_id,
    name = names,
    dbrkey = dbrkey,
  }
  --新用户
  talk_users[userInfo.userid]=userInfo
  client_fds[userInfo.userid]=client_fd
  return "yes"
end
--判断用户是否已经登录
function isUser(name)
  print("判断用户名是否存在")
  for userid in pairs(talk_users) do
    if talk_users[userid].name==name then
      print("用户名存在")
      return true , talk_users[userid].dbrkey
    end
  end
  print("用户名不存在")
  return false
end
--用户断开
function CMD.rmUser(dbm,dbr,dbrT,client_fd)
  for userid in pairs(client_fds) do
    if client_fds[userid]==client_fd then
--      for userid2 in pairs(client_fds) do --广播
--        socket.write(client_fds[userid2], netpack.pack(skynet.pack(1,1011,protobuf.encode("talkbox.talk_result",{id=userid}))))
--      end
      --用户下线
      print("--------------下线----------", talk_users[userid].dbrkey)
      talk_users[userid]=nil
      client_fds[userid]=nil
    end
  end
end
------------------------------------------------------------

--宠物加血
function addUserROle01(dbr,userRoles)
   --print(dump(userRoles))
   print("判断是否加血")
   --20分钟执行一次
   local t2 = math.floor(os.time()  / 1200)
   if userRoles[cli_user_t[12]]==nil then
    print("键不存在")
    return
   end
   if userRoles[cli_user_t[12]] < t2  then
    local roleS = t2-userRoles[cli_user_t[12]]
    userRoles[cli_user_t[12]] = t2
    local resd = dbr:hset(userRoles[cli_user[2]], cli_user_t[12], t2)
    for k,v in pairs(userRoles[cli_user[15]]) do
      local roled = dbr:hmget(v[cli_user[15]],tableRoleS[10],tableRoleS[7],tableRoleS[8])
      local roleA = tonumber(roled[1])
      local roleB = tonumber(roled[2])
      local roleC = tonumber(roled[3])
      print(dump(roled))
      if roleB > roleC then
        print("异常")
        local role03 = dbr:hset(v[cli_user[15]],tableRoleS[7],roled[3])
      elseif roleB == roleC then
        print("满血")
      else
        print("加血")
        local roleD = roleC-roleB
        --判断是否加满
        if roleD <= roleA*roleS then
          print(roleD)
          print(roleS)
          print("可以加满")
          local okd = dbr:hincrby(v[cli_user[15]],tableRoleS[7],roleD)
        else
          print("不能加满")
          local okd = dbr:hincrby(v[cli_user[15]],tableRoleS[7],roleA*roleS)
        end
      end
    end
  else
    print("不加血")
  end
end

--1使用进行注册 CMD.mysqlServer01(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.mysqlServer01(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
  local talk_login = unserialize(talk_logins)
  print("用户正常登录")
--     local talk_login = {
--      name = "12",
--      passwords = "12",
--    }
  local user03 = {}
  local n = tonumber(talk_login.name);
  if n then
   -- n就是得到数字
    return "ok",serialize({msg = "用户名不能为数字"})
  end
  if string.len(talk_login.passwords) <= 1 or string.len(talk_login.passwords) > 8 then
   -- 密码限制
   print(string.len(talk_login.passwords) )
   print("feffeff")
    return "ok",serialize({msg = "密码不能为空或大于8位"})
  end
--    if talk_login.passwords
    local userd1,userd2 = isUser(talk_login.name)
    if userd1 then
      print("已经存在该用户")
      return "ok",serialize({msg = "用户重复登录"})
    end
    local luas = "call userLongin01("
    luas = luas ..dbmL.lr..talk_login.name ..dbmL.lz..talk_login.passwords..dbmL.lr..')'
    local res = dbm:query(luas)
--    print("数据库得到数据----",luas)
--    print("数据库得到数据----",dump(res))
    if res[1][1]["row_key"] == "no"  then
      print("判断为no，需要创建宠物")
--      print(dump(res))
      return res[1][1],serialize(res[2])
    elseif res[1][1]["row_key"]== "ok" then
      print("密码不正确")
      return res[1][1],serialize({id = 11})
    elseif res[1][1]["row_key"]== "yes" then
      print("判断为yes")
      
      --用户成功登录
      --将数据写入redis数据库
      --通过userId和记录id组成唯一的数据查找id
        local userInfo = {}
        print("---------")
        print("得到用户键名:",res[2][1][cli_user[2]])
        if (dbr:hlen(res[2][1][cli_user[2]]))~= 0 then
          print("键存在")

          --从redis获取用户信息
          local userw = dbr:hmget(res[2][1][cli_user[2]],cli_user[1],cli_user[2],cli_user[3],cli_user[4],cli_user[5],cli_user[6],cli_user[7],cli_user[8],cli_user[9],cli_user[10],cli_user[11],cli_user[12],cli_user[13],cli_user[14], cli_user[17])
          local userw2 = dbr:hmget(res[2][1][cli_user[2]],1,2,3,4,5,6,7,8)
          user_item[res[2][1][cli_user[2]] ] = {[1]= tonumber(userw2[1]),[2]= tonumber(userw2[2]),[3]= tonumber(userw2[3]), [4]=tonumber(userw2[4]), [5]= tonumber(userw2[5]), [6]= tonumber(userw2[6]), [7]= tonumber(userw2[7]), [8]= tonumber(userw2[8])}
          --记录道具信息
          datacenter.set(res[2][1][cli_user[2]]..cli_user_k[1],user_item[res[2][1][cli_user[2]] ])
          print("道具信息----",dump(datacenter.get(res[2][1][cli_user[2]]..':'.."item") ) )
           --获取宠物信息
           for k,v in pairs(res[3]) do
            if type(v) == "table" then
--              print("宠物名",v[tableRoleS[4]])
              table.insert(userInfo, {id = v[tableRoleS[2]], rolekey = v[tableRoleS[3]]})
            end
          end
           --数据组装
          for k,v in pairs(cli_user02) do
            if k == "dbrkey" or k == "roleopen" or k == "userGame" then
              user03[k] = userw[v]
            else
              user03[k] = tonumber( userw[v])
            end
          end
          --星星关卡/
          local dbrs = dbr:hmget(res[2][1][cli_user[2]],cli_user_t[11],cli_user_t[12],cli_user_t[14])
          local starsPass = tonumber(dbrs[1])
          local roleTimes = tonumber(dbrs[2])
          local stratVs = tonumber(dbrs[3])
          user03["starsP"] = starsPass
          user03["roleTime"] = roleTimes
          user03["rolekey"] = userInfo
          user03["starsV"] = stratVs
          user03["levelCurr"] = tardSer[user03[cli_user[3]] ]
          print("ddddd",dump(user03))
          
          --判断是否加血
          addUserROle01(dbr,user03)
          --当前宠物信息
         local opens = dbr:hmget(userw[12], tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10],tableRoleS[19])
         user03["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8]),actionVal = tonumber(opens[9]), }
          
          local b = os.clock()
          print(b-a)
          user_names[res[2][1] [cli_user[2]] ] = clone(user03)
          --sharedata.new(res[2][1][cli_user[2]], user03)
          --记录用户数据
          datacenter.set(res[2][1] [cli_user[2]],user03)
          useronline(client_fd,res[2][1] [cli_user[2]],talk_login.name)
--          print("新建的----",dump(datacenter.get(res[2][1] [cli_user[2]]) ) )
          return res[1][1] ,serialize(user03)
        else
          print("键不存在")
          --创建用户键
          local userdb = res[2][1]
          local userItem = res[4][1]
          local rer2 = dbr:hmset(userdb[cli_user[2]], cli_user[1], userdb[cli_user[1]],cli_user[2], userdb[cli_user[2]],cli_user[3], userdb[cli_user[3]],cli_user[4], userdb[cli_user[4]], cli_user[5], userdb[cli_user[5]], cli_user[6],userdb[cli_user[6]], cli_user[7],userdb[cli_user[7]], cli_user[8],userdb[cli_user[8]], cli_user[9],userdb[cli_user[9]], cli_user[10],userdb[cli_user[10]], cli_user[11],userdb[cli_user[11]], cli_user[12],userdb[cli_user[12]], cli_user[13],userdb[cli_user[13]], cli_user[14],userdb[cli_user[14]], cli_user[17],userdb[cli_user[17]] )
          local rer3 = dbr:hmset(userdb[cli_user[2]],1,userItem[tableItemTable[2]],2,userItem[tableItemTable[3]],3,userItem[tableItemTable[4]], 4,userItem[tableItemTable[5]], 5,userItem[tableItemTable[6]], 6,userItem[tableItemTable[7]], 7,userItem[tableItemTable[8]], 8,userItem[tableItemTable[9]],cli_user_t[11],1,cli_user_t[12],math.floor(os.time()  / 1200), cli_user_t[14],0 )
          --关卡/星星开启关卡
          --user_item[userdb[cli_user[2]] ] = {[1]= userItem[tableItemTable[2]],[2]=userItem[tableItemTable[3]],[3]=userItem[tableItemTable[4]],[4]=userItem[tableItemTable[5]], [5]=userItem[tableItemTable[6]], [6]=userItem[tableItemTable[7]], [7]=userItem[tableItemTable[8]], [8]=userItem[tableItemTable[9]]}
          --每日完成任务数//和新建的键
          local res5 = dbr:hmset(userdb[cli_user[2]],cli_user_t[1],0,cli_user_t[2],0,cli_user_t[3],0,cli_user_t[4], userdb[cli_user_t[4]],cli_user_t[5], userdb[cli_user_t[5]],cli_user_t[6], userdb[cli_user_t[6]],cli_user_t[7], userdb[cli_user_t[7]],cli_user_t[8], userdb[cli_user_t[8]], cli_user_t[9],1 )
          local userw2 = dbr:hmget(userdb[cli_user[2]],1,2,3,4,5,6,7,8)
          user_item[userdb[cli_user[2]] ] = {[1]= tonumber(userw2[1]),[2]= tonumber(userw2[2]),[3]= tonumber(userw2[3]), [4]=tonumber(userw2[4]), [5]= tonumber(userw2[5]), [6]= tonumber(userw2[6]), [7]= tonumber(userw2[7]), [8]= tonumber(userw2[8])}
          --记录道具信息
          datacenter.set(userdb[cli_user[2]]..cli_user_k[1],user_item[userdb[cli_user[2]] ])
          print("道具信息----",dump(datacenter.get(userdb[cli_user[2]]..':'.."item") ) )
          if rer2 == "OK" then
            print("用户键创建成功")
          else
            print("用户键创建失败用户需要重新登录")
          end
          --创建宠物信息
          for k,v in pairs(res[3]) do
            print("---",k,v)
            if type(v) == "table" then
              print("宠物名",v[tableRoleS[4]])
              local varl = {id = v[tableRoleS[1]],rolekey = v[tableRoleS[3]]}
              table.insert(userInfo,varl)
              local rer = dbr:hmset(v[tableRoleS[3]],tableRoleS[1],v[tableRoleS[1]],tableRoleS[2],v[tableRoleS[2]],tableRoleS[3],v[tableRoleS[3]],tableRoleS[4],v[tableRoleS[4]],tableRoleS[5],v[tableRoleS[5]],tableRoleS[6],v[tableRoleS[6]], tableRoleS[7],v[tableRoleS[7]],tableRoleS[8],v[tableRoleS[8]],tableRoleS[9],v[tableRoleS[9]],tableRoleS[10],v[tableRoleS[10]],tableRoleS[11],v[tableRoleS[11]],tableRoleS[12],v[tableRoleS[12]], tableRoleS[13],v[tableRoleS[13]], tableRoleS[14],v[tableRoleS[14]],tableRoleS[15],v[tableRoleS[15]], tableRoleS[16],v[tableRoleS[16]], tableRoleS[17],v[tableRoleS[17]],tableRoleS[18],v[tableRoleS[18]],tableRoleS[19],v[tableRoleS[19]] )
            
               if rer == "OK" then
--                print("用户键创建成功")
              else
--                print("用户键创建失败用户需要重新登录")
              end
            end
          end
--          print("这里返回数据")
         local userw = dbr:hmget(userdb[cli_user[2]],cli_user[1],cli_user[2],cli_user[3],cli_user[4],cli_user[5],cli_user[6],cli_user[7],cli_user[8],cli_user[9],cli_user[10],cli_user[11],cli_user[12],cli_user[13],cli_user[14],cli_user[17])
         local opens = dbr:hmget(userw[12], tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
         for k,v in pairs(cli_user02) do
            if k == "dbrkey" or k == "roleopen"  or k == "userGame" then
              user03[k] = userw[v]
            else
              user03[k] = tonumber( userw[v])
            end
          end
          local listP = dbr:zadd(ranking_List[2],1,userdb[cli_user[2]] )
         --星星开启关卡/百分比
          local dbrs = dbr:hmget(userdb[cli_user[2]],cli_user_t[11],cli_user_t[12],cli_user_t[14])
          local starsPass = tonumber(dbrs[1])
          local roleTimes = tonumber(dbrs[2])
          local stratVs = tonumber(dbrs[3])
          user03["starsP"] = starsPass
          user03["roleTime"] = roleTimes
          user03["stratV"] = stratVs
          user03["rolekey"] = userInfo
          user03["levelCurr"] = tardSer[user03[cli_user[3]] ]
          --判断是否加血
          --addUserROle01(dbr,user03)
         user03["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
         user_names[userdb[cli_user[2]]] = user03
         datacenter.set(res[2][1] [cli_user[2]],user03)
         useronline(client_fd,res[2][1] [cli_user[2]],talk_login.name)
--         print("新建的----",dump(user_names))
          return res[1][1] ,serialize(user03)
        end
    end
    
end

--1.1.1用户再次进入主界面时触发CMD.loginServer0101(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.loginServer0101(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
  print("再次进入主界面")
  --1用户再次登录
  local talk_login = unserialize(talk_logins)
  print("sd",dump(talk_login))
--  local talk_login = {
--    dbrkey = "33:12",
--    userId = 33,
--    roleopen = "33:12:20",
--  }
  --从缓存中读取更新的数据
--  local obj = sharedata.query(talk_login.dbrkey)
--  print(dump(obj))
--  user_names[talk_login.dbrkey] =obj
  local obj =datacenter.get(talk_login.dbrkey)
  --print("用户角色信息",dump(obj))
  user_names[talk_login.dbrkey] =obj
  print("再次",dump(user_names))
  if user_names[talk_login.dbrkey] == nil then
    return "no",{id = 902}
  end
    --2判断用户输入是否正确
  if talk_login.userId == user_names[talk_login.dbrkey][cli_user[1]] and talk_login.roleopen ==  user_names[talk_login.dbrkey][cli_user[12]] then
    --3输入正确可以使用
    print("正确返回主界面")
    addUserROle01(dbr,user_names[talk_login.dbrkey])
    user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = tonumber(dbr:hget(talk_login.roleopen,tableRoleS[7]))
    print("就在这里")
    print(dump(user_names[talk_login.dbrkey]))
    --1.1判断用户的宝气值是否大于最高宝气值
    if user_names[talk_login.dbrkey][cli_user[4]] < user_names[talk_login.dbrkey][cli_user[5]] then
      print("最高宝气值小于当前宝气值")
      user_names[talk_login.dbrkey][cli_user[4]] = user_names[talk_login.dbrkey][cli_user[5]]
      print(user_names[talk_login.dbrkey][cli_user[2]], cli_user[4], user_names[talk_login.dbrkey][cli_user[4]])
      local res011 = dbr:hset(user_names[talk_login.dbrkey][cli_user[2]], cli_user[4], user_names[talk_login.dbrkey][cli_user[4]])
      --判断缓存数据是否存在
      if trac_server[1] == nil then
        print("没有缓存数据")
        local luas = "call tardServer0102("
        luas = luas ..')'
        --print(luas)
        local res = dbm:query(luas)
        --print("my001----",dump(res))
        trac_server = res[1]
      else
        print("有缓存数据")
      end
      --print(dump(trac_server[user_names[talk_login.dbrkey][cli_user[3]]+1]))
      --1.2判断现在是否满足等级
      if trac_server[user_names[talk_login.dbrkey][cli_user[3]] +1][cli_user_t[10]] == nil then
        print("为最高等级")
        if user_names[talk_login.dbrkey][cli_user[5]] >= 99999 then
          res011 = dbr:hset(user_names[talk_login.dbrkey][cli_user[2]], cli_user[4], 99999)
          res011 = dbr:hset(user_names[talk_login.dbrkey][cli_user[2]], cli_user[5], 99999)
        end
      elseif trac_server[user_names[talk_login.dbrkey][cli_user[3]]+1][cli_user_t[10]] < user_names[talk_login.dbrkey][cli_user[4]] then
        print("达到升级要求")
        local res011 = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[2]], cli_user[3],1)
        user_names[talk_login.dbrkey][cli_user[3]] = res011
        user_names[talk_login.dbrkey]["levelCurr"] = tardSer[res011 ]
        --的
        datacenter.set(talk_login.dbrkey, user_names[talk_login.dbrkey])
      else
        print("没有达到升级要求")
      end
    else
      print("最高宝气值大于当前宝气值")
    end
     ----
    local b = os.clock() 
    print(b-a)
    return "yes",serialize(user_names[talk_login.dbrkey])
  else
    print("输入不正确或用户还未登录")
    local b = os.clock() 
    print(b-a)
    return "no",{id = 902}
  end
end


--1.1.2用户再次进入主界面时触发CMD.loginServer0101(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.loginServer0102(dbm,dbr,dbrT,client_fd,talk_logins)
  print("再次进入主界面")
  --1用户再次登录
  local talk_login = unserialize(talk_logins)
  print("sd",dump(talk_login))
--  local talk_login = {
--    dbrkey = "33:12",
--    userId = 33,
--    roleopen = "33:12:20",
--  }
  --从缓存中读取更新的数据
  local obj =datacenter.get(talk_login.dbrkey)
  --print("用户角色信息",dump(obj))
  user_names[talk_login.dbrkey] =obj
  print("再次",dump(user_names))
  if user_names[talk_login.dbrkey] == nil then
    return "no",{id = 902}
  end
    --2判断用户输入是否正确
  if talk_login.userId == user_names[talk_login.dbrkey][cli_user[1]] and talk_login.roleopen ==  user_names[talk_login.dbrkey][cli_user[12]] then
    --3输入正确可以使用
    return "yes",serialize(user_names[talk_login.dbrkey])
  else
    print("输入不正确或用户还未登录")
    local b = os.clock() 
    print(b-a)
    return "no",{id = 902}
  end
end


--1.2使用临时用户创建宠物  CMD.mysqlCreateROle02(dbm,dbr,dbrT,client_fd,talk_login)
function CMD.mysqlCreateROle02(dbm,dbr,dbrT,client_fd,talk_logins)
    print("用户正常登入后")
    local talk_login = unserialize(talk_logins)
--    local talk_login = {
--      name = "Bob",
--      passwords = "123",
--      sex = 1,
--      roles = 1,
--    }
    local user03 = {}
    --查询mysql数据库
    local luas = "call userRoleCreate02("
    luas = luas ..dbmL.lr..talk_login.name ..dbmL.lz..talk_login.passwords..dbmL.lz2..talk_login.roles..')'
    print(luas)
    local res = dbm:query(luas)
    print("my001----",dump(res))
    if res[1][1]["row_key"] == "yes" then
      print("用户创建成功")
      return {id = 8}
    elseif res[1][1]["row_key"]  == "no" then
      print("用户不存在创表内")
      return {id = 11}
    else
      print("出现异常")
      return {id = 902}
    end
  return user03
end

--2宝气值界面 CMD.treaServer0102(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.treaServer0102(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
  local talk_login = unserialize(talk_logins)
  print("2宝气值界面")
  --1用户再次登录
--  local talk_login = {
--      dbrkey = "33:12",
--    }
  --从缓存中读取更新的数据
  local obj =datacenter.get(talk_login.dbrkey)
  print("用户角色信息",dump(obj))
  user_names[talk_login.dbrkey] =obj
    --1得到当前用户的最高宝气值和当前宝气值在判断缓存是否有数据
    if user_names[talk_login.dbrkey] == nil then
      print("用户还没有登录")
      return "no",{id = 903}
    end
    print("dddddddd")
    print(dump(trac_server))
    if trac_server[1] == nil then
      print("没有缓存数据")
      local luas = "call tardServer0102("
      luas = luas ..')'
      --print(luas)
      local res = dbm:query(luas)
      --print("my001----",dump(res))
      trac_server = res[1]
    else
      print("有缓存数据")
    end
    print(dump({gasNo = user_names[talk_login.dbrkey][cli_user[3]], gasValues = user_names[talk_login.dbrkey][cli_user[4]],usegasValues = user_names[talk_login.dbrkey][cli_user[5]], trea = trac_server}))
    --2返回数据当前用户的最高宝气值和当前宝气值和缓存数据
    return "yes",serialize({gasNo = user_names[talk_login.dbrkey][cli_user[3]], gasValues = user_names[talk_login.dbrkey][cli_user[4]],usegasValues = user_names[talk_login.dbrkey][cli_user[5]], trea = trac_server})
end
-------------------------

local yan = {}
yan[1] = {name = "荣安翔",passwords = "123",}
yan[2] = {name = "空昂雄",passwords = "123",}
yan[3] = {name = "12",passwords = "12",}
yan[4] = {name = "庄博达",passwords = "123",}

local task = {}
task[1] = {dbrkey = "33:12",}
task[2] = {dbrkey2 = "51:夏苑杰",}

function mysqlServer01d(dbm,dbr,dbrT,tas)
  local a = os.clock() 
    print("用户正常登录")
     local talk_login = tas
    local user03 = {}
    local userd1,userd2 = isUser(talk_login.name)
    if userd1 then
      print("已经存在该用户")
      return "ok",serialize({msg = "用户重复登录"})
    end
    local luas = "call userLongin01("
    luas = luas ..dbmL.lr..talk_login.name ..dbmL.lz..talk_login.passwords..dbmL.lr..')'
    local res = dbm:query(luas)
--    print("数据库得到数据----",luas)
--    print("数据库得到数据----",dump(res))
    if res[1][1]["row_key"] == "no"  then
      print("判断为no，需要创建宠物")
--      print(dump(res))
      return res[1][1],serialize(res[2])
    elseif res[1][1]["row_key"]== "ok" then
      return res[1][1],serialize({id = 11})
    elseif res[1][1]["row_key"]== "yes" then
      print("判断为yes")
      --用户成功登录
      --将数据写入redis数据库
      --通过userId和记录id组成唯一的数据查找id
        local userInfo = {}
        print("---------")
        print("得到用户键名:",res[2][1][cli_user[2]])
        if (dbr:hlen(res[2][1][cli_user[2]]))~= 0 then
          print("键存在")

          --从redis获取用户信息
          local userw = dbr:hmget(res[2][1][cli_user[2]],cli_user[1],cli_user[2],cli_user[3],cli_user[4],cli_user[5],cli_user[6],cli_user[7],cli_user[8],cli_user[9],cli_user[10],cli_user[11],cli_user[12],cli_user[13],cli_user[14], cli_user[17])
          local userw2 = dbr:hmget(res[2][1][cli_user[2]],1,2,3,4,5,6,7,8)
          user_item[res[2][1][cli_user[2]] ] = {[1]= userw2[1],[2]= userw2[2],[3]= userw2[3], [4]=userw2[4], [5]= userw2[5], [6]= userw2[6], [7]= userw2[7], [8]= userw2[8]}
          --记录道具信息
          datacenter.set(res[2][1][cli_user[2]]..cli_user_k[1],user_item[res[2][1][cli_user[2]] ])
          print("道具信息----",dump(datacenter.get(res[2][1][cli_user[2]]..':'.."item") ) )
           --获取宠物信息
           for k,v in pairs(res[3]) do
            if type(v) == "table" then
--              print("宠物名",v[tableRoleS[4]])
              table.insert(userInfo, {id = v[tableRoleS[2]], rolekey = v[tableRoleS[3]]})
            end
          end
           --数据组装
          for k,v in pairs(cli_user02) do
            if k == "dbrkey" or k == "roleopen" or k == "userGame" then
              user03[k] = userw[v]
            else
              user03[k] = tonumber( userw[v])
            end
          end
          --星星关卡
          local starsPass = tonumber(dbr:hget(res[2][1][cli_user[2]],cli_user_t[11]))
          local roleTimes = tonumber(dbr:hget(res[2][1][cli_user[2]],cli_user_t[12]))
          user03["starsP"] = starsPass
          user03["roleTime"] = roleTimes
          user03["rolekey"] = userInfo
          --判断是否加血
          addUserROle01(dbr,user03)
          --当前宠物信息
         local opens = dbr:hmget(userw[12], tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
         user03["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
          
          local b = os.clock()
          print(b-a)
          user_names[res[2][1] [cli_user[2]] ] = clone(user03)
          --sharedata.new(res[2][1][cli_user[2]], user03)
          --记录用户数据
          datacenter.set(res[2][1] [cli_user[2]],user03)
          useronline(client_fd,res[2][1] [cli_user[2]],talk_login.name)
--          print("新建的----",dump(datacenter.get(res[2][1] [cli_user[2]]) ) )
          return res[1][1] ,serialize(user03)
        else
          print("键不存在")
          --创建用户键
          local userdb = res[2][1]
          local userItem = res[4][1]
          local rer2 = dbr:hmset(userdb[cli_user[2]], cli_user[1], userdb[cli_user[1]],cli_user[2], userdb[cli_user[2]],cli_user[3], userdb[cli_user[3]],cli_user[4], userdb[cli_user[4]], cli_user[5], userdb[cli_user[5]], cli_user[6],userdb[cli_user[6]], cli_user[7],userdb[cli_user[7]], cli_user[8],userdb[cli_user[8]], cli_user[9],userdb[cli_user[9]], cli_user[10],userdb[cli_user[10]], cli_user[11],userdb[cli_user[11]], cli_user[12],userdb[cli_user[12]], cli_user[13],userdb[cli_user[13]], cli_user[14],userdb[cli_user[14]], cli_user[17],userdb[cli_user[17]] )
          local rer3 = dbr:hmset(userdb[cli_user[2]],1,userItem[tableItemTable[2]],2,userItem[tableItemTable[3]],3,userItem[tableItemTable[4]], 4,userItem[tableItemTable[5]], 5,userItem[tableItemTable[6]], 6,userItem[tableItemTable[7]], 7,userItem[tableItemTable[8]], 8,userItem[tableItemTable[9]],cli_user_t[11],1,cli_user_t[12],math.floor(os.time()  / 1200) )
          --星星开启关卡
          user_item[userdb[cli_user[2]] ] = {[1]= userItem[tableItemTable[2]],[2]=userItem[tableItemTable[3]],[3]=userItem[tableItemTable[4]],[4]=userItem[tableItemTable[5]], [5]=userItem[tableItemTable[6]], [6]=userItem[tableItemTable[7]], [7]=userItem[tableItemTable[8]], [8]=userItem[tableItemTable[9]]}
          --每日完成任务数//和新建的键
          local res5 = dbr:hmset(userdb[cli_user[2]],cli_user_t[1],0,cli_user_t[2],0,cli_user_t[3],0,cli_user_t[4], userdb[cli_user_t[4]],cli_user_t[5], userdb[cli_user_t[5]],cli_user_t[6], userdb[cli_user_t[6]],cli_user_t[7], userdb[cli_user_t[7]],cli_user_t[8], userdb[cli_user_t[8]], cli_user_t[9],1 )
          local userw2 = dbr:hmget(userdb[cli_user[2]],1,2,3,4,5,6,7,8)
          user_item[userdb[cli_user[2]] ] = {[1]= userw2[1],[2]= userw2[2],[3]= userw2[3], [4]=userw2[4], [5]= userw2[5], [6]= userw2[6], [7]= userw2[7], [8]= userw2[8]}
          --记录道具信息
          datacenter.set(userdb[cli_user[2]]..cli_user_k[1],user_item[userdb[cli_user[2]] ])
          print("道具信息----",dump(datacenter.get(userdb[cli_user[2]]..':'.."item") ) )
          if rer2 == "OK" then
            print("用户键创建成功")
          else
            print("用户键创建失败用户需要重新登录")
          end
          --创建宠物信息
          for k,v in pairs(res[3]) do
            print("---",k,v)
            if type(v) == "table" then
              print("宠物名",v[tableRoleS[4]])
              local varl = {id = v[tableRoleS[1]],rolekey = v[tableRoleS[3]]}
              table.insert(userInfo,varl)
              local rer = dbr:hmset(v[tableRoleS[3]],tableRoleS[1],v[tableRoleS[1]],tableRoleS[2],v[tableRoleS[2]],tableRoleS[3],v[tableRoleS[3]],tableRoleS[4],v[tableRoleS[4]],tableRoleS[5],v[tableRoleS[5]],tableRoleS[6],v[tableRoleS[6]], tableRoleS[7],v[tableRoleS[7]],tableRoleS[8],v[tableRoleS[8]],tableRoleS[9],v[tableRoleS[9]],tableRoleS[10],v[tableRoleS[10]],tableRoleS[11],v[tableRoleS[11]],tableRoleS[12],v[tableRoleS[12]], tableRoleS[13],v[tableRoleS[13]], tableRoleS[14],v[tableRoleS[14]],tableRoleS[15],v[tableRoleS[15]], tableRoleS[16],v[tableRoleS[16]], tableRoleS[17],v[tableRoleS[17]],tableRoleS[18],v[tableRoleS[18]],tableRoleS[19],v[tableRoleS[19]] )
            
               if rer == "OK" then
--                print("用户键创建成功")
              else
--                print("用户键创建失败用户需要重新登录")
              end
            end
          end
--          print("这里返回数据")
         local userw = dbr:hmget(userdb[cli_user[2]],cli_user[1],cli_user[2],cli_user[3],cli_user[4],cli_user[5],cli_user[6],cli_user[7],cli_user[8],cli_user[9],cli_user[10],cli_user[11],cli_user[12],cli_user[13],cli_user[14],cli_user[17])
         local opens = dbr:hmget(userw[12], tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
         for k,v in pairs(cli_user02) do
            if k == "dbrkey" or k == "roleopen"  or k == "userGame" then
              user03[k] = userw[v]
            else
              user03[k] = tonumber( userw[v])
            end
          end
          local listP = dbr:zadd(ranking_List[2],1,userdb[cli_user[2]] )
         --星星开启关卡
         local starsPass = tonumber(dbr:hget(userdb[cli_user[2]],cli_user_t[11]))
         local roleTimes = tonumber(dbr:hget(res[2][1][cli_user[2]],cli_user_t[12]))
         user03["starsP"] = starsPass
         user03["roleTime"] = roleTimes
         user03["rolekey"] = userInfo
          --判断是否加血
          --addUserROle01(dbr,user03)
         user03["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
         user_names[userdb[cli_user[2]]] = user03
         datacenter.set(res[2][1] [cli_user[2]],user03)
         useronline(client_fd,res[2][1] [cli_user[2]],talk_login.name)
--         print("新建的----",dump(user_names))
          return res[1][1] ,serialize(user03)
        end
    end
    
end
---------------------------------------------------------------------------------
--local against_A = {}  --进入系统匹配的用户fds
--local against_B = {}  --点击系统匹配的用户
--local against_C = {}  --进入对战的用户
--local against_L1 = {}   --不同等级的加入到不同的对战匹配66:庄博达
local task = {}
task[1] = {dbrkey = "33:12"}
task[2] = {dbrkey = "50:荣安翔",}
task[3] = {dbrkey = "49:空昂雄",}
task[4] = {dbrkey = "66:庄博达",}
--11.1用户点击对战 CMD.gameLevel11(dbm,dbr,dbrT,client_fd,talk_logins)
function gameLevel11(dbm,dbr,dbrT)
  local talk_login = task[2]
  print(dump(talk_login))
  --1用户请求对战/弹出用户的宝气值信息和成就
  --2用户对战条件的信息
  local obj =datacenter.get(talk_login.dbrkey)
  --print("用户角色信息",dump(obj))
  --消息键
--  aganst_A[talk_login.dbrkey] = client_fd
  
  user_names[talk_login.dbrkey] =obj
    local userInfo = {
    [cli_user[2]] = talk_login.dbrkey,
    [cli_user[3]] = user_names[talk_login.dbrkey][cli_user[3]],
    [cli_user[5]] = user_names[talk_login.dbrkey][cli_user[5]],
    [cli_user_t[13]] = "stop",
  }
  against_L[talk_login.dbrkey] = userInfo
  print("sd",dump(against_L))
  
  --新用户
--  user_names[talk_login.dbrkey][cli_user[3]]
--  return "yes",serialize(against_A[talk_login.dbrkey])

end

--11.2用户点击系统匹配 CMD.gameLevel11(dbm,dbr,dbrT,client_fd,talk_logins)

function gameLevel1102(dbm,dbr,dbrT,task)
  local talk_login = task
  --1用户请求对战/弹出用户的宝气值信息和成就
  --2用户对战条件的信息
  local obj =datacenter.get(talk_login.dbrkey)
--  print("用户角色信息",dump(obj))
  user_names[talk_login.dbrkey] =obj
  print("1.2添加用户名****")
  local userInfo = {
    [cli_user[2]] = talk_login.dbrkey,
    [cli_user[3]] = user_names[talk_login.dbrkey][cli_user[3]],
    [cli_user[5]] = user_names[talk_login.dbrkey][cli_user[5]],
    [cli_user_t[13]] = "stop",
  }
  print(talk_login.dbrkey)
  --第一次进入不可以被别人匹配
  if against_L[talk_login.dbrkey]~= nil then
    --被他人匹配到
    if against_L[talk_login.dbrkey][cli_user_t[13]] ~= "stop" then
      print("得到对战对象")
      local aps = against_L[talk_login.dbrkey][cli_user_t[13]]
      against_L[talk_login.dbrkey] = nil
      print("被匹配",dump({[aps] = Astate_ps[aps]}))
      return "yes",serialize({id = 8,[aps] = Astate_ps[aps]})
    else
      print("未得到对战对象")
      return "yes",serialize({id = 10})
    end
  end
  --1遍历系统匹配表//匹配他人
  print("开始匹配他人")
  for k,v in pairs(against_L) do
    print(against_L[k][cli_user[2]])
    if talk_login.dbrkey ~= k and against_L[k][cli_user_t[13]] == "stop"  then
      --匹配到可以对战的对象
      print("匹配到",k)
      against_L[k][cli_user_t[13]]= talk_login.dbrkey
      print("sss",dump(against_L[k]))
      Astate_ps[talk_login.dbrkey] = {[talk_login.dbrkey]={ [cli_user[3]] = userInfo[cli_user[3]],[cli_user[5]] = userInfo[cli_user[5]],id =1},[k]={ [cli_user[3]] = against_L[k][cli_user[3]],[cli_user[5]] = against_L[k][cli_user[5]],id =2}}
      Astate_vs[talk_login.dbrkey] = {[1]=talk_login.dbrkey,[2] = k}
      --记录用户数据
      datacenter.set(talk_login.dbrkey..cli_user_k[2], Astate_ps[talk_login.dbrkey])
      datacenter.set(talk_login.dbrkey..cli_user_k[3], Astate_vs[talk_login.dbrkey])
      against_L[talk_login.dbrkey] =nil
      print("主匹配",dump({[talk_login.dbrkey] = Astate_ps[talk_login.dbrkey]}))
      return "yes",serialize({id = 8,Astate_ps[talk_login.dbrkey]})
      --创建对战信息
    else
      --匹配到自己跳过
      print("相等匹配到自己") --跳过
    end
  end
  against_L[talk_login.dbrkey] = userInfo
  
  print("自己加入到匹配中",dump(against_L[talk_login.dbrkey]))
--  return "yes",serialize(against_A[talk_login.dbrkey])

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
--  mysqlServer01(dbm,dbr,dbrT)
--  loginServer0101(dbm,dbr,dbrT)
--  treaServer0102(dbm,dbr,dbrT)
--mysqlServer01(dbm,dbr,dbrT)

  mysqlServer01d(dbm,dbr,dbrT,yan[1])
  mysqlServer01d(dbm,dbr,dbrT,yan[2])
  mysqlServer01d(dbm,dbr,dbrT,yan[3])
  mysqlServer01d(dbm,dbr,dbrT,yan[3])
  mysqlServer01d(dbm,dbr,dbrT,yan[4])
  gameLevel11(dbm,dbr,dbrT)
	gameLevel1102(dbm,dbr,dbrT,task[1])
	gameLevel1102(dbm,dbr,dbrT,task[3])
	gameLevel1102(dbm,dbr,dbrT,task[4])
	 gameLevel1102(dbm,dbr,dbrT,task[2])
  gameLevel1102(dbm,dbr,dbrT,task[4])
	skynet.register "loginServer"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



