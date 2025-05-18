local urlencode = require("urlencode")
local _ = require("gettext")

function ZLibraryBrowser:onDownloaded(page)
    local res = self:request("/eapi/user/book/downloaded?" .. urlencode.table({
        limit = self.perpage,
        page = page,
        order = self.settings.order
    }), "GET", '')
    if (not res) then return end
    self:handlePaged(res, page, _("Downloaded"))
end
