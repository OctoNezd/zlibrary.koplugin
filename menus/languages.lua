local _ = require("gettext")
function ZLibraryBrowser:onLanguagePicker()
    local languages = self:request("/eapi/info/languages")
    if not languages then return end
    local indicator_on = "◉"
    local indicator_off = "◯"
    local all_active = indicator_off
    if self.settings.language == "all" then
        all_active = indicator_on
    end

    local items = {
        {
            text = all_active .. _("All"),
            action = "setlang_all"
        }
    }
    for code, language in pairs(languages.languages) do
        local active = indicator_off
        if code == self.settings.language then
            active = indicator_on
        end
        table.insert(items, {
            text = active .. language,
            action = "setlang_" .. code
        })
    end
    self:switchItemTable(_("Languages"), items)
end

function ZLibraryBrowser:onLangChange(lang)
    self.settings.language = lang
    self:saveSettings()
    self:onReturn()
end
