local ContentCursor = {}
local ContentCursor_Static = {}

function ContentCursor_Static.new(index,line,colomn,file_name,text)
    return setmetatable({
        index = index or 0,
        line = line or 0,
        column = column or 0,
        file_name = file_name,
        text = text
    },{
        __index = ContentCursor
    }) 
end

function ContentCursor:advance(char)
    self.index = self.index + 1
    self.column = self.column + 1

    if char == '\n' then
        self.line = self.line + 1 
        self.column = 0
    end
end

function ContentCursor:copy()
    return ContentCursor_Static.new(self.index,self.line,self.column,self.file_name,self.text) 
end

return ContentCursor_Static
