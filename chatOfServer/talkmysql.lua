local skynet = require "skynet"

local netpack = require "netpack"
local socket = require "socket"
local Levels = require "Levels"
local mysql = require "mysql"
local redis = require "redis"

local sharedata = require "sharedata"

require "gameG"

local CMD = {}
local client_fds={}
--缓存数据
local user_passk = {}   --关卡信息
local user_passG = {}  --进入游戏的关卡信息
local user_mapItems ={}  --地图物品信息
local user_map = {}     --用于动态地图信息
local user_com = {}     --用户战斗中的数据
local user_names = {} --用户基本信息
local user_item = {}      --用户道具表
local item_open = {}    --用户查询过得商品信息
local user_card = {}      --用户月卡数据
local user_state = {}     --用户上一步操作保存
local card_Item = {[1]={},[2]={},[3]={},}    --月卡信息
local trac_server = {}    --宝气值的等级数据
local trea_server = {}  --保存宝藏位置
--提交给客户端的数据-登录后提交
local crate_dbrkey = {
  [1] = "id",
  [2] = "rolekey",
}
local cli_user = {
  [1] = "userId",                   --用户Id
  [2] = "dbrkey",                  --建id
  [3] = "gasNo",                   --宝气等级
  [4] = "gasValues",            --最高宝气值
  [5] = "usegasValues",     --当前宝气值
  [6] = "userCurr",              --萌币
  [7] = "diamondVip",       --钻石等级
  [8] = "diamond",              --钻石
  [9] = "pass",                       --最高关卡
  [10] = "userSlot",             --角色槽
  [11] = "stars",                    --星星
  [12] = "roleopen",            --当前角色键值
  [13] = "userState",           --当前状态
  [14] = "userGame",          --游戏中的战斗
  [15] = "rolekey",               --角色列表keys
  [16] = "currRole",             --当前角色信息
  [17] = "diamondAdd",    --累计充值钻石数量
}


--每日任务
local cli_user_t ={
  [1] = "taskOn",            --当日完成关卡数
  [2] = "taskSc",              --当日完成对战数
  [3] = "taskTrea",          --当日完成宝藏份数
  [4] = "taskReward",    --当前领取奖品键
  [5] = "taskOld",            --当前天数
  [6] = "timeOld",           --每日签到
  [7] = "timeLogin",       --连续登录
  [8] = "mail",                   --邮件键
  [9] = "onCard",             --月卡
  [10] = "treaNum",       --等级宝气值
}
local cli_card = {
  [1] = "opentimeC",      --月卡开始时间
  [2] = "overtimeC",        --月卡结束时间
  [3] = "cardKey",            --月卡键名
  [4] = "cardVip",              --月卡等级
  [5] = "cardId"                 --领取编号
}

local cli_user_t2 ={
  taskOn = 1,            --当日完成关卡数
  taskSc = 2,              --当日完成对战数
  taskTrea = 3,          --当日完成宝藏份数
  taskReward = 4,   --当前领取奖品键
  
}

--月卡的道具信息
local cardItemTable = {
  item001 =1,    --沙漏
  item002 = 2,    --时光机
  item003 = 3,    --金钟罩
  item004 = 4,    --寻宝镖
  item005 = 5,    --飞云铲
  item006 = 6,    --疾风术
  item007 = 7,    --禁锢术
  item008 = 8,    --抢夺术
}
--
local cli_user02 = {
  userId = 1,
  dbrkey = 2,
  gasNo = 3,
  gasValues = 4,
  usegasValues = 5,
  userCurr = 6,
  diamondVip = 7,
  diamond = 8,
  pass = 9,
  userSlot = 10,
  stars = 11,
  roleopen = 12,
  userState = 13,       --当前状态
  userGame = 14,      --游戏中的战斗
  rolekey =15,             --角色列表keys
  currRole =16,           --当前角色信息
  diamondAdd= 17,    --累计充值钻石数量
}
--用户道具信息
tableItemTable = {
  [1] = "uerId",
  [2] = "item001",    --沙漏
  [3] = "item002",    --时光机
  [4] = "item003",    --金钟罩
  [5] = "item004",    --寻宝镖
  [6] = "item005",    --飞云铲
  [7] = "item006",    --疾风术
  [8] = "item007",    --禁锢术
  [9] = "item008",    --抢夺术
}

--用户宠物属性表
local tableRoleS = {
  [1] = "id",        --用户的角色id
  [2] = "gameuser",    --角色Id
  [3] = "rolekey", --角色键值
  [4] = "name",      --角色名称
  [5] = "stageId",   --角色阶段id
  [6] = "stage",   --角色阶段
  [7] = "life",         --当前生命值
  [8] = "userLife",    --角色生命值
  [9] = "levelCap",    --角色等级
  [10] = "restoreLife",   --每小时恢复生命值
  [11] = "objTres",     --物抗
  [12] = "objPati",     --物耐
  [13] = "iceTres",     --冰抗
  [14] = "icePati",     --冰耐
  [15] = "fireTres",    --火抗
  [16] = "firePati",    --火耐
  [17] = "electTres",   --电抗
  [18] = "electPati",   --电耐
  [19] = "actionVal",  --角色行动值
}

tableRoleS02 = {
  id = 1,        --用户的角色id
  gameuser = 2,    --角色Id
  rolekey = 3, --角色键值
  name = 4,      --角色名称
  stageId = 5,
  stage = 6,    --角色阶段
  life = 7,    --当前生命值
  userLife = 8,    --角色生命值
  level = 9,    --角色等级
  restoreLife =10,   --每小时恢复生命值
  objTres = 11,     --物抗
  objPati = 12,     --物耐
  iceTres = 13,     --冰抗
  icePati = 14,     --冰耐
  fireTres = 15,    --火抗
  firePati = 16,    --火耐
  electTres = 17,   --电抗
  electPati = 18,   --电耐
  actionVal = 19,  --角色行动值
}
--用户升级表
roleLevel = {
  userLife = 1,    --角色生命值
  levelCap = 2,    --角色等级
  objTres = 3,     --物抗
  objPati = 4,     --物耐
  iceTres = 5,     --冰抗
  icePati = 6,     --冰耐
  fireTres = 7,    --火抗
  firePati = 8,    --火耐
  electTres = 9,   --电抗
  electPati = 10,   --电耐
  actionVal = 11,  --角色行动值
}
roleLevel02 = {
  [1] = "userLife",    --角色生命值
  [2] = "levelCap",    --角色等级
  [3] = "objTres",     --物抗
  [4] = "objPati",     --物耐
  [5] = "iceTres",     --冰抗
  [6] = "icePati",     --冰耐
  [7] = "fireTres",    --火抗
  [8] = "firePati",    --火耐
  [9] = "electTres",   --电抗
  [10] = "electPati",   --电耐
  [11] = "actionVal",  --角色行动值
}

