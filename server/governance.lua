local socket = require "socket"

governance = {}
function governance.getIp ()
	local udp = socket.udp()
	udp:setpeername("1.1.1.1",1)
	local ip = udp:getsockname()
	udp:close()
	return ip
end


--========================================================
--== task object
--========================================================
function governance.newTask (label, numberId, rate, rates)
	local obj = {}
	setmetatable(obj, task)
	obj:__init(label, numberId, rate, rates)
	return obj
end

task = {}
task.__index = task
function task:__init (label, numberId, rate, rates)
	self.label = label
	self.numberId = numberId
	self.rate = rate or 5
	self.rates = rates or {}
end
function task:addRate (rate)
	table.insert(self.rates,rate)
	local c, a = 0, 0
	for i,v in ipairs(self.rates) do
		c = c + v
		a = i
	end
	local average = c/a
	if average+0.5 < math.floor(average)+1 then
		average = math.floor(average)
	else
		average = math.floor(average)+1
	end
	self.rate = average
end
function task:setRate (rate)
	self.rate = rate
	self.rates = {}
end

--========================================================
--== task board object
--========================================================
function governance.newTaskManager ()
	local obj = setmetatable({}, taskManager)
	return obj
end

taskManager = {
	container = {},
	draw_cursor = {x = 0, y = 0, margin = 10, width = 140, height = 140}
}
taskManager.__index = taskManager
function taskManager:addTask (task)
	task.numberId = self:countTasks() + 1
	table.insert(self.container,task.numberId, task)
end
function taskManager:removeTask (task_id)
	table.remove(self.container, task_id)
	for i,v in ipairs(self.container) do
		if i ~= v.numberId then
			v.numberId = i
		end
	end
end
function taskManager:countTasks ()
	local tnb = 0
	for i,t in ipairs(self.container) do
		tnb = i or tnb
	end
	return tnb
end
function taskManager:getTask (no)
	return self.container[no]
end
function taskManager:draw ()
	self.draw_cursor.x, self.draw_cursor.y = 0,0+self.draw_cursor.margin
	for i,utask in ipairs(self.container) do
		self.draw_cursor.x = self.draw_cursor.x + self.draw_cursor.margin
		utask:draw(self.draw_cursor.x, self.draw_cursor.y, self.draw_cursor.width, self.draw_cursor.height)
		self.draw_cursor.x = self.draw_cursor.x + self.draw_cursor.width
		if self.draw_cursor.x + self.draw_cursor.width + self.draw_cursor.margin*2 >= screenWidth then
			self.draw_cursor.x = 0; self.draw_cursor.y = self.draw_cursor.y + self.draw_cursor.height + self.draw_cursor.margin
		end
	end
end

return governance
