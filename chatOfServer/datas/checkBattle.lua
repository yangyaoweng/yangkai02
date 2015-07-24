local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"
local Levels = require "Levels"

--local sharedata = require "sharedata"
local datacenter = require "datacenter"

require "gameG"

local CMD = {}
local client_fds={}
--
--陷阱的随机数
local rolevs = {
  [4] = 10,
  [5] = 30,
  [6] = 60,
  [7] = 10,
  [8] = 30,
  [9] = 60,
  [10] = 10,
  [11] =30,
  [12] =60,
  [13] = 10,
  [14] = 30,
  [15] = 60,
}
local rolevsl = {
  [1] = "objTres",     --物抗
  [2] = "objPati",     --物耐
  [3] = "iceTres",     --冰抗
  [4] = "icePati",     --冰耐
  [5] = "fireTres",    --火抗
  [6] = "firePati",    --火耐
  [7] = "electTres",   --电抗
  [8] = "electPati",   --电耐
}
local bearVS = {
}

local user_roles = {}     --当前宠物信息表

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

------------------------------------------------------------
--3.1返回关卡信息数据 CMD.mysqlSelectMap031(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.mysqlSelectMap031(dbm,dbr,dbrT,client_fd,talk_logins)
    local a = os.clock() 
   local talk_login = unserialize(talk_logins)
    --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--      pass = 315,
--    }
    local obj =datacenter.get(talk_login.dbrkey)
    print(dump(obj))
    user_names[talk_login.dbrkey] =obj
    print("用户点击关卡后")
    local user03 = {}
    --print(talk_login.pass)
    --print(user_names[talk_login.dbrkey].pass)
    --查询键查看用户关卡查看权限
    if user_names[talk_login.dbrkey] ~= nil then
      --查询用户的最高可访问关卡
      --print(user_names[talk_login.dbrkey].pass)
      print(talk_login.pass )
      if talk_login.pass <= user_names[talk_login.dbrkey].pass then
        print("可以访问");
        --print(user_names[talk_login.dbrkey][cli_user_t[11]])
        --得到地图信息
        if user_passk[talk_login.pass] == nil then
          local map = {}
          print("no----------")
          local mapT01 = dbrT:hmget(mapG[1]..talk_login.pass, mapServer[1] , mapServer[2] , mapServer[3] , mapServer[4] ,mapServer[5] , mapServer[6] , mapServer[7] ,  mapServer[8] , mapServer[9] ,mapServer[10] ,mapServer[11] ,mapServer[12] , mapServer[13] ,mapServer[14],mapServer[15], mapServer[16] )
          --组织地图数据
          for k,v in pairs(mapServer02) do
             if k == "gateNum" or k == "boxSize" then
              map[k] = mapT01[v]
             else
              map[k] = tonumber(mapT01[v])
             end
          end
          map["mapType"] = mapType[map[mapServer[16]]]
          user_passk[talk_login.pass] = clone(map)
--          print("添加关卡信息----",dump(user_passk))
        else
          print("有关卡信息----------")
        end
        --判断当前宠物信息是否存在
        if user_roles[talk_login.dbrkey] == nil or user_names[talk_login.dbrkey][cli_user[12]] ~= user_roles[talk_login.dbrkey][tableRoleS[3]] then
          local opens = dbr:hmget(user_names[talk_login.dbrkey][cli_user[12]], tableRoleS[3],tableRoleS[11], tableRoleS[12], tableRoleS[13], tableRoleS[14], tableRoleS[15], tableRoleS[16], tableRoleS[17],tableRoleS[18])
          user_roles[talk_login.dbrkey] = {[tableRoleS[3]] = opens[1],[tableRoleS[11]] = tonumber(opens[2]),[tableRoleS[12]] = tonumber(opens[3]),[tableRoleS[13]] = tonumber(opens[4]),[tableRoleS[14]] = tonumber(opens[5]),[tableRoleS[15]] = tonumber(opens[6]),[tableRoleS[16]] = tonumber(opens[7]),[tableRoleS[17]] = tonumber(opens[8]),[tableRoleS[18]] = tonumber(opens[9]),}
          print("进入没")
        end
        print(dump(user_roles[talk_login.dbrkey]))
        
        --判断关卡是否开启
        if talk_login.pass == user_names[talk_login.dbrkey][cli_user_t[11]]+1 then
          print("使用星星开启关卡")
          return "ok",serialize(user_passk[talk_login.pass])
        elseif talk_login.pass > user_names[talk_login.dbrkey][cli_user_t[11]]+1 then
          print("关卡异常")
          return "ok",serialize({id = 12})
        end
        --返回地图信息
        local b = os.clock()
        print(b-a)
        return "yes",  serialize(user_passk[talk_login.pass])
      else
        print("需要开启关卡")
        return "ok",serialize({id = 13})
      end
  else
    print("用户还未登录");
    return "no",{id = 833}
  end
end

--3.8开启关卡
function CMD.statsMap038(dbm,dbr,dbrT,client_fd,talk_logins)
    local a = os.clock() 
   local talk_login = unserialize(talk_logins)
    --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--      pass = 315,
--    }
    local obj =datacenter.get(talk_login.dbrkey)
    --print(dump(obj))
    user_names[talk_login.dbrkey] =obj
    print("用户开启关卡")
    local user03 = {}
    --查询用户信息是否存在
    if user_names[talk_login.dbrkey] ~= nil then
      --查询用户的最高可访问关卡
      print(user_names[talk_login.dbrkey][cli_user_t[11]])
      print(talk_login.pass )
      if user_names[talk_login.dbrkey][cli_user_t[11]]+1 == talk_login.pass then
       print("将要开启关卡");
       if user_passk[talk_login.pass][mapServer[5]] <= user_names[talk_login.dbrkey][cli_user[11]] then
          print("星星数足够可以开启")
