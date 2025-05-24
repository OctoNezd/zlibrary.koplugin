local _ = require("gettext")
function ZLibraryBrowser:onExtensionPicker(update)
    local extensions = self:request("/eapi/info/extensions")
    if not extensions then return end
    local indicator_on = "☑ "
    local indicator_off = "☐ "
    local all_active = indicator_off
    if self.settings.extensions == "all" then
        all_active = indicator_on
    end
    if not update then
        self.extensions = {}
    else
        for k, _ in pairs(self.extensions) do
            self.extensions[k] = nil
        end
    end
    table.insert(self.extensions,
        {
            text = all_active .. _("All"),
            action = "setext_all"
        }
    )
    local i = 2
    table.sort(extensions.extensions)
    for _, extension in pairs(extensions.extensions) do
        local active = indicator_off
        if self.settings.extensions[extension] ~= nil then
            active = indicator_on
        end
        self.extensions[i] = {
            text = active .. extension,
            action = "setext_" .. extension
        }
        i = i + 1
    end
    if not update then
        table.insert(self.paths, {
            title = _("Extensions"),
        })
        self:switchItemTable(_("Extensions"), self.extensions)
    else
        self:updateItems(1, true)
    end
end

function ZLibraryBrowser:onExtensionChange(extension)
    if extension == "all" then
        self.settings.extensions = "all"
    else
        if self.settings.extensions == "all" then
            self.settings.extensions = {}
        end
        if self.settings.extensions[extension] ~= nil then
            self.settings.extensions[extension] = nil
        else
            self.settings.extensions[extension] = true
        end
    end
    self:saveSettings()
    self:onExtensionPicker(true)
end
