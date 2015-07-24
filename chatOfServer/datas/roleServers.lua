local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"

--local sharedata = require "sharedata"
local datacenter = require "datacenter"
require "gameG"

local CMD = {}
local client_fds={}
--只返回价格
local roleM = {
}
--返回升级数据
local roleLevels = {
}
--角色最高等级
local levelCap = {
} 
--角色初始化数据
local roleOnS = {
}
local roleOn = {
  [1] = "gameUser",
  [2] = "level",
  [3] = "levelOn",
  [4] = "userCurr",
  [5] = "diamond",
  [6] = "gameuser",
  [7] = "levelCap",
  [8] = "stage",
}
--阶段角色最高等级
local roleLon = {
  [1] = 5,
  [2] = 10,
  [3] = 15,
  [4] = 1,
  [5] = 5,
}
--得到角色阶段
local roleL_s = {
  [1] = 5,
  [2] = 5,
  [3] = 10,
  [4] = 10,
  [5] = 15,
}
local roleLst2 = {
  [0] = 5,
  [1] = 5,
  [2] = 5,
  [3] = 5,
  [4] = 5,
  [5] = 5,
  [6] = 10,
  [7] = 10,
  [8] = 10,
  [9] = 10,
  [10] = 10,
  [11] = 15,
  [12] = 15,
  [13] = 15,
  [14] = 15,
}
local roleLst1 = {
  [0] = 1,
  [1] = 2,
  [2] = 3,
  [3] = 4,
  [4] = 5,
  [5] = 6,
  [6] = 7,
  [7] = 8,
  [8] = 9,
  [9] = 10,
  [10] = 11,
  [11] = 12,
  [12] = 13,
  [13] = 14,
  [14] = 15,
}
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
--    local luas = "call roleLeve0404("
--    luas = luas..roleLe[1]..')'
--    local res = (dbm:query(luas))[1][1]
--    
function role0004(dbm)
      local luas = "call roleLevel0004()"
      local luad = dbm:query(luas)
      local roleLevel = {}
      local roleS = {}
      for k,v in pairs(luad[1]) do
        roleLevel = {[roleOn[4]] = v.userCurr,[roleOn[5]] = v.diamond,}
        roleS = {[roleOn[4]] = v.userCurr, [roleOn[5]] = v.diamond, [roleLevel02[1]]=v[roleLevel03[1]], [roleLevel02[2]]=v[roleLevel03[2]],  [roleLevel02[3]]=v[roleLevel03[3]], [roleLevel02[4]]=v[roleLevel03[4]], [roleLevel02[5]]=v[roleLevel03[5]], [roleLevel02[6]]=v[roleLevel03[6]], [roleLevel02[7]]=v[roleLevel03[7]], [roleLevel02[8]]=v[roleLevel03[8]], [roleLevel02[9]]=v[roleLevel03[9]], [roleLevel02[10]]=v[roleLevel03[10]], [roleLevel02[11]]=v[roleLevel03[11]],}
        roleM[v[roleOn[1]]..':'..v[roleOn[2]]..':'..v[roleOn[3]] ] = roleLevel
        roleLevels[v[roleOn[1]]..':'..v[roleOn[2]]..':'..v[roleOn[3] ] ] = roleS
      end
      print(dump(roleLevels))
--      print(roleM[11 ..':'.. 9 ..':'.. 1][roleOn[4]])
--      local sk = roleL_s[1]
--      print(sk)
--      print(dump(luad[1]))
end
--得到宠物的最高等级
function role00041(dbm)
      local luas = "call roleLevel00041()"
      local luad = dbm:query(luas)
      for k,v in pairs(luad[1]) do
        levelCap[v.id] = v.levelCap
        roleOnS[v.id] = {[roleLevel02[1]] = v[roleLevel02[1]],[roleLevel02[2]] = v[roleLevel02[2]], [roleLevel02[3]] = v[roleLevel02[3]], [roleLevel02[4]] = v[roleLevel02[4]], [roleLevel02[5]] = v[roleLevel02[5]], [roleLevel02[6]] = v[roleLevel02[6]], [roleLevel02[7]] = v[roleLevel02[7]], [roleLevel02[8]] = v[roleLevel02[8]], [roleLevel02[9]] = v[roleLevel02[9]], [roleLevel02[10]] = v[roleLevel02[10]], [roleLevel02[11]] = v[roleLevel02[11]] }
      end
      print(dump(levelCap))
      print(dump(roleOnS))