--          print(user_names[talk_login.dbrkey][cli_user[11]])
          user_names[talk_login.dbrkey][cli_user[11]] = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[2]], cli_user[11],-user_passk[talk_login.pass][mapServer[5]])
          user_names[talk_login.dbrkey][cli_user_t[11]] = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[2]], cli_user_t[11],1)
          local listP = dbr:zadd(ranking_List[2],user_names[talk_login.dbrkey][cli_user_t[11]],talk_login.dbrkey )
          datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
--        print(user_names[talk_login.dbrkey][cli_user[11]])
          return "yes", serialize({id=1})
        else
          print("星星数不够不能开启")
          return "yes", serialize({id = 2})
        end
      else
        print("支付关卡异常")
        return "no",{id = 12}
      end
  else
    print("用户还未登录");
    return "no",{id = 833}
  end
end




--3.2进入游戏 CMD.redisSelectMap0302(dbm, dbr, dbrT,client_fd,talk_logins)
function CMD.redisSelectMap0302(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock() 
  local talk_login = unserialize(talk_logins)
  if talk_login == nil then
      print("数据为空")
  end
  print("创建地图****")
--  local talk_login = {
--      dbrkey = "33:12",
--      pass = 315,
--      engame = "yes",
--    }
  print("进入关卡")
  local obj =datacenter.get(talk_login.dbrkey)
  --print(dump(obj))
  user_names[talk_login.dbrkey] =obj
  local user03 = {}
  --得到用户数据
  local mapuser1 = user_names[talk_login.dbrkey].pass
--  print("用户名:", user_names[talk_login.dbrkey].dbrkey)
--  print("地图:",user_names[talk_login.dbrkey].pass)
  if  user_map[mapuser1] ~= nil then
--    print("清除原有数据")
    user_map[mapuser1]=nil
  end
  --查看键是否存在
--  print("ddddddddd")
  if user_mapItems[1] == nil then
    --得到关卡信息
    local obj02 =datacenter.get("user_item_s")
    user_mapItems = obj02
  end
  --print("user_mapItems",dump(user_mapItems))
  --得到地图
  local los2 = Levels.get(talk_login.pass)
  --得到地图信息
  local luas = ""
  local res ={}
  local resY ={}
  if user_passG[talk_login.pass] ~= nil then
    resY = user_passG[talk_login.pass]
  else
    print("得到关卡信息")
    luas = "call mapTableOn02("
    luas = luas..talk_login.pass ..')'
    res = dbm:query(luas)
--    print("地图信息",dump(res))
    user_passG[talk_login.pass] = clone(res[1][1])
    resY = res[1][1]
  end
  --产生地图物品位置
  math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
  local mapSerS = resY
  local iss = 0
  local rands = clone(los2.grid)   --保存随机数用于判断是否相同
  local h = 0
  local w = 0
  local mapSerV={}
  local mapTrea = newset()
  print(los2.rows*los2.cols-1)
  for k,v in pairs(mapApp) do
    iss = mapSerS[v]
    while iss ~= 0 do
      --print(iss)
      --产生随机数
      local s = math.random(1,los2.rows*los2.cols-1)
      h = math.floor(s/los2.cols)+1
      w = s%los2.cols+1
      --print("第一次产生的随机数",s)
      while (rands[h][w] == 2 or type(rands[h][w]) == "string") do
        --print("第二次产生的随机数",s)
        s = math.random(1,los2.rows*los2.cols-1)
        h = math.floor(s/los2.cols)+1
        w = s%los2.cols+1
      end
      rands[h][w] = 2;
      mapSerV[h..":"..w] = k
      if k <=3 then
       mapTrea:insert(h..":"..w)
      end
      iss = iss - 1
    end
  end
  trea_server[talk_login.dbrkey] = mapTrea
  user_map[talk_login.dbrkey] = mapSerV
  user03.maptTrap = mapSerV
  --用户道具表信息
  user_item[talk_login.dbrkey] = datacenter.get(talk_login.dbrkey..':'.."item")
--  print("用户道具表信息",dump(user_item))
  user03.itemtab = user_item[talk_login.dbrkey]
  --查看当前宠物属性
  local opens2 = user_names[talk_login.dbrkey][cli_user[12]]
  local opens = user_names[talk_login.dbrkey][cli_user[16]]
--  local roleOn ={}
--  local rolews = dbr:hmget(opens,tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[19],tableRoleS[9])
--  roleOn={ gameuser = tonumber(rolews[1]),rolekey = opens, life = tonumber(rolews[3]), userLife = tonumber(rolews[4]) ,stage = tonumber(rolews[2]), actionVal = tonumber(rolews[5]),levelCap = tonumber(rolews[6]) }
--  user03.roleuser = roleOn
  user03.roleuser = { gameuser = opens[tableRoleS[5]],rolekey = opens2, life = opens[tableRoleS[7]], userLife = opens[tableRoleS[8]] ,stage = opens[tableRoleS[6]], actionVal = opens[tableRoleS[19]],levelCap = opens[tableRoleS[9]] }
  print("地图位置----",dump(user03))
  --print("dfdfd",dump(user_mapItems))
  if user_com[talk_login.dbrkey] ~= nil then
    user_com[talk_login.dbrkey] =nil
  end
  user_com[talk_login.dbrkey] = {[gameLevelk[3] ]=gameLevelk[19],[gameLevelk[2] ] = gameLevelk[19],[gameLevelk[1] ] = gameLevelk[19], [gameLevelk[7] ] = mapSerS.treaNum, [gameLevelk[8] ] = mapSerS.numTrap,[ gameLevelk[9] ] = opens[tableRoleS[19]],[ gameLevelk[10] ] = (os.time()+mapSerS.timeS), [  gameLevelk[11] ] = gameLevelk[19], [gameLevelk[12] ]= gameLevelk[19] , [gameLevelk[13] ]= mapSerS.timeS , [gameLevelk[14] ]= gameLevelk[19] ,[gameLevelk[15] ]= opens[tableRoleS[19]], [gameLevelk[16] ]=gameLevelk[19] ,[gameLevelk[22] ]=talk_login.pass }
--  print("-用户战斗数据-",dump(user_com))
  local b = os.clock()
  print(b-a)
  return "yes",serialize(user03)
end

--陷阱盘点roleVS(dbr,adds)
function roleVS(adds,dbrkey)
    --宠物信息
    if user_mapItems[1] == nil then
    --得到关卡信息
    local obj02 =datacenter.get("user_item_s")
      user_mapItems = obj02
    end
    local addst=clone(user_mapItems[adds])
  --得到陷阱对抗的属性
  local switch = {
    [1] = {roleA =user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[11]],roleB = user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[12]] },
    [2] = {roleA =user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[13]],roleB = user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[14]] },
    [3] = {roleA =user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[15]],roleB = user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[16]] },
    [4] = {roleA =user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[17]],roleB = user_roles[user_names[dbrkey][cli_user[2]]][tableRoleS[18]] },
  }
  local ss = math.floor((adds-1)/3)
  print("ss",dump(switch[ss]))
  
  print(dump(addst))
  --判断陷阱大小和类型
  math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
    --1固定伤害/1抗性
    local sc
    local sm
    --当固定伤害
    sm = math.random(1,rolevs[adds])
    if switch[ss].roleA ~= 1 then
      sc = math.random(1,10)
    else
