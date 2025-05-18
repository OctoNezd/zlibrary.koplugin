local util = require("util")
local Device = require("device")
local InputDialog = require("ui/widget/inputdialog")
local _ = require("gettext")
local UIManager = require("ui/uimanager")
local logger = require("logger")

function ZLibraryBrowser:downloadDirFlow()
    local dialog
    local suggested_dir = ""
    if Device:isKindle() then
        suggested_dir = "/mnt/us/books"
    end
    dialog = InputDialog:new {
        title = _("You dont have download directory set."),
        input = suggested_dir,
        input_hint = _("E.g. /Users/octo/books"),
        buttons = {
            {
                {
                    text = _("Set"),
                    id = "set",
                    is_enter_default = true,
                    callback = function()
                        local path = dialog:getInputText()
                        self.settings.download_dir = path
                        self:saveSettings()
                        logger.info(util.makePath(path))
                        UIManager:close(dialog)
                    end
                }
            }
        }
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end
