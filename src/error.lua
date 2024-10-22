local Error = {}
local Error_Static = {}

Error_Static.ILLEGAL_CHAR = 0

function Error_Static.new(id,details,cursor_start,cursor_end)
    return setmetatable({
        id = id,
        details = details,
        cursor_start = cursor_start,
        cursor_end =cursor_end 
    },{
        __index = Error
    })
end

function Error_Static.id_tostring(id)
    if id == Error_Static.ILLEGAL_CHAR then
        return "Illegal Char"
    end
end

function Error:id_tostring()
    return Error_Static.id_tostring(self.id)
end

function Error:what()
    local message = ""

    message = message .. string.format("%s: %s",self:id_tostring(),self.details)
    message = message .. string.format("\nFile: '%s' line: %d",
    self.cursor_start.file_name,self.cursor_start.line)

    return message
end

return Error_Static