roleLevel03 = {
  [1] = "userLife",    --角色生命值
  [2] = "levelOn",    --角色等级
  [3] = "objTres",     --物抗
  [4] = "objPati",     --物耐
  [5] = "iceTres",     --冰抗
  [6] = "icePati",     --冰耐
  [7] = "fireTres",    --火抗
  [8] = "firePati",    --火耐
  [9] = "electTres",   --电抗
  [10] = "electPati",   --电耐
  [11] = "actionVal",  --角色行动值
}
--全局键自动生成变量
local mapG={
[1] = "mmxb",
}
--地图信息键
local mapServer={
   [1] = "mapId",                   --地图编号
   [2] = "gateNum",             --地图编号
   [3] = "boxSize",               --地图大小
   [4] = "mapNumber",      --地图编号
   [5] = "openStars",         --开启星星数
   [6] = "timeS",                 --时间（秒）
   [7] = "effeGrid",            --有效格子
   [8] = "porTal",              --传送门
   [9] = "treaNum",       --宝藏份数
   [10] = "treaSpikes",   --尖刺
   [11] = "treaFrozen",   --冰冻
   [12] = "treaFlame",    --火
   [13] = "treaGrid",       --电网
   [14] = "numTrap",    --陷阱总数
   [15] = "treaProps",    --生命道具
}
local mapServer02={
   mapId = 1,
   gateNum = 2,
   boxSize = 3,
   mapNumber = 4,
   openStars = 5,
   timeS = 6,
   effeGrid = 7,
   porTal = 8,
   treaNum = 9,
   treaSpikes = 10,
   treaFrozen = 11,
   treaFlame = 12,
   treaGrid = 13,
   numTrap = 14,
   treaProps = 15,
}

local mapNum = {
  [1] = "treaNum",    --宝藏份数
  [2] = "numTrap",    --陷阱总数
  [3] = "Traps",            --宝藏总数
}

local mapApp = {
  [1]= "smallTrea",   --小宝藏
  [2] = "inTrea",         --中宝藏
  [3] = "bigTrea",        --大宝藏
  [4]= "smallSpikes",   --尖刺
  [5] = "theSpikes",      --
  [6] = "bigSpikes",      --
  [7] = "smallFrozen",   --冰冻
  [8] = "theFrozen",       --
  [9] = "bigFrozen",       --
  [10] = "semallFlame",   --火
  [11] = "theFlame",      --
  [12] = "bigFlame",      --
  [13] = "semallGrid",    --电网
  [14] = "theGrid",         --
  [15] = "bigGrid",         --
  [16] = "semallProps",   --命道具
  [17] = "theProps",    --
  [18] = "bigProps",    --
  [19] = "semallMagic",   --魔法剂
  [20] = "theMagic",    --
  [21] = "bigMagic",    --
}
 --未用
local mapNumC = {  
  treaNum = 1,    --宝藏份数
  numTrap = 2,    --陷阱总数
  Traps = 3,            --宝藏总数
}

local mapAppC = {
  smallTrea = 1,   --小宝藏
  inTrea = 2,         --中宝藏
  bigTrea = 3,        --大宝藏
  smallSpikes = 4,   --尖刺
  theSpikes = 5,      --
  bigSpikes = 6,      --
  smallFrozen = 7,   --冰冻
  theFrozen = 8,       --
  bigFrozen = 9,       --
  semallFlame = 10,   --火
  theFlame = 11,      --
  bigFlame = 12,      --
  semallGrid = 13,    --电网
  theGrid =14,         --
  bigGrid = 15,         --
  semallProps = 16,   --命道具
  theProps = 17,    --
  bigProps = 18,    --
  semallMagic = 19,   --魔法剂
  theMagic = 20,
  bigMagic = 21,
}

local gameMaxk = {
  [1] = "game9map001",
  [2] = "game9map002",
  [3] = "game9map003",
  [4] = "game9map004",
  [5] = "game9map005",
  [6] = "game9map006",
  [7] = "game9map007",
  [8] = "game9map008",
  [9] = "game9map009",
  [10] = "game9map010",
  [11] = "game9map011",
  [12] = "game9map012",
  [13] = "game9map013",
  [14] = "game9map014",
  [15] = "game9map015",
  [16] = "game9map016",
  [17] = "game9map017",
  [18] = "game9map018",
  [19] = "game9map019",
  [20] = "game9map020",
  [21] = "game9map021",
}

local gameMaxv = {
  game9map001 = 1,
  game9map002 = 2,
  game9map003 = 3,
  game9map004 = 4,
  game9map005 = 5,
  game9map006 = 6,
  game9map007 = 7,
  game9map008 = 8,
  game9map009 = 9,
  game9map010 = 10,
  game9map011 = 11,
  game9map012 = 12,
  game9map013 = 13,
  game9map014 = 14,
  game9map015 = 15,
  game9map016 = 16,
  game9map017 = 17,
  game9map018 = 18,
  game9map019 = 19,
  game9map020 = 20,
  game9map021 = 21,
}
--每日签到
local mailMaxk={
  [1] = "game:time:01",
  [2] = "game:time:02",
  [3] = "game:time:03",
  [4] = "game:time:04",
  [5] = "game:time:05",
  [6] = "game:time:06",
  [7] = "game:time:07",
  [8] = "game:time:08",
  [9] = "game:time:09",
  [10] = "game:time:10",
  [11] = "game:time:11",
  [12] = "game:time:12",
  [13] = "game:time:13",
  [14] = "game:time:14",
}
--邮件字段
local mailType ={
  [1] = "沙漏",
  [2] = "时光机",
  [3] = "金钟罩",
  [4] = "寻宝镖",
  [5] = "飞云铲",
  [6] = "飞云铲",
  [7] = "禁锢术",
  [8] = "抢夺术",
  [9] = "每日签到奖励",
  [10] = "成就奖励",
  [11] = "萌币",
  [12] = "钻石",
  [13] = ":|",
}
local mailTable ={
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = "userCurr",
  [12] = "diamond",
  [13] = ":|",
}
--游戏中的陷阱触发
local gameLevelk = {
  [1] = "warlockTime",      --持续时间
  [2] = "warlock",                --伤害点
  [3] = "trapDamage",       --固定伤害
  [4] = "addTrea",                --宝藏
  [5] = "addProps",             --加血
  [6] = "addMagic",             --加行动值
  [7] = "treaNum",              --宝藏份数
  [8] = "numTrap",              --陷阱总数
  [9] = "actionVal",              --角色行动值
  [10] = "timec",                   --游戏时间
  [11] = "addTreaNum",    --得到宝藏数
  [12] = "addNumTrap",    --触发的陷阱数 
  [13] = "timego",                --游戏开始时间
  [14] = "trapgo",                --陷阱触发时间
  [15] = "actionVals",         --当前角色行动值
  [16] = "timetrap",            --陷阱的持续伤害时间保存
  [17] = "item003",             --道具金钟罩
  [18] = "state",                   --上一步触发位置
  [19] = 0,
  [20] = "pasOn",               --上一步的键值
  [21] = "life",                      --上一步生命值
}
--购买星星和萌币
local open_buy = {
  [1] = "time",     --道具
  [2] = "stars",    --星星
  [3] = "userCurr",   --萌币
}

