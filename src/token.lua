local Token_Static = {}
local Token = {}

local c = 0

local function add_field(field_name,v)
    Token_Static[field_name] = v and v or c 
    c = c + 1
end

add_field("INT")
add_field("FLOAT")
add_field("STRING")
add_field("IDENTIFIER")
add_field("CLOSE_PAREN")
add_field("OPEN_PAREN")
add_field("PLUS")
add_field("SUB")

add_field("MUL")
add_field("DIV")

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
    },{__index = Token})

    -- return setmetatable({
    --     type_id = type_id,
    --     value = value
    -- },{__index = function(self,key,value)
    --     if rawget(Token,key) then
    --         return rawget(Token,key)
    --     else
    --         return report_table_error(nil,{key = key,where = "Token instance"})
    --     end
    -- end})
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
    elseif type_id == Token_Static.PLUS then
        return "PLUS"
    elseif type_id == Token_Static.SUB then
        return "SUB"
    elseif type_id == Token_Static.MUL then
        return "MUL"
    elseif type_id == Token_Static.DIV then
        return "DIV"
    end

    error("UNHANDLED_TOKEN_TYPEID")
end

function Token:typeid_tostring()
    return Token_Static.typeid_tostring(self.type_id)
end

function Token:tostring()
   return string.format("%s: %s",self:typeid_tostring(),self.value) 
end

return Token_Static