--      print(roleM[11 ..':'.. 9 ..':'.. 1][roleOn[4]])
--      local sk = roleL_s[1]
--      print(sk)
--      print(dump(luad[1]))
end

------------------------------------------------------------
--4.1更换当前角色返回所有角色信息 CMD.changeRole041(dbm, dbr, dbrT,client_fd,talk_updateroles)
function CMD.changeRole041(dbm, dbr, dbrT,client_fd,talk_updateroles)
  local a = os.clock() 
  local roleU = {}
  local talk_updaterole = unserialize(talk_updateroles)
  --得到用户数据
--  local talk_updaterole = {
--      dbrkey = "33:12",
--    }
  
  print(dump(user_names[talk_updaterole.dbrkey]))
  local obj =datacenter.get(talk_updaterole.dbrkey)
  print("用户角色信息",dump(obj))
  user_names[talk_updaterole.dbrkey] =obj
  --通过用户提供的角色键名得到角色信息
  local roles = {}
  for k,v in pairs(user_names[talk_updaterole.dbrkey][cli_user[15]]) do
     if type(v) == "table" then
        print("角色",v.rolekey)
        --得到角色信息
        local rolec = dbr:hmget( v.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
        local rolecs = {}
        --组合角色信息
        for k,v in pairs(tableRoleS02) do
          rolecs[k] = rolec[v]
        end
        local sk = tonumber(rolecs[roleOn[8]])
        local s6 = tonumber(rolecs[roleOn[6]])
        local s7 = tonumber(rolecs[roleOn[7]])
        local sk2 = tonumber(rolecs[tableRoleS[9]])
        print(sk,s6,s7)
        print(roleL_s[sk],sk2)
        if sk2 < roleL_s[sk] then
          print(s6..':'..roleLst1[s7]..':'..roleLon[4] )
          rolecs[roleOn[4]] = roleM[s6..':'..roleLst1[s7]..':'..roleLon[4] ][roleOn[4]]
          
          print(s6..':'..roleLst2[s7]..':'..roleLst2[s7])
          rolecs[roleOn[5]] = roleM[s6..':'..roleLst2[s7]..':'..roleLst2[s7] ][roleOn[5]]
        else
          rolecs[roleOn[4]] = 0
          rolecs[roleOn[5]] = 0
        end

        table.insert(roles,rolecs)
      else
        print("角色不存在")
    end
  end
  roleU.roeluser = roles
  roleU[cli_user[12]] = user_names[talk_updaterole.dbrkey][cli_user[12]]
   local b = os.clock()
   print(b-a)
  print("返回的数据信息",dump(roleU))
  return "yes",serialize( roleU )
end

--4.2更换当前角色 CMD.dbrUpdateRole042(dbm, dbr, dbrT,client_fd,talk_updateroles)
function CMD.dbrUpdateRole042(dbm, dbr, dbrT,client_fd,talk_updateroles)
--local talk_updaterole = {
--    dbrkey = "33:12",
--    roleopen = "33:12:20",
--  }
  local talk_updaterole = unserialize(talk_updateroles)
  print("dd数据",dump(user_names[talk_updaterole.dbrkey]))
--  local obj =sharedata.query(talk_updaterole.dbrkey)
--  print(dump(obj))
--  user_names[talk_updaterole.dbrkey] = obj
  --判断当前角色键是否存在
  --local userIs = dbr:hexists(talk_updaterole.dbrkey,cli_user[12])
  if user_names[talk_updaterole.dbrkey][cli_user[12]] ~= nil then
    print("键存在")
    local userIs = dbr:hset(talk_updaterole.dbrkey, cli_user[12], talk_updaterole.roleopen)
         --当前宠物信息
    local opens = dbr:hmget(talk_updaterole.roleopen, tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
    user_names[talk_updaterole.dbrkey]["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
    print("ddddddddddddddd",talk_updaterole.dbrkey)
    print("dd",dump(user_names[talk_updaterole.dbrkey]))
    if userIs == 0 then
      --更新角色
      user_names[talk_updaterole.dbrkey][cli_user[12]] = talk_updaterole.roleopen
      datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
      print(dump(datacenter.get(talk_updaterole.dbrkey)))
      print("修改成功")
      
      return "yes",{id = 8}
    else
      print("修改失败")
      return "no",{id = 832}
    end
  else
    print("键不存在")
    return "no",{id = 831}
  end
end

--4.3恢复角色生命值  CMD.characterLife043(dbm, dbr, dbrT,client_fd,talk_updateroles)
function CMD.characterLife043(dbm, dbr, dbrT,client_fd,talk_updateroles)
  local talk_updaterole = unserialize(talk_updateroles)
  --用户数据
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:20",
--  }
  --得到宠物的血量
  print("判断是否存在")
--  local obj =datacenter.get(talk_updaterole.dbrkey)
--  print("用户角色信息",dump(obj))
--  user_names[talk_updaterole.dbrkey] =obj
  if user_names[talk_updaterole.dbrkey] ~= nil then
    local roleLife = {user_names[talk_updaterole.dbrkey][cli_user[16]][tableRoleS[7]] ,user_names[talk_updaterole.dbrkey][cli_user[16]][tableRoleS[8]] }
    print(dump(roleLife))
    --local roleLife = dbr:hmget(talk_updaterole.rolekey,tableRoleS[7],tableRoleS[8])
    print("当前血",roleLife[1],"--最高血量",roleLife[2])
    local lifes = tonumber(roleLife[2]) - tonumber(roleLife[1])
    if lifes < 0 then
      print("出现异常血量高于最高值")
      return "no",{id = 910}
    elseif lifes == 0 then
      print("不用加血")
      return "no",{id = 821}
    else
      print("可以加血")
      local diamu = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[8]))
      if lifes < diamu then
        print("血量可以加满")
        local life01 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[8], -lifes)
        local life02 = dbr:hincrby(talk_updaterole.rolekey,tableRoleS[7],lifes)
        user_names[talk_updaterole.dbrkey][cli_user[8]]= life01
        user_names[talk_updaterole.dbrkey][cli_user[16]][tableRoleS[7]] = life02
        datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
        return "yes",serialize ({diamond = life01,life = life02} )
      else
        print("血量不可以加满")
        local life01 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[8], -diamu)
        local life02 = dbr:hincrby(talk_updaterole.rolekey,tableRoleS[7],diamu)
        user_names[talk_updaterole.dbrkey][cli_user[8]]= life01
        user_names[talk_updaterole.dbrkey][cli_user[16]][tableRoleS[7]] = life02
        datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
         return "yes",serialize( {diamond = life01,life = life02} )
      end
    end
  else
    --宠物不存在
    return "no",{id = 903}
  end
