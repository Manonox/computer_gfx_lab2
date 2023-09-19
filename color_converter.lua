local math_max, math_min, math_abs = math.max, math.min, math.abs


return {
    rgb2hsv = function(r, g, b)
        local mx, mn = math_max(r, g, b), math_min(r, g, b)
        local c = mx - mn
        local k = 1.0 / (6.0 * c)
        local h = 0.0
        if c ~= 0.0 then
            if mx == r then     h = ((g - b) * k) % 1.0
            elseif mx == g then h = (b - r) * k + 1.0/3.0
            else                h = (r - g) * k + 2.0/3.0
            end
        end
        return h, mx == 0.0 and 0.0 or c / mx, mx
    end,


    hsv2rgb = function(h, s, v)
        local c = v * s
        local m = v - c
        local r, g, b = m, m, m
        if h == h then
            local h_ = (h % 1.0) * 6
            local x = c * (1 - math_abs(h_ % 2 - 1))
            c, x = c + m, x + m
            if     h_ < 1 then r, g, b = c, x, m
            elseif h_ < 2 then r, g, b = x, c, m
            elseif h_ < 3 then r, g, b = m, c, x
            elseif h_ < 4 then r, g, b = m, x, c
            elseif h_ < 5 then r, g, b = x, m, c
            else               r, g, b = c, m, x
            end
        end
        return r, g, b
    end,
}