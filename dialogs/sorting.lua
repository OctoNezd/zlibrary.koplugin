local UIManager = require("ui/uimanager")
local misc = require("misc")
local _ = require("gettext")
local logger = require("logger")
local ButtonDialog = require("ui/widget/buttondialog")

local ORDERABLES = {
    "search_", "saved_", "downloaded"
}

local ORDERS = {
    { key = "popular",   text = _("Popular") },
    { key = "bestmatch", text = _("Best match") },
    { key = "date",      text = _("Recently added") },
    { key = "titleA",    text = _("A to Z") },
    { key = "title",     text = _("Z to A") },
    { key = "year",      text = _("Year") },
    { key = "filesize",  text = _("From biggest to smallest") },
    { key = "filesizeA", text = _("From smallest to biggest") }
}


function ZLibraryBrowser:onLeftButtonTap()
    local dialog
    local buttons = {}
    for _, item in pairs(ORDERS) do
        local ordertext = item.text
        local orderkey = item.key
        table.insert(buttons, { {
            text = ordertext,
            callback = function()
                self.settings.order = orderkey
                self:saveSettings()
                UIManager:close(dialog)
                for _, orderable in pairs(ORDERABLES) do
                    if misc.startswith(self.last_action, orderable) then
                        logger.info("We are in orderable, refreshing")
                        self:onGotoPage(1)
                    end
                end
            end
        } })
    end
    dialog = ButtonDialog:new {
        title = "Sort by...",
        buttons = buttons
    }
    UIManager:show(dialog)
end