--游戏中的奖励
local gameTime = {

}
--vip数据whFor
local gameVip = {
  [0] ={userCurr = 0,whFor = 0, addBy = 0.0},
  [1] ={userCurr = 100,whFor = 2, addBy = 0.2},
  [2] ={userCurr = 1000,whFor = 4, addBy = 0.4,userSole = 2},
  [3] ={userCurr = 2500,whFor = 6, addBy = 0.6,userSole = 3 },
  [4] ={userCurr = 10000,whFor = 10, addBy = 0.8,userSole = 4 },
  [5] ={userCurr = 50000,whFor = 15, addBy = 1.0, userSole =5 },
}


--用于连接字符串的逗号和单引号使用
local dbmL = {
  lr = "'",     --头部结尾1个单引号
  lz = "','",   --中间2个单引号加1个逗号
  lz2 = "',", --左1个单引号加1个逗号
  lc = ",",     --中间0个单引号加1个逗号
  lcz = ",'",     --右1个单引号加1个逗号
}

--深拷贝,完全的拷贝,
function clone(object)--clone函数
    local lookup_table = {}--新建table用于记录
    local function _copy(object)--_copy(object)函数用于实现复制
        if type(object) ~= "table" then 
            return object   --如果内容不是table 直接返回object(例如如果是数字\字符串直接返回该数字\该字符串)
        elseif lookup_table[object] then
            return lookup_table[object]--这里是用于递归滴时候的,如果这个table已经复制过了,就直接返回
        end
        local new_table = {}
        lookup_table[object] = new_table--新建new_table记录需要复制的二级子表,并放到lookup_table[object]中.
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)--遍历object和递归_copy(value)把每一个表中的数据都复制出来
        end
        return setmetatable(new_table, getmetatable(object))--每一次完成遍历后,就对指定table设置metatable键值
    end
    return _copy(object)--返回clone出来的object表指针/地址
end

--table转字符串(只取标准写法，以防止因系统的遍历次序导致ID乱序)  
function serialize(obj)  
    local lua = ""  
    local t = type(obj)  
    if t == "number" then  
        lua = lua .. obj  
    elseif t == "boolean" then  
        lua = lua .. tostring(obj)  
    elseif t == "string" then  
        lua = lua .. string.format("%q", obj)  
    elseif t == "table" then  
        lua = lua .. "{"  
    for k, v in pairs(obj) do  
        lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ","  
    end  
    local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
        for k, v in pairs(metatable.__index) do  
            lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ","  
        end  
    end  
        lua = lua .. "}"  
    elseif t == "nil" then  
        return nil  
    else  
        error("can not serialize a " .. t .. " type.")  
    end  
    return lua  
end

--反序列化一个Table
function unserialize(str)
    if str == nil or str == "nil" then
        return nil
    elseif type(str) ~= "string" then
        EMPTY_TABLE = {}
        return EMPTY_TABLE
    elseif #str == 0 then
        EMPTY_TABLE = {}
        return EMPTY_TABLE
    end

    local code, ret = pcall(loadstring(string.format("do local _=%s return _ end", str)))

    if code then
        return ret
    else
        EMPTY_TABLE = {}
        return EMPTY_TABLE
    end
end

--分割字符串
function Split(szFullString, szSeparator)  
  local nFindStartIndex = 1  
  local nSplitIndex = 1  
  local nSplitArray = {}  
  while true do  
     local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
     if not nFindLastIndex then  
      nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
      break  
     end  
     nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
     nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
     nSplitIndex = nSplitIndex + 1  
  end  
  return nSplitArray  
end
--利用下面代码可以定义一个集合S，对该集合所有的操作，比如插入、删除元素和查找元素都是O(1)
function newset()
    local reverse = {} --以数据为key，数据在set中的位置为value
    local set = {} --一个数组，其中的value就是要管理的数据
    return setmetatable(set,{__index = {
          insert = function(set,value)
              if not reverse[value] then
                    table.insert(set,value)
                    reverse[value] = #(set)
              end
          end,

          remove = function(set,value)
              local index = reverse[value]
              if index then
                    reverse[value] = nil
                    local top = table.remove(set) --删除数组中最后一个元素
                    if top ~= value then
                        --若不是要删除的值，则替换它
                        reverse[top] = index
                        set[index] = top
                    end
              end
          end,

          find = function(set,value)
              local index = reverse[value]
              return (index and true or false)
          end,
    }})
end

