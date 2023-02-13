local socket = require "socket"
local governance = require "governance"
local states = require "states"

function love.load()
	love.window.maximize()
	-- io stufs
	love.keyboard.setKeyRepeat(true)
	currentTextBox = nil
	output = "client"
	console = ""
	-- graphic part
	os = love.system.getOS()
	toPixels = love.window.toPixels
	fromPixels = love.window.fromPixels
	screenWidth, screenHeight = love.window.fromPixels(love.graphics.getDimensions())
	mouse = {x=0,y=0, x2=0,y2=0, x3=0,y3=0, dx=0,dy=0}
	if os == "Android" then
		box_width = screenWidth*0.98
		box_width_2 = screenWidth
		box_height = 80
		box_height_2 = 40
		text_height = 60
		app_margin = screenWidth*0.02
		task_min_width = (screenWidth - app_margin*3)/2
		task_max_width = screenWidth - app_margin*2
		task_height = task_min_width
		button_font_size = 22
		text_font_size = 20
	else
		box_width = 500
		box_width_2 = box_width
		box_height = 80
		box_height_2 = 40
		text_height = 60
		app_margin = 10
		task_min_width = 160
		task_max_width = 320
		task_height = 160
		button_font_size = 22
		text_font_size = 20
	end
	GUI_scrolling = false
	GUI_scroll_click = false
	GUI_scroll_lock = false
	GUI_scroll_init = false
	GUI_scrolling_min_x = 0
	GUI_scrolling_max_x = 0
	GUI_scrolling_min_y = 0
	GUI_scrolling_max_y = 0
	GUI_scrolling_y_pos = 0
	GUI_scrolling_delta_y = 0
	-- network part
	client = 1
	-- states part
	state = "home"
	states[state]:load()
end

function love.textinput(text)
	if currentTextBox then
		currentTextBox:addToBuffer(text)
	end
end

function love.keypressed(key, scancode, isrepeat)
	if currentTextBox then
		if key == "backspace" then
			currentTextBox:bufferBackspace()
		end
	end
end

function love.update(dt)
	screenWidth, screenHeight = love.window.fromPixels(love.graphics.getDimensions())
	mouse.x3, mouse.y3 = mouse.x, mouse.y
	if love.mouse.isDown(1) then
		if GUI_scroll_click == false then
			GUI_scrolling = false
			GUI_scroll_init = false
		end
		while GUI_scroll_init == false do
			mouse.x, mouse.y = love.mouse.getPosition()
			mouse.x2, mouse.y2 = mouse.x, mouse.y
			mouse.dx, mouse.dy = mouse.x-mouse.x2, mouse.y-mouse.y2
			GUI_scroll_init = true
			GUI_scroll_click = true
		end
		mouse.x2, mouse.y2 = mouse.x, mouse.y
		mouse.x, mouse.y = love.mouse.getPosition()
		mouse.dx, mouse.dy = mouse.x-mouse.x2, mouse.y-mouse.y2
		if (mouse.dx ~= 0 or mouse.dy ~= 0 ) then
			GUI_scrolling = true
		end
	else
		mouse.x, mouse.y = love.mouse.getPosition()
		mouse.x2, mouse.y2 = mouse.x, mouse.y
		mouse.dx, mouse.dy = mouse.x-mouse.x2, mouse.y-mouse.y2
		if (mouse.x3 ~= mouse.x or mouse.y3 ~= mouse.y) and mouse.released == false then
			GUI_scrolling = false
			GUI_scroll_init = false
		end
		GUI_scroll_click = false
	end
	states[state]:update(dt)
	output = ""
	mouse.released = false
end

function love.mousereleased(x, y, button, isTouch)
	mouse.released = true
	-- GUI_scroll_click = false
end

function love.draw()
	love.graphics.setBackgroundColor(35/255, 36/255, 45/255, 1)
	states[state]:draw()
	love.graphics.setColor(200/255,200/255,200/255, 1)
	love.graphics.setNewFont(20)
	love.graphics.print(output)
end
