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

--3将物品写入redis
function RedisSelectMap(dbm,dbr,dbrT)
    print("将物品写入redis")
    local luas = "call mapTableProps04("
    luas = luas..')'
    local res = dbm:query(luas)
    print("----",dump(res))
    --判断写入
    for k,v in pairs(res[1]) do
      if v.trapId <=3 then
        print("宝藏")
        local mapdd = dbr:hmset(gameMaxk[v.trapId],gameLevelk[4],v[gameLevelk[4]])
      elseif v.trapId <=15 then
        print("陷阱")
        local mapdd = dbr:hmset(gameMaxk[v.trapId],gameLevelk[3],v[gameLevelk[3]],gameLevelk[2],v[gameLevelk[2]],gameLevelk[1],v[gameLevelk[1]])
      elseif v.trapId <=18  then
        print("加血")
        local mapdd = dbr:hmset(gameMaxk[v.trapId],gameLevelk[5],v[gameLevelk[5]])
      elseif v.trapId <=21  then
        print("魔法剂")
        local mapdd = dbr:hmset(gameMaxk[v.trapId],gameLevelk[6],v[gameLevelk[6]])
      else
        print("其他")
      end
    end
end

--3将物品写入lua
function ItemsMap(dbm,dbr,dbrT)
    print("将物品写入redis")
    local luas = "call mapTableProps04("
    luas = luas..')'
    local res = dbm:query(luas)
    --print("----",dump(res))
    --判断写入user_mapItems
    for k,v in pairs(res[1]) do
      if v.trapId <=3 then
        print("宝藏")
        user_mapItems[v.trapId] = { [ gameLevelk[4] ]  = v[gameLevelk[4]] }
      elseif v.trapId <=15 then
        print("陷阱")
        user_mapItems[v.trapId] ={ [ gameLevelk[3] ]=v[gameLevelk[3]],[ gameLevelk[2] ] = v[gameLevelk[2]],[ gameLevelk[1] ]=v[gameLevelk[1]]}
      elseif v.trapId <=18  then
        print("加血")
        user_mapItems[v.trapId] = { [ gameLevelk[5] ]  = v[gameLevelk[5]] }
      elseif v.trapId <=21  then
        print("魔法剂")
        user_mapItems[v.trapId] = { [ gameLevelk[6] ]  = v[gameLevelk[6]] }
      else
        print("其他")
      end
    end
    datacenter.set("user_item_s",user_mapItems)
    --local obj =datacenter.get("user_item_s")
    --print(dump(obj))
end
--4创建地图信息键
function mysqlMapKey04(dbm, dbr, dbrT)
--查询mysql数据库
      local luas = "call mapTableS04("
      luas = luas ..')'
      print(luas)
      local res = dbm:query(luas)
      print("my001----",dump(res))
      for k,v in pairs(res[1]) do
          if type(v) == "table"  then
            print(mapG[1]..v[mapServer[1]], mapServer[1] ,v[mapServer[1]])
            local mapT01 = dbrT:hmset(mapG[1]..':'..v[mapServer[1]], mapServer[1] ,v[mapServer[1]], mapServer[2] ,v[mapServer[2]], mapServer[3] ,v[mapServer[3]], mapServer[4] ,v[mapServer[4]], mapServer[5] ,v[mapServer[5]], mapServer[6] ,v[mapServer[6]], mapServer[7] ,v[mapServer[7]],  mapServer[8] ,v[mapServer[8]], mapServer[9] ,v[mapServer[9]], mapServer[10] ,v[mapServer[10]], mapServer[11] ,v[mapServer[11]],mapServer[12] ,v[mapServer[12]], mapServer[13] ,v[mapServer[13]],mapServer[14] ,v[mapServer[14]], mapServer[15], v[mapServer[15]],mapServer[16], v[mapServer[16]])
          else
            print("结束了.......")
          end
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
  ItemsMap(dbm,dbr,dbrT)
--  mysqlMapKey04(dbm,dbr,dbrT)

	
	skynet.register "globalData"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)



