local _ = require("gettext")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")

function ZLibraryBrowser:onSearchHistory()
    local items = {}
    if #self.settings.history == 0 then
        UIManager:show(InfoMessage:new {
            text = "No search history!"
        })
        return
    end
    table.insert(self.paths, {
        title = _("Search history"),
        action = "searchhistory"
    })
    for _, item in pairs(self.settings.history) do
        table.insert(items, {
            text = item,
            action = "search_" .. item
        })
    end
    self:switchItemTable(_("Search history"), items)
end
