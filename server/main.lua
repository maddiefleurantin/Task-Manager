local socket = require "socket"
local governance = require "governance"

function love.load()
	output = ""
	servMsg = "waitting"
	hostIp = governance.getIp()

	server = socket.tcp()
	server:bind(hostIp,26464)
	success, err = server:listen()
	server:settimeout(0)
	clients = {}
	clientNb = 0

	taskManager = governance.newTaskManager()

	file = love.filesystem.newFile("task_load.lua")
	FILE_PATH = love.filesystem.getSaveDirectory()
	if love.filesystem.exists("task_load.lua") then -- should be replaced by love.filesystem.getInfo()
		dofile(FILE_PATH.."/task_load.lua")
	end

	time = 0
end

function love.update(dt)
	time = time + dt
	output = "Host IP: "..hostIp.."\nlisten: "..success.."\nserver message: "..servMsg
	if success then
		local new_client = server:accept()
		if new_client then
			table.insert(clients,new_client)
			new_client:settimeout(0)
			clientNb = clientNb + 1
			servMsg = servMsg.."\nnew client: "..clientNb

			local count = taskManager:countTasks()
			if count > 0 then
				local tasksArg = ""
				for i=1,count do
					local task = taskManager:getTask(i)
					tasksArg = tasksArg.."$"..task.label.."$"..task.numberId.."$"..task.rate
				end
				local msg = string.format("%s$%s$%d%s", "task", "load", count, tasksArg)
				servMsg = servMsg.."\nsending :: "..msg
				new_client:send(msg.."\n")
			else
				servMsg = servMsg.."\nno task"
				new_client:send("task$none\n")
			end
		end
		for i,connected_client in ipairs(clients) do
			local data = connected_client:receive()
			if data then
				servMsg = servMsg.."\nreceived :: "..data
				local cmd, arg = data:match("(%a+)$(.+)")
				if cmd == "newTask" then
					local newTask = governance.newTask(arg, taskManager:countTasks()+1)
					taskManager:addTask(newTask)
					for i,v in ipairs(clients) do
						local msg = string.format("%s$%s$%d", "addTask", arg, newTask.numberId)
						servMsg = servMsg.."\nsending "..msg
						v:send(msg.."\n")
					end
				elseif cmd == "rate" then
					local task_numberId, rate = arg:match("(%d+)$(%d+)")
					local rated_task = taskManager:getTask(tonumber(task_numberId))
					rated_task:addRate(rate)
					for i,v in ipairs(clients) do
						local msg = string.format("rate$%d$%d$average", task_numberId, rated_task.rate)
						servMsg = servMsg.."\nsending "..msg
						v:send(msg.."\n")
					end
				elseif cmd == "solution" then
					local task_numberId, rate = arg:match("(%d+)$(%d+)")
					local rated_task = taskManager:getTask(tonumber(task_numberId))
					rated_task:setRate(rate)
					for i,v in ipairs(clients) do
						local msg = string.format("rate$%d$%d$solution", task_numberId, rated_task.rate)
						servMsg = servMsg.."\nsending "..msg
						v:send(msg.."\n")
					end
				elseif cmd == "remove" then
					local task_numberId = arg:match("(%d+)")
					taskManager:removeTask(tonumber(task_numberId))
					for i,v in ipairs(clients) do
						local msg = string.format("%s$%d", "remove", tonumber(task_numberId))
						servMsg = servMsg.."\nsending "..msg
						v:send(msg.."\n")
					end
				end
			end
		end
		if time < 30 then
			local file_content = ""
			for i,v in ipairs(taskManager.container) do
				local rates = "{"
				for j,w in ipairs(v.rates) do
					rates = rates..string.format("%d,", w)
				end
				rates = rates.."}"
				file_content = file_content..string.format("LOADTASK{[[%s]], %d, %d, %s}\n", v.label, v.numberId, v.rate, rates)
			end
			file:open("w")
			file:write(file_content)
			file:close()
			time = 0
		end
	else
		output = output.." err: "..err
	end
end

function love.draw()
	love.graphics.setNewFont(20)
	love.graphics.print(output)
end

function LOADTASK (t)
	taskManager:addTask(governance.newTask(t[1], t[2], t[3], t[4]))
end
