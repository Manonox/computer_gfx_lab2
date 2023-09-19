local t = 0
local current_image
local current_imageData

local imgui = require("cimgui") -- cimgui is the folder containing the Lua module (the "src" folder in the github repository)
local menu = require("menu")


function love.load()
    imgui.love.Init()
    love.graphics.setBackgroundColor(31 / 255, 31 / 255, 31 / 255, 1)
    if love.filesystem.getInfo("target.jpg") then
        current_imageData = love.image.newImageData("target.jpg")
        current_image = love.graphics.newImage(current_imageData)
    end
end


function love.update(dt)
    t = t + dt
    menu.image = current_image
    menu.imageData = current_imageData
    menu:update(dt)

    imgui.love.Update(dt)
    imgui.NewFrame()
end


local function draw_swaying_text(x, y)
    local font = love.graphics.getFont()
    local text = "Drag and drop an image..."
    local w, h = font:getWidth(text), font:getHeight()
    
    love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(math.sin(t) * 0.1)
        love.graphics.translate(-w / 2, -h / 2)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.print(text)
    love.graphics.pop()
end

local function draw_current_image(x, y, w, h)
    local cx, cy = x + w / 2, y + h / 2
    if not current_image then
        draw_swaying_text(cx, cy)
        return
    end


    local iw, ih = current_image:getDimensions()
    local mul_w, mul_h = w / iw, h / ih
    local min_mul = math.min(mul_w, mul_h)
    
    --love.graphics.rectangle("line", x, y, w, h)
    love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.scale(min_mul)
        love.graphics.translate(-iw / 2, -ih / 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_image)
    love.graphics.pop()
end


local function draw_menu_opener(x, y, w, h)
    local _, my = love.mouse.getPosition()
    local b = my < h and (love.mouse.isDown(1) and 0.2 or 0.4) or 0.3
    if imgui.love.GetWantCaptureMouse() then b = 0.3 end
    love.graphics.setColor(b, b, b, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.push()
        local font = love.graphics.getFont()
        local text = (menu.visible and "Hide" or "Show") .. " menu"
        local tw, th = font:getWidth(text), font:getHeight()
        love.graphics.translate(x + w / 2 - tw / 2, y + h / 2 - th / 2)
        love.graphics.print(text)
    love.graphics.pop()
end


function love.draw()
    local w, h = love.graphics.getDimensions()

    draw_menu_opener(0, 0, w, 32)

    --love.graphics.translate(100, 100)
    --love.graphics.rectangle("line", 0, 0, w, h)
    draw_current_image(0, 32, w, h - 32)
    
    love.graphics.setColor(1, 1, 1, 1)
    menu:draw()
    imgui.ShowDemoWindow()

    imgui.Render()
    imgui.love.RenderDrawLists()
end


function love.filedropped(file)
    file:open("r")
    current_imageData = file:read("data")
    file:close()
    
	current_image = love.graphics.newImage(current_imageData)
end


love.mousemoved = function(x, y, ...)
    imgui.love.MouseMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here
    end
end

love.mousepressed = function(x, y, button, ...)
    imgui.love.MousePressed(button)
    if not imgui.love.GetWantCaptureMouse() then
        if y < 32 then
            menu.visible = not menu.visible
        end
    end
end

love.mousereleased = function(x, y, button, ...)
    imgui.love.MouseReleased(button)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end

love.wheelmoved = function(x, y)
    imgui.love.WheelMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end

love.keypressed = function(key, ...)
    imgui.love.KeyPressed(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.keyreleased = function(key, ...)
    imgui.love.KeyReleased(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.textinput = function(t)
    imgui.love.TextInput(t)
    if imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.quit = function()
    return imgui.love.Shutdown()
end
