local socket = require "socket"

states = {
	home = {},
	connect = {},
	run = {},
	createNewTask = {},
	editTask = {},
}

--=====================================================
-- home
function states.home:load ()
	self.output = love.graphics.newText(love.graphics.newFont(text_font_size), "")
	self.text_buffer = {}
	self.server_name_button = governance.newTextBox("Serveur (host name)", 100)
	self.user_name_button = governance.newTextBox("Utilisateur", 180)
	self.passwrd_button = governance.newTextBox("code", 260)
	self.connect_button = governance.newButton("se connecter", function()
		local width = box_width
		local x = screenWidth/2 - width/2
		local height = box_height
		local y = screenHeight - height - 40
		return x,y,width,height
	end,
	function ()
		states.hostName = self.server_name_button:retrieveInput()
		states.userName = self.user_name_button:retrieveInput()
		states.passWord = self.passwrd_button:retrieveInput()
		state = "connect"
		states[state]:load()
	end)
	self.clickableManager = governance.newClickableManager()
	self.clickableManager:addClickable(self.server_name_button)
	self.clickableManager:addClickable(self.user_name_button)
	self.clickableManager:addClickable(self.passwrd_button)
	self.clickableManager:addClickable(self.connect_button)
end
function states.home:update (dt)
	self.output:set(console)
	local clickable = self.clickableManager:getSelectedClikable()
	if last_clickable and not last_clickable.busy then
		last_clickable:unSelect()
		last_clickable = false
	end
	if clickable then
		if not clickable.busy then
			clickable:select(1)
		end
		if love.mouse.isDown(1) then
		elseif mouse.released then
			if last_busy then
				last_busy:unSelect()
				last_busy = false
			end
			if clickable.buffer then
				clickable:select(2)
				last_busy = clickable
				currentTextBox = clickable:action()
			else
				clickable:action()
			end
		end
		last_clickable = clickable
	end
end
function states.home:draw ()
	self.server_name_button:draw()
	self.user_name_button:draw()
	self.passwrd_button:draw()
	self.connect_button:draw()
	love.graphics.draw(self.output, toPixels(screenWidth/2 - self.output:getWidth()/2), toPixels(screenHeight - box_height - 40 - (self.output:getHeight()/2*3)))
end
--========================================
-- connect
function states.connect:load ()
	self.send = false
	self.time = 0
	states.serverIp, err = socket.dns.toip(states.hostName)
	if states.serverIp then
		client = socket.tcp()
		client:settimeout(7)
	else
		console = err
		state = "home"
	end
end
function states.connect:update (dt)
	success, err = client:connect(states.serverIp, 26464)
	if success then
		state = "run"
		states.run:load()
	else
		console = "error: "..err
		state = "home"
	end
end
function states.connect:draw ()
	love.graphics.print("connect", 0, 400)
end
--=======================================
-- run
function states.run:load ()
	self.dbg = ""
	self.taskManager = governance.newTaskManager()
	self.clickableManager = governance.newClickableManager()
	self.drawableManager = governance.newDrawableManager()
	self.addTaskButton = governance.newButton(
	"Nouvelle Tâche",
	function ()
		local x = 0
		local y = screenHeight - 75
		local width = screenWidth
		local height = 75
		return x,y,width,height
	end,
	function ()
		state = "createNewTask"
		states[state]:load()
	end, 3)
	self.exitButton = governance.newButton(
	"quiter",
	function ()
		local x = screenWidth - box_width/3 - box_width/3/2
		local y = screenHeight - 75/2 - box_height_2/2
		local width = box_width/3
		local height = box_height_2
		return x,y,width,height
	end,
	function ()
		client:close()
		self.taskManager:close()
		self.clickableManager:close()
		self.drawableManager:close()
		love.load()
	end, 4)
	self.exitButton:setColor(.20,.24,.28,1)
	self.exitButton:setTextColor(.78,.78,.78,1)

	self.clickableManager:addClickable(self.addTaskButton)
	self.drawableManager:addDrawable(self.addTaskButton)
	self.clickableManager:addClickable(self.exitButton)
	self.drawableManager:addDrawable(self.exitButton)

	-- output = "getting task"
	local data = client:receive()
	if data then
		local cmd, arg = data:match("(%a+)$(.+)")
		if cmd == "task" then
			cmd, arg = arg:match("(%a+)$?(.*)")
			if cmd == "load" then
				local count, labels = arg:match("(%d+)$(.+)")
				for i=1,count do
					local label = ""
					label, numberId, rate, labels = labels:match("(.-)$(%d+)$(%d+)$?(.*)")
					-- output = output..string.format("\nlabel %s, numberId %d, rate %d, labels %s", label, numberId, rate, labels)
					local newTask = governance.newTask(label, tonumber(numberId), tonumber(rate))
					self.taskManager:addTask(newTask)
					self.clickableManager:addClickable(newTask)
					self.drawableManager:addDrawable(newTask)
				end
			end
			client:settimeout(0)
			-- output = "connected!!"
		end
	end
