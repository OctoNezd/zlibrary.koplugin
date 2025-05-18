local _ = require("gettext")
local T = require("ffi/util").template
function ZLibraryBrowser:indexPage()
    local item_table = {
        {
            text = "\u{f002} " .. _("Search"),
            action = "search"
        },
        {
            text = "\u{f1da} " .. _("Search history"),
            action = "searchhistory"
        },
        {
            text = "\u{e8c8} " .. _("Recommended"),
            action = "recommended"
        },
        {
            text = "\u{e7b9} " .. _("Saved"),
            action = "saved"
        },
        {
            text = "\u{eb62} " .. _("Popular"),
            action = "popular"
        },
        {
            text = "\u{e8d9}" .. _("Previously downloaded"),
            action = "downloaded"
        },
        {
            text = "\u{eb92} " .. _("Configuration"),
            action = "config"
        }
    }
    self.page_count = 1
    self:switchItemTable("Z-Library", item_table)
    if (self.profile) then
        self.page_info_text:setText(T(_("%1/%2 DLs used"),
            self.profile.user.downloads_today,
            self.profile.user.downloads_limit))
        self.page_info_left_chev:hide()
        self.page_info_right_chev:hide()
        self.page_info_first_chev:hide()
        self.page_info_last_chev:hide()
    end
    return item_table
end
