local _ = require("gettext")

function ZLibraryBrowser:onPopular()
    local res = self:request("/eapi/book/most-popular")
    if (not res) then return end
    table.insert(self.paths, {
        title = _("Popular")
    })
    self:switchItemTable(_("Popular"), self:convertToItemTable(res.books))
end
