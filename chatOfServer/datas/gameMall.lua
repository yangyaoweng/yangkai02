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

--5商城 CMD.openMall05(dbm, dbr, dbrT,client_fd,talk_logins)
function CMD.openMall05(dbm, dbr, dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
  --提取游戏角色相关数据/
--  local talk_login = {
--    id = 1,
--  }
  print("5商城CMD--------------------进入")
  local openM = {}
  if talk_login.id >3 or talk_login.id < 1 then
    return "no", {id = 902}
  end
  if item_open[talk_login.id] == nil then
    local luas = "call openMall06("
    luas = luas..talk_login.id..')'
    local res = dbm:query(luas)
    print(dump(res))
    if talk_login.id < 3 then
      openM = {mallrole = res[1],mallitem = res[2]}
      item_open[talk_login.id] = openM
      return "yes",serialize(openM)
    elseif talk_login.id == 3 then
      openM ={diams = res[1]}
      item_open[talk_login.id] = openM
      return "yes",serialize(openM)
    else
      return "no", {id = 902}
    end
  else
    print("dddd",dump(item_open))
    if talk_login.id < 3 then
      --商城信息
      return "yes",serialize(item_open[talk_login.id])
    elseif talk_login.id == 3 then
      --购买钻石
      return "yes",dump(item_open[talk_login.id])
    else
      return "no", {id = 902}
    end
  end
  
end


--5.1用户购买角色 CMD.openRole051(dbm, dbr, dbrT,client_fd,talk_logins)
function CMD.openRole051(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock()
  local talk_login = unserialize(talk_logins)
  print("1用户购买角色") 
  local user051 = {}
  local onkey = ""
--  local talk_login = {
--    openuser = "33:12",
--    openrole  = 7,
--    openmoney = 2,
--  }
  local obj =datacenter.get(talk_login.dbrkey)
  print("用户角色信息",dump(obj))
  user_names[talk_login.dbrkey] =obj
  if user_names[talk_login.openuser] ~= nil then
    local luas = "call openMallRole0502("
    luas = luas..talk_login.openrole..')'
    local res = dbm:query(luas)
    --得到宠物的价格信息
    --print("得到宠物信息",dump(res))
    local rolekey05 = res[1][1]
    --判断宠物是否存在
    if  rolekey05 ~= nil then
      --得到用户的信息/购买方式
      if talk_login.openmoney == 1 then
        print("通过方式一购买")
        --得到用户的萌币数
        if rolekey05.userCurr <= user_names[talk_login.openuser][cli_user[6]] then
          print("可以购买")
          --创建角色
          local luaRole = "call openMallRole0503("
          luaRole = luaRole..talk_login.openrole..dbmL.lcz..talk_login.openuser..dbmL.lz2..user_names[talk_login.openuser][cli_user[1]]..')'
          print(luaRole)
          local resRole = dbm:query(luaRole)
          if resRole[1][1].row_key == "yes" then
            --减萌币
            local userM2 = dbr:hincrby(talk_login.openuser,cli_user[6],-rolekey05.userCurr)
            user_names[talk_login.openuser][cli_user[6]] = userM2
            --加角色
            local v = resRole[2][1]
            print("创建成功")
            table.insert(user_names[talk_login.openuser][cli_user[15]] , {id =v[tableRoleS[2]], rolekey = v[tableRoleS[3]] })
            --数据改变更新
            datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
            print(dump(datacenter.get(talk_login.dbrkey)))
            --将宠物信息写入redis
            local rer = dbr:hmset(v[tableRoleS[3]],tableRoleS[1],v[tableRoleS[1]],tableRoleS[2],v[tableRoleS[2]],tableRoleS[3],v[tableRoleS[3]],tableRoleS[4],v[tableRoleS[4]],tableRoleS[5],v[tableRoleS[5]],tableRoleS[6],v[tableRoleS[6]], tableRoleS[7],v[tableRoleS[7]],tableRoleS[8],v[tableRoleS[8]],tableRoleS[9],v[tableRoleS[9]],tableRoleS[10],v[tableRoleS[10]],tableRoleS[11],v[tableRoleS[11]],tableRoleS[12],v[tableRoleS[12]], tableRoleS[13],v[tableRoleS[13]], tableRoleS[14],v[tableRoleS[14]],tableRoleS[15],v[tableRoleS[15]], tableRoleS[16],v[tableRoleS[16]], tableRoleS[17],v[tableRoleS[17]],tableRoleS[18],v[tableRoleS[18]],tableRoleS[19],v[tableRoleS[19]] )
            local b = os.clock()
            print(b-a)
            return "yes",serialize( v)
          else
            print("创建失败")
            return "no",{id = 902}
          end
        else
          local b = os.clock()
          print(b-a)
          print("不可以购买")
          return "no",{id = 802}
        end
      elseif talk_login.openmoney == 2 then
        print("通过方式二购买")
        if rolekey05.diamond <= user_names[talk_login.openuser][cli_user[8]] then
          print("可以购买")
          local luaRole = "call openMallRole0503("
          luaRole = luaRole..talk_login.openrole..dbmL.lcz..talk_login.openuser..dbmL.lz2..user_names[talk_login.openuser][cli_user[1]]..')'
          local resRole = dbm:query(luaRole)
          if resRole[1][1].row_key == "yes" then
            --减钻石
            local userM2 = dbr:hincrby(talk_login.openuser,cli_user[8],-rolekey05.diamond)
            user_names[talk_login.openuser][cli_user[8]] = userM2
             local v = resRole[2][1]
            print("创建成功")
            table.insert(user_names[talk_login.openuser][cli_user[15]] , {id =v[tableRoleS[2]], rolekey = v[tableRoleS[3]] })
            --数据改变更新
            datacenter.set(talk_login.dbrkey,user_names[talk_login.dbrkey])
            print(dump(datacenter.get(talk_login.dbrkey)))
            local rer = dbr:hmset(v[tableRoleS[3]],tableRoleS[1],v[tableRoleS[1]],tableRoleS[2],v[tableRoleS[2]],tableRoleS[3],v[tableRoleS[3]],tableRoleS[4],v[tableRoleS[4]],tableRoleS[5],v[tableRoleS[5]],tableRoleS[6],v[tableRoleS[6]], tableRoleS[7],v[tableRoleS[7]],tableRoleS[8],v[tableRoleS[8]],tableRoleS[9],v[tableRoleS[9]],tableRoleS[10],v[tableRoleS[10]],tableRoleS[11],v[tableRoleS[11]],tableRoleS[12],v[tableRoleS[12]], tableRoleS[13],v[tableRoleS[13]], tableRoleS[14],v[tableRoleS[14]],tableRoleS[15],v[tableRoleS[15]], tableRoleS[16],v[tableRoleS[16]], tableRoleS[17],v[tableRoleS[17]],tableRoleS[18],v[tableRoleS[18]],tableRoleS[19],v[tableRoleS[19]] )
            return "yes",serialize( v)
          else
            print("创建失败")
            return "no",{id = 902}
          end
        else
          print("不可以购买")
          return "no",{id = 801}
        end
      else
        print("非法操作")
        return "no",{id = 902}
      end
    else
      print("输入的宠物号有误")
      return "no",{id = 903}
    end
  else
    print("用户还未登录")
    return "no",{id = 904}
  end
end

--
--5.2购买道具 CMD.openItem052(dbm, dbr, dbrT,client_fd,talk_logins)
function CMD.openItem052(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock()
  local talk_login = unserialize(talk_logins)
  print("2用户购买道具") 
  local user051 = {}
  local onkey = ""
--  local talk_login = {
--    openuser = "33:12",
--    openitem  = 1,
--    openNo = 2,
--    openmoney = 2,
--  }
  --得到用户道具信息
  local obj =datacenter.get(talk_login.openuser..cli_user_k[1])
  print("用户道具表",dump(obj))
  user_item[talk_login.openuser] =obj
  --得到用户数据
  local obj02=datacenter.get(talk_login.openuser)
  print("用户角色信息",dump(obj02))
  user_names[talk_login.openuser] =obj02
  if  user_item[talk_login.openuser] ~= nil then
    local luas = "call openMallRole0504("
    luas = luas..talk_login.openitem..')'
    local res = dbm:query(luas)
    --得到道具的价格信息
    print("得到道具信息",dump(res))
    local rolekey052 = res[1][1]
    --判断道具是否
    if  rolekey052 ~= nil then
      --得到用户的信息/购买方式
      if talk_login.openmoney == 1 then
        print("通过方式一购买")
        --得到用户的萌币数
        local item05021 = rolekey052.userCurr*talk_login.openNo
        if item05021 <= user_names[talk_login.openuser][cli_user[6]] then
          print("可以购买")
          --增加道具
          local item0522 = dbr:hincrby(talk_login.openuser,talk_login.openitem,talk_login.openNo)
          local itme0523 = dbr:hincrby(talk_login.openuser,cli_user[6],-item05021)
          user_item[talk_login.openuser][talk_login.openitem] = item0522
          user_names[talk_login.openuser][cli_user[6]] = itme0523
          --更新数据
          datacenter.set(talk_login.openuser..cli_user_k[1],user_item[talk_login.openuser])
          datacenter.set(talk_login.openuser,user_names[talk_login.openuser])
          print(dump(datacenter.get(talk_login.openuser)))
          local b = os.clock()
          print(b-a)
          return "yes",serialize( )
        else
          local b = os.clock()
          print(b-a)
         print("不可以购买")
          return "no",{id = 802}
        end
      elseif talk_login.openmoney == 2 then
        print("通过方式二购买")
        print(rolekey052.userCurr)
        local item05021 = rolekey052.diamond*talk_login.openNo
        if item05021 <= user_names[talk_login.openuser][cli_user[8]] then
          print("可以购买")
          --增加道具
          local item0522 = dbr:hincrby(talk_login.openuser,talk_login.openitem,talk_login.openNo)
          local itme0523 = dbr:hincrby(talk_login.openuser,cli_user[8],-item05021)
          user_item[talk_login.openuser][talk_login.openitem] = item0522
          user_names[talk_login.openuser][cli_user[8]] = itme0523
          --更新数据
          datacenter.set(talk_login.openuser..cli_user_k[1],user_item[talk_login.openuser])
          datacenter.set(talk_login.openuser,user_names[talk_login.openuser])
          print(dump(datacenter.get(talk_login.openuser)))
          local b = os.clock()
          print(b-a)
          return "yes",serialize( {[talk_login.openitem]=item0522,diamond = itme0523 } )
        else
          local b = os.clock()
          print(b-a)
         print("不可以购买")
          return "no",{id = 801}
        end
      else
        print("非法操作")
        return "no",{id = 902}
      end
    else
      print("输入的道具号有误")
      return "no",{id = 903}
    end
  else
    print("用户还未登录")
    return "no",{id = 904}
  end
end

--5.3购买萌币和星星 CMD.openStart053(dbm, dbr, dbrT,client_fd,talk_logins)
function CMD.openStart053(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock()
--  local talk_login = unserialize(talk_logins)
  print("2用户购买萌币和星星") 
  local user051 = {}
  local onkey = ""
  local talk_login = {
    openuser = "33:12",
    openitem  = 10,     --物品编号  
    openNo = 2,           --数量
  }
    --得到用户数据
  local obj02=datacenter.get(talk_login.openuser)
  print("用户角色信息",dump(obj02))
  user_names[talk_login.openuser] =obj02
  if  user_names[talk_login.openuser] ~= nil then
    local luas = "call openMallRole0505("
    luas = luas..talk_login.openitem..')'
    print(luas)
    local res = dbm:query(luas)
    --得到道具的价格信息open_buy
    print("得到萌币和星星信息",dump(res))
    local rolekey053 = res[1][1]
    --判断道具是否
    if  rolekey053 ~= nil then
      --得到用户的信息/购买方式
        print("通过钻石购买")
        --得到用户的萌币数
        print(user_names[talk_login.openuser][cli_user[1]])
        print(user_names[talk_login.openuser][cli_user[8]])
        print(rolekey053.userCurr)
        print(rolekey053.itemOn)
        local item05031 = rolekey053.diamond*talk_login.openNo
        if item05031 <= user_names[talk_login.openuser][cli_user[8]] then
          print("可以购买")
          print(open_buy[rolekey053.itemOn])
          --增加物品
          local item0532 = dbr:hincrby(talk_login.openuser,open_buy[rolekey053.itemOn],(talk_login.openNo* rolekey053.itemOpen) )
          --减少钻石
          local itme0533 = dbr:hincrby(talk_login.openuser,cli_user[8],-item05031)
          print(item0532)
          print(itme0533)
          --更新数据
          user_names[talk_login.openuser][open_buy[rolekey053.itemOn]] = item0532
          user_names[talk_login.openuser][cli_user[8]] = itme0533
          datacenter.set(talk_login.openuser,user_names[talk_login.openuser])
          print(dump(datacenter.get(talk_login.openuser)))
          local b = os.clock()
          print(b-a)
          return "yes",serialize( {[open_buy[rolekey053.itemOn]]= item0532,diamond =itme0533 })
        else
          local b = os.clock()
          print(b-a)
         print("不可以购买")
          return "no",{id = 802}
        end
    else
      print("输入的萌币和星星号有误")
      return "no",{id = 903}
    end
  else
    print("用户还未登录")
    return "no",{id = 904}
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
--  openStart053(dbm, dbr, dbrT)

--  onCard0901(dbm,dbr,dbrT)

	
	skynet.register "gameMall"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



