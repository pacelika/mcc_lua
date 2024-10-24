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

        if not this.current_token then return end

        if this.current_token.type_id == Token.LPAREN or this.current_token.type_id == Token.RPAREN then
            this:advance()
        end

        while this.current_token and (is_type_present(ops,this.current_token.type_id)) do
            local op_token = this.current_token

            if not initial_op_token then
                initial_op_token = op_token
            end

            this:advance()

            left = func(this)
            right = func(this)

            if not left and (this.current_token.type_id == Token.INT or this.current_token.type_id == Token.FLOAT) then
                left = Nodes.NumberNode.new(this.current_token)
                self:advance()
            end

            if op_token.type_id == Token.SUB and not right then
                if this.current_token.type_id == Token.RPAREN then
                    local negative_value_token = Token.new(left.token.type_id,"-"..left.token.value)
                    return Nodes.NumberNode.new(negative_value_token)
                end
            end

            if not right and (this.current_token.type_id == Token.INT or this.current_token.type_id == Token.FLOAT) then
                right = Nodes.NumberNode.new(this.current_token)
                self:advance()
            end

            left = Nodes.BinOp.new(left,op_token,right)
        end

        return left
    end

    final_left = get(func,self)
    final_right = get(func,self)
    
    if not final_left then
        return
    end

    if final_left and not final_right then
        return final_left
    end

    if final_left and final_right then
        return Nodes.BinOp.new(final_left,initial_op_token,final_right)
    end
end

function Parser:term()
    return self:bin_op(self.factor,bin_ops)
end

function Parser:var_decl()
    if not self.current_token then return end

    if self.current_token.type_id == Token.DEFVAR then
        self:advance()

        local id_tok = self.current_token
        
        if id_tok.type_id ~= Token.IDENTIFIER  then
            return print "ERROR: No identi provided"
        end

        self:advance()

        local value_node = self:expr()

        local type_ = value_node and (value_node.type_id == Nodes.NODE_NUMBER and value_node.token.type_id or value_node and value_node.type_id)
        local value = value_node and (value_node.type_id == Nodes.NODE_NUMBER and value_node.token.value or value_node) 

        if value and (is_type_present({Token.INT,Token.FLOAT},type_) or type_ == Nodes.NODE_BIN_OP) then
            return Nodes.Declaration.new("VARDECL",id_tok.value,type_,value)
        elseif not value_node then
            return Nodes.Declaration.new("VARDECL",id_tok.value,Token.INT,0)
        end
    end
end

function Parser:expr()
    local bin_op = self:bin_op(self.factor,bin_ops)

    if bin_op then return bin_op end

    local expr = self:factor()

    if expr then
        return expr
    end
end

function Parser:parse()
    local ast = {}

    while self.current_token do
        if self.current_token.type_id == Token.DEFVAR then
            local declaration = self:var_decl()

            if declaration then
                table.insert(ast,declaration)
            end
        elseif self.current_token.type_id == Token.INT then
            local expr = self:expr()
            if expr then
                table.insert(ast,expr)
            end

        elseif self.current_token.type_id == Token.LPAREN or self.current_token.type_id == Token.RPAREN then
            self:advance()
        elseif self.current_token.type_id == Token.PLUS then
            local expr = self:expr()

            if expr then
                table.insert(ast,expr)
            end
        else
            -- self:bin_op(self.factor,bin_ops)
            -- print(self.current_token.value)
            -- self:advance()
        end

        if not self.current_token or self.current_token.type_id == Token.EOF then
            break
        end
    end

    return ast 
end

return Parser_Static
