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

    if not token then
        return
    end

    if token.type_id == Token.INT or token.type_id == Token.FLOAT then
        self:advance()
        return Nodes.NumberNode.new(token)
    end
end

function Parser:bin_op(func,ops)
    local final_left = nil
    local final_right = nil
    local initial_op_token = nil

    local function get(func,this)
        local left = nil
        local right = nil

        if this.current_token.type_id == Token.LPAREN or this.current_token.type_id == Token.RPAREN then
            this:advance()
        end

        while this.current_token and (is_type_present(ops,this.current_token.type_id)) do
            local op_token = this.current_token
            this:advance()

            left = func(this)
            right = func(this)

            if not right and (this.current_token.type_id == Token.INT or this.current_token.type_id == Token.FLOAT) then
                right = Nodes.NumberNode.new(this.current_token)
            end

            left = Nodes.BinOp.new(left,op_token,right)
        end

        return left
    end

    final_left = get(func,self)
    final_right = get(func,self)

    if final_left and final_right then
        final_left = Nodes.BinOp.new(final_left,initial_op_token,final_right)
    end

    return final_left
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
