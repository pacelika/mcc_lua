local Token_Static = {}
local Token = {}

Token_Static.INT = 0
Token_Static.FLOAT = 1

Token_Static.STRING = 2
Token_Static.IDENTIFER = 3

Token_Static.BIN_OP = 4

Token_Static.OPEN_PAREN = 5
Token_Static.CLOSE_PAREN = 6

local function report_table_error(errno,args)
    if errno == nil then
        error(string.format("key: \"%s\" is not valid a index on %s",args.key,args.where))
    end
end

setmetatable(Token_Static,{
    __index = function(self,key)
        return report_table_error(nil,{key = key,where = "Token Static"})
    end
})

function Token_Static.new(type_id,value)
    return setmetatable({
        type_id = type_id,
        value = value
    },{__index = function(self,key,value)
        if rawget(Token,key) then
            return rawget(Token,key)
        else
            return report_table_error(nil,{key = key,where = "Token instance"})
        end
    end})
end

function Token_Static.typeid_tostring(type_id)
    if type_id == Token_Static.INT then
        return "Int"
    elseif type_id == Token_Static.FLOAT then
        return "Float"
    elseif type_id == Token_Static.STRING then
        return "String"
    elseif type_id == Token_Static.OPEN_PAREN then
        return "OPEN_PAREN"
    elseif type_id == Token_Static.CLOSE_PAREN then
        return "CLOSE_PAREN"
    end

    error("UNHANDLED_TOKEN_TYPEID")
end

function Token:typeid_tostring()
    return Token_Static.typeid_tostring(self.type_id)
end

return Token_Static