end

--4.4角色升级
function CMD.roleLevel044(dbm, dbr, dbrT,client_fd,talk_updateroles)
  local talk_updaterole = unserialize(talk_updateroles)
  --用户数据
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:20",
--    openmoney = 2,
--  }
  --得到宠物的等级
  print("判断是否存在")
  if true == (dbr:exists(talk_updaterole.rolekey)) then
    local roleLe = dbr:hmget(talk_updaterole.rolekey,tableRoleS[2],tableRoleS[9] )
    --local roleLe = dbr:hmget(talk_updaterole.rolekey,tableRoleS[2],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
    print("宠物id",roleLe[1],"--角色等级",roleLe[2])
--    local luas = "call roleLeve0404("
--    luas = luas..roleLe[1]..')'
--    local res = (dbm:query(luas))[1][1] --levelCap
    --得到等级
    local role1 = tonumber(roleLe[1])
    local rLevelCap = levelCap[role1]
    print("----",rLevelCap)
    --
    local levels = tonumber(roleLe[2])
    if levels < 0 or levels >rLevelCap  then
      print("出现异常")
      return "no",{id = 902}
    elseif levels == rLevelCap  then
      print("最高等级")
      return "no",{id = 803}
    else
      print("可以升级")
      --得到角色的值
--      local luas = "call roleLeve04041("
--      luas = luas..roleLe[1]..dbmL.lc..roleLe[2]..')'
--      local res = (dbm:query(luas))[1][1]
      local res = roleLevels[role1..':'..(levels+1)..':'..roleLon[4]]
      print(dump(res))
      --判断支付方式
      if talk_updaterole.openmoney == 1 then
        --local userM = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[6]) )
        local userM = user_names[talk_updaterole.dbrkey][cli_user[6]]
        print("dddd",userM)
        if userM >= res.userCurr then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[6],-res.userCurr)
          user_names[talk_updaterole.dbrkey][cli_user[6]]= userM2