--      sc = 1
      sc = math.random(1,10)
      print(type(switch[ss].roleA))
    end
    print("sm",sm,"sc",sc)
    if sc >= sm then
      print("陷阱不触发")
      return {[gameLevelk[1]] = 0,[gameLevelk[2]] = 0, [gameLevelk[3]] = 0,vs = 1}
    end
    --持续时间
    sm = math.random(1,rolevs[adds])
    if switch[ss].roleB ~= 1 then
      sc = math.random(1,10)
    else
--      sc = 1
      sc = math.random(1,10)
    end
    print("sm",sm,"sc",sc)
    if sc >= sm then
      print("没有持续伤害")
      return {[gameLevelk[1]] = addst[gameLevelk[1]]*0.4,[gameLevelk[2]] = addst[gameLevelk[2]], [gameLevelk[3]] =  addst[gameLevelk[3]],vs = 2}
    end
    return {[gameLevelk[1]] = addst[gameLevelk[1]],[gameLevelk[2]] = addst[gameLevelk[2]], [gameLevelk[3]] = addst[gameLevelk[3]], vs = 3}

end



--结算界面
--local yangk = ClearOk(user_com[talk_login.dbrkey],talk_login.dbrkey)
function ClearOk(dbr,user_com,dbrkeys)
  local timejs = (user_com[gameLevelk[10]]+2) -os.time()
  --剩余时间判断
  if timejs >0  then
    -- user_names[dbrkeys]
    print(dbrkeys)
    print("打印结算相关")
    --百分比星星
    local timeV = timejs + user_names[dbrkeys][cli_user_t[14]]
    local timeG = user_names[dbrkeys][cli_user_t[14]]
    if timeV <=100 then
      print("第三颗星星")
      user_names[dbrkeys][cli_user_t[14]] = timeV - 100
    else
      print("没有第三颗星星")
      user_names[dbrkeys][cli_user_t[14]] = timeV
    end
    
    print(user_com[gameLevelk[7]])
    local stars
    if user_com[gameLevelk[12]] == 0 then
      print("没有触发陷阱")
      stars = stars_user[2]
    else
      print("触发陷阱")
      stars = stars_user[3]
    end
    if user_com[gameLevelk[22]] == user_names[dbrkeys][cli_user[9]] then
      --print(user_names[dbrkeys][cli_user[9]])
      --print(dbrkeys,cli_user[9])
      user_names[dbrkeys][cli_user[9]] = dbr:hincrby(dbrkeys, cli_user[9],1)
      print("最高关卡加1")
    end
    --更新宝气值
--    print(dbrkeys, cli_user[5],user_com[gameLevelk[11]])
    user_names[dbrkeys][cli_user[5]] = dbr:hincrby(dbrkeys, cli_user[5],user_com[gameLevelk[11]])
    user_names[dbrkeys][cli_user[11]] = dbr:hincrby(dbrkeys, cli_user[11],stars)
    local listV = dbr:zadd(ranking_List[1],user_names[dbrkeys][cli_user[5]],dbrkeys)
    listV = dbr:zrevrank(ranking_List[1], dbrkeys)+1
    datacenter.set(dbrkeys,user_names[dbrkeys])
    local addBys = gameVip[user_names[dbrkeys][cli_user[7]] ].addBy
    local jis = math.floor(user_com[gameLevelk[7]]*5*(1+timejs/user_com[gameLevelk[13]]+addBys ) )
    print(jis)
    --user_com = nil
    return {gameEnded = jis,stars = stars,listP = listV,usegasValues=user_names[dbrkeys][cli_user[5]],addBy= addBys,timeV = timeV,timeG = timeG}
  else
    print("-游戏超时-")
  end
end
--3.3进入游戏状态 CMD.mysqlSelectMap033(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.mysqlSelectMap033(dbm,dbr,dbrT,client_fd,talk_logins)

    --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--      trapstr = "3:8",
--      pos = "3:8",
--    }
--    local talk_logins = serialize(talk_login)
   local posa,message = localMap033(dbm,dbr,dbrT,talk_logins)
   return posa,message
end
--重生
local gameRebirth={
  diamond = 20,
  life = 30,
}

--3.3.1
function localMap033(dbm,dbr,dbrT,talk_logins)
   local a = os.clock() 
    local talk_login = unserialize(talk_logins)
    print("进入游戏动作")
    local user03 = {}
