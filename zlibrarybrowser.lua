local Menu = require("ui/widget/menu")
local _ = require("gettext")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local InputDialog = require("ui/widget/inputdialog")
local http = require("socket.http")
local ltn12 = require("ltn12")
local urlencode = require("urlencode")
local json = require("json")
local misc = require("misc")
local logger = require("logger")
local ButtonDialog = require("ui/widget/buttondialog")
local ScrollHtmlWidget = require("ui/widget/scrollhtmlwidget")
local T = require("ffi/util").template
local base64 = require("base64")
local ZLibraryBrowser = Menu:extend {}
local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local VerticalSpan = require("ui/widget/verticalspan")
local FrameContainer = require("ui/widget/container/framecontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local CenterContainer = require("ui/widget/container/centercontainer")
local Geom = require("ui/geometry")
local ButtonTable = require("ui/widget/buttontable")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Device = require("device")
local Screen = Device.screen
local time = require("ui/time")
function ZLibraryBrowser:init()
    self.catalog_title = "Z-Library"
    self.item_table = self:genItemTableFromRoot()
    self.settings = self:loadSettings()
    self.headers = {
        ['remix-userid'] = self.settings.userid,
        ['remix-userkey'] = self.settings.userkey,
        ['Content-Type'] = 'application/x-www-form-urlencoded',
        ['Cookie'] = T("remix-userid=%1; remix-userkey=%2", self.settings.userid, self.settings.userkey)
    }
    self.last_action = ""
    self.width = Screen:getWidth()
    self.height = Screen:getHeight()
    Menu.init(self)
end

function ZLibraryBrowser:loadSettings()
    local file = io.open("plugins/zlibrary.koplugin/settings.json", 'r')
    if file == nil then
        UIManager:show(InfoMessage:new {
            text = "Settings file is missing!"
        })
        return
    end
    local data = file:read("*a")
    logger.info(data)
    return json.decode(data)
end

function ZLibraryBrowser:genItemTableFromRoot()
    local item_table = {
        {
            text = "\u{f002} " .. _("Search"),
            action = "search"
        },
        {
            text = _("Recommended"),
            action = "recommended"
        },
        {
            text = _("Saved"),
            action = "saved"
        },
        {
            text = _("Popular"),
            action = "popular"
        },
        {
            text = _("Previously downloaded"),
            action = "downloaded"
        }
    }
    self.page_count = 1
    return item_table
end

function ZLibraryBrowser:onSearchMenuItem()
    local dialog
    dialog = InputDialog:new {
        title = _("Search Z-Library"),
        input_hint = _("Do Androids Dream of Electric Sheep?"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("Search"),
                    id = "search",
                    is_enter_default = true,
                    callback = function()
                        local query = dialog:getInputText()
                        print("Searching for", query)
                        UIManager:close(dialog)
                        self:onMenuSelect({
                            action = "search_" .. query
                        })
                    end
                }
            }
        }
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
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
        self:onPopuler()
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
        self:onMenuSelect({ action = path.url })
    else
        -- return to root path, we simply reinit opdsbrowser
        self:init()
    end
    return true
end

function ZLibraryBrowser:request(path, method, query)
    local body = ""
    if method == "POST" then
        body = urlencode.table(query)
    end
    local response_tbl = {}
    local ret, status, headers = http.request {
        url = self.settings.endpoint .. path,
        headers = self.headers,
        method = method,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_tbl)
    }
    local response = table.concat(response_tbl)
    if (status ~= 200) then
        logger.err("error during request:")
        logger.err(response)
        UIManager:show(InfoMessage:new {
            text = "Error during request: " .. tostring(ret) .. "-" .. tostring(status) .. "\n\n" .. response
        })
        return false
    end
    local res = json.decode(response)
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
        table.insert(book_tbl, {
            text = T("%1 by %2 (%3)",
                v["title"], v["author"], v["extension"]
            ),
            action = "book_" .. v.id .. "/" .. v.hash
        })
    end
    return book_tbl
end

function ZLibraryBrowser:handlePaged(res, page, title)
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
        for _, v in pairs(self:convertToItemTable(res.books)) do
            table.insert(self.book_tbl, v)
        end
        self:updateItems(1, true)
    end
end

function ZLibraryBrowser:onSearch(query, page)
    local res = self:request("/eapi/book/search", "POST", {
        message = query,
        limit = self.perpage,
        page = page
    })
    if (not res) then return end
    self:handlePaged(res, page, _("Search Results"))
end

function ZLibraryBrowser:onDownloaded(page)
    local res = self:request("/eapi/user/book/downloaded?" .. urlencode.table({
        limit = self.perpage,
        page = page
    }), "GET", '')
    if (not res) then return end
    self:handlePaged(res, page, _("Downloaded"))
end