--          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          for k,v in pairs(roleLevel02) do
                  local user3 = dbr:hincrby(talk_updaterole.rolekey,v,res[v])
                  print(res[v])
          end
          local std = dbr:hget(talk_updaterole.rolekey,roleLevel02[1])
          local sd = dbr:hset(talk_updaterole.rolekey,tableRoleS[7],std)
          print("升级成功")
          --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
          --tableRoleS[7],rolecs[roleLevel02[1]],
          local sk = tonumber(rolecs[roleOn[8]])
          local s6 = tonumber(rolecs[roleOn[6]])
          local s7 = tonumber(rolecs[roleOn[7]])
          local sk2 = tonumber(rolecs[tableRoleS[9]])
          print(sk,s6,s7)
          print(roleL_s[sk],sk2)
          if sk2 < roleL_s[sk] then
            print(s6..':'..roleLst1[s7]..':'..roleLon[4] )
            rolecs[roleOn[4]] = roleM[s6..':'..roleLst1[s7]..':'..roleLon[4] ][roleOn[4]]
            
            print(s6..':'..roleLst2[s7]..':'..roleLst2[s7])
            rolecs[roleOn[5]] = roleM[s6..':'..roleLst2[s7]..':'..roleLst2[s7] ][roleOn[5]]
          else
            rolecs[roleOn[4]] = 0
            rolecs[roleOn[5]] = 0
          end
           --更新角色信息
          local rolest = {id =tonumber(rolecs[tableRoleS[2]]), name = tonumber(rolecs[tableRoleS[4]]), stageId = tonumber(rolecs[tableRoleS[5]]), stage = tonumber(rolecs[tableRoleS[6]]), life = tonumber(rolecs[tableRoleS[7]]),userLife = tonumber(rolecs[tableRoleS[8]]),levelCap = tonumber(rolecs[tableRoleS[9]]), restoreLife = tonumber(rolecs[tableRoleS[10]])}
          user_names[talk_updaterole.dbrkey][cli_user[16]] = rolest
          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          
          print("升级成功",dump(rolecs))
          return "yes",serialize( {userRole = rolecs, diamond = 0, userCurr = userM2} )
        else
          print("萌币不够")
          return "no",{id = 802}
        end
      else
        print("通过方式二购买")
        local userM = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[8]) )
        print("dddd",userM)
        if userM >= res.diamond then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[8],-res.diamond)
          user_names[talk_updaterole.dbrkey][cli_user[8]]= userM2
--          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          for k,v in pairs(roleLevel02) do
                  local userM2 = dbr:hincrby(talk_updaterole.rolekey,v,res[v])
          end
          local std = dbr:hget(talk_updaterole.rolekey,roleLevel02[1])
          local sd = dbr:hset(talk_updaterole.rolekey,tableRoleS[7],std)
          --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
          --
          local sk = tonumber(rolecs[roleOn[8]])
          local s6 = tonumber(rolecs[roleOn[6]])
          local s7 = tonumber(rolecs[roleOn[7]])
          local sk2 = tonumber(rolecs[tableRoleS[9]])
          print(sk,s6,s7)
          print(roleL_s[sk],sk2)
          if sk2 < roleL_s[sk] then
            print(s6..':'..roleLst1[s7]..':'..roleLon[4] )
            rolecs[roleOn[4]] = roleM[s6..':'..roleLst1[s7]..':'..roleLon[4] ][roleOn[4]]
            
            print(s6..':'..roleLst2[s7]..':'..roleLst2[s7])
            rolecs[roleOn[5]] = roleM[s6..':'..roleLst2[s7]..':'..roleLst2[s7] ][roleOn[5]]
          else
            rolecs[roleOn[4]] = 0
            rolecs[roleOn[5]] = 0
          end
          --更新角色信息
          local rolest = {id =tonumber(rolecs[tableRoleS[2]]), name = tonumber(rolecs[tableRoleS[4]]), stageId = tonumber(rolecs[tableRoleS[5]]), stage = tonumber(rolecs[tableRoleS[6]]), life = tonumber(rolecs[tableRoleS[7]]),userLife = tonumber(rolecs[tableRoleS[8]]),levelCap = tonumber(rolecs[tableRoleS[9]]), restoreLife = tonumber(rolecs[tableRoleS[10]])}
          user_names[talk_updaterole.dbrkey][cli_user[16]] = rolest
          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          print("升级成功",dump(rolecs))
          return "yes",serialize( {userRole = rolecs, diamond = userM2, userCurr = 0} )
        else
          print("钻石不够")
          return "no",{id = 801}
        end
      end
    end
  else
    --宠物不存在
    return "no",{id = 903}
  end