--    --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--      trapstr = "3:8",
--      pos = "3:8",
--    }
    if user_names[talk_login.dbrkey] ==nil then
      print("用户还没有登录")
      return "no", {id =904 }
    end
    --跟新血槽
    
    --1角色陷阱持续伤害
    print(user_com[talk_login.dbrkey][gameLevelk[2]],user_com[talk_login.dbrkey][gameLevelk[1]])
    if user_com[talk_login.dbrkey][gameLevelk[2]] == 0 and  user_com[talk_login.dbrkey][gameLevelk[1]] == 0 then
      print("没有持续伤害")
    else
      print("有持续伤害")
      --陷阱的持续时间是否结束
      if user_com[talk_login.dbrkey][gameLevelk[16]] <= user_com[talk_login.dbrkey][gameLevelk[14]] then
        print("继续持续伤害")
        --减生命值//陷阱已经持续时间
        local timeDel = os.time() - user_com[talk_login.dbrkey][gameLevelk[16]]
--        print("持续伤害时间",os.time() )
--        print("持续伤害时间",timeDel)
--        print("持续伤害时间",user_com[talk_login.dbrkey][gameLevelk[16]])
--        print("持续伤害点",user_com[talk_login.dbrkey][gameLevelk[2]])
        --剩余生命值
        user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] - timeDel*user_com[talk_login.dbrkey][gameLevelk[2]]
        --更新时间
        user_com[talk_login.dbrkey][gameLevelk[16]] = os.time()
      else
        print("停止持续伤害")
        user_com[talk_login.dbrkey][gameLevelk[16]] = gameLevelk[19]
        user_com[talk_login.dbrkey][gameLevelk[14]] = gameLevelk[19]
        user_com[talk_login.dbrkey][gameLevelk[3]] = gameLevelk[19]
        user_com[talk_login.dbrkey][gameLevelk[2]] = gameLevelk[19]
        user_com[talk_login.dbrkey][gameLevelk[1]] = gameLevelk[19]
      end
    end
    --2生命值判断
    if user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] <= gameLevelk[19] then
      print("角色死亡")
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = gameLevelk[19]
      local res033 = dbr:hset(user_names[talk_login.dbrkey][cli_user[12]],tableRoleS[7],gameLevelk[19])
      print("角色",res033)
      datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
      return "no", serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    elseif user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] > user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]] then
      print("生命值异常")
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]] 
    
    end
    --3行动值减一
    if user_com[talk_login.dbrkey][gameLevelk[15]] <= 0 then
      --游戏结束
      print(dump(user_com))
      datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
      return "no", serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    else
      user_com[talk_login.dbrkey][gameLevelk[15]] = user_com[talk_login.dbrkey][gameLevelk[15]] -1
    end
    --4时间判断
    if user_com[talk_login.dbrkey][gameLevelk[10]] <= os.time() then
      print("时间到游戏结束")
      datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
      return "no",serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    end
    --5游戏成功/宝藏全部挖完
     if user_com[talk_login.dbrkey][gameLevelk[7]] <= user_com[talk_login.dbrkey][gameLevelk[11]] then
       --游戏结束/宝藏挖完
       --print(dump(user_com))       {gameEnded = jis,stars = stars}
       local passOK = ClearOk(dbr,user_com[talk_login.dbrkey],talk_login.dbrkey)
       user_map[talk_login.dbrkey] =nil
