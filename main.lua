local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")

local _ = require("gettext")
local ZLibrary = WidgetContainer:new {
    name = 'zlibrary',
}
local zlibrarybrowser = require("zlibrarybrowser")


function ZLibrary:init()
    self.ui.menu:registerToMainMenu(self)
end

function ZLibrary:addToMainMenu(menu_items)
    if not self.ui.document then -- FileManager menu only
        menu_items.zlibrary = {
            text = _("Z-Library"),
            sorting_hint = "search",
            callback = function()
                self:onShowZLibrary()
            end,
        }
    end
end

function ZLibrary:onShowZLibrary()
    self.destinationselector = zlibrarybrowser:new {
        title = "Z-Library",
        is_popout = false,
        is_borderless = true,
        title_bar_fm_style = true,
        multilines_show_more_text = true
    }
    UIManager:show(self.destinationselector)
end

return ZLibrary
