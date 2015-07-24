local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local mysql = require "mysql"
local redis = require "redis"

--local sharedata = require "sharedata"
local datacenter = require "datacenter"
require "gameG"

local CMD = {}
--保存临时数据
local diams = {}

--
local loadSerG = {}
local loadSerT = {
  [0] = 1,
  [1] = 2,
  [2] = 3,
  [3] = 4,
  [4] = 5,
  [5] = 6,
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
-----------------------------------------
--1查询排名前20名和本人排名 CMD.rankingList01(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.rankingList01(dbm,dbr,dbrT,client_fd,talk_logins)
   local talk_login = unserialize(talk_logins)
      --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
  print("排行榜")
  local read = dbr:zrevrank(ranking_List[1],talk_login.dbrkey)
  print(dump(read))
  local read2 = dbr:zrevrange(ranking_List[1],0,20,"withscores")
  print(dump(read2))
  return "yes",serialize({list =read,lists =read2 })
end
--2关卡排行榜     CMD.rankingList02(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.rankingList02(dbm,dbr,dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
      --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
  print("排行榜")
  local read = dbr:zrevrank(ranking_List[2],talk_login.dbrkey)
  print(dump(read))
  local read2 = dbr:zrevrange(ranking_List[2],0,20,"withscores")
  print(dump(read2))
  return "yes",serialize({list =read,lists =read2 })
end

--10.3钻石界面 CMD.diamonUId(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.diamonUId(dbm,dbr,dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
      --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
    --用户钻石数据
    local diaA = dbr:hmget(talk_login.dbrkey,cli_user[7],cli_user[8],cli_user[17] )
    local diaB = {[cli_user[7]] = tonumber(diaA[1]),[cli_user[8]] = tonumber(diaA[2]),[cli_user[17]] = tonumber(diaA[3]),}
    --返回钻石表信息/和用户钻石信息
    diaB.next = gameVip[diaB[cli_user[7]]+1][cli_user[8]]
    local vip = gameVip[diaB[cli_user[7]]]
    print(dump({dia = diaB,vip = vip}))
    return "yes", serialize({dia = diaB,vip = vip})
end

--10.4萌币界面 CMD.diamonUIc(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.diamonUIc(dbm,dbr,dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
      --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
    --用户萌币数据
    local diaA = tonumber(dbr:hget(talk_login.dbrkey,cli_user[6] ) )
    --返回户萌币信息
    print(dump({userCurr = diaA}))
    return "yes", serialize({userCurr = diaA})
end

--10.5星星界面 CMD.diamonUIs(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.diamonUIs(dbm,dbr,dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
      --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
    --用户星星数据
    print("10.4----1")
    local starsA = dbr:hmget(talk_login.dbrkey,cli_user[11], cli_user_t[11])
    print("10.4----2")
    local starsB = {[cli_user[11]] =starsA[1],spass = starsA[2]+1}
    print("10.4----3")
    starsB["upS"] = tonumber(dbrT:hget(mapG[1]..starsB.spass,mapServer[5]))
    print("10.4----4")
    --返回户萌币信息
    print(dump(starsB))
    return "yes", serialize(starsB)
end

--10.6宝气界面 CMD.diamonUIg(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.diamonUIg(dbm,dbr,dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
      --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--    }
    --1得到用户的数据//宝气值
  local obj =datacenter.get(talk_login.dbrkey)
--  print("用户角色信息",dump(obj))
  user_names[talk_login.dbrkey] = obj
  if user_names[talk_login.dbrkey] == nil then
    print("2999")
    return "no",{id = 902}
  end
  --得到当前宝气值
  local ps1 = user_names[talk_login.dbrkey][cli_user[3]]
--  local ps2 = user_names[talk_login.dbrkey][cli_user[5]]
  print(ps1)
  print(dump(loadSerG[loadSerT[ps1]]))
  --得到的数据//
--  print(loadSerG[ps1].treaName) --成就
--  print(loadSerG[loadSerT[ps1]].treaNum)  --宝气值
  print(dump({[cli_user[5]] = user_names[talk_login.dbrkey][cli_user[5]], [cli_user[3]] = ps1, treaName = loadSerG[ps1].treaName, treaNum = loadSerG[loadSerT[ps1]].treaNum, load =loadSerG ,}))
  return "yes",serialize({[cli_user[5]] = user_names[talk_login.dbrkey][cli_user[5]], [cli_user[3]] = ps1, treaName = loadSerG[ps1].treaName, treaNum = loadSerG[loadSerT[ps1]].treaNum, load =loadSerG ,})
    
end
--成就数据
function loadServG(dbm)
  --得到系统宝气数据
  if loadSerG[1] == nil then
    print("没有缓存数据")
    local luas = "call tardServer0102("
    luas = luas ..')'
    --print(luas)
    local res = dbm:query(luas)
    --print("my001----",dump(res))
--    loadSerG = res[1]
    for k,v in pairs(res[1]) do
      print("---",k,v)
      loadSerG[v.treaId] =v
    end
  else
    print("有缓存数据")
  end
  print(dump(loadSerG))

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
--  rankingList01(dbm,dbr,dbrT)
--	rankingList02(dbm,dbr,dbrT)
--	diamonUId(dbm,dbr,dbrT)
--	diamonUIc(dbm,dbr,dbrT)
--	diamonUIs(dbm,dbr,dbrT)
  loadServG(dbm)
--  diamonUIg(dbm,dbr,dbrT)
	
	skynet.register "rankingList"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