--       user_com[talk_login.dbrkey] =nil
       return "ok",serialize( {numa = 110,gameEnded=passOK.gameEnded,stars=passOK.stars, listP =passOK.listP,addBy = passOK.addBy,usegasValues =passOK.usegasValues ,timeV = passOK.timeV,timeG = passOK.timeG, addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
     end
    --得到战斗信息
    if talk_login.trapstr == "0:0" then
      print("持续结束")
      return "yes" , serialize({numa =108,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    end 
    local paskey = user_map[talk_login.dbrkey][talk_login.trapstr]
    print("触发的键值为",user_map[talk_login.dbrkey][talk_login.trapstr])
    user_map[talk_login.dbrkey][talk_login.trapstr] = nil
    print("键值为",talk_login.trapstr)
    --1保存上一步操作
    local state_on = {}
    state_on[gameLevelk[18]] =talk_login.trapstr
    state_on[gameLevelk[20]] =paskey
    
    if paskey == nil then
      print("值异常")
      print("空")
      user_state[talk_login.dbrkey] = clone(state_on)
      return "yes",serialize( {numa = 0,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    elseif paskey <=3 then
      print("宝藏")
      local adds = user_mapItems[paskey]
      print(dump(adds))
--      print(dump(user_com))
      --保存上一步宝藏数
      state_on[gameLevelk[4]]=user_com[talk_login.dbrkey][gameLevelk[11]]
      user_state[talk_login.dbrkey] = clone(state_on)
      --
      user_com[talk_login.dbrkey][gameLevelk[11]] = user_com[talk_login.dbrkey][gameLevelk[11]] + adds[gameLevelk[4]]
      local posStr = trea_server[talk_login.dbrkey]:remove(trea_server[talk_login.dbrkey][talk_login.trapstr])
      print("弹出的是",posStr)
      if user_com[talk_login.dbrkey][gameLevelk[11]] < user_com[talk_login.dbrkey][gameLevelk[7]] then
--        print(dump(user_com))
        return "yes",serialize( {numa = paskey,addTrea = adds[gameLevelk[4]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
      else
         --游戏结束/宝藏挖完
         print("宝藏挖完",dump(user_com))
         local passOK = ClearOk(dbr,user_com[talk_login.dbrkey],talk_login.dbrkey)
         user_map[talk_login.dbrkey] =nil
         --user_com[talk_login.dbrkey] =nil
         return "ok",serialize( {numa = 110,gameEnded=passOK.gameEnded,stars=passOK.stars,listP =passOK.listP,addBy = passOK.addBy,usegasValues =passOK.usegasValues , timeV = passOK.timeV,timeG = passOK.timeG,addTrea = adds[gameLevelk[4]], addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
       end
    elseif paskey <=15 then
      print("陷阱")
--      print(talk_login.trapstr )
--      print(talk_login.pos)
      if talk_login.trapstr ~= talk_login.pos then
        user_com[talk_login.dbrkey][gameLevelk[12]] = user_com[talk_login.dbrkey][gameLevelk[12]] + 1
        return "yes",serialize( {numa = paskey,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]], addNumTrap = user_com[talk_login.dbrkey][gameLevelk[12]]} )
      end
      --得到陷阱数据
      local add = user_mapItems[paskey]
      --判断是否有金钟罩
      if user_com[talk_login.dbrkey][gameLevelk[17]] ~= nil then
        user_com[talk_login.dbrkey][gameLevelk[17]] = nil
        user_com[talk_login.dbrkey][gameLevelk[12]] = user_com[talk_login.dbrkey][gameLevelk[12]] + 1
        return "yes",serialize( {numa = paskey,addgame = {trapDamage = add[gameLevelk[3]],warlock = add[gameLevelk[2]],warlockTime = add[gameLevelk[1]],vs =1 },actionVals =user_com[talk_login.dbrkey][gameLevelk[15]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]} )
      end
      --减血
      --保存上一步生命值
      state_on[gameLevelk[21]]= user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]
      user_state[talk_login.dbrkey] = clone(state_on)
      --从全局变量中取得当前宠物的血
      print(dump(user_com))
      print( dump(user_names[talk_login.dbrkey][cli_user[16]]))
      print("----------进入判定------------")
      local adds = roleVS(paskey,talk_login.dbrkey)
      print(dump(adds))
      print(dump(add))
      print("----------判定结束------------")
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] -adds[gameLevelk[3]]
      local life02 = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[12]],tableRoleS[7],-adds[gameLevelk[3]])
      datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
      user_com[talk_login.dbrkey][gameLevelk[14]] = os.time()+adds[gameLevelk[1]]
      user_com[talk_login.dbrkey][gameLevelk[16]] = os.time()
      print( dump(user_names[talk_login.dbrkey][cli_user[16]]))
      user_com[talk_login.dbrkey][gameLevelk[12]] = user_com[talk_login.dbrkey][gameLevelk[12]] + 1
      if user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] <= 0 then
        --游戏结束
        user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = 0
        datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
        print(dump(user_names))
        --return "no", serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
        return "yes",serialize( {numa = paskey,addgame = {trapDamage = adds[gameLevelk[3]],warlock = adds[gameLevelk[2]],warlockTime = adds[gameLevelk[1]],vs =adds.vs },actionVals =user_com[talk_login.dbrkey][gameLevelk[15]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]} )
      end
      if adds[ gameLevelk[1] ] == '0' and adds[ gameLevelk[2] ] == "0" then
        print("保持原来的伤害")
      else
        user_com[talk_login.dbrkey][gameLevelk[2]] = adds[gameLevelk[2]]
        user_com[talk_login.dbrkey][gameLevelk[1]] = adds[gameLevelk[1]]
      end
      print(dump(user_com))
      local b = os.clock()
      print(b-a)
      return "yes",serialize( {numa = paskey,addgame = {trapDamage = adds[gameLevelk[3]],warlock = adds[gameLevelk[2]],warlockTime = adds[gameLevelk[1]],vs =adds.vs},actionVals =user_com[talk_login.dbrkey][gameLevelk[15]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]} )
    elseif paskey <=18  then
      print("加血")
      local adds = user_mapItems[paskey]
      print(dump(adds))
      --print(dump(user_names))
      --保存上一步生命值
      state_on[gameLevelk[21]]= user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]
      user_state[talk_login.dbrkey] = clone(state_on)
      print(adds[gameLevelk[5]])
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] + adds[gameLevelk[5]]
      if user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]] < user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] then
        user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]]
      end
      print(dump(user_names))
      return "yes",serialize( {numa = paskey,addLife = adds[gameLevelk[5]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    elseif paskey <=21  then
      print("魔法剂")
      local adds = user_mapItems[paskey]
      --保存上一步行动值
      state_on[gameLevelk[15]]= user_com[talk_login.dbrkey][gameLevelk[15]]
      user_state[talk_login.dbrkey] = clone(state_on)
      user_com[talk_login.dbrkey][gameLevelk[15]] = user_com[talk_login.dbrkey][gameLevelk[15]] +adds[gameLevelk[6]]
      if user_com[talk_login.dbrkey][gameLevelk[9]]  < user_com[talk_login.dbrkey][gameLevelk[15]] then
        user_com[talk_login.dbrkey][gameLevelk[15]] = user_com[talk_login.dbrkey][gameLevelk[9]] 
      end
      print(adds)
      --user_com[talk_login.dbrkey][]
      return "yes",serialize( {numa = paskey,addMagic =adds[gameLevelk[6]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    else
      print("其他")
      return "no",serialize({id =902,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    end
  --根据键值取数据
end


--3.4重生
function CMD.luaSelectMap034(dbm,dbr,dbrT,client_fd,talk_logins)
    local a = os.clock() 
    local talk_login = unserialize(talk_logins)
     --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
  --1扣除钻石
    if user_names[talk_login.dbrkey][cli_user[8]] < gameRebirth.diamond then
      print("钻石不足不可以复活")
      return "no",serialize({id = 12})
    else
      local userCurr6 = dbr:hincrby( talk_login.dbrkey, cli_user[8], -gameRebirth.diamond)
      user_names[talk_login.dbrkey][cli_user[8]] = userCurr6
      --2改变数据继续游戏
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = gameRebirth.life
      if (user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]+gameRebirth.life) <= user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]] then
        local life02 = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[12]],tableRoleS[7],gameRebirth.life)
        user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = life02
      else
        local life03 = dbr:hset(user_names[talk_login.dbrkey][cli_user[12]],tableRoleS[7],user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]])
        user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[8]]
      end
      datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
      user_com[talk_login.dbrkey][gameLevelk[15]]  = user_com[talk_login.dbrkey][gameLevelk[9]] 
      user_com[talk_login.dbrkey][gameLevelk[10]] =  (os.time()+user_com[talk_login.dbrkey][gameLevelk[13]])
      local b = os.clock()
      print(b-a)
      return "yes",serialize({numa = 111,life = user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]], timeS =user_com[talk_login.dbrkey][gameLevelk[13]] })
    end
