local UIManager = require("ui/uimanager")
local misc = require("misc")
local _ = require("gettext")
local logger = require("logger")
local ButtonDialog = require("ui/widget/buttondialog")
local T = require("ffi/util").template
function ZLibraryBrowser:onConfig()
    local dialog
    dialog = ButtonDialog:new {
        title = "Config",
        buttons = {
            {
                {
                    text = _("Set download dir"),
                    callback = function() self:downloadDirFlow() end
                }
            },
            {
                {
                    text = _("Logout"),
                    callback = function()
                        self.settings.login = nil
                        self.settings.password = nil
                        self.settings.userid = nil
                        self.settings.userkey = nil
                        self:saveSettings()
                        self:loginFlow()
                    end
                }
            },
            {
                {
                    text = _("Languages"),
                    callback = function()
                        UIManager:close(dialog)
                        self:onLanguagePicker()
                    end
                }
            },
            {
                {
                    text = _("Extensions"),
                    callback = function()
                        UIManager:close(dialog)
                        self:onExtensionPicker()
                    end
                }
            },
            {
                {
                    text = T(_("Update (Current: %1)"), self.ZL_VERSION),
                    callback = function()
                        UIManager:close(dialog)
                        self:update()
                    end
                }
            },
            {
                {
                    text = _("Close"),
                    callback = function()
                        UIManager:close(dialog)
                    end
                }
            }
        }
    }
    UIManager:show(dialog)
end
