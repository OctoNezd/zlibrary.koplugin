local Menu = require("ui/widget/menu")
local _ = require("gettext")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local http = require("socket/http")
local ltn12 = require("ltn12")
local urlencode = require("urlencode")
local json = require("json")
local misc = require("misc")
local logger = require("logger")
local T = require("ffi/util").template

local Device = require("device")
local Screen = Device.screen
ZLibraryBrowser = Menu:extend {
    title_bar_left_icon = "align.left"
}
require("menus.extensions")
require("menus.languages")
require("dialogs.config")
require("dialogs.sorting")
require("dialogs.download_dir")
require("dialogs.login")
require("dialogs.search")
require("routes.book")
require("routes.downloaded")
require("routes.popular")
require("routes.recommended")
require("routes.saved")
require("routes.search")
require("routes.search_history")
require("routes.similar")
require("routes.index")
require("functions.update")
require("functions.save")
local ds = require("datastorage")
function ZLibraryBrowser:init()
    self.catalog_title = "Z-Library"
    self.ZL_VERSION = require("zl-version")
    self.headers = {
        ['Content-Type'] = 'application/x-www-form-urlencoded',
        ['User-Agent'] = 'octonezd.zlibrary.koplugin/1.0'
    }
    self.settings_path = ds:getDataDir() .. "/zlibrary.json"
    logger.info("Settings path is", self.settings_path)
    self:loadSettings()
    self.last_action = ""
    self.width = Screen:getWidth()
    self.height = Screen:getHeight()
    Menu.init(self)
    self:indexPage()
end

function ZLibraryBrowser:checkSettingsSanity()
    if self.settings == nil then
        self.settings = {}
    end
    if self.settings.history == nil then
        self.settings.history = {}
    end
    if self.settings.languages == nil then
        self.settings.languages = "all"
    end
    if self.settings.extensions == nil then
        self.settings.extensions = "all"
    end
    if self.settings.order == nil then
        self.settings.order = "popular"
    end
    if self.settings.endpoint == nil then
        self.profile = false
    else
        self:loadProfileData()
    end
    if (self.profile == false) then
        logger.err("Error on /user/profile: Starting login flow")
        UIManager:nextTick(function()
            self:loginFlow(function()
                if (self.settings.download_dir == nil) then
                    logger.err("no download dir set")
                    UIManager:nextTick(function() self:downloadDirFlow() end)
                end
            end)
        end)
        return
    end
    if (self.settings.download_dir == nil) then
        logger.err("no download dir set")
        UIManager:nextTick(function() self:downloadDirFlow() end)
    end
end

function ZLibraryBrowser:loadProfileData()
    self.profile = self:request("/eapi/user/profile", "GET", "", true)
    if self.profile then
        self:loadSavedBooks()
    end
end

function ZLibraryBrowser:login(endpoint, login, password, remember_me)
    self.settings["endpoint"] = endpoint
    local res = self:request("/eapi/user/login", "POST", {
        email = login,
        password = password
    })
    if (not res) then return false end
    self.settings["userid"] = res.user.id
    self.settings["userkey"] = res.user.remix_userkey
    if remember_me then
        self.settings["login"] = login
        self.settings["password"] = password
    end
    self:saveSettings()
    self:loadProfileData()
    return true
end

function ZLibraryBrowser:setupHeaders()
    self.headers['remix-userid'] = self.settings.userid
    self.headers['remix-userkey'] = self.settings.userkey
    self.headers['Cookie'] = T("remix-userid=%1; remix-userkey=%2", self.settings.userid, self.settings.userkey)
end

function ZLibraryBrowser:loadSettings()
    local file = io.open(self.settings_path, 'r')
    if file == nil then
        self.settings = {}
        return
    end
    local data = file:read("*a")
    data = json.decode(data)
    self.settings = data
    file:close()
    self:checkSettingsSanity()
    self:setupHeaders()
end

function ZLibraryBrowser:saveSettings()
    local file = io.open(self.settings_path, 'w')
    if file == nil then
        UIManager:show(InfoMessage:new {
            text = _("Failed to open settings for writing. This should be impossible.")
        })
        return
    end
    file:write(json.encode(self.settings))
    file:close()
    self:setupHeaders()
end

function ZLibraryBrowser:onMenuSelect(item)
    if item.action == nil then
        logger.err("Invalid menu item! Returning to start")
        self:init()
        return
    end
    local args = misc.split(item.action, "_")[2]
    self.previous_action = self.last_action
    self.last_action = item.action
    if item.action == "search" then
        self:onSearchMenuItem()
    elseif item.action == "searchhistory" then
        self:onSearchHistory()
    elseif misc.startswith(item.action, "search_") then
        self.page = 1
        self:onSearch(args, self.page)
    elseif item.action == "downloaded" then
        self.page = 1
        self:onDownloaded(self.page)
    elseif item.action == "saved" then
        self.page = 1
        self:onSaved(self.page)
    elseif item.action == "recommended" then
        self:onRecommended()
    elseif item.action == "popular" then
        self:onPopular()
    elseif item.action == "config" then
        self:onConfig()
    elseif misc.startswith(item.action, "setlang_") then
        self:onLangChange(args)
    elseif misc.startswith(item.action, "setext_") then
        self:onExtensionChange(args)
    elseif misc.startswith(item.action, "book_") then
        self:onBook(args)
    elseif misc.startswith(item.action, "similar_") then
        self:onSimilar(args)
    else
        UIManager:show(InfoMessage:new {
            text = _("Not implemented"),
        })
    end