end

--3.5游戏中购买钻石
function CMD.luaSelectMap035(dbm,dbr,dbrT,client_fd,talk_logins)
    local a = os.clock() 
    local talk_login = unserialize(talk_logins)
     --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
  --1钻石
      local resd = dbr:hincrby(talk_login.dbrkey,user_names[talk_login.dbrkey][cli_user[8]],100)
      user_names[talk_login.dbrkey][cli_user[8]] = resd
      return "yes",serialize({diamond = resd})
end
--3.6失败的结算
function CMD.luaSelectMap036(dbm,dbr,dbrT,client_fd,talk_logins)
    local a = os.clock() 
    local talk_login = unserialize(talk_logins)
     --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
      --user_names[talk_login.dbrkey][cli_user[5]] = user_names[talk_login.dbrkey][cli_user[5]] + user_com[talk_login.dbrkey][gameLevelk[11]]
      local resd = dbr:hincrby(talk_login.dbrkey,user_names[talk_login.dbrkey][cli_user[5]],user_com[talk_login.dbrkey][gameLevelk[11]])
      user_names[talk_login.dbrkey][cli_user[5]] = resd
      user_com[talk_login.dbrkey] = nil
      user_map[talk_login.dbrkey] =nil
      return "yes",serialize({usegasValues = resd})
end

--3.7道具的使用
function CMD.itemServerMap0307(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
   --得到用户数据
   local talk_login = unserialize(talk_logins)
--  local talk_login = {
--    dbrkey = "33:12",
--    itemOn = 2,   --使用的道具
--    pos = "3:8",        --当前位置
--    trapstr = "3:8",  --上一次触发的位置
--    state = 2,    --用户状态
--  }
    --得到用户的道具数量
  if user_names[talk_login.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
  --1.用户是否有该道具
  --print(dump(user_item))
  if user_item[talk_login.dbrkey][talk_login.itemOn] ==0 then
    print("用户不可以使用该道具")
    return "no",{id = 108}
  else
    print("用户可以使用该道具")
  end
  local switch = {
      [1] = function (userkey01,t4,dbr) --沙漏/增加寻宝时间30秒
        --沙漏（游戏剩余的秒数<总时间-加的秒数）成立时间为
        local res_u3 = user_com[userkey01][gameLevelk[10]]-os.time()
        if  res_u3 <=user_com[userkey01][gameLevelk[13]] - 30  then
          print("加上30")
          user_com[userkey01][gameLevelk[10]] = user_com[userkey01][gameLevelk[10]] + 30
          res_u3 = res_u3+30
        else
          print("当前时间加游戏时间")
          res_u3 = user_com[userkey01][gameLevelk[13]]
          user_com[userkey01][gameLevelk[10]] = user_com[userkey01][gameLevelk[13]] + os.time()
        end
        user_com[userkey01][gameLevelk[10]] = user_com[userkey01][gameLevelk[10]] + 30

        return "yes" ,{numa = 1,timeS = res_u3}
      end,
      [2] = function (userkey01,t4,dbr) --时光机/在寻宝中使用可以返回到上一步
        --时光机
--        user_item[userkey01][t4] = user_item[userkey01][t4] - 1
        --状态值判断
        if talk_login.state == 1 or talk_login.state == 0 then
          print("行走")
          return "yes", {prot = 2,numa = 0,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] }
        elseif talk_login.state == 2 then
          print("挖掘")
          print(dump(user_state))
          
          if talk_login.trapstr ~= user_state[talk_login.dbrkey][gameLevelk[18]] then
            print("位置不对")
            return "no",{id = 9}
          end
          --local paske = user_map[userkey01][talk_login.trapstr]
          local paske = user_state[talk_login.dbrkey][gameLevelk[20]]
          print("dfdf",paske)
            if paske == nil then
            print("值异常")
            print("空")
            return "yes",{numa = 0,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] }
          elseif paske <=3 then
            print("宝藏")
            user_map[talk_login.dbrkey][talk_login.trapstr] = paske
            user_com[talk_login.dbrkey][gameLevelk[11]] = user_state[userkey01][gameLevelk[4]]
            
             return "yes",{numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] }
          elseif paske <=15 then
            print("陷阱")
            user_map[talk_login.dbrkey][talk_login.trapstr] = paske
            print(dump(user_map[talk_login.dbrkey]))
             print("陷阱")
            --回退到上一步数据
            if user_state[userkey01][gameLevelk[21]] == nil then
              print("使用金钟罩")
            else
              user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_state[userkey01][gameLevelk[21]]
            end
              --
            local life02 = dbr:hset(user_names[talk_login.dbrkey][cli_user[12]], tableRoleS[7], user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]])
            user_com[talk_login.dbrkey][gameLevelk[12]] = user_com[talk_login.dbrkey][gameLevelk[12]] - 1
            user_com[talk_login.dbrkey][gameLevelk[16]] = gameLevelk[19]
            user_com[talk_login.dbrkey][gameLevelk[14]] = gameLevelk[19]
            user_com[talk_login.dbrkey][gameLevelk[3]] = gameLevelk[19]
            user_com[talk_login.dbrkey][gameLevelk[2]] = gameLevelk[19]
            user_com[talk_login.dbrkey][gameLevelk[1]] = gameLevelk[19]
             return "yes",{numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] }
          elseif paske <= 18 then
            user_map[talk_login.dbrkey][talk_login.trapstr] = paske
            print("加血")
            user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_state[userkey01][gameLevelk[21]]
            local life02 = dbr:hset(user_names[talk_login.dbrkey][cli_user[12]], tableRoleS[7], user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]])
            return "yes",{numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] }
          elseif paske<= 21 then
            user_map[talk_login.dbrkey][talk_login.trapstr] = paske
            user_com[talk_login.dbrkey][gameLevelk[15]] = user_state[userkey01][gameLevelk[15]]
            return "yes",{numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] }
          end
        end
        return "no", { id = 8 }
      end,
      [3] = function (userkey01,t4,dbr) --金钟罩/在寻宝中使用进入到无敌状态，可以抵御一次陷阱
         user_com[userkey01][gameLevelk[17]] = 1
         print(dump({numa = 3, user_com[userkey01][gameLevelk[17]] }))
