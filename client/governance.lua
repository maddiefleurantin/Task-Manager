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
function governance.newTask (label, numberId, rate)
	local obj = {}
	setmetatable(obj, task)
	obj:__init(label, numberId, rate)
	return obj
end

task = {}
task.__index = task
function task:__init (label, numberId, rate)
	self.priority = 1
	self.label = label
	self.numberId = numberId
	self.title = love.graphics.newText(love.graphics.newFont(toPixels(text_font_size)), self.label)
	self.rate = rate or 5
	self.rated = false
	self.x = 0; self.y = 0; self.width = 0; self.height = 0
	self.good_r = 20; self.good_g = 255; self.good_b = 255
	self.bad_r = 255; self.bad_g = 60; self.bad_b = 20
	self:setRate(self.rate, "solution")
end
function task:setPosition (x,y)
	self.x = x; self.y = y
end
function task:setDimensions (w,h)
	self.width = w; self.height = h
end
function task:action ()
	state = "editTask"
	states[state]:load(self.label, self.numberId, self.rate, self.rated, self)
end
function task:select ()
	self.red = self.sred; self.green = self.sgreen; self.blue = self.sblue; self.alpha = self.salpha
end
function task:unSelect ()
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function task:setRate (rate, type)
	if type == "solution" then
		self.rated = false
	end
	self.rate = rate
	local percent = ((self.rate-1) * 100/4)*0.01
	local red,green,blue = self.good_r-self.bad_r, self.good_g-self.bad_g, self.good_b-self.bad_b
	self.nred = self.bad_r+red*percent; self.ngreen = self.bad_g+green*percent; self.nblue = self.bad_b+blue*percent
	self.sred = self.nred*0.7; self.sgreen = self.ngreen*0.7; self.sblue = self.nblue*0.8
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue
	-- output = string.format("rate: ")
end
function task:draw ()
	love.graphics.setColor(self.red,self.green,self.blue,255)
	love.graphics.rectangle("fill", toPixels(self.x), toPixels(self.y), toPixels(self.width), toPixels(self.height))
	love.graphics.setColor(self.red*0.45, self.green*0.45, self.blue*0.45, 255)
	self.title:set(self.label)
	-- output = output..string.format("\ntitle pos x: %d, x: %d, w: %d, tw: %d", self.x+(self.width/2)-(self.title:getWidth()/2), self.x, self.width, self.title:getWidth())
	love.graphics.draw(self.title, toPixels(self.x+(self.width/2))-(self.title:getWidth()/2), toPixels(self.y))
end

--========================================================
--== task board object
--========================================================
function governance.newTaskManager ()
	local obj = setmetatable({}, taskManager)
	obj:__init()
	return obj
end

taskManager = {}
taskManager.__index = taskManager
function taskManager:__init ()
	self.container = {}
	self.draw_cursor = {x = 0, y = 0}
end
function taskManager:addTask (task)
	table.insert(self.container,getId(task, self), task)
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
	local obj = self.container[no]
	return obj
end
function taskManager:updateTasksPosition ()
	self.draw_cursor.x, self.draw_cursor.y = 0,0+app_margin
	local count = self:countTasks()
	output = string.format("screenWidth: %d\ncount: %d", screenWidth, count)
	local width = (screenWidth - (app_margin*(count+1)))/count
	-- output = output..string.format("\napp_margin: %d\ntask_min_width: %d\ntask_max_width: %d\nvacant width: %d", app_margin,task_min_width,task_max_width,width)
	if width < task_min_width then
		local count1 = count-1
		while width < task_min_width do
			width = (screenWidth - (app_margin*(count1+1)))/count1
			count1 = count1 - 1
			if count1 < 1 then
				width = task_min_width
			end
		end
	elseif width > task_max_width then
		width = task_max_width
	end
	-- output = output.."\nfinal width: "..width
	for i,utask in ipairs(self.container) do
		self.draw_cursor.x = self.draw_cursor.x + app_margin
		utask:setPosition(self.draw_cursor.x, self.draw_cursor.y)
		utask:setDimensions(width, task_height)
		self.draw_cursor.x = self.draw_cursor.x + width
		if self.draw_cursor.x + width + app_margin*2 > screenWidth and i < count then
			-- output = output.."\nlast crs pos: "..self.draw_cursor.x + width + app_margin*2
			self.draw_cursor.x = 0; self.draw_cursor.y = self.draw_cursor.y + task_height + app_margin
			GUI_scrolling_max_y = self.draw_cursor.y + task_height + app_margin
		end
	end
	if GUI_scrolling_max_y < screenHeight then
		GUI_scrolling_max_y = screenHeight + 75
	end
	self:scrollTasks()