local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    
    getIndent = function(level)
        --print("level",level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        --print("quoteStr--函数执行")
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        --print("wrapKey--函数取出键名")
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        --print("wrapVal--函数执行")
        if type(val) == "table" then
            --print("当数据类型不为table时跳出")
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        --print("dumpObj--函数执行")
        --print("在这里对level进行处理")
        if type(obj) ~= "table" then
            --print("判断obj类型",type(obj))
            return wrapVal(obj)
        end
        --print("对level加一")
        level = level + 1
        local tokens = {}
        --每条记录的id号
        tokens[#tokens + 1] = "{"
        --取出对象的键和值
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

local function test2( dbm)
    	local i=1
        --排序
        local    res = dbm:query("select * from userData order by id asc")
        print ( "test2 loop times=" ,i,"\n","query result=",dump( res ) )
        i=i+1
end
--创建用户
local function suerverUserCreate01(dbm)
	local res = dbm:query("call serverUserCreate('yangkai','yangpassowrd',111111111,'yangkkkd','qq','qs')");
	print("yangkai----",dump(res))
	
end

--用户正常登录
local function serverUserLogs02a(dbm)
	local res = dbm:query("call serverUserLongs02a('yangkai','yangpassowrd',2)");
	print("serverUserLogs02a----",dump(res))
	print(res[3][1]["name"])
	
end
--多行數具測試
local function skynet003(dbm)
	local res = dbm:query("call skynet003()");
	print("yangkai----",dump(res))
	return res;
end
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

--1使用进行注册 CMD.mysqlServer01(dbm,dbr,dbrT,client_fd,talk_login)
function CMD.mysqlServer01(dbm,dbr,dbrT,client_fd,talk_login)
  local a = os.clock() 
    print("用户正常注册")
     local talk_login = {
      name = "12",
      passwords = "12",
    }
--    local client_fd = 0
--    client_fd=client_fd+1
    local user03 = {}
    local luas = "call userLongin01("
    luas = luas ..dbmL.lr..talk_login.name ..dbmL.lz..talk_login.passwords..dbmL.lr..')'
    local res = dbm:query(luas)
    --print("数据库得到数据----",dump(res))
    if res[1][1]["row_key"] == "no"  then
      print("判断为no，需要创建宠物")
      return res[1][1],serialize(res[2])
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
          
             sharedata.new(res[2][1][cli_user[2]]..':'.."yang", { a=1, b= { "hello",  "world" } })
          
           --获取宠物信息
           for k,v in pairs(res[3]) do
            if type(v) == "table" then
              print("宠物名",v[tableRoleS[4]])
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
          user03["rolekey"] = userInfo
          --当前宠物信息
         local opens = dbr:hmget(userw[12], tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
         user03["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
          
          local b = os.clock()
          print(b-a)
           user_names[res[2][1] [cli_user[2]] ] = clone(user03)
          print("新建的----",dump(user_names))
          return res[1][1] ,serialize(user03)
        else
          print("键不存在")
          --创建用户键
          local userdb = res[2][1]
          local userItem = res[4][1]
          local rer2 = dbr:hmset(userdb[cli_user[2]], cli_user[1], userdb[cli_user[1]],cli_user[2], userdb[cli_user[2]],cli_user[3], userdb[cli_user[3]],cli_user[4], userdb[cli_user[4]], cli_user[5], userdb[cli_user[5]], cli_user[6],userdb[cli_user[6]], cli_user[7],userdb[cli_user[7]], cli_user[8],userdb[cli_user[8]], cli_user[9],userdb[cli_user[9]], cli_user[10],userdb[cli_user[10]], cli_user[11],userdb[cli_user[11]], cli_user[12],userdb[cli_user[12]], cli_user[13],userdb[cli_user[13]], cli_user[14],userdb[cli_user[14]], cli_user[17],userdb[cli_user[17]] )
          local rer3 = dbr:hmset(userdb[cli_user[2]],1,userItem[tableItemTable[2]],2,userItem[tableItemTable[3]],3,userItem[tableItemTable[4]], 4,userItem[tableItemTable[5]], 5,userItem[tableItemTable[6]], 6,userItem[tableItemTable[7]], 7,userItem[tableItemTable[8]], 8,userItem[tableItemTable[9]])
         user_item[userdb[cli_user[2]] ] = {[1]= userItem[tableItemTable[2]],[2]=userItem[tableItemTable[3]],[3]=userItem[tableItemTable[4]],[4]=userItem[tableItemTable[5]], [5]=userItem[tableItemTable[6]], [6]=userItem[tableItemTable[7]], [7]=userItem[tableItemTable[8]], [8]=userItem[tableItemTable[9]]}
          --每日完成任务数//和新建的键
          local res5 = dbr:hmset(userdb[cli_user[2]],cli_user_t[1],0,cli_user_t[2],0,cli_user_t[3],0,cli_user_t[4], userdb[cli_user_t[4]],cli_user_t[5], userdb[cli_user_t[5]],cli_user_t[6], userdb[cli_user_t[6]],cli_user_t[7], userdb[cli_user_t[7]],cli_user_t[8], userdb[cli_user_t[8]], cli_user_t[9],1 )
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
                print("用户键创建成功")
              else
                print("用户键创建失败用户需要重新登录")
              end
            end
          end
          print("这里返回数据")
         local userw = dbr:hmget(userdb[cli_user[2]],cli_user[1],cli_user[2],cli_user[3],cli_user[4],cli_user[5],cli_user[6],cli_user[7],cli_user[8],cli_user[9],cli_user[10],cli_user[11],cli_user[12],cli_user[13],cli_user[14],cli_user[17])
         local opens = dbr:hmget(userw[12], tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
         for k,v in pairs(cli_user02) do
            if k == "dbrkey" or k == "roleopen"  or k == "userGame" then
              user03[k] = userw[v]
            else
              user03[k] = tonumber( userw[v])
            end
          end
         user03["rolekey"] = userInfo
         user03["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
         user_names[userdb[cli_user[2]]] = user03
         print("新建的----",dump(user_names))
          return res[1][1] ,serialize(user03)
        end
    end
    
end

--1.1用户再次进入主界面时触发CMD.loginServer0101(dbm,dbr,dbrT,client_fd,talk_login)
function CMD.loginServer0101(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
  print("用户正常注册")
  --1用户再次登录
  local talk_login = unserialize(talk_logins)
--  local talk_login = {
--    dbrkey = "33:12",
--    userId = 33,
--    pass = 315,
--    roleopen = "33:12:20",
--  }
    --2判断用户输入是否正确
  if talk_login.userId == user_names[talk_login.dbrkey][cli_user[1]] and talk_login.pass ==  user_names[talk_login.dbrkey][cli_user[9]] and talk_login.roleopen ==  user_names[talk_login.dbrkey][cli_user[12]] then
    --3输入正确可以使用
    print("正确返回主界面")
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
      if trac_server[user_names[talk_login.dbrkey][cli_user[3]]+1][cli_user_t[10]] == nil then
        print("为最高等级")
      elseif trac_server[user_names[talk_login.dbrkey][cli_user[3]]+1][cli_user_t[10]] < user_names[talk_login.dbrkey][cli_user[4]] then
        print("达到升级要求")
        local res011 = dbr:hincrby(user_names[talk_login.dbrkey][cli_user[2]], cli_user[3],1)
        user_names[talk_login.dbrkey][cli_user[3]] = res011
      else
        print("没有达到升级要求")
      end
    else
      print("最高宝气值大于当前宝气值")
    end

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

--1.2宝气值界面 CMD.treaServer0102(dbm,dbr,dbrT,client_fd,talk_logins)
function CMD.treaServer0102(dbm,dbr,dbrT,client_fd,talk_logins)
  local a = os.clock() 
  local talk_login = unserialize(talk_logins)
  print("2宝气值界面")
  --1用户再次登录
--  local talk_login = {
--      dbrkey = "33:12",
--    }
    --1得到当前用户的最高宝气值和当前宝气值在判断缓存是否有数据
    if user_names[talk_login.dbrkey] == nil then
      print("用户还没有登录")
      return "no",{id = 903}
    end
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
    --print(dump(trac_server))
    --2返回数据当前用户的最高宝气值和当前宝气值和缓存数据
    return "yes",serialize({gasNo = user_names[talk_login.dbrkey][cli_user[3]], gasValues = user_names[talk_login.dbrkey][cli_user[4]],usegasValues = user_names[talk_login.dbrkey][cli_user[5]], trea = trac_server})
end



--2使用临时用户创建宠物  CMD.mysqlCreateROle02(dbm,dbr,dbrT,client_fd,talk_login)
function CMD.mysqlCreateROle02(dbm,dbr,dbrT,client_fd,talk_login)
    print("用户正常登入后")
--    local talk_login = {
--      name = "Bob",
--      passwords = "123",
--      sex = 1,
--      roles = 1,
--    }
    local user03 = {}
    --查询mysql数据库
    local luas = "call userRoleCreate02("
    luas = luas ..dbmL.lr..talk_login.name ..dbmL.lz..talk_login.passwords..dbmL.lz2..talk_login.sex ..dbmL.lc..talk_login.roles..')'
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

--3.1返回关卡信息数据CMD.mysqlSelectMap031(dbm,dbr,dbrT,client_fd,talk_login)
function CMD.mysqlSelectMap031(dbm,dbr,dbrT,client_fd,talk_logins)
    local a = os.clock() 
    local talk_login = unserialize(talk_logins)
    print("用户点击关卡后")
    local user03 = {}
--      ----------------------------
--  local client_fd = 0
--  client_fd=client_fd+1
    --得到用户数据
--    local talk_login = {
--      dbrkey = "33:12",
--      pass = 315,
--    }
    
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

--3.2进入游戏CMD.redisSelectMap0302(dbm, dbr, dbrT,client_fd,talk_login)
function CMD.redisSelectMap0302(dbm, dbr, dbrT,client_fd,talk_login)
  local a = os.clock() 
--  local talk_login = unserialize(talk_logins)
--  if talk_login == nil then
--      print("数据为空")
--  end
  print("创建地图****")
  local talk_login = {
      dbrkey = "33:12",
      pass = 315,
      engame = "yes",
    }
  print("进入关卡")
  local user03 = {}
  --得到用户数据
  local mapuser1 = user_names[talk_login.dbrkey].pass
  print("用户名:", user_names[talk_login.dbrkey].dbrkey)
  print("地图:",user_names[talk_login.dbrkey].pass)
  if  user_map[mapuser1] ~= nil then
    print("清除原有数据")
    user_map[mapuser1]=nil
  end
  local los2 = Levels.get(2)
  --得到地图信息
  local luas = ""
  local res ={}
  local resY ={}
  if user_passG[talk_login.pass] ~= nil then
    resY = user_passG[talk_login.pass]
  else
    luas = "call mapTableOn02("
    luas = luas..talk_login.pass ..')'
    res = dbm:query(luas)
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
  for k,v in pairs(mapApp) do
    iss = mapSerS[v]
    while iss ~= 0 do
      --print(iss)
      --产生随机数
      local s = math.random(1,98)
      h = math.floor(s/los2.cols)+1
      w = s%los2.cols+1
      --print("第一次产生的随机数",s)
      while (rands[h][w] == 2 or type(rands[h][w]) == "string") do
        --print("第二次产生的随机数",s)
        s = math.random(1,98)
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
  local itemOn = dbr:hmget(talk_login.dbrkey,1,2,3,4,5 )
  local trap02 ={}
  for k,v in pairs(itemOn) do
    trap02[k]=v
  end
  user_item[talk_login.dbrkey] = trap02
  user03.itemtab = trap02
  --查看当前宠物属性
  local opens = dbr:hget(talk_login.dbrkey,cli_user[12])
  local roleOn ={}
  local rolews = dbr:hmget(opens,tableRoleS[2],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[19])
  roleOn={ gameuser = tonumber(rolews[1]),rolekey = opens, life = tonumber(rolews[4]), userLife = tonumber(rolews[3]) ,levelCap = tonumber(rolews[2]), actionVal = tonumber(rolews[5]) }
  user03.roleuser = roleOn
  print("地图位置----",dump(user03))

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
--3.3进入游戏状态CMD.mysqlSelectMap033(dbm,dbr,dbrT,client_fd,talk_login)
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
      return "no", serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    end
    --3行动值减一
    if user_com[talk_login.dbrkey][gameLevelk[15]] <= 0 then
      --游戏结束
      print(dump(user_com))
      return "no", serialize({numa =109,addTreaNum =user_com[talk_login.dbrkey][gameLevelk[11]], addNumTrap =user_com[talk_login.dbrkey][gameLevelk[12]],life =user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]],actionVals =user_com[talk_login.dbrkey][gameLevelk[15]] } )
    else
      user_com[talk_login.dbrkey][gameLevelk[15]] = user_com[talk_login.dbrkey][gameLevelk[15]] -1
    end
    --4时间判断
    if user_com[talk_login.dbrkey][gameLevelk[10]] <= os.time() then
      print("时间到游戏结束")
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
      user_com[talk_login.dbrkey][gameLevelk[14]] = os.time()+adds[gameLevelk[1]]
      user_com[talk_login.dbrkey][gameLevelk[16]] = os.time()
      print( dump(user_names[talk_login.dbrkey][cli_user[16]]))
      user_com[talk_login.dbrkey][gameLevelk[12]] = user_com[talk_login.dbrkey][gameLevelk[12]] + 1
      if user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] <= 0 then
        --游戏结束
        user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = 0
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
      user_names[talk_login.dbrkey][cli_user[8]] = user_names[talk_login.dbrkey][cli_user[8]] - gameRebirth.diamond
      --2改变数据继续游戏
      user_names[talk_login.dbrkey][cli_user[16]][tableRoleS[7]] = gameRebirth.life
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


--4.1更换当前角色返回所有角色信息
function CMD.changeRole041(dbm, dbr, dbrT,client_fd,talk_updateroles)
  local roleU = {}
  local talk_updaterole = unserialize(talk_updateroles)
  --得到用户数据
--  local talk_updaterole = {
--      dbrkey = "33:12",
--      roleopen = {
--        [1] = {["rolekey"] = "33:12:20",["id"] = 1,},
--        [2] = { ["rolekey"] = "33:12:38", ["id"] = 5, },
--        [3] = { ["rolekey"] = "33:12:39", ["id"] = 9, },
--        [4] = { ["rolekey"] = "33:12:40",["id"] = 9, },
--        [5] = {["rolekey"] = "33:12:41", ["id"] = 9, },
--      },
--    }
  --通过用户提供的角色键名得到角色信息
  local roles = {}
  for k,v in pairs(talk_updaterole.roleopen) do
     if type(v) == "table" then
        print("角色",v.rolekey)
        --得到角色信息
        local rolec = dbr:hmget( v.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
        local rolecs = {}
        --组合角色信息
        for k,v in pairs(tableRoleS02) do
          rolecs[k] = rolec[v]
        end
        table.insert(roles,rolecs)
      else
        print("角色不存在")
    end
  end
  roleU.roeluser = roles
  print("返回的数据信息",dump(roleU))
  return "yes",serialize( roleU )
end

--4.2更换当前角色
function CMD.dbrUpdateRole042(dbm, dbr, dbrT,client_fd,talk_updateroles)
--local talk_updaterole = {
--    dbrkey = "33:12",
--    roleopen = "33:12:20",
--  }
  local talk_updaterole = unserialize(talk_updateroles)
  local userIs = dbr:hexists(talk_updaterole.dbrkey,cli_user[12])
  if userIs == 1 then
    print("键存在")
    userIs = dbr:hset(talk_updaterole.dbrkey, cli_user[12], talk_updaterole.roleopen)
              --当前宠物信息
         local opens = dbr:hmget(talk_updaterole.roleopen, tableRoleS[2], tableRoleS[4], tableRoleS[5], tableRoleS[6], tableRoleS[7], tableRoleS[8], tableRoleS[9],tableRoleS[10])
         user_names[talk_updaterole.dbrkey]["currRole"] = {id =tonumber(opens[1]), name = opens[2], stageId = tonumber(opens[3]), stage = tonumber(opens[4]), life = tonumber(opens[5]),userLife = tonumber(opens[6]),levelCap = tonumber(opens[7]), restoreLife = tonumber(opens[8])}
    if userIs == 0 then
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

--4.3恢复角色生命值 
function CMD.characterLife043(dbm, dbr, dbrT,client_fd,talk_updateroles)
  local talk_updaterole = unserialize(talk_updateroles)
  --用户数据
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    rolekey = "33:12:20",
--  }
  --得到宠物的血量
  print("判断是否存在")
  if true == (dbr:exists(talk_updaterole.rolekey)) then
    local roleLife = dbr:hmget(talk_updaterole.rolekey,tableRoleS[7],tableRoleS[8])
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
        return "yes",serialize ({diamond = life01,life = life02} )
      else
        print("血量不可以加满")
         local life01 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[8], -diamu)
         local life02 = dbr:hincrby(talk_updaterole.rolekey,tableRoleS[7],diamu)
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
--    rolekey = "33:12:41",
--    openmoney = 2,
--  }
  --得到宠物的等级
  print("判断是否存在")
  if true == (dbr:exists(talk_updaterole.rolekey)) then
    local roleLe = dbr:hmget(talk_updaterole.rolekey,tableRoleS[2],tableRoleS[9] )
    --local roleLe = dbr:hmget(talk_updaterole.rolekey,tableRoleS[2],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
    print("宠物id",roleLe[1],"--角色等级",roleLe[2])
    local luas = "call roleLeve0404("
    luas = luas..roleLe[1]..')'
    local res = (dbm:query(luas))[1][1]
    print("----",res.levelCap)
    local levels = tonumber(roleLe[2])
    if levels < 0 or levels >res.levelCap  then
      print("出现异常")
      return "no",{id = 902}
    elseif levels == res.levelCap  then
      print("最高等级")
      return "no",{id = 803}
    else
      print("可以升级")
      --得到角色的值
      local luas = "call roleLeve04041("
      luas = luas..roleLe[1]..dbmL.lc..roleLe[2]..')'
      local res = (dbm:query(luas))[1][1]
      --判断支付方式
      if talk_updaterole.openmoney == 1 then
        local userM = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[6]) )
        print("dddd",userM)
        if userM >= res.userCurr then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[6],-res.userCurr)
          for k,v in pairs(roleLevel02) do
                  local userM2 = dbr:hincrby(talk_updaterole.rolekey,v,res[roleLevel03[k]])
          end
          print("升级成功")
          --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
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
          for k,v in pairs(roleLevel02) do
                  local userM2 = dbr:hincrby(talk_updaterole.rolekey,v,res[roleLevel03[k]])
          end
          --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
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
    local luas = "call roleLeve0404("
    luas = luas..roleLe[1]..')'
    local res = (dbm:query(luas))[1][1]
    print("----",res.levelCap)
    local levels = tonumber(roleLe[2])
    if levels < 0 or levels >res.levelCap  then
      print("出现异常")
      return "no",{id = 902}
    elseif levels == res.levelCap  then
      print("最高等级")
      return "no",{id = 803}
    elseif levels == talk_updaterole.levelS  then
      print("等级相同")
      return "no",{id = 804}
    else
      print("可以升级")
      --得到角色的值
      local luas2 = "call roleLevel04051("
      luas2 = luas2..roleLe[1]..dbmL.lc..talk_updaterole.levelS..')'
      local res2 = (dbm:query(luas2))[1][1]
      print(res2.userCurr,res2.diamond)
      --判断支付方式
      if talk_updaterole.openmoney == 1 then
        local userM = tonumber(dbr:hget(talk_updaterole.dbrkey,cli_user[6]) )
        print("dddd",userM)
        if userM >= res2.userCurr then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[6],-res2.userCurr)
          local roleleve01 =  "call roleLevel0405("
          roleleve01 = roleleve01..roleLe[1]..dbmL.lc..talk_updaterole.levelS..')'
          local v = (dbm:query(roleleve01))[1][1]
          local rer = dbr:hmset(talk_updaterole.rolekey,roleLevel02[1],v[roleLevel02[1]],roleLevel02[2],v[roleLevel02[2]],roleLevel02[3],v[roleLevel02[3]],roleLevel02[4],v[roleLevel02[4]],roleLevel02[5],v[roleLevel02[5]],roleLevel02[6],v[roleLevel02[6]], roleLevel02[7],v[roleLevel02[7]],roleLevel02[8],v[roleLevel02[8]],roleLevel02[9],v[roleLevel02[9]],roleLevel02[10],v[roleLevel02[10]],roleLevel02[11],v[roleLevel02[11]])
          print("ddd",dump(rer))
          --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
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
        if userM >= res2.diamond then
          local userM2 = dbr:hincrby(talk_updaterole.dbrkey,cli_user[8],-res2.diamond)
          local roleleve01 =  "call roleLevel0405("
          roleleve01 = roleleve01..roleLe[1]..dbmL.lc..talk_updaterole.levelS..')'
          local v = (dbm:query(roleleve01))[1][1]
          local rer = dbr:hmset(talk_updaterole.rolekey,roleLevel02[1],v[roleLevel02[1]],roleLevel02[2],v[roleLevel02[2]],roleLevel02[3],v[roleLevel02[3]],roleLevel02[4],v[roleLevel02[4]],roleLevel02[5],v[roleLevel02[5]],roleLevel02[6],v[roleLevel02[6]], roleLevel02[7],v[roleLevel02[7]],roleLevel02[8],v[roleLevel02[8]],roleLevel02[9],v[roleLevel02[9]],roleLevel02[10],v[roleLevel02[10]],roleLevel02[11],v[roleLevel02[11]])
          print("ddd",dump(rer))
           --得到角色信息
          local rolec = dbr:hmget( talk_updaterole.rolekey, tableRoleS[1],tableRoleS[2],tableRoleS[3],tableRoleS[4],tableRoleS[5],tableRoleS[6],tableRoleS[7],tableRoleS[8],tableRoleS[9],tableRoleS[10],tableRoleS[11],tableRoleS[12],tableRoleS[13],tableRoleS[14],tableRoleS[15],tableRoleS[16],tableRoleS[17],tableRoleS[18],tableRoleS[19] )
          local rolecs = {}
          --组合角色信息
          for k,v in pairs(tableRoleS02) do
            rolecs[k] = rolec[v]
          end
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

