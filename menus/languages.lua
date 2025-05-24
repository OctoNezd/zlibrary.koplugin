local _ = require("gettext")
local logger = require("logger")
function ZLibraryBrowser:onLanguagePicker(update)
    local languages = self:request("/eapi/info/languages")
    if not languages then return end
    local indicator_on = "☑ "
    local indicator_off = "☐ "
    local all_active = indicator_off
    if self.settings.languages == "all" then
        all_active = indicator_on
    end
    if not update then
        self.lang_items = {}
    else
        for k, _ in pairs(self.lang_items) do
            self.lang_items[k] = nil
        end
    end
    self.lang_items[1] = {
        text = all_active .. _("All"),
        action = "setlang_all"
    }

    local i = 2
    local keys = {}
    for key in pairs(languages.languages) do
        table.insert(keys, key)
    end
    table.sort(keys)
    if self.settings.languages ~= "all" then
        for code in pairs(self.settings.languages) do
            self.lang_items[i] = {
                text = indicator_on .. languages.languages[code],
                action = "setlang_" .. code
            }
            i = i + 1
        end
    end

    for _, code in ipairs(keys) do
        local language = languages.languages[code]
        local active = indicator_off
        if self.settings.languages[code] then
            goto continue
        end
        self.lang_items[i] = {
            text = active .. language,
            action = "setlang_" .. code
        }
        i = i + 1
        ::continue::
    end
    if not update then
        table.insert(self.paths, {
            title = _("Languages"),
        })
        self:switchItemTable(_("Languages"), self.lang_items)
    else
        self:updateItems(1, true)
    end
end

function ZLibraryBrowser:onLangChange(lang)
    if lang == "all" then
        self.settings.languages = "all"
    else
        if self.settings.languages == "all" then
            self.settings.languages = {}
        end
        if self.settings.languages[lang] ~= nil then
            self.settings.languages[lang] = nil
        else
            self.settings.languages[lang] = true
        end
    end
    self:saveSettings()
    self:onLanguagePicker(true)
end
