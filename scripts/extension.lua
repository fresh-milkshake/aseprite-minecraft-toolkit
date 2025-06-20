
local script_path = debug.getinfo(1, "S").source:match("@(.*)")
local extension_dir = script_path:match("(.*/)")
if not extension_dir then
    extension_dir = script_path:match("(.*\\)")
end
if not extension_dir then
    extension_dir = ""
end

_G.load_mc_module = function(path)
    return dofile(extension_dir .. path)
end

local Render3D = load_mc_module("features/render_3d.lua")
local HueShift = load_mc_module("features/hue_shift.lua")
local Export = load_mc_module("features/export.lua")
local RenderAdjacent = load_mc_module("features/render_adjacent.lua")
local IntermediateColors = load_mc_module("features/intermediate_colors.lua")

function init(plugin)

    plugin:newMenuGroup {
        id = "mc_toolkit_menu_group",
        title = "MC Toolkit",
        group = "sprite_crop"
    }

    Render3D.create_command(plugin)

    HueShift.create_command(plugin)

    RenderAdjacent.create_command(plugin)

    IntermediateColors.create_command(plugin)

    Render3D.start_global_timer()

    plugin:newMenuSeparator {
        id = "mc_toolkit_menu_separator",
        group = "mc_toolkit_menu_group"
    }

    Export.create_command(plugin)
end

function exit(plugin)
    if Render3D and Render3D.stop_all_timers then
        Render3D.stop_all_timers()
    end
    if RenderAdjacent and RenderAdjacent.stop_all_timers then
        RenderAdjacent.stop_all_timers()
    end
end