end

--4.5角色快速升级 5/10/15
function CMD.roleLevel045(dbm, dbr, dbrT,client_fd,talk_updateroles)
  local talk_updaterole = unserialize(talk_updateroles)
  --用户数据
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:40",
--    levelS = 10,
--    openmoney = 2,
--  }
  --得到宠物的等级
  print("判断是否存在")
  if true == (dbr:exists(talk_updaterole.rolekey)) then
    local roleLe = dbr:hmget(talk_updaterole.rolekey,tableRoleS[2],tableRoleS[9] )
    print("宠物id",roleLe[1],"--角色等级",roleLe[2])
--    local luas = "call roleLeve0404("
--    luas = luas..roleLe[1]..')'
--    local res = (dbm:query(luas))[1][1]
     --得到等级
    local role1 = tonumber(roleLe[1])
    local rLevelCap = levelCap[role1]
    local levels = tonumber(roleLe[2])
    if levels < 0 or levels >rLevelCap  then
      print("出现异常")
      return "no",{id = 902}
    elseif levels == rLevelCap  then
      print("最高等级")
      return "no",{id = 803}
    elseif levels == roleLon[talk_updaterole.levelS]  then
      print("等级相同")
      return "no",{id = 804}
    else
      print("可以升级")
      --得到角色的值
--      local luas2 = "call roleLevel04051("
--      luas2 = luas2..roleLe[1]..dbmL.lc..talk_updaterole.levelS..')'
--      local res2 = (dbm:query(luas2))[1][1]
      local res2 = roleM[role1..':'..roleLon[talk_updaterole.levelS]..':'..roleLon[talk_updaterole.levelS]]
      print(res2.userCurr,res2.diamond)
      --判断支付方式
      if talk_updaterole.openmoney == 1 then
        local userM = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[6]) )
        print("dddd",userM)
        if userM >= res2.userCurr then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[6],-res2.userCurr)
          user_names[talk_updaterole.dbrkey][cli_user[6]]= userM2
--          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          if roleLon[talk_updaterole.levelS] == nil then
            return "no",{id = 902}
          end
--          local roleleve01 =  "call roleLevel0405("
--          roleleve01 = roleleve01..roleLe[1]..dbmL.lc..roleLon[talk_updaterole.levelS]..')'
--          local v = (dbm:query(roleleve01))[1][1]
          --宠物初始数据
          --宠物升级数据
          local rolecs = {}
          local roleOnS1 = roleOnS[role1]
          local roleLevels1= roleLevels[role1..':'..roleLon[talk_updaterole.levelS]..':'..roleLon[talk_updaterole.levelS] ]
          for k,v in pairs(roleLevel02) do
--            print(roleOnS[role1][v])
--            print(roleLevels[role1..':'..roleLon[talk_updaterole.levelS]..':'..roleLon[talk_updaterole.levelS] ][v])
            rolecs[v] = roleOnS1[v] + roleLevels1[v]
          end
          rolecs[roleLevel02[2]] = roleOnS1[roleLevel02[2]]
          print(dump(rolecs))
          local rer = dbr:hmset(talk_updaterole.rolekey,tableRoleS[7],rolecs[roleLevel02[1]],roleLevel02[1],rolecs[roleLevel02[1]],roleLevel02[2],rolecs[roleLevel02[2]],roleLevel02[3],rolecs[roleLevel02[3]],roleLevel02[4],rolecs[roleLevel02[4]],roleLevel02[5],rolecs[roleLevel02[5]],roleLevel02[6],rolecs[roleLevel02[6]], roleLevel02[7],rolecs[roleLevel02[7]],roleLevel02[8],rolecs[roleLevel02[8]],roleLevel02[9],rolecs[roleLevel02[9]],roleLevel02[10],rolecs[roleLevel02[10]],roleLevel02[11],rolecs[roleLevel02[11]])
          print("ddd",dump(rer))
          --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