end
function taskManager:scrollTasks ()
	for i,v in ipairs(self.container) do
		v.y = v.y + GUI_scrolling_y_pos
	end
end
function taskManager:close ()
	self.container = nil
	self = nil
end

function getId (obj, host)
	if obj.numberId then
		return obj.numberId
	else
		local idCount = 0
		for i,v in ipairs(host.container) do
			idCount = i
		end
		obj.numberId = idCount + 1
		return obj.numberId
	end
end

--========================================================
--== buttons & text boxes
--========================================================
function governance.boxCollision (box, mouse)
	if box.x then
		return toPixels(box.x) <= mouse.x and
			toPixels(box.x) + toPixels(box.width) > mouse.x and
			toPixels(box.y) <= mouse.y and
			toPixels(box.y) + toPixels(box.height) > mouse.y
	end
end
--========================================================
function governance.newClickableManager (label)
	local obj = setmetatable({}, clickableManager)
	obj:__init(label)
	return obj
end
function governance.newDrawableManager (label)
	local obj = setmetatable({}, drawableManager)
	obj:__init(label)
	return obj
end

clickableManager = {}
clickableManager.__index = clickableManager
function clickableManager:__init (label)
	self.container = {}
	self.label = label
end
function clickableManager:addClickable (clickable)
	table.insert(self.container, getId(clickable, self), clickable)
end
function clickableManager:removeClickable (clickable_id)
	table.remove(self.container, clickable_id)
	for i,v in ipairs(self.container) do
		if i ~= v.numberId then
			v.numberId = i
		end
	end
end
function clickableManager:getSelectedClikable ()
	local clickable_id, clickable_priority = 0,0
	for i,clickable in ipairs(self.container) do
		-- output = i
		if governance.boxCollision(clickable, mouse) and clickable.priority > clickable_priority then
			clickable_priority = clickable.priority
			clickable_id = i
		end
	end
	return self.container[clickable_id]
end
function clickableManager:close ()
	self.container = nil
	self = nil
end
--=============================================
drawableManager = {}
drawableManager.__index = drawableManager
function drawableManager:__init (label)
	self.container = {}
	self.label = label
end
function drawableManager:addDrawable (drawable)
	table.insert(self.container, getId(drawable, self), drawable)
end
function drawableManager:drawDrawables ()
	for i,drawable in ipairs(self.container) do
		drawable:draw()
	end
end
function drawableManager:removeDrawable (drawable_id)
	table.remove(self.container, drawable_id)
	for i,v in ipairs(self.container) do
		if i ~= v.numberId then
			v.numberId = i
		end
	end
end
function drawableManager:close ()
	self.container = nil
	self = nil
end
--===============================================

function governance.newButton (label, setPositionAndDimensions, action, priority)
	local obj = setmetatable({}, button)
	obj:__init(label, setPositionAndDimensions, action, priority)
	return obj
end

button = {}
button.__index = button
function button:__init (label, setPositionAndDimensions, action, priority)
	self.priority = priority or 1
	self.label = label
	self.text = love.graphics.newText(love.graphics.setNewFont(toPixels(button_font_size)), self.label)
	self.action = action
	self.setPositionAndDimensions = setPositionAndDimensions
	self.percent = 0.8
	self.nred = 20; self.ngreen = 160; self.nblue = 80; self.nalpha = 255
	self.tred = 10; self.tgreen = 80; self.tblue = 60; self.talpha = 255
	self.sred = self.nred*self.percent; self.sgreen = self.ngreen*self.percent; self.sblue = self.nblue*self.percent; self.salpha = self.nalpha
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function button:select ()
	self.red = self.sred; self.green = self.sgreen; self.blue = self.sblue; self.alpha = self.salpha
end
function button:unSelect ()
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function button:setColor (r,g,b,a)
	self.nred = r or self.nred; self.ngreen = g or self.ngreen; self.nblue = b or self.nblue; self.nalpha = a or self.nalpha
	self.sred = self.nred*self.percent; self.sgreen = self.ngreen*self.percent; self.sblue = self.nblue*self.percent; self.salpha = self.nalpha
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function button:setTextColor (r,g,b,a)
	self.tred = r or self.tred; self.tgreen = g or self.tgreen; self.tblue = b or self.tblue; self.talpha = a or self.talpha
end
function button:draw ()
	self.x, self.y, self.width, self.height = self.setPositionAndDimensions()
	love.graphics.setColor(self.red, self.green, self.blue, self.alpha)
	love.graphics.rectangle("fill", toPixels(self.x), toPixels(self.y), toPixels(self.width), toPixels(self.height))
	love.graphics.setColor(self.tred, self.tgreen, self.tblue, self.talpha)
	love.graphics.draw(self.text, toPixels(self.x) + toPixels(self.width/2) - self.text:getWidth()/2, toPixels(self.y) + toPixels(self.height/2) - self.text:getHeight()/2)
