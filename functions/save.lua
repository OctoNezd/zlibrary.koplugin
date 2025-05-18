local misc = require "misc"
function ZLibraryBrowser:loadSavedBooks()
    local res = self:request("/papi/my-library/saved-book-ids", "GET", nil, true)
    self.saved_books = {}
    if (not res) then return end
    for _, book in pairs(res.list) do
        self.saved_books[tostring(book)] = true
    end
end

function ZLibraryBrowser:saveBook(bookid)
    local res = self:request("/eapi/user/book/" .. bookid .. "/save")
end

function ZLibraryBrowser:unSaveBook(bookid)
    local res = self:request("/eapi/user/book/" .. bookid .. "/unsave")
end