--4.6添加用户角色槽
function CMD.roleSlot046(dbm, dbr, dbrT,client_fd,talk_updateroles)
  --提取游戏用户槽
  local talk_updaterole = unserialize(talk_updateroles)
--  local talk_updaterole = {
--    dbrkey = "33:12",
--    openmoney = 2,
--  }
  local res = dbr:hmget( talk_updaterole.dbrkey, cli_user[10] ,cli_user[6],cli_user[8])
  local userSole = tonumber(res[1])
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



--5商城CMD.openMall05(dbm, dbr, dbrT,client_fd,talk_login)
function CMD.openMall05(dbm, dbr, dbrT,client_fd,talk_logins)
  local talk_login = unserialize(talk_logins)
  --提取游戏角色相关数据/
--  local talk_login = {
--    id = 1,
--  }
  print("5商城CMD")
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
      return "yes",openM
    elseif talk_login.id == 3 then
      openM ={diams = res[1]}
      item_open[talk_login.id] = openM
      return "ok",openM
    else
      return "no", {id = 902}
    end
  else
    print("dddd",dump(item_open))
    if talk_login.id < 3 then
      return "yes",item_open[talk_login.id]
    elseif talk_login.id == 3 then
      return "ok",item_open[talk_login.id]
    else
      return "no", {id = 902}
    end
  end
  
