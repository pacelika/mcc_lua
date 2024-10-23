local Parser_Static = {}
local Parser = {}

local Token = require "src.token"
local Nodes = require "src.ast_node"

local bin_ops = {Token.MUL,Token.DIV,Token.PLUS,Token.SUB}

local function is_type_present(t,id)
    for _, value in ipairs(t) do
        if value == id then
            return value
        end
    end
end

function Parser_Static.new(tokens)
    local self = setmetatable({
        tokens = tokens,
        token_index = 0,
    },{
        __index = Parser
    })

    self:advance()

    return self
end

function Parser:advance()
    if self.token_index > #self.tokens then
        print(self.token_index)
        return
    end

    self.token_index = self.token_index + 1
    self.current_token = self.tokens[self.token_index]

    return self.current_token
end

function Parser:factor()
    local token = self.current_token

    if token and (token.type_id == Token.INT or token.type_id == Token.FLOAT) then
        self:advance()
        return Nodes.NumberNode.new(token)
    end
end

function Parser:bin_op(func,ops)
    local left = func(self)

    while self.current_token and (is_type_present(ops,self.current_token.type_id)) do
        local op_token = self.current_token
        self:advance()
        local right = func(self)
        left = Nodes.BinOp.new(left,op_token,right)
    end

    return left
end

function Parser:term()
    return self:bin_op(self.factor,bin_ops)
end

function Parser:expr()
    return self:bin_op(self.term,bin_ops)
end

function Parser:parse()
    local result = {}

    while true do
        local expr = self:expr()

        if expr == nil then
            break 
        end

        table.insert(result,expr)
    end

    return result
end

return Parser_Static
