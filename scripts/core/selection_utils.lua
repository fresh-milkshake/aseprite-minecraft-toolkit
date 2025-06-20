
local Constants = load_mc_module("core/constants.lua")
local SelectionUtils = {}

function SelectionUtils.is_valid_cell_selection()
    local sprite = app.activeSprite
    if not sprite then return false end

    local selection = sprite.selection
    if selection.isEmpty then return false end

    local bounds = selection.bounds
    return bounds.width == Constants.GRID_SIZE and bounds.height == Constants.GRID_SIZE
end

function SelectionUtils.get_current_cell_selection()
    local sprite = app.activeSprite
    if not sprite then return nil end

    local selection = sprite.selection
    if selection.isEmpty then return nil end

    local bounds = selection.bounds
    if bounds.width == Constants.GRID_SIZE and bounds.height == Constants.GRID_SIZE then
        return bounds
    end

    return nil
end

function SelectionUtils.create_cell_image(bounds)
    local sprite = app.activeSprite
    if not sprite then return nil end

    local cel = app.activeCel
    if not cel then return nil end

    local image = cel.image
    local cell_image = Image(Constants.GRID_SIZE, Constants.GRID_SIZE, image.colorMode)

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local src_x = bounds.x + x
            local src_y = bounds.y + y

            if src_x >= 0 and src_x < image.width and src_y >= 0 and src_y < image.height then
                local pixel = image:getPixel(src_x, src_y)
                cell_image:putPixel(x, y, pixel)
            end
        end
    end

    return cell_image
end

return SelectionUtils