end

function ZLibraryBrowser:onReturn()
    table.remove(self.paths)
    local path = self.paths[#self.paths]
    if path then
        -- return to last path
        self.catalog_title = path.title
        self:onMenuSelect({ action = path.action })
    else
        self:indexPage()
    end
    return true
end

function ZLibraryBrowser:request(path, method, query, suppress_error)
    local body = ""
    if method == "POST" then
        body = urlencode.table(query)
    end
    logger.info("Request:", path, "Q:", query, "B:", body)
    local response_tbl = {}
    local url = path
    local headers = {
        ["User-Agent"] = "octonezd.zlibrary.koplugin/1.0"
    }
    if (not misc.startswith(url, "http")) then
        url = self.settings.endpoint .. path
        headers = self.headers
    end
    local ret, status, headers = http.request {
        url = url,
        headers = headers,
        method = method,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_tbl)
    }
    local response = table.concat(response_tbl)
    if (status ~= 200) then
        logger.err("error during request:")
        logger.err(response)
        if not suppress_error then
            UIManager:show(InfoMessage:new {
                text = "Error during request: " .. tostring(ret) .. "-" .. tostring(status) .. "\n\n" .. response
            })
        end
        return false
    end
    local res = json.decode(response)
    if (misc.startswith(url, "http")) then
        return res
    end

    if res.success ~= 1 then
        logger.err("Request failed!")
        logger.err(res)
        UIManager:show(InfoMessage:new {
            text = "Error during request: " .. response
        })
        return false
    end
    return res
end

function ZLibraryBrowser:convertToItemTable(books)
    local book_tbl = {}
    for k, v in pairs(books) do
        local template = _("%1 by %2 (%3, %4)")
        if v["extension"] == nil then
            template = _("%1 by %2")
        end
        table.insert(book_tbl, {
            text = T(template,
                v["title"], v["author"], v["extension"], v["filesizeString"]
            ),
            action = "book_" .. v.id .. "/" .. v.hash
        })
    end
    return book_tbl
end

function ZLibraryBrowser:handlePaged(res, page, title)
    if (#res.books) == 0 then
        UIManager:show(InfoMessage:new {
            text = _("Nothing found!")
        })
        return
    end
    self.page_count = res.pagination.total_pages
    self.page = page
    self.catalog_title = title
    if page == 1 then
        self.book_tbl = self:convertToItemTable(res.books)
        table.insert(self.paths, {
            title = title,
        })
        self:switchItemTable(title, self.book_tbl)
    else
        for i, v in pairs(self:convertToItemTable(res.books)) do
            local position = i + (self.page - 1) * self.perpage
            table.insert(self.book_tbl, position, v)
        end
        self:updateItems(1, true)
    end
end

function ZLibraryBrowser:getPageNumber(item_number)
    if misc.startswith(self.last_action, "search_") then
        return self.page_count
    end
    return Menu.getPageNumber(self, item_number)
end

function ZLibraryBrowser:onGotoPage(page)
    if misc.startswith(self.last_action, "search_") then
        self:onSearch(misc.split(self.last_action, "_")[2], page)
        return true
    elseif self.last_action == "downloaded" then
        self:onDownloaded(page)
        return true
    elseif self.last_action == "saved" then
        self:onSaved(page)
        return true
    end
    return Menu.onGotoPage(self, page)
end

function ZLibraryBrowser:onDownload(bookid)
    logger.info("Downloading " .. bookid)
    local res = self:request("/eapi/book/" .. bookid .. "/file")
    if (not res) then return end
    if res.file == nil then
        UIManager:show(InfoMessage:new {
            text = _("Limit reached? File is nil")
        })
    end
    res = res.file
    if res.allowDownload == false then
        UIManager:show(InfoMessage:new {
            text = _("Z-Library didnt allow download: ") .. misc.unescape(res.disallowDownloadMessage:gsub("%b<>", ""))
        })
        return
    end
    if res.description == nil then
        UIManager:show(InfoMessage:new {
            text = _("Limit reached? Description is nil")
        })
        return
    end
    if res.extension == nil then
        UIManager:show(InfoMessage:new {
            text = _("Limit reached? Extension is nil")
        })
        return
    end
    local filepath = T("%1/%2_%3.%4",
        self.settings.download_dir,
        string.gsub(res.description, "[<>:\"/\\|?*]", ''),
        bookid:gsub("/", "_"),
        res.extension)
    local file = io.open(filepath, 'w')
    if file == nil then
        UIManager:show(InfoMessage:new {
            text = _("Failed to open file ") .. filepath
        })
        return
    end
    local ret, status, headers = http.request {
        method = "GET",
        url = res.downloadLink,
        sink = ltn12.sink.file(file)
    }
    if (status ~= 200) then
        logger.err("Request failed!")
        logger.err(res)
        UIManager:show(InfoMessage:new {
            text = _("Error during request: ") .. status
        })
        return
    end
    UIManager:close(self.book_dlg)
    UIManager:show(InfoMessage:new {
        text = "Downloaded to " .. filepath .. " successfully!"
    })
    self:loadProfileData()
end

return ZLibraryBrowser
