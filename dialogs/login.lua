local logger = require("logger")
local MultiInputDialog = require("ui/widget/multiinputdialog")
local UIManager = require("ui/uimanager")
local CheckButton = require("ui/widget/checkbutton")
local _ = require("gettext")
function ZLibraryBrowser:loginFlow(callback)
    local remembered_login = self.settings.login and self.settings.login or ""
    if remembered_login ~= "" then
        logger.info("trying to log in with remembered log/pass")
        if self:login(self.settings.endpoint, self.settings.login, self.settings.password) then
            return
        end
        logger.err("failed to log in with remembered password")
    else
        logger.info("no saved log/pass")
    end
    local dialog, remember_me
    local fields = {
        {
            hint = "Z-Library instance (starting with https://, WITHOUT / AT THE END)"
        },
        {
            hint = "Login"
        },
        {
            hint = "Password",
            text_type = "password"
        }
    }
    dialog = MultiInputDialog:new {
        fields = fields,
        title = _("Please log in"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    callback = function()
                        UIManager:close(dialog)
                    end
                },
                {
                    text = _("Login"),
                    callback = function()
                        local fields = dialog:getFields()
                        local endpoint = fields[1]
                        local login = fields[2]
                        local password = fields[3]
                        if self:login(endpoint, login, password, remember_me.checked) then
                            UIManager:close(dialog)
                        end
                        callback()
                    end
                }
            }
        }
    }
    remember_me = CheckButton:new {
        text = _("Remember me"),
        parent = dialog,
        checked = true,
    }
    dialog:addWidget(remember_me)
    dialog:onShowKeyboard()
    UIManager:nextTick(function() UIManager:show(dialog) end)
end
