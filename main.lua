local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui.widget.infomessage")

local _ = require("gettext")
local ZLibrary = WidgetContainer:new {
    name = 'zlibrary',
}
local zlibrarybrowser = require("zlibrarybrowser")
local NetworkMgr = require("ui/network/manager")

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

function ZLibrary:openZLibMenu()
    self.destinationselector = zlibrarybrowser:new {
        title = "Z-Library",
        is_popout = false,
        is_borderless = true,
        title_bar_fm_style = true,
        multilines_show_more_text = true
    }
    UIManager:show(self.destinationselector)
end

function ZLibrary:onShowZLibrary()
    if not NetworkMgr:isOnline() then
        NetworkMgr:turnOnWifiAndWaitForConnection(function()
            UIManager:scheduleIn(2, function() self:openZLibMenu() end)
        end)
        return
    end
    self:openZLibMenu()
end

return ZLibrary
