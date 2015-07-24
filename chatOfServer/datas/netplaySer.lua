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

    --查询键查看用户关卡查看权限
    if user_names[talk_login.dbrkey] == nil then
    --查看键是否存在
      local userIs = dbr:hexists(talk_login.dbrkey,cli_user[9])
      if userIs ==1 then
          local userPass = dbr:hget(talk_login.dbrkey,cli_user[9])
          local userP = tonumber(userPass)
          local map = {}
          --查询用户的最高可访问关卡
          print(userP)
          print(talk_login.pass )
          
          if talk_login.pass <= userP then
            print("可以访问");
            if user_passk[talk_login.pass] ~= nil then
              print("yes----------")
              return "yes", serialize(user_passk[talk_login.pass])
            else
              print("no----------")
              local mapT01 = dbrT:hmget(mapG[1]..':'..talk_login.pass, mapServer[1] , mapServer[2] , mapServer[3] , mapServer[4] ,mapServer[5] , mapServer[6] , mapServer[7] ,  mapServer[8] , mapServer[9] ,mapServer[10] ,mapServer[11] ,mapServer[12] , mapServer[13] ,mapServer[14],mapServer[15]  )
              --组织地图数据
              for k,v in pairs(mapServer02) do
                 if k == "gateNum" or k == "boxSize" then
                  map[k] = mapT01[v]
                 else
                  map[k] = tonumber(mapT01[v])
                 end
              end
              user_passk[talk_login.pass] = clone(map)
              print("my002----",dump(user_passk))
              local b = os.clock()
              print(b-a)
              return "yes", serialize(map)
            end
          else
            print("不可以访问");
            return "no",{id = 833}
          end
      elseif userIs == 0 then
        print("键不存在")
        return "no",{id = 831}
      else
        print("出现异常")  
        return "no",{id = 902}
      end
  elseif talk_login.pass<= user_names[talk_login.dbrkey].pass then
    print("可以访问");
    if user_passk[talk_login.pass] ~= nil then
      print("yes----------")
      return "yes", serialize(user_passk[talk_login.pass])
    else
      local map = {}
      print("no----------")
      local mapT01 = dbrT:hmget(mapG[1]..':'..talk_login.pass, mapServer[1] , mapServer[2] , mapServer[3] , mapServer[4] ,mapServer[5] , mapServer[6] , mapServer[7] ,  mapServer[8] , mapServer[9] ,mapServer[10] ,mapServer[11] ,mapServer[12] , mapServer[13] ,mapServer[14],mapServer[15]  )
      --组织地图数据
      for k,v in pairs(mapServer02) do
         if k == "gateNum" or k == "boxSize" then
          map[k] = mapT01[v]
         else
          map[k] = tonumber(mapT01[v])
         end
      end
      user_passk[talk_login.pass] = clone(map)
      print("my002----",dump(user_passk))
      local b = os.clock()
      print(b-a)
      return "yes", serialize(map)
    end
    
  else
    print("不可以访问");
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
--  local obj =datacenter.get(talk_login.dbrkey)
--  print(dump(obj))
--  user_names[talk_login.dbrkey] =obj
  local user03 = {}
  --得到用户数据
  local mapuser1 = user_names[talk_login.dbrkey].pass
  print("用户名:", user_names[talk_login.dbrkey].dbrkey)
  print("地图:",user_names[talk_login.dbrkey].pass)
  if  user_map[mapuser1] ~= nil then
    print("清除原有数据")
    user_map[mapuser1]=nil
  end
  --得到地图
  local los2 = Levels.get(2)
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
    print("地图信息",dump(res))
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
  --查看用户道具表
--  local itemOn = dbr:hmget(talk_login.dbrkey,1,2,3,4,5 )
--  local trap02 ={}
--  for k,v in pairs(itemOn) do
--    trap02[k]=v
--  end
  --用户道具表信息
  user_item[talk_login.dbrkey] = datacenter.get(talk_login.dbrkey..':'.."item")
  print("用户道具表信息",dump(user_item))
  user03.itemtab = user_item[talk_login.dbrkey]
  --查看当前宠物属性
  local opens = user_names[talk_login.dbrkey][cli_user[12]]
  local roleOn ={}
  local rolews = dbr:hmget(opens,tableRoleS[2],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[19])
  roleOn={ gameuser = tonumber(rolews[1]),rolekey = opens, life = tonumber(rolews[4]), userLife = tonumber(rolews[3]) ,levelCap = tonumber(rolews[2]), actionVal = tonumber(rolews[5]) }
  user03.roleuser = roleOn
  print("地图位置----",dump(user03))
  
  --得到关卡信息
  local obj = sharedata.query("user_item")
  user_mapItems = obj
  
  user_com[talk_login.dbrkey] = {[gameLevelk[3] ]=gameLevelk[19],[gameLevelk[2] ] = gameLevelk[19],[gameLevelk[1] ] = gameLevelk[19], [gameLevelk[7] ] = mapSerS.treaNum, [gameLevelk[8] ] = mapSerS.numTrap,[ gameLevelk[9] ] = tonumber(rolews[5]),[ gameLevelk[10] ] = (os.time()+mapSerS.timeS), [  gameLevelk[11] ] = gameLevelk[19], [gameLevelk[12] ]= gameLevelk[19] , [gameLevelk[13] ]= mapSerS.timeS , [gameLevelk[14] ]= gameLevelk[19] ,[gameLevelk[15] ]= tonumber(rolews[5]), [gameLevelk[16] ]=gameLevelk[19]  }
  print("-用户战斗数据-",dump(user_com))
  local b = os.clock()
  print(b-a)
  return "yes",serialize(user03)
