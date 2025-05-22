local _ = require("gettext")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local http = require("socket/http")
function ZLibraryBrowser:update()
    local releases = self:request("https://api.github.com/repos/octonezd/zlibrary.koplugin/releases", "GET")
    if not releases then return end
    local release = releases[1]
    if self.ZL_VERSION == release["name"] then
        UIManager:show(InfoMessage:new {
            text = _("You are up to date")
        })
        return
    end

    local filepath = "plugins/zlibrary.koplugin/update.zip"
    local file = io.open(filepath, 'w')
    if file == nil then
        UIManager:show(InfoMessage:new {
            text = _("Failed to open update file ") .. filepath
        })
        return
    end
    http.request {
        method = "GET",
        url = release.assets[1].browser_download_url,
        sink = ltn12.sink.file(file)
    }
    local retcode = os.execute(
        "unzip -o plugins/zlibrary.koplugin/update.zip -d plugins/zlibrary.koplugin/update.tmp")
    if (retcode ~= 0) then
        UIManager:show(InfoMessage:new {
            text = _("Failed to unzip update, exit code ") .. retcode
        })
        return
    end
    retcode = os.execute(
        "cp -rvf plugins/zlibrary.koplugin/update.tmp/* plugins/zlibrary.koplugin")
    if (retcode ~= 0) then
        UIManager:show(InfoMessage:new {
            text = _("Failed to move update files")
        })
        return
    end
    os.execute("rm -rvf plugins/zlibrary.koplugin/update.tmp")

    UIManager:show(InfoMessage:new {
        text = _("Updated. Restart KOReader for changes to apply.")
    })
end

return ZLibraryBrowser