--         user_item[userkey01][t4] = user_item[userkey01][t4] - 1
        return "yes",{[gameLevelk[17]]=user_com[userkey01][gameLevelk[17]] }
      end,
      [4] = function (userkey01,t4,dbr) --寻宝镖/在寻宝中使用可以随机标注一处宝藏
--        user_map[talk_login.dbrkey] = 1
         --print("宝藏",dump(trea_server[userkey01]))
         --指定用户的宝藏位置弹出
         local posStr = table.remove(trea_server[userkey01])
--         user_item[userkey01][t4] = user_item[userkey01][t4] - 1
         print("--------------------------")
         print("结束",posStr)
        --遍历地图取宝藏位置
        return "yes",  {pos =  posStr}
      end,
      [5] = function (userkey01,t4,dbr) --飞云铲/在寻宝中使用可以挖开任何一个有效的格子
        print("使用飞云铲")
        local talk_st = serialize(talk_login)
        local posa,message = localMap033(dbm,dbr,dbrT,talk_st)
--        print(posa)
        print(dump(message))
        print("使用飞云铲结束")
        return "yes", unserialize(message)
      end,
      [6] = function (userkey01,t4,dbr) --疾风术/吹散屏幕中的云雾
        
        return "yes", {id = 8 }
      end,
      [7] = function (userkey01,t4,dbr) --禁锢术/禁锢对手，让对手3秒行动不能，冷却时间20秒
      
        
        return "yes",{id = 8 }
      end,
      [8] = function (userkey01,t4,dbr) --抢夺术/随机抢夺对手获得的宝藏0-1份，冷却时间20秒
        
        return "yes", {id = 8 }
      end,
     }
     --判断使用的道具
     local st,s
     local f = switch[talk_login.itemOn]
     print(type(f))
     if (f) then
        st,s = f(talk_login.dbrkey, talk_login.itemOn, dbr)
        print(st,s)
        if st == "yes" then
        user_item[talk_login.dbrkey][talk_login.itemOn] =dbr:hincrby(talk_login.dbrkey,talk_login.itemOn,-1)
        datacenter.set(talk_login.dbrkey..':'.."item",user_item[talk_login.dbrkey])
        end
        return st,serialize({p = s,item =user_item[talk_login.dbrkey][talk_login.itemOn],prot = talk_login.itemOn } )
      else
        return "no",{id = 834}
      end
   
end

----------------------------------------------------------------

--12得到地图信息
function astateMap(dbrT,passK)
    --得到地图信息
    if user_passk[passK] == nil then
      local map = {}
      print("no----------")
      local mapT01 = dbrT:hmget(mapG[1]..passK, mapServer[1] , mapServer[2] , mapServer[3] , mapServer[4] ,mapServer[5] , mapServer[6] , mapServer[7] ,  mapServer[8] , mapServer[9] ,mapServer[10] ,mapServer[11] ,mapServer[12] , mapServer[13] ,mapServer[14],mapServer[15],mapServer[16]  )
      --组织地图数据
      for k,v in pairs(mapServer02) do
         if k == "gateNum" or k == "boxSize" then
          map[k] = mapT01[v]
         else
          map[k] = tonumber(mapT01[v])
         end
      end
      map["mapType"] = mapType[map[mapServer[16]]]
      user_passk[passK] = clone(map)

      print("添加关卡信息----")
    else
      print("有关卡信息----------")
    end
end

--12创建对战地图
function astatePass(dbm,talk_login)
  print("对战关卡地图")
   --产生地图物品位置/和关卡编号
  math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
  local pass = math.random(1,240) + 60
  if  Astate_map[talk_login.key] ~= nil then
    print("清除原有对战关卡地图")
    Astate_map[talk_login.key]=nil
  end
  --查看键是否存在
  print("陷阱消息")
  if user_mapItems[1] == nil then
    --得到关卡信息
    local obj =datacenter.get("user_item_s")
    user_mapItems = obj
  end
  --得到地图
  local los2 = Levels.get(pass)
  
  --得到地图信息
  local luas = ""
  local res ={}
  local resY ={}
  if user_passG[pass] ~= nil then
    resY = user_passG[pass]
  else
    print("得到关卡信息")
    luas = "call mapTableOn02("
    luas = luas..pass ..')'
    res = dbm:query(luas)