end


--结算界面
--local yangk = ClearOk(user_com[talk_login.dbrkey],talk_login.dbrkey)
function ClearOk(user_com,dbrkeys)
  local timejs = (user_com[gameLevelk[10]]+5) -os.time()
  if timejs >0  then
    --+ user_names[dbrkeys]
    local jis = user_com[gameLevelk[7]]*5*(1+timejs/user_com[gameLevelk[13]]+gameVip[user_names[dbrkeys][cli_user[7]] ].addBy )
    return jis
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

    --1角色陷阱持续伤害
    if user_com[talk_login.dbrkey][gameLevelk[2]] == 0 and  user_com[talk_login.dbrkey][gameLevelk[1]] == 0 then
      print("没有持续伤害")
    else
      print("有持续伤害")
      if user_com[talk_login.dbrkey][gameLevelk[16]] <= user_com[talk_login.dbrkey][gameLevelk[14]] then
        print("继续持续伤害")
        --减生命值
        local timeDel = os.time() - user_com[talk_login.dbrkey][gameLevelk[16]]
        print("持续伤害时间",os.time() )
        print("持续伤害时间",timeDel)
        print("持续伤害时间",user_com[talk_login.dbrkey][gameLevelk[16]])
        print("持续伤害点",user_com[talk_login.dbrkey][gameLevelk[2]])
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
      datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
      return "no", serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
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
       --print(dump(user_com))
       local passOK = ClearOk(user_com[talk_login.dbrkey],talk_login.dbrkeys)
       return "ok",serialize( {numa = 110,gameEnded=passOK} )
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
      print(dump(user_com))
      --保存上一步宝藏数
      state_on[gameLevelk[4]]=user_com[talk_login.dbrkey][gameLevelk[11]]
      user_state[talk_login.dbrkey] = clone(state_on)
      --
      user_com[talk_login.dbrkey][gameLevelk[11]] = user_com[talk_login.dbrkey][gameLevelk[11]] + adds[gameLevelk[4]]
      if user_com[talk_login.dbrkey][gameLevelk[11]] < user_com[talk_login.dbrkey][gameLevelk[7]] then
        print(dump(user_com))
        return "yes",serialize( {numa = paskey,addTrea = adds[gameLevelk[4]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
      else
         --游戏结束/宝藏挖完
         print(dump(user_com))
         local passOK = ClearOk(user_com[talk_login.dbrkey],talk_login.dbrkeys)
         return "ok",serialize( {numa = 110,gameEnded=passOK} )
       end
    elseif paskey <=15 then
      print("陷阱")
      print(talk_login.trapstr )
      print(talk_login.pos)
      if talk_login.trapstr ~= talk_login.pos then
        return "yes",serialize( {numa = 30,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
      end
      --判断是否有金钟罩
      if user_com[talk_login.dbrkey][gameLevelk[17]] ~= nil then
        user_com[talk_login.dbrkey][gameLevelk[17]] = nil
        return "yes",serialize( {numa = 30,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
      end
      local adds = user_mapItems[paskey]
      --减血
      --保存上一步生命值
      state_on[gameLevelk[21]]= user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]
      user_state[talk_login.dbrkey] = clone(state_on)
      --从全局变量中取得当前宠物的血
      print(dump(user_com))
      print( dump(user_names[talk_login.dbrkey][cli_user[16]]))
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
        return "yes",serialize( {numa = paskey,addgame = {trapDamage = adds[gameLevelk[3]],warlock = adds[gameLevelk[2]],warlockTime = adds[gameLevelk[1]]},actionVals =user_com[talk_login.dbrkey][gameLevelk[15]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]} )
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
      return "yes",serialize( {numa = paskey,addgame = {trapDamage = adds[gameLevelk[3]],warlock = adds[gameLevelk[2]],warlockTime = adds[gameLevelk[1]]},actionVals =user_com[talk_login.dbrkey][gameLevelk[15]],addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]} )
    elseif paskey <=18  then
      print("加血")
      local adds = user_mapItems[paskey]
      print(dump(adds))
      --print(dump(user_names))
      --保存上一步生命值
      state_on[gameLevelk[21]]= user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]]
      user_state[talk_login.dbrkey] = clone(state_on)
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
      return "no",{id = 112}
    else
      local userCurr6 = dbr:hincrby( talk_updaterole.dbrkey, cli_user[8], -gameRebirth.diamond)
      user_names[talk_login.dbrkey][cli_user[8]] = userCurr6
      datacenter.set(talk_login.dbrkey,user_names[talk_updaterole.dbrkey])
      --2改变数据继续游戏
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = gameRebirth.life
      local life02 = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[12]],tableRoleS[7],gameRebirth.life)
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = life02
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
      return "yes",serialize({usegasValues = resd})
end

--3.7道具的使用
function CMD.itemServerMap0307(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
   --得到用户数据
   local talk_login = unserialize(talk_logins)
--  local talk_login = {
--    dbrkey = "33:12",
--    itemOn = 2,
--    pos = "3:8",
--    trapstr = "3:8",
--    state = 2,
--  }
    --得到用户的道具数量
  if user_names[talk_login.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
  --1.用户是否有该道具
  print(dump(user_item))
  if user_item[talk_login.dbrkey][talk_login.itemOn] ==0 then
    print("用户不可以使用该道具")
    return "no",{id = 108}
  else
    print("用户可以使用该道具")
  end
  local switch = {
      [1] = function (userkey01,t4,dbr) --沙漏/增加寻宝时间30秒
        --沙漏
        user_com[userkey01][gameLevelk[10]] = user_com[userkey01][gameLevelk[10]] + 30
        user_item[userkey01][t4] = user_item[userkey01][t4] - 1
        return "yes" ,serialize({numa = 1,timec = user_com[userkey01][gameLevelk[10]]})
      end,
      [2] = function (userkey01,t4,dbr) --时光机/在寻宝中使用可以返回到上一步
        --时光机
        user_item[userkey01][t4] = user_item[userkey01][t4] - 1
        --状态值判断
        if talk_login.state == 1 then
          print("行走")
        elseif talk_login.state == 2 then
          print("挖掘")
          print(dump(user_state))
          
          if talk_login.trapstr ~= user_state[talk_login.dbrkey][gameLevelk[18]] then
            print("位置不对")
            return "yes",{id =9}
          end
          local paske = user_map[userkey01][talk_login.trapstr]
            if paske == nil then
            print("值异常")
            print("空")
            return "yes",serialize( {numa = 0,actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
          elseif paske <=3 then
            print("宝藏")
            user_com[talk_login.dbrkey][gameLevelk[11]] = user_state[userkey01][gameLevelk[4]]
             return "yes",serialize( {numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
          elseif paske <=15 then 
            --回退到上一步数据
            if user_state[userkey01][gameLevelk[21]] == nil then
              print("使用金钟罩")
            else
              user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_state[userkey01][gameLevelk[21]]
            end
            
             return "yes",serialize( {numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
          elseif paske <= 18 then
            user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = user_state[userkey01][gameLevelk[21]]
            return "yes",serialize( {numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
          elseif paske<= 21 then
            user_com[talk_login.dbrkey][gameLevelk[15]] = user_state[userkey01][gameLevelk[15]]
            return "yes",serialize( {numa = paske,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]],addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
          end
        end
        return "no", { id = 8 }
      end,
      [3] = function (userkey01,t4,dbr) --金钟罩/在寻宝中使用进入到无敌状态，可以抵御一次陷阱
         user_com[userkey01][gameLevelk[17]] = 1
         print(dump({numa = 3, user_com[userkey01][gameLevelk[17]] }))
         user_item[userkey01][t4] = user_item[userkey01][t4] - 1
        return "yes",serialize( {numa = 3, [gameLevelk[17]]=user_com[userkey01][gameLevelk[17]] })
      end,
      [4] = function (userkey01,t4,dbr) --寻宝镖/在寻宝中使用可以随机标注一处宝藏
--        user_map[talk_login.dbrkey] = 1
         --print("宝藏",dump(trea_server[userkey01]))
         local posStr = table.remove(trea_server[userkey01])
         user_item[userkey01][t4] = user_item[userkey01][t4] - 1
         print("--------------------------")
         print("结束",posStr)
        --遍历地图取宝藏位置
        return "yes", serialize( {numa = 4, pos =  posStr})
      end,
      [5] = function (userkey01,t4,dbr) --飞云铲/在寻宝中使用可以挖开任何一个有效的格子
        print("使用飞云铲")
        local talk_st = serialize(talk_login)
        local posa,message = localMap033(dbm,dbr,dbrT,talk_st)
--        print(posa)
--        print(dump(message))
        print("使用飞云铲结束")
        user_item[userkey01][t4] = user_item[userkey01][t4] - 1
        return "yes", serialize(message)
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
        return st,s
      else
        print("no");
      end
   
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
  skynet.register "checkBattle"
  --dbm:disconnect()
  --skynet.exit()
  skynet.dispatch("lua", function(session, address, cmd, ...)
    local f = CMD[cmd]
    skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
  
  end)
end)



