local Lexer = {}
local Lexer_Static = {}

local Token = require "src.token"
local Error = require "src.error"
local ContentCursor = require "src.content_cursor"

function Lexer_Static.new(source_code,file_name)
    return setmetatable({
        source = source_code,
        source_size = #source_code,
        char = 0,
        cursor = ContentCursor.new(0,1,0,file_name,source_code),
        should_exit = false,
        tokens = {},
    },{
        __index = Lexer
    })
end

function Lexer:advance()
    if self.cursor.index > self.source_size then
        self.should_exit = true
        self.char = nil
        return
    end

    self.cursor:advance(self.char)
    self.char = string.sub(self.source,self.cursor.index,self.cursor.index)
end

function Lexer:make_number()
    local number = ""
    local dot_count = 0

    while (tonumber(self.char) or self.char == ".") and not self.should_exit do
        if self.char == "." then
            if dot_count == 1 then
                print("ERROR: floating point number with double period")
                break
            end

            number = number .. self.char
            dot_count = dot_count + 1
        else
            number = number .. self.char
        end

        self:advance()
    end

    table.insert(self.tokens,Token.new(dot_count > 0 and Token.FLOAT or Token.INT,number))
end

function Lexer:make_string()
    self:advance()
    local str = ""

    while not self.should_exit and self.char ~= "\"" do
        str = str..self.char
        self:advance()
    end

    table.insert(self.tokens,Token.new(Token.STRING,str))
end

function Lexer:make_identifier()
    local identifier = ""
    
    while not self.should_exit and self.char ~= " " and self.char:match("^[a-zA-Z]+$") do
        identifier = identifier .. self.char
        self:advance()
    end

    if identifier:lower() == "defvar" then
        table.insert(self.tokens,Token.new(Token.DEFVAR,identifier)) 
        return
    end

    table.insert(self.tokens,Token.new(Token.IDENTIFIER,identifier)) 
end

function Lexer:tokenize()
    self:advance()

    while not self.should_exit do
        if self.char == "\t" or self.char == '' or self.char == " " then
            self:advance()
        elseif self.char == "(" then
            table.insert(self.tokens,Token.new(Token.LPAREN,self.char))
            self:advance()
        elseif self.char == ")" then
            table.insert(self.tokens,Token.new(Token.RPAREN,self.char))
            self:advance()
        elseif tonumber(self.char) then
            self:make_number()
        elseif self.char == "\"" then
            self:make_string()
            self:advance()
        elseif self.char == "+" then
            table.insert(self.tokens,Token.new(Token.PLUS,self.char))
            self:advance()
        elseif self.char == "-" then
            table.insert(self.tokens,Token.new(Token.SUB,self.char))
            self:advance()
        elseif self.char == "*" then
            table.insert(self.tokens,Token.new(Token.MUL,self.char))
            self:advance()
        elseif self.char == "/" then
            table.insert(self.tokens,Token.new(Token.DIV,self.char))
            self:advance()
        elseif tostring(self.char) then
            self:make_identifier()
        elseif self.char == ";" then
            table.insert(self.tokens,Token.new(Token.SEMI_COLON,self.char))
            self:advance()
        else
            local cursor_start = self.cursor:copy()
            local char = self.char
            self:advance()
            return Error.new(Error.ILLEGAL_CHAR,string.format("'%s'",char),cursor_start,self.cursor)           
        end
    end

    table.insert(self.tokens,Token.new(Token.EOF))
    self:advance()
end

return Lexer_Static
