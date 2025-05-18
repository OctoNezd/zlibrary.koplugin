local _ = require("gettext")
function ZLibraryBrowser:onExtensionPicker()
    local extensions = self:request("/eapi/info/extensions")
    if not extensions then return end
    local indicator_on = "◉"
    local indicator_off = "◯"
    local all_active = indicator_off
    if self.settings.extension == "all" then
        all_active = indicator_on
    end

    local items = {
        {
            text = all_active .. _("All"),
            action = "setext_all"
        }
    }
    for _, extension in pairs(extensions.extensions) do
        local active = indicator_off
        if extension == self.settings.extension then
            active = indicator_on
        end
        table.insert(items, {
            text = active .. extension,
            action = "setext_" .. extension
        })
    end
    self:switchItemTable(_("Extensions"), items)
end

function ZLibraryBrowser:onExtensionChange(extension)
    self.settings.extension = extension
    self:saveSettings()
    self:onReturn()
end
