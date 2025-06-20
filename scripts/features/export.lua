
local Constants = load_mc_module("core/constants.lua")
local SelectionUtils = load_mc_module("core/selection_utils.lua")

local Export = {}

function Export.create_command(plugin)
    return plugin:newCommand {
        id = "MCToolkitExport",
        title = "Export Selection",
        group = "mc_toolkit_menu_group",
        onenabled = function()
            return app.activeSprite ~= nil and SelectionUtils.is_valid_cell_selection()
        end,
        onclick = function()
            Export.export_selection()
        end
    }
end

function Export.export_selection()
    local bounds = SelectionUtils.get_current_cell_selection()
    if not bounds then
        app.alert("Please select a 16x16 cell to export")
        return
    end

    local original_selection = app.activeSprite.selection
    local had_selection = not original_selection.isEmpty

    app.activeSprite.selection:select(Rectangle(bounds.x, bounds.y, bounds.width, bounds.height))

    app.command.SaveFileCopyAs()

    if had_selection then
        app.activeSprite.selection = original_selection
    else
        app.activeSprite.selection:deselect()
    end
end

return Export