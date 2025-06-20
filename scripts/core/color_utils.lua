
local ColorUtils = {}

function ColorUtils.hsl_to_rgb(h, s, l)
    h = h / 360
    local r, g, b

    if s == 0 then
        r, g, b = l, l, l
    else
        local function hue_to_rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1 / 3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1 / 3)
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

function ColorUtils.rgb_to_hsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max == min then
        h, s = 0, 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)

        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h * 360, s, l
end

function ColorUtils.interpolate_hsl(color1, color2, factor)
    local h1, s1, l1 = ColorUtils.rgb_to_hsl(color1.red, color1.green, color1.blue)
    local h2, s2, l2 = ColorUtils.rgb_to_hsl(color2.red, color2.green, color2.blue)

    local h_diff = h2 - h1
    if h_diff > 180 then
        h_diff = h_diff - 360
    elseif h_diff < -180 then
        h_diff = h_diff + 360
    end

    local h_interp = (h1 + h_diff * factor) % 360
    local s_interp = s1 + (s2 - s1) * factor
    local l_interp = l1 + (l2 - l1) * factor

    local r, g, b = ColorUtils.hsl_to_rgb(h_interp, s_interp, l_interp)

    return Color{
        red = r,
        green = g,
        blue = b,
        alpha = math.floor(color1.alpha + (color2.alpha - color1.alpha) * factor)
    }
end

return ColorUtils