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

    local filepath = ZL_PATH .. "/update.zip"
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
        "unzip -o " .. ZL_PATH .. "/update.zip -d" .. ZL_PATH .. "/update.tmp")
    if (retcode ~= 0) then
        UIManager:show(InfoMessage:new {
            text = _("Failed to unzip update, exit code ") .. retcode
        })
        return
    end
    retcode = os.execute(
        "cp -rvf " .. ZL_PATH .. "/update.tmp/* " .. ZL_PATH .. "")
    if (retcode ~= 0) then
        UIManager:show(InfoMessage:new {
            text = _("Failed to move update files")
        })
        return
    end
    os.execute("rm -rvf " .. ZL_PATH .. "/update.tmp")

    UIManager:show(InfoMessage:new {
        text = _("Updated. Restart KOReader for changes to apply.")
    })
end

return ZLibraryBrowser
