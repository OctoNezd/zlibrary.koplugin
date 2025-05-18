local _ = require("gettext")

function ZLibraryBrowser:onRecommended()
    local res = self:request("/eapi/user/book/recommended")
    if (not res) then return end
    table.insert(self.paths, {
        title = _("Recommended")
    })
    self:switchItemTable(_("Recommended"), self:convertToItemTable(res.books))
end
