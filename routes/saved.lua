local urlencode = require("urlencode")
local _ = require("gettext")
function ZLibraryBrowser:onSaved(page)
    local res = self:request("/eapi/user/book/saved?" .. urlencode.table({
        limit = self.perpage,
        page = page,
        order = self.settings.order
    }))
    if (not res) then return end
    self:handlePaged(res, page, _("Saved"))
end
