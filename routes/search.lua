local _ = require("gettext")
function ZLibraryBrowser:onSearch(query, page)
    table.insert(self.settings.history, 0, query)
    self:saveSettings()
    query = {
        message = query,
        limit = self.perpage,
        page = page,
        order = self.settings.order
    }
    if self.settings.languages ~= "all" then
        query["languages[]"] = self.settings.languages
    end
    if self.settings.extension ~= "all" then
        query["extensions[]"] = self.settings.extension
    end
    local res = self:request("/eapi/book/search", "POST", query)
    if (not res) then return end
    self:handlePaged(res, page, _("Search Results"))
end
