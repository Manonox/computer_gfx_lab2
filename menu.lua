local ffi = require("ffi")
local imgui = require("cimgui")
local color_converter = require("color_converter")
local rgb2hsv = color_converter.rgb2hsv
local hsv2rgb = color_converter.hsv2rgb
local menu = {}

menu.bar = {
    File = {
        Save = {
            func = function(self)
                print("Saving...")
                self.menu.currentImageData:encode("png", "output.png")
            end
        }
    }
}

menu.tools = {
    {
        name = "HSV",

        hsv = ffi.new("float[3]"),
        preview = ffi.new("bool[1]"),
        debounce = nil,


        init = function(self)
            self.hsv[0] = 0
            self.hsv[1] = 1
            self.hsv[2] = 1
        end,

        draw = function(self)
            local hsv_changed = imgui.ColorEdit3(
                "HSV Modifier",
                self.hsv,
                imgui.love.ColorEditFlags("InputHSV", "PickerHueWheel", "DisplayHSV")
            )

            local preview_changed = imgui.Checkbox("Preview HSV", self.preview)

            if hsv_changed and not self.debounce then
                self.debounce = 0.01
            end

            if preview_changed then
                self.menu:scheduleProcess()
            end
        end,
        
        update = function(self, dt)
            if not self.debounce then return end
            
            if self.menu.image then
                self.debounce = self.debounce - dt
            end
            if self.debounce < 0 then
                self.debounce = nil
                self.menu:scheduleProcess()
            end
        end,
        

        process = function(self, imageData)
            local hsv = self.hsv
            local mod_h, mod_s, mod_v = hsv[0], hsv[1], hsv[2]
            local preview = self.preview[0]
            imageData:mapPixel(function(x, y, r, g, b, a)
                local h, s, v = rgb2hsv(r, g, b)
                h = (h + mod_h) % 1
                s = s * mod_s
                v = v * mod_v
                if preview then return h, s, v, a end
                r, g, b = hsv2rgb(h, s, v)
                return r, g, b, a
            end)
        end,
    },

    {
        name = "Channels",

        channel_r = ffi.new("bool[1]"),
        channel_g = ffi.new("bool[1]"),
        channel_b = ffi.new("bool[1]"),
        channel_a = ffi.new("bool[1]"),

        init = function(self)
            self.channel_r[0] = true
            self.channel_g[0] = true
            self.channel_b[0] = true
            self.channel_a[0] = true
        end,

        colored_button_vec4 = function(hue, brightness)
            local r, g, b = hsv2rgb(hue, brightness, brightness)
            return imgui.ImVec4_Float(r, g, b, 1)
        end,

        draw = function(self)
            local clicked = false
            local c = {{"R", self.channel_r}, {"G", self.channel_g}, {"B", self.channel_b}}
            local white_vec = imgui.ImVec4_Float(1, 1, 1, 1)
            for i, channel in ipairs(c) do
                if i > 1 then imgui.SameLine() end
                imgui.PushID_Int(i - 1)
                imgui.PushStyleColor_Vec4(imgui.ImGuiCol_FrameBg, self.colored_button_vec4((i - 1) / 3, 0.6))
                imgui.PushStyleColor_Vec4(imgui.ImGuiCol_FrameBgHovered, self.colored_button_vec4((i - 1) / 3, 0.7))
                imgui.PushStyleColor_Vec4(imgui.ImGuiCol_FrameBgActive, self.colored_button_vec4((i - 1) / 3, 0.8))
                imgui.PushStyleColor_Vec4(imgui.ImGuiCol_CheckMark, white_vec)

                if imgui.Checkbox(channel[1], channel[2]) then
                    clicked = true
                end
                imgui.PopStyleColor(4)
                imgui.PopID()
            end

            imgui.SameLine()
            imgui.PushID_Int(3)
            imgui.PushStyleColor_Vec4(imgui.ImGuiCol_FrameBg, imgui.ImVec4_Float(0.3, 0.3, 0.3, 1))
            imgui.PushStyleColor_Vec4(imgui.ImGuiCol_FrameBgHovered, imgui.ImVec4_Float(0.4, 0.4, 0.4, 1))
            imgui.PushStyleColor_Vec4(imgui.ImGuiCol_FrameBgActive, imgui.ImVec4_Float(0.5, 0.5, 0.5, 1))
            imgui.PushStyleColor_Vec4(imgui.ImGuiCol_CheckMark, white_vec)

            if imgui.Checkbox("A", self.channel_a) then
                clicked = true
            end
            imgui.PopStyleColor(4)
            imgui.PopID()

            if clicked then
                self.menu:scheduleProcess()
            end
        end,

        process = function(self, imageData)
            local reset_r = not self.channel_r[0]
            local reset_g = not self.channel_g[0]
            local reset_b = not self.channel_b[0]
            local reset_a = not self.channel_a[0]

            imageData:mapPixel(function(x, y, r, g, b, a)
                if reset_r then r = 0 end
                if reset_g then g = 0 end
                if reset_b then b = 0 end
                if reset_a then a = 0 end
                return r, g, b, a
            end)
        end
    },

    {
        name = "Monochrome",
        mode = ffi.new("int[1]"),
        modes = {"Normal", "HSV - Value", "CIE - Y"},
        c_modes = {},
        c_modes_arr = nil,

        init = function(self)
            self.c_modes_arr = ffi.new("const char*[?]", #self.modes)
            for i, mode in ipairs(self.modes) do
                local s = ffi.new("const char[?]", #mode, mode)
                self.c_modes[i] = s
                self.c_modes_arr[i - 1] = s
            end
        end,

        draw = function(self)
            if imgui.Combo_Str_arr("Mode", self.mode, self.c_modes_arr, #self.modes, #self.modes) then
                self.menu:scheduleProcess()
            end
        end,

        process = function(self, imageData)
            local mode = self.mode[0]
            local math_max = math.max
            imageData:mapPixel(function(x, y, r, g, b, a)
                if mode == 1 then
                    local value = math_max(r, g, b)
                    return value, value, value, 1
                elseif mode == 2 then
                    local lightness = 0.222 * r + 0.707 * g + 0.071 * b
                    return lightness, lightness, lightness, 1
                end
                return r, g, b, a
            end)
        end,
    }
}

function menu:init()
    menu.visible = self.image ~= nil
end


function menu:drawMenubar()
    if not imgui.BeginMenuBar() then return end
    for group_name, group in pairs(self.bar) do
        if imgui.BeginMenu(group_name) then
            for item_name, item in pairs(group) do
                item.menu = self
                if imgui.MenuItem_Bool(item_name) then
                    item:func()
                end
            end

            imgui.EndMenu()
        end
    end

    imgui.EndMenuBar()
end


function menu:drawTools()
    for _, tool in pairs(self.tools) do
        if tool.init then
            tool:init()
            tool.init = false
            tool.menu = self
        end

        if imgui.CollapsingHeader_TreeNodeFlags(tool.name, imgui.love.TreeNodeFlags("CollapsingHeader")) then
            tool:draw()
        end
    end
end


function menu:process()
    local imageDataCopy = self.imageData:clone()
    for _, tool in pairs(self.tools) do
        if tool.process then
            tool:process(imageDataCopy)
        end
    end
    self.image:replacePixels(imageDataCopy)
    self.currentImageData = imageDataCopy
end

function menu:scheduleProcess()
    self:process()
end


function menu:draw()
    if not self.visible then return end

    if not imgui.Begin("Menu", nil, imgui.ImGuiWindowFlags_MenuBar) then
        imgui.End()
        return
    end

    menu:drawMenubar()
    menu:drawTools()

    imgui.End()
end


function menu:update(dt)
    if menu.init then
        menu:init()
        menu.init = false
    end

    for group_name, group in pairs(self.bar) do
        if group.update then
            group:update(dt)
        end
    end

    for _, tool in pairs(self.tools) do
        if tool.update then
            tool:update(dt)
        end
    end
end



return menu