end


--5.1用户购买角色CMD.openRole051(dbm, dbr, dbrT,client_fd,talk_login)
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
            local rer = dbr:hmset(v[tableRoleS[3]],tableRoleS[1],v[tableRoleS[1]],tableRoleS[2],v[tableRoleS[2]],tableRoleS[3],v[tableRoleS[3]],tableRoleS[4],v[tableRoleS[4]],tableRoleS[5],v[tableRoleS[5]],tableRoleS[6],v[tableRoleS[6]], tableRoleS[7],v[tableRoleS[7]],tableRoleS[8],v[tableRoleS[8]],tableRoleS[9],v[tableRoleS[9]],tableRoleS[10],v[tableRoleS[10]],tableRoleS[11],v[tableRoleS[11]],tableRoleS[12],v[tableRoleS[12]], tableRoleS[13],v[tableRoleS[13]], tableRoleS[14],v[tableRoleS[14]],tableRoleS[15],v[tableRoleS[15]], tableRoleS[16],v[tableRoleS[16]], tableRoleS[17],v[tableRoleS[17]],tableRoleS[18],v[tableRoleS[18]],tableRoleS[19],v[tableRoleS[19]] )
            table.insert(user_names[talk_login.openuser][cli_user[15]] , {id =v[tableRoleS[2]], rolekey = v[tableRoleS[3]] })
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
--5.2购买道具CMD.openItem052(dbm, dbr, dbrT,client_fd,talk_login)
function CMD.openItem052(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock()
  local talk_login = unserialize(talk_logins)
  print("2用户购买道具") 
  local user051 = {}
  local onkey = ""
--  local talk_login = {
--    openuser = "33:12",
--    openitem  = 1,
--    openNo = 8,
--    openmoney = 2,
--  }
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

--5.3购买萌币和星星
function CMD.openStart053(dbm, dbr, dbrT,client_fd,talk_logins)
  local a = os.clock()
  local talk_login = unserialize(talk_logins)
  print("2用户购买萌币和星星") 
  local user051 = {}
  local onkey = ""
--  local talk_login = {
--    openuser = "33:12",
--    openitem  = 10,
--    openNo = 8,
--  }
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
          user_item[talk_login.openuser][open_buy[rolekey053.itemOn]] = item0532
          user_names[talk_login.openuser][cli_user[8]] = itme0533

          
          print(user_item[talk_login.openuser][open_buy[rolekey053.itemOn]])
          print(user_names[talk_login.openuser][cli_user[8]])
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



--6.1好友信息CMD.openFriends0601(dbm, dbr, dbrT,client_fd,talk_login)
function CMD.openFriends0601(dbm, dbr, dbrT,client_fd,talk_logins)
  --查询好友表/
--  local talk_login={id = 33}
  local talk_login = unserialize(talk_logins)
  print("dddddddddddd",talk_login.id)
  local luas = "call openFriends07("
  luas = luas ..talk_login.id..')'
  local res = dbm:query(luas)
  local userd ={}
  for k,v in pairs(res[1]) do
    if type(v) == "table" then
      print("宠物名",v["purName"])
      local users = dbr:hmget(v["friKey"],cli_user[1], cli_user[3],cli_user[5],cli_user[9],cli_user[11])
      table.insert(userd,{userId=users[1],purName = v["purName"],gasNo = users[2],usegasValues = users[3],pass = users[4],start = users[5]})
    end
  end
  local userf = {}
  userf.friends = userd;
  userf.addfriend = res[2];
  print("userd--",dump(userf))
  return serialize(userf)
end

--6-2好友查询CMD.queryFriends0602(dbm, dbr, dbrT,client_fd,talk_login)
function CMD.queryFriends0602(dbm, dbr, dbrT,client_fd,talk_logins)
--  local talk_login={name = "32"}
  --查询好友表/
  local talk_login = unserialize(talk_logins)
  print("dddddddddddddd",talk_login.name)
  local luas = ""
  local n = tonumber(talk_login.name);
  if n then
   -- n就是得到数字
    luas = luas .."call queryFriends06("..n..')'
  else
   -- 转数字失败,不是数字, 这时n == nil
   luas = luas .."call queryFriends061("..dbmL.lr..talk_login.name..dbmL.lr..')'
  end
  local res = dbm:query(luas)
  print("userd--",dump(res))
  if res[1][1]["row_key"] == "yes" then
    local userdb = {}
    print("用户存在")
    userdb = res[2][1]
    return "yes",serialize(userdb)
  else
    print("用户不存在")
    return "no",{id = 120}
  end
end

--6-3确定邀请好友
function CMD.addsFriends06(dbm, dbr, dbrT,client_fd,talk_logins)
  --查询好友表/
--  local talk_login={
--    purid = 31,
--    puruser = "yangddd",
--    purkey = "yang:001",
--    souid = 33,
--    souuser = "kai001",
--    soukey = "kai001:33",
--  }
  local talk_login = unserialize(talk_logins)
  local luas = "call addFriends062("
  luas = luas ..talk_login.purid..dbmL.lcz..talk_login.puruser..dbmL.lz..talk_login.purkey..dbmL.lz2..talk_login.souid..dbmL.lcz..talk_login.souuser..dbmL.lz..talk_login.soukey..dbmL.lr..')'
  print(luas)
  local res = dbm:query(luas)
  print("openMall--",dump(res))
  if res[1][1]["row_key"] == 0 then
    print("用户已经添加")
    return "no",{id = 121}
  else
    print("用户添加成功")
    return "yes",{id = 8}
  end
  
end
--6-4同意被邀请
function CMD.AgreedFriends0604(dbm, dbr, dbrT,client_fd,talk_logins)
  --查询邀请表/
--    local talk_login={
--    nokey = "yes",
--    purid = 31,
--    souid = 33,
--  }
  local talk_login = unserialize(talk_logins)
  local luas = "call addFriends063("
  luas = luas ..dbmL.lr..talk_login.nokey..dbmL.lz2..talk_login.purid..dbmL.lc..talk_login.souid..')'
  print(luas)
  local res = dbm:query(luas)
  print("openMall--",dump(res))
  if res[1][1]["row_key"] == 1 then
    print("同意邀请")
    return "yes",{id = 9}
  elseif res[1][1]["row_key"] ==2 then
    print("没有消息")
    return "no",{id = 123}
  else
    print("未同意邀请")
    return "no",{id = 124}
  end
  
end

--7活动
--7.1每日任务CMD.Daily_Task0701(dbm, dbr, dbrT, client_fd, table_task)
function CMD.Daily_Task0701(dbm, dbr, dbrT, client_fd, table_tasks)
   local a = os.clock() 
  --所需数据
--  local table_task={
--    dbrkey = "33:12",
--  }
  local table_task = unserialize(table_tasks)
  --判断是否为当天的数据
  local t7 = os.time() 
  if user_names[table_task.dbrkey] == nil then
    print("用户还没有登录")
    return "no", {id =904 }
  end
  t7 = math.floor(t7 / 86400)
  local time07 = dbr:hmget(table_task.dbrkey,cli_user_t[4],cli_user_t[5])
  print(time07[1])
  if tonumber(time07[2]) == t7 then
    print("是当天任务")
  else
    print("不是当天任务清零")
    local timeres07 = dbr:hmset(table_task.dbrkey,cli_user_t[1],0,cli_user_t[2],0,cli_user_t[3],0,cli_user_t[5],t7)
    local timeres0701 = dbr:del(time07[2])
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

--7.2领取奖励 Daily_Task0702(dbm, dbr, dbrT)
function CMD.Daily_Task0702(dbm, dbr, dbrT, client_fd, table_tasks)
  local a = os.clock()
  --所需数据
--  local table_task={
--    dbrkey = "33:12",
--  }
  local table_task = unserialize(table_tasks)
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
    taskuser02[k] = restask02;
  end
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
        st,s = f(table_task.dbrkey,t4,dbr)
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

--8.1邮件 CMD.mailSelect0801(dbm,dbr,dbrT, client_fd, table_task)
function CMD.mailSelect0801(dbm,dbr,dbrT, client_fd, table_tasks)
  local a = os.clock()
--  local table_task={
--    dbrkey = "33:12",
--  }
  local table_task = unserialize(table_tasks)
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

--9.1月卡//月卡编号在购买后自动产生CMD.onCard0901(dbm,dbr,dbrT, client_fd, table_task)
function onCard0901(dbm,dbr,dbrT)
  local a = os.clock()
  local table_task={
    dbrkey = "33:12",
  }
  --local table_task = unserialize(table_tasks)
  local obj = sharedata.query(table_task.dbrkey)
  print(dump(obj))
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

--9.2领取月卡奖品//触发购买信息 CMD.onCard0902(dbm,dbr,dbrT, client_fd, table_task)
function CMD.onCard0902(dbm,dbr,dbrT, client_fd, table_tasks)
--  local table_task={
--    dbrkey = "33:12",
--    cardId = 30,
--  }
  local table_task = unserialize(table_tasks)
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
    print(user_card[table_task.dbrkey][cli_card[4]])
    print(card_Item[user_card[table_task.dbrkey][cli_card[4]]][table_task.cardId])
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
    print("地图物品信息",dump(user_mapItems))
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
            print(mapG[1]..':'..v[mapServer[1]], mapServer[1] ,v[mapServer[1]])
            local mapT01 = dbrT:hmset(mapG[1]..':'..v[mapServer[1]], mapServer[1] ,v[mapServer[1]], mapServer[2] ,v[mapServer[2]], mapServer[3] ,v[mapServer[3]], mapServer[4] ,v[mapServer[4]], mapServer[5] ,v[mapServer[5]], mapServer[6] ,v[mapServer[6]], mapServer[7] ,v[mapServer[7]],  mapServer[8] ,v[mapServer[8]], mapServer[9] ,v[mapServer[9]], mapServer[10] ,v[mapServer[10]], mapServer[11] ,v[mapServer[11]],mapServer[12] ,v[mapServer[12]], mapServer[13] ,v[mapServer[13]],mapServer[14] ,v[mapServer[14]], mapServer[15], v[mapServer[15]])
          else
            print("结束了.......")
          end
      end
end

--将每日签到写入DailyCheck


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
--  mysqlServer01(dbm,dbr,dbrT)
--  redisSelectMap0302(dbm,dbr,dbrT)
--  mysqlSelectMap033(dbm,dbr,dbrT)
--  itemServerMap0307(dbm,dbr,dbrT)
--  loginServer0101(dbm,dbr,dbrT)
--  treaServer0102(dbm,dbr,dbrT)
--  print("测试月卡")
--  onCard0901(dbm,dbr,dbrT)
--  onCard0901(dbm,dbr,dbrT)
--  print("第一次")
--  onCard0902(dbm,dbr,dbrT)
--  print("第二次")
--  onCard0902(dbm,dbr,dbrT)
--  mailSelect0801(dbm,dbr,dbrT)
--  mailSelect0802(dbm,dbr,dbrT)
--onCard0903(dbm,dbr,dbrT)
  --onCard0901(dbm,dbr,dbrT)
--	mysqlServer01(dbm,dbr,dbrT)
--	dailyCheck0703(dbm,dbr,dbrT)
--  mailSelect0801(dbm,dbr,dbrT)
--  mailSelect0802(dbm,dbr,dbrT)
--	mysqlSelectMap031(dbm,dbr,dbrT)
--	
--	mysqlSelectMap033(dbm,dbr,dbrT)
--	mailSelect0801(dbm, dbr, dbrT)
--  mailSelect0801(dbm, dbr, dbrT)
  --daily_Check0703(dbm, dbr, dbrT)
  
  --mysqlServer01(dbm,dbr)
	--redis01(dbr)
	--test2(dbm)
	--suerverUserCreate01(dbm);
	--redismysql01server(dbm,dbr)
	
	skynet.register "talkmysql"
	--dbm:disconnect()
	--skynet.exit()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(dbm,dbr,dbrT,...)))
	
	
	end)
end)