--          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
          print("升级成功",dump(rolecs))
          
          local sk = tonumber(rolecs[roleOn[8]])
          local s6 = tonumber(rolecs[roleOn[6]])
          local s7 = tonumber(rolecs[roleOn[7]])
          local sk2 = tonumber(rolecs[tableRoleS[9]])
          print(sk,s6,s7)
          print(roleL_s[sk],sk2)
          if sk2 < roleL_s[sk] then
            print(s6..':'..roleLst1[s7]..':'..roleLon[4] )
            rolecs[roleOn[4]] = roleM[s6..':'..roleLst1[s7]..':'..roleLon[4] ][roleOn[4]]
            
            print(s6..':'..roleLst2[s7]..':'..roleLst2[s7])
            rolecs[roleOn[5]] = roleM[s6..':'..roleLst2[s7]..':'..roleLst2[s7] ][roleOn[5]]
          else
            rolecs[roleOn[4]] = 0
            rolecs[roleOn[5]] = 0
          end
          
           --更新角色信息
          local rolest = {id =tonumber(rolecs[tableRoleS[2]]), name = tonumber(rolecs[tableRoleS[4]]), stageId = tonumber(rolecs[tableRoleS[5]]), stage = tonumber(rolecs[tableRoleS[6]]), life = tonumber(rolecs[tableRoleS[7]]),userLife = tonumber(rolecs[tableRoleS[8]]),levelCap = tonumber(rolecs[tableRoleS[9]]), restoreLife = tonumber(rolecs[tableRoleS[10]])}
          user_names[talk_updaterole.dbrkey][cli_user[16]] = rolest
          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          
          return "yes",serialize( {userRole = rolecs, diamond = 0, userCurr = userM2} )
        else
          print("萌币不够")
          return "no",{id = 802}
        end
      else
        print("通过方式二购买")
        local userM = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[8]) )
        print("dddd",userM)
        if userM >= res2.diamond then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[8],-res2.diamond)
          user_names[talk_updaterole.dbrkey][cli_user[8]]= userM2
--          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
--          local roleleve01 =  "call roleLevel0405("
--          roleleve01 = roleleve01..roleLe[1]..dbmL.lc..roleLon[talk_updaterole.levelS]..')'
--          local v = (dbm:query(roleleve01))[1][1]
           --宠物初始数据
          --宠物升级数据
          local rolecs = {}
          local roleOnS1 = roleOnS[role1]
          local roleLevels1= roleLevels[role1..':'..roleLon[talk_updaterole.levelS]..':'..roleLon[talk_updaterole.levelS] ]
          for k,v in pairs(roleLevel02) do
--            print(roleOnS[role1][v])
--            print(roleLevels[role1..':'..roleLon[talk_updaterole.levelS]..':'..roleLon[talk_updaterole.levelS] ][v])
            rolecs[v] = roleOnS1[v] + roleLevels1[v]
          end
          rolecs[roleLevel02[2]] = roleOnS1[roleLevel02[2]]
          print(dump(rolecs))
          local rer = dbr:hmset(talk_updaterole.rolekey,tableRoleS[7],rolecs[roleLevel02[1]],roleLevel02[1],rolecs[roleLevel02[1]],roleLevel02[2],rolecs[roleLevel02[2]],roleLevel02[3],rolecs[roleLevel02[3]],roleLevel02[4],rolecs[roleLevel02[4]],roleLevel02[5],rolecs[roleLevel02[5]],roleLevel02[6],rolecs[roleLevel02[6]], roleLevel02[7],rolecs[roleLevel02[7]],roleLevel02[8],rolecs[roleLevel02[8]],roleLevel02[9],rolecs[roleLevel02[9]],roleLevel02[10],rolecs[roleLevel02[10]],roleLevel02[11],rolecs[roleLevel02[11]])
          print("ddd",dump(rer))
           --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
          print("升级成功",dump(rolecs))
          
          local sk = tonumber(rolecs[roleOn[8]])
          local s6 = tonumber(rolecs[roleOn[6]])
          local s7 = tonumber(rolecs[roleOn[7]])
          local sk2 = tonumber(rolecs[tableRoleS[9]])
          print(sk,s6,s7)
          print(roleL_s[sk],sk2)
          if sk2 < roleL_s[sk] then
            print(s6..':'..roleLst1[s7]..':'..roleLon[4] )
            rolecs[roleOn[4]] = roleM[s6..':'..roleLst1[s7]..':'..roleLon[4] ][roleOn[4]]
            
            print(s6..':'..roleLst2[s7]..':'..roleLst2[s7])
            rolecs[roleOn[5]] = roleM[s6..':'..roleLst2[s7]..':'..roleLst2[s7] ][roleOn[5]]
          else
            rolecs[roleOn[4]] = 0
            rolecs[roleOn[5]] = 0
          end
          
          --更新角色信息
          local rolest = {id =tonumber(rolecs[tableRoleS[2]]), name = tonumber(rolecs[tableRoleS[4]]), stageId = tonumber(rolecs[tableRoleS[5]]), stage = tonumber(rolecs[tableRoleS[6]]), life = tonumber(rolecs[tableRoleS[7]]),userLife = tonumber(rolecs[tableRoleS[8]]),levelCap = tonumber(rolecs[tableRoleS[9]]), restoreLife = tonumber(rolecs[tableRoleS[10]])}
         user_names[talk_updaterole.dbrkey][cli_user[16]] = rolest
          datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
          
          return "yes",serialize( {userRole = rolecs, diamond = userM2, userCurr = 0} )
        else
          print("钻石不够")
          return "no",{id = 801}
        end
      end
    end
  else
    --宠物不存在
    return "no",{id = 903}
  end
