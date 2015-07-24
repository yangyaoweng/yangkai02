local skynet = require "skynet"
local redis = require "redis"

local conf = {
	host = "127.0.0.1" ,
	port = 6379 ,
	db = 0
}

local function watching()
	local w = redis.watch(conf)
	w:subscribe "foo"
	w:psubscribe "hello.*"
	while true do
		print("Watch", w:message())
	end
end

skynet.start(function()
	skynet.fork(watching)
	local dbr = redis.connect(conf)
	print("[NAMESPACE_DB] start success!")
	--db:disconnect()
end)