end
--===============================================
function governance.newTextBox (label, y_pos, priority)
	local obj = setmetatable({}, textBox)
	obj:__init(label, y_pos, priority)
	return obj
end

textBox = {}
textBox.__index = textBox
function textBox:__init (label, y_pos, priority)
	self.priority = priority or 1
	self.label = label
	self.input = ""
	self.cursor = ""
	self.buffer = {}
	self.text = love.graphics.newText(love.graphics.newFont(toPixels(text_font_size)), self.label)
	self.action = function ()
		love.keyboard.setTextInput(true)
		return self
	end
	self.y_pos = y_pos
	self.percent = 0.8
	self.nred = 200; self.ngreen = 200; self.nblue = 200; self.nalpha = 255
	self.sred = self.nred*self.percent; self.sgreen = self.ngreen*self.percent; self.sblue = self.nblue*self.percent; self.salpha = self.nalpha
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function textBox:addToBuffer (text)
	table.insert(self.buffer,text)
	self.input = table.concat(self.buffer)
end
function textBox:bufferBackspace ()
	table.remove(self.buffer)
	self.input = table.concat(self.buffer)
end
function textBox:setText ()
	self.text:set(self.input..self.cursor)
end
function textBox:retrieveInput ()
	return self.input
end
function textBox:select (n)
	if n == 1 then
		self.red = self.sred; self.green = self.sgreen; self.blue = self.sblue; self.alpha = self.salpha
	elseif n == 2 then
		self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
		self.cursor = "_"
		self.busy = true
	end
end
function textBox:unSelect ()
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
	self.cursor = ""
	self.busy = false
end
function textBox:draw()
	self:setText()
	local w,h = self.text:getDimensions()
	self.width = box_width
	self.height = text_height
	self.x = screenWidth/2-self.width/2
	self.y = self.y_pos-self.height/2
	love.graphics.setColor(self.red, self.green, self.blue, self.alpha)
	love.graphics.rectangle("fill", toPixels(self.x), toPixels(self.y), toPixels(self.width), toPixels(self.height))
	love.graphics.setColor(200, 200, 200, 255)
	love.graphics.setNewFont(toPixels(text_font_size*0.8))
	love.graphics.print(self.label, toPixels(self.x), toPixels(self.y-text_font_size*0.8))
	love.graphics.setColor(60, 60, 60, 255)
	love.graphics.draw(self.text, toPixels(self.x)+10, toPixels(self.y)+toPixels(self.height)/2-h/2)
end
--=========================================================
function governance.newCursorButton (y_pos)
	local obj = setmetatable({}, cursorButton)
	obj:__init(y_pos)
	return obj
end
cursorButton = {}
cursorButton.__index = cursorButton
function cursorButton:__init (y_pos)
	self.priority = 1
	self.input = 5
	self.is_cursor = true
	self.y_pos = y_pos
	self.nred = 50; self.ngreen = 60; self.nblue = 80; self.nalpha = 0
	self.sred = self.nred; self.sgreen = self.ngreen; self.sblue = self.nblue; self.salpha = 20
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function cursorButton:action ()
	local unit = toPixels(self.width/5)
	local new_input = math.floor((mouse.x - toPixels(self.x))/unit+1)
	-- output = string.format("%d\n%d", unit, new_input)
	self.input = new_input
end
function cursorButton:select ()
	self.red = self.sred; self.green = self.sgreen; self.blue = self.sblue; self.alpha = self.salpha
end
function cursorButton:unSelect ()
	self.red = self.nred; self.green = self.ngreen; self.blue = self.nblue; self.alpha = self.nalpha
end
function cursorButton:retrieveInput ()
	return self.input
end
function cursorButton:draw ()
	self.width = box_width
	self.height = text_height
	self.x = screenWidth/2-self.width/2
	self.y = self.y_pos-self.height/2
	love.graphics.setColor(self.red, self.green, self.blue, self.alpha)
	love.graphics.rectangle("fill", toPixels(self.x), toPixels(self.y), toPixels(self.width), toPixels(self.height))
	local star_rad = self.height/2
	local star_margin = (self.width - (star_rad*2)*5)/5
	local star_x = self.x+star_rad+star_margin/2
	for i=1,5 do
		if i <= self.input then
			love.graphics.setColor(200, 200, 200, 255)
		else
			love.graphics.setColor(50, 60, 80, 255)
		end
		love.graphics.circle("fill", toPixels(star_x), toPixels(self.y+self.height/2), toPixels(star_rad), 4)
		star_x = star_x + star_rad*2 + star_margin
	end
end

return governance