end

--4.6添加用户角色槽
function CMD.roleSlot046(dbm, dbr, dbrT,client_fd,talk_updateroles)
  --提取游戏用户槽
  local talk_updaterole = unserialize(talk_updateroles)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    openmoney = 2,
--  }
  local res ={user_names[talk_updaterole.dbrkey][cli_user[10]],user_names[talk_updaterole.dbrkey][cli_user[6]],user_names[talk_updaterole.dbrkey][cli_user[8]]}
  print(dump(res))
  local userSole = res[1]
  if userSole < 1 and userSole>5 then
    print("异常")
    return "no",{id = 902}
  elseif userSole == 5 then
    print("槽位已满")
    return "no",{id = 810}
  else
    print("可以创建槽位")
    local luas = "call roleSolt0406("
    luas = luas..userSole..dbmL.lc..'9'..')'
    local res2 = (dbm:query(luas))[1][1]
    print(dump(res2))
    if talk_updaterole.openmoney == 1 then
      if tonumber(res[2]) < res2.userCurr then
        print("萌币不足") 
        return "no",{id = 802}
      else
        local userCurr6 = dbr:hincrby( talk_updaterole.dbrkey, cli_user[6], -res2.userCurr)
        local userSole6 = dbr:hincrby( talk_updaterole.dbrkey, cli_user[10],1)
        user_names[talk_updaterole.dbrkey][cli_user[6]]= userCurr6
        user_names[talk_updaterole.dbrkey][cli_user[10]]= userSole6
        datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
        print("槽位信息",dump(res2))
        print("剩余萌币",dump(userCurr6))
        print("用户槽位",dump(userSole6))
        return "yes",  serialize( {userCurr = userCurr6,userSlot = userSole6} )
      end
    elseif talk_updaterole.openmoney == 2 then
      if tonumber(res[3]) < res2.diamond then
        print("钻石不足") 
        return "no",{id = 801}
      else
        local userCurr6 = dbr:hincrby( talk_updaterole.dbrkey, cli_user[8], -res2.diamond)
        local userSole6 = dbr:hincrby( talk_updaterole.dbrkey, cli_user[10],1)
        user_names[talk_updaterole.dbrkey][cli_user[8]]= userCurr6
        user_names[talk_updaterole.dbrkey][cli_user[10]]= userSole6
        datacenter.set(talk_updaterole.dbrkey,user_names[talk_updaterole.dbrkey])
        print("槽位信息",dump(res2))
        print("剩余萌币",dump(userCurr6))
        print("用户槽位",dump(userSole6))
        return "yes", serialize( {diamond = userCurr6,userSlot = userSole6} )
      end
    else
      print("支付方式有误")
      return "no",{id =901 }
    end
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
--	ItemsMap(dbm,dbr,dbrT)
--  changeRole041(dbm, dbr, dbrT)
--  dbrUpdateRole042(dbm, dbr, dbrT)
--  characterLife043(dbm, dbr, dbrT)
  role0004(dbm)
	 role00041(dbm)
	skynet.register "roleServers"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



