local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local _ = require("gettext")
function ZLibraryBrowser:onSearchMenuItem()
    local dialog
    dialog = InputDialog:new {
        title = _("Search Z-Library"),
        input_hint = _("Do Androids Dream of Electric Sheep?"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("Search"),
                    id = "search",
                    is_enter_default = true,
                    callback = function()
                        local query = dialog:getInputText()
                        logger.info("Searching for", query)
                        UIManager:close(dialog)
                        self:onMenuSelect({
                            action = "search_" .. query
                        })
                    end
                }
            }
        }
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end
