local Blitbuffer = require("ffi/blitbuffer")
local base64 = require("base64")
local Size = require("ui/size")
local FrameContainer = require("ui/widget/container/framecontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local CenterContainer = require("ui/widget/container/centercontainer")
local Geom = require("ui/geometry")
local ButtonTable = require("ui/widget/buttontable")
local ScrollHtmlWidget = require("ui/widget/scrollhtmlwidget")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local http = require("socket/http")
local logger = require("logger")
local misc = require("misc")
local _ = require("gettext")
local T = require("ffi/util").template

function ZLibraryBrowser:onBook(bookid)
    local res = self:request("/eapi/book/" .. bookid)
    if (not res) then return end
    res = res.book
    local frame_bordersize = Size.border.window
    local book_dialog
    local is_saved = self.saved_books[misc.split(bookid, "/")[1]]
    local save_button_text = _("Save")
    local save_button_func = self.saveBook
    if is_saved then
        save_button_text = _("Unsave")
        save_button_func = self.unSaveBook
    end
    local button_table = ButtonTable:new {
        width = self.width,
        buttons = {
            {
                {
                    text = _("Download") .. " (" .. res.extension .. ", " .. res.filesizeString .. ")",
                    callback = function()
                        self:onDownload(bookid)
                    end
                }
            },
            {
                {
                    text = save_button_text,
                    callback = function()
                        save_button_func(self, misc.split(bookid, "/")[1])
                        self:loadSavedBooks()
                        self:onBook(bookid)
                        UIManager:close(book_dialog)
                    end
                }
            },
            {
                {
                    text = _("Similar"),
                    callback = function()
                        UIManager:close(book_dialog)
                        self:updateItems(1, true)
                        self:onMenuSelect({ action = "similar_" .. bookid })
                    end
                }
            },
            {
                {
                    text = _("Close"),
                    callback = function()
                        UIManager:close(book_dialog)
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
    local comments = "Failed to load comments"
    local comments_data = self:request("/papi/comments/book/" .. misc.split(bookid, "/")[1], "GET", "", true)
    if comments_data then
        comments = ""
        for _, comment in pairs(comments_data.comments) do
            comments = comments .. T("<br><i>%1: </i>%2", comment.user.name, comment.text)
        end
    end

    UIManager:close(message)
    if type(res.publisher) == "function" then
        res.publisher = _("Unknown publisher")
    end
    local textview = ScrollHtmlWidget:new {
        html_body = cover .. T(
            _("%1 by %2 (Published by %3)<br/>%4<br/><b>Comments:</b><br/>%5"),
            res.title, res.author, res.publisher, res.description, comments
        ),
        css = "img {text-align: center} .cover { text-align: center }",
        width = self.width,
        height = self.height - button_table:getSize().h,
        dialog = self
    }
    book_dialog = FrameContainer:new {
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
    UIManager:nextTick(function() UIManager:show(book_dialog) end)
end
