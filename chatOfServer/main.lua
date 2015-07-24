local skynet = require("skynet")

local max_client = 64

skynet.start(function()

	print("Server start")
	
	--skynet.newService("chatOfSkynet")
	local console = skynet.newservice("console")
	skynet.newservice("talkbox")
	local watchdog = skynet.newservice("watchdog")
	-- 启动DB服务， 一个全局命名DB, 若干个角色数据服务--redis
  	--skynet.newservice("database/testredis5")
--  skynet.newservice("talkmysql")     --
 --全局常量
  skynet.newservice("datas/globalData")                --1
 --角色登录服务器
  skynet.newservice("datas/loginServer")                --1
  --进入游戏关卡的服务器
  skynet.newservice("datas/checkBattle")                --3
  --角色操作服务器
  skynet.newservice("datas/roleServers")                 --4
  --游戏商城
  skynet.newservice("datas/gameMall")                   --5
  --6好友信息
  skynet.newservice("datas/addBuddy")                 --6
  --7每日任务
  skynet.newservice("datas/dailyTask")                    --7
  --8邮件
  skynet.newservice("datas/mailSelect")                  --8
  --9月卡服务器
  skynet.newservice("datas/monthCardservice")   --9
  --10排行榜/钻石/萌币/星星/
  skynet.newservice("datas/rankingList")   --10
	--skynet.newservice("talkredis01")
	
	skynet.call(watchdog,"lua","start",{
		port = 10101,
		maxclient = max_client,
	})
	skynet.exit()

end)