end
function states.run:update (dt)
	local data = client:receive()
	if data then
		-- self.dbg = self.dbg.."\nreceived "..data
		local cmd, arg = data:match("(%a+)$(.+)")
		if cmd == "addTask" then
			local label, numberId = arg:match("(.+)$(%d+)")
			local newTask = governance.newTask(label, tonumber(numberId))
			self.taskManager:addTask(newTask)
			self.clickableManager:addClickable(newTask)
			self.drawableManager:addDrawable(newTask)
		elseif cmd == "rate" then
			local numberId, rate, type = arg:match("(%d+)$(%d+)$(%a+)")
			local task = self.taskManager:getTask(tonumber(numberId))
			task:setRate(tonumber(rate), type)
		elseif cmd == "remove" then
			local numberId = arg:match("(%d+)")
			self.taskManager:removeTask(tonumber(numberId))
			self.clickableManager:removeClickable(tonumber(numberId))
			self.drawableManager:removeDrawable(tonumber(numberId))
		end
	end
	self.taskManager:updateTasksPosition()

	local clickable = self.clickableManager:getSelectedClikable()
	if last_clickable then
		last_clickable:unSelect()
		last_clickable = false
	end
	if clickable and not GUI_scrolling then
		if clickable.select then
			clickable:select()
			if love.mouse.isDown(1) then
			elseif mouse.released then
				clickable:unSelect()
				clickable:action()
				clickable = false
			end
			last_clickable = clickable
		end
	end

	if GUI_scrolling then
		-- self.taskManager:scrollTasks(mouse.dy)
		GUI_scrolling_y_pos = GUI_scrolling_y_pos + fromPixels(mouse.dy)
		GUI_scrolling_delta_y = GUI_scrolling_max_y - screenHeight + 75
		if GUI_scrolling_y_pos > GUI_scrolling_min_y then
			GUI_scrolling_y_pos = GUI_scrolling_min_y
		elseif GUI_scrolling_y_pos < -GUI_scrolling_delta_y then
			GUI_scrolling_y_pos = -GUI_scrolling_delta_y
		end
	end
end
function states.run:draw ()
	self.drawableManager:drawDrawables()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.dbg, 0, screenHeight - 50)
end
--===========================================================
--== task creation & edition
--===========================================================
function states.createNewTask:load ()
	self.clickableManager = governance.newClickableManager()
	self.tname_button = governance.newTextBox("Nom de la tâche", 50)
	self.tincharge_button = governance.newTextBox("Personnes en charge", 130)
	self.cancel_button = governance.newButton("annuler", function()
		local width = box_width
		local height = box_height_2
		local x = screenWidth/2 - width/2
		local y = screenHeight - box_height_2*3
		return x,y,width,height
	end,
	function ()
		state = "run"
	end)
	self.newTask_button = governance.newButton("Ajouter", function()
		local width = box_width
		local height = box_height_2
		local x = screenWidth/2 - width/2
		local y = screenHeight - box_height_2 - height/2
		return x,y,width,height
	end,
	function ()
		local task_name = self.tname_button:retrieveInput()
		local task_incharge = self.tincharge_button:retrieveInput()
		client:send(string.format("newTask$%s\n", task_name))
		state = "run"
	end)

	self.cancel_button:setColor(.20,.24,.28)
	self.cancel_button:setTextColor(.71,.71,.71)
	-- self.newTask_button:setTextColor(180,180,180)

	self.clickableManager:addClickable(self.tname_button)
	self.clickableManager:addClickable(self.tincharge_button)
	self.clickableManager:addClickable(self.cancel_button)
	self.clickableManager:addClickable(self.newTask_button)
end
function states.createNewTask:update (dt)
	local clickable = self.clickableManager:getSelectedClikable()
	if last_clickable and not last_clickable.busy then
		last_clickable:unSelect()
		last_clickable = false
	end
	if clickable then
		if not clickable.busy then
			clickable:select(1)
		end
		if love.mouse.isDown(1) then
		elseif mouse.released then
			if last_busy then
				last_busy:unSelect()
				last_busy = false
			end
			if clickable.buffer then
				clickable:select(2)
				last_busy = clickable
				currentTextBox = clickable:action()
			else
				clickable:action()
			end
		end
		last_clickable = clickable
	end
