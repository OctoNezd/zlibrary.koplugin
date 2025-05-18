local _ = require("gettext")
function ZLibraryBrowser:onSimilar(bookid)
    local res = self:request("/eapi/book/" .. bookid .. "/similar")
    if (not res) then return end
    table.insert(self.paths, {
        title = _("Similar")
    })
    self:switchItemTable(_("Similar"), self:convertToItemTable(res.books))
end