--    print("地图信息",dump(res))
    user_passG[pass] = clone(res[1][1])
    resY = res[1][1]
  end
 
  local mapSerS = resY
  local iss = 0
  local rands = clone(los2.grid)   --深拷贝
  local h = 0
  local w = 0
  local mapSerV={}
  local mapTrea = newset()
  print(pass)
  print(los2.rows*los2.cols-1)
  --双方出现位置
  local vst = {}
  local vsA = 2
  while vsA~= 0 do
    local vss = math.random(1,los2.rows*los2.cols-1)
    h = math.floor(vss/los2.cols)+1
    w = vss%los2.cols+1
    while (type(rands[h][w]) == "string") do
        vss = math.random(1,los2.rows*los2.cols-1)
        h = math.floor(vss/los2.cols)+1
        w = vss%los2.cols+1
    end
    vst[vsA]=h..":"..w
    vsA = vsA - 1
  end
  bearVS[talk_login.key] = vst
  --地图物品
  for k,v in pairs(mapApp) do
    iss = mapSerS[v]
    while iss ~= 0 do
      --print(iss)
      --产生随机数
      local s = math.random(1,los2.rows*los2.cols-1)
      h = math.floor(s/los2.cols)+1
      w = s%los2.cols+1
      --print("第一次产生的随机数",s)
      while (rands[h][w] == 2 or type(rands[h][w]) == "string") do
        --print("第二次产生的随机数",s)
        s = math.random(1,los2.rows*los2.cols-1)
        h = math.floor(s/los2.cols)+1
        w = s%los2.cols+1
      end
      rands[h][w] = 2;
      mapSerV[h..":"..w] = k
      if k <=3 then
       mapTrea:insert(h..":"..w)
      end
      iss = iss - 1
    end
  end
  trea_server[talk_login.key] = mapTrea
  Astate_map[talk_login.key] = mapSerV
  return pass
end


local ak = {}
ak[1] = {key = "33:12"}
--ak[2] = {dbrkey = "50:荣安翔",}
--ak[3] = {dbrkey = "49:空昂雄",}
ak[4] = {key = "66:庄博达",}

--当匹配成功后跳转到这里进行对战地图和信息的采集
function gameLevel1104(dbm,dbr,dbrT,st)
  print("打印消息对战")
  local talk_login = st
--  local Apd = datacenter.get(talk_login.key..cli_user_k[2])
  local Apd = datacenter.get(talk_login.key..cli_user_k[3])
  print("得到红黑方")
  Astate_vs[talk_login.key] = Apd
  print(dump(Astate_vs[talk_login.key]))
    
  local passK = astatePass(dbm,talk_login)
  astateMap(dbrT,passK)
  print("得到地图物品信息")
  print(dump( Astate_map[talk_login.key]))
  print("得到关卡信息")
  print(dump( user_passk[passK]))
  print("双方位置")
  print(dump(bearVS))
  --
  local mapSerS ={}
  if user_passG[passK] ~= nil then
    mapSerS = user_passG[passK]
  else
    print("得到关卡信息")
    luas = "call mapTableOn02("
    luas = luas..passK ..')'
    res = dbm:query(luas)
    print("地图信息",dump(res))
    user_passG[passK] = clone(res[1][1])
    mapSerS = res[1][1]
  end
  --得到双方的对战宠物
  --判断当前宠物信息是否存在
  print("-------k,v-----双方对战宠物----")
  for k,v in pairs(Astate_vs[talk_login.key]) do
    print(k,v)
    user_names[v] = datacenter.get(v)
    if user_roles[v] == nil or user_names[v][cli_user[12]] ~= user_roles[v] then
      local opens = dbr:hmget(user_names[v][cli_user[12]], tableRoleS[3],tableRoleS[11], tableRoleS[12], tableRoleS[13], tableRoleS[14], tableRoleS[15], tableRoleS[16], tableRoleS[17],tableRoleS[18])
      user_roles[v]= {[tableRoleS[3]] = opens[1],[tableRoleS[11]] = tonumber(opens[2]),[tableRoleS[12]] = tonumber(opens[3]),[tableRoleS[13]] = tonumber(opens[4]),[tableRoleS[14]] = tonumber(opens[5]),[tableRoleS[15]] = tonumber(opens[6]),[tableRoleS[16]] = tonumber(opens[7]),[tableRoleS[17]] = tonumber(opens[8]),[tableRoleS[18]] = tonumber(opens[9]),}
      print("宠物属性",dump(user_roles[v]))
    end
    if user_com[v] ~= nil then
      user_com[v] =nil
    end
      user_com[v] = {bear = v,[gameLevelk[3] ]=gameLevelk[19],[gameLevelk[2] ] = gameLevelk[19],[gameLevelk[1] ] = gameLevelk[19], [gameLevelk[7] ] = mapSerS.treaNum, [gameLevelk[8] ] = mapSerS.numTrap,[ gameLevelk[9] ] = tonumber(user_names[v][tableRoleS[19]]),[ gameLevelk[10] ] = (os.time()+mapSerS.timeS), [  gameLevelk[11] ] = gameLevelk[19], [gameLevelk[12] ]= gameLevelk[19] , [gameLevelk[13] ]= mapSerS.timeS , [gameLevelk[14] ]= gameLevelk[19] ,[gameLevelk[15] ]= tonumber(user_names[v][tableRoleS[19]]), [gameLevelk[16] ]=gameLevelk[19] ,[gameLevelk[22] ]=passK }
  end
end

--进入地图对战
function gameLevel1105(dbm,dbr,dbrT)
  --双方位置改变
  
  
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
--  mysqlSelectMap031(dbm,dbr,dbrT)
--  redisSelectMap0302(dbm,dbr,dbrT)
--  mysqlSelectMap033(dbm,dbr,dbrT)
--
  gameLevel1104(dbm,dbr,dbrT,ak[1])
  gameLevel1104(dbm,dbr,dbrT,ak[4])

  skynet.register "checkBattle"
  --dbm:disconnect()
  --skynet.exit()
  skynet.dispatch("lua", function(session, address, cmd, ...)
    local f = CMD[cmd]
    skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
  
  end)
end)



