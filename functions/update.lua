local _ = require("gettext")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local http = require("socket/http")
function ZLibraryBrowser:update()
    local filepath = "plugins/zlibrary.koplugin/update.zip"
    local file = io.open(filepath, 'w')
    if file == nil then
        UIManager:show(InfoMessage:new {
            text = _("Failed to open file ") .. filepath
        })
        return
    end
    http.request {
        method = "GET",
        url = "https://github.com/OctoNezd/zlibrary.koplugin/archive/refs/heads/main.zip",
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
        "mv plugins/zlibrary.koplugin/update.tmp/zlibrary.koplugin-main/* plugins/zlibrary.koplugin")
    if (retcode ~= 0) then
        UIManager:show(InfoMessage:new {
            text = _("Failed to move update files")
        })
        return
    end

    UIManager:show(InfoMessage:new {
        text = _("Updated. Restart KOReader for changes to apply.")
    })
end

return ZLibraryBrowser