function ZLibraryBrowser:onSaved(page)
    local res = self:request("/eapi/user/book/saved?" .. urlencode.table({
        limit = self.perpage,
        page = page
    }))
    if (not res) then return end
    self:handlePaged(res, page, _("Saved"))
end

function ZLibraryBrowser:onRecommended()
    local res = self:request("/eapi/user/book/recommended")
    if (not res) then return end
    table.insert(self.paths, {
        title = _("Recommended")
    })
    self:switchItemTable(_("Recommended"), self:convertToItemTable(res.books))
end

function ZLibraryBrowser:onPopuler()
    local res = self:request("/eapi/book/most-popular")
    if (not res) then return end
    table.insert(self.paths, {
        title = _("Popular")
    })
    self:switchItemTable(_("Popular"), self:convertToItemTable(res.books))
end

function ZLibraryBrowser:onSimilar(bookid)
    local res = self:request("/eapi/book/" .. bookid .. "/similar")
    if (not res) then return end
    table.insert(self.paths, {
        title = _("Similar")
    })
    self:switchItemTable(_("Similar"), self:convertToItemTable(res.books))
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
        self:onDownload(page)
        return true
    elseif self.last_action == "saved" then
        self:onSaved(page)
        return true
    end
    return Menu.onGotoPage(self, page)
end

function ZLibraryBrowser:onBook(bookid)
    local res = self:request("/eapi/book/" .. bookid)
    if (not res) then return end
    res = res.book
    local frame_bordersize = Size.border.window
    local frame
    local button_table = ButtonTable:new {
        width = self.width,
        buttons = {
            {
                {
                    text = _("Download") .. " (" .. res.extension .. ")",
                    callback = function()
                        self:onDownload(bookid)
                    end
                }
            },
            {
                {
                    text = _("Similar"),
                    callback = function()
                        UIManager:close(frame)
                        self:updateItems(1, true)
                        self:onMenuSelect({ action = "similar_" .. bookid })
                    end
                }
            },
            {
                {
                    text = _("Close"),
                    callback = function()
                        UIManager:close(frame)
                        -- restore our previous action
                        self.last_action = self.previous_action
                        self:updateItems(1, true)
                    end
                }
            }
        },
        zero_sep = true,
        show_parent = self,
    }
    local cover_tbl = {}
    local message = InfoMessage:new {
        text = "Loading cover art..."
    }
    UIManager:show(message)
    local ret, status, headers = http.request {
        url = res.cover,
        headers = self.headers,
        method = "GET",
        sink = ltn12.sink.table(cover_tbl)
    }
    local cover
    if status ~= 200 then
        logger.err("Failed to get cover art!" .. status)
        cover = _("Failed to load cover<br/>")
    else
        cover = base64.encode(table.concat(cover_tbl))
        cover = '<div class="cover"><img src="data:image/jpeg;base64,' ..
            cover .. '" style="width: 300px"/></div><br/>'
    end
    UIManager:close(message)
    if type(res.publisher) == "function" then
        res.publisher = _("Unknown publisher")
    end
    local textview = ScrollHtmlWidget:new {
        html_body = cover .. T(
            _("%1 by %2 (Published by %3)\n\n%4"),
            res.title, res.author, res.publisher, res.description
        ),
        css = "img {text-align: center} .cover { text-align: center }",
        width = self.width,
        height = self.height - button_table:getSize().h,
        dialog = self
    }
    frame = FrameContainer:new {
        radius = Size.radius.window,
        bordersize = frame_bordersize,
        padding = 0,
        margin = 0,
        background = Blitbuffer.COLOR_WHITE,
        VerticalGroup:new {
            align = "left",
            CenterContainer:new {
                dimen = Geom:new {
                    w = self.width,
                    h = textview:getSize().h,
                },
                textview,
            },
            -- buttons
            CenterContainer:new {
                dimen = Geom:new {
                    w = self.width,
                    h = button_table:getSize().h,
                },
                button_table,
            }
        }
    }
    UIManager:nextTick(function() UIManager:show(frame) end)
end

function ZLibraryBrowser:onDownload(bookid)
    logger.info("Downloading " .. bookid)
    local res = self:request("/eapi/book/" .. bookid .. "/file")
    if (not res) then return end
    res = res.file
    local filepath = T("%1/%2.%3",
        self.settings.download_dir,
        string.gsub(res.description, "[<>:\"/\\|?*]", ''),
        res.extension)
    local ret, status, headers = http.request {
        method = "GET",
        url = res.downloadLink,
        sink = ltn12.sink.file(io.open(filepath, 'w'))
    }
    if (status ~= 200) then
        logger.err("Request failed!")
        logger.err(res)
        UIManager:show(InfoMessage:new {
            text = "Error during request: " .. ret .. "-" .. status
        })
    end
    UIManager:close(self.book_dlg)
    UIManager:show(InfoMessage:new {
        text = "Downloaded to " .. filepath .. " successfully!"
    })
end

return ZLibraryBrowser
