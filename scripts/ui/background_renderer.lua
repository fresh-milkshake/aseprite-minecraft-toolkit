
local BackgroundRenderer = {}

function BackgroundRenderer.draw_background(ctx, bg_type, custom_color)
    if bg_type == "transparent" then
        local tile_size = 8
        for y = 0, ctx.height - 1, tile_size do
            for x = 0, ctx.width - 1, tile_size do
                local is_light = ((math.floor(x / tile_size) + math.floor(y / tile_size)) % 2) == 0
                if is_light then
                    ctx.color = Color { red = 192, green = 192, blue = 192 }
                else
                    ctx.color = Color { red = 128, green = 128, blue = 128 }
                end
                ctx:fillRect(Rectangle(x, y, tile_size, tile_size))
            end
        end
    else
        ctx.color = custom_color or Color { red = 220, green = 220, blue = 220 }
        ctx:fillRect(Rectangle(0, 0, ctx.width, ctx.height))
    end
end

return BackgroundRenderer