end
function states.createNewTask:draw ()
	self.tname_button:draw()
	self.tincharge_button:draw()
	self.cancel_button:draw()
	self.newTask_button:draw()
end
--===========================================================
function states.editTask:load (label, numberId, rate, rated, rated_task)
	self.task_label = label
	self.task_numberId = numberId
	self.task_rate = rate
	self.task_rated = rated
	self.rated_task = rated_task

	self.task = governance.newTask(self.task_label, self.task_numberId, self.task_rate)
	self.clickableManager = governance.newClickableManager()
	self.dbg = screenHeight
	self.rate_button = governance.newCursorButton(screenHeight/2)
	self.cancel_button = governance.newButton("annuler", function ()
		local width = box_width
		local height = box_height_2
		local x = screenWidth/2 - width/2
		local y = screenHeight - box_height_2*6
		return x,y,width,height
	end,
	function() state = "run" end)
	self.submit_rate_button = governance.newButton("noter", function ()
		local width = box_width
		local height = box_height_2
		local x = screenWidth/2 - width/2
		local y = screenHeight - box_height_2*4.5
		return x,y,width,height
	end,
	function  ()
		if not self.rated_task.rated then
			local rate = self.rate_button:retrieveInput()
			client:send(string.format("rate$%d$%d\n", self.task_numberId, rate))
			self.rated_task.rated = true
			state = "run"
		end
	end)
	self.submit_solution_button = governance.newButton("soumettre solution", function ()
		local width = box_width
		local height = box_height_2
		local x = screenWidth/2 - width/2
		local y = screenHeight - box_height_2*3
		return x,y,width,height
	end,
	function  ()
		local rate = self.rate_button:retrieveInput()
		client:send(string.format("solution$%d$%d\n", self.task_numberId, rate))
		self.rated_task.rated = false
		state = "run"
	end)
	self.remove_button = governance.newButton("supprimer", function ()
		local width = box_width
		local height = box_height_2
		local x = screenWidth/2 - width/2
		local y = screenHeight - box_height_2 - height/2
		return x,y,width,height
	end,
	function  ()
		client:send(string.format("remove$%d\n", self.task_numberId))
		state = "run"
	end)

	self.cancel_button:setColor(.20, .24, .28)
	self.cancel_button:setTextColor(.78, .78, .78)
	self.submit_rate_button:setTextColor(.78, .78, .78)
	self.submit_solution_button:setColor(.25, .47, .63)
	self.submit_solution_button:setTextColor(.78, .78, .78)
	self.remove_button:setColor(.39, .20, .20)
	self.remove_button:setTextColor(.78, .78, .78)

	self.clickableManager:addClickable(self.rate_button)
	self.clickableManager:addClickable(self.cancel_button)
	self.clickableManager:addClickable(self.submit_rate_button)
	self.clickableManager:addClickable(self.submit_solution_button)
	self.clickableManager:addClickable(self.remove_button)
end
function states.editTask:update (dt)
	local t_w, t_h = box_width_2, screenHeight*0.4
	local t_x, t_y = screenWidth/2 - box_width_2/2, 0
	self.task:setPosition(t_x, t_y)
	self.task:setDimensions(t_w, t_h)

	-- output = string.format("label: %s\nnumberId: %d\nrated: %s", self.task_label, self.task_numberId, tostring(self.rated_task))

	local clickable = self.clickableManager:getSelectedClikable()
	if last_clickable and not last_clickable.busy then
		last_clickable:unSelect()
		last_clickable = false
	end
	if clickable then
		if not clickable.busy then
			clickable:select(1)
		end
		if love.mouse.isDown(1) then
			if clickable.is_cursor then
				clickable:action()
			end
		elseif mouse.released then
			if last_busy then
				last_busy:unSelect()
				last_busy = false
			end
			if clickable.buffer then
				clickable:select(2)
				last_busy = clickable
				currentTextBox = clickable:action()
			else
				clickable:action()
			end
		end
		last_clickable = clickable
	end
end
function states.editTask:draw ()
	self.rate_button:draw()
	self.cancel_button:draw()
	self.submit_rate_button:draw()
	self.submit_solution_button:draw()
	self.remove_button:draw()
	self.task:draw()
end

return states
