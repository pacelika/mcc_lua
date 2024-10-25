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

function Parser_Static.new(tokens,token_index)
    local self = setmetatable({
        tokens = tokens,
        token_index = token_index or 0,
    },{
        __index = Parser
    })

    self:advance()

    return self
end

function Parser:copy()
    return Parser_Static.new(self.tokens,self.token_index) 
end

function Parser:advance()
    if self.token_index > #self.tokens then
        print "what's wrong"
        return
    end

    self.token_index = self.token_index + 1
    self.current_token = self.tokens[self.token_index]

    return self.current_token
end

function Parser:factor()
    local token = self.current_token

    if not token then
        return nil
    end

    if token.type_id == Token.INT or token.type_id == Token.FLOAT then
        self:advance()
        return Nodes.NumberNode.new(token)
    end
end

function Parser:bin_op(func, ops)
   if not self:validate_parentheses(self.tokens) then
        return nil,"ERROR: Unbalanced parentheses"  -- Abort if parentheses are unbalanced
    end

    local initial_op_token = nil

    local function get(func, this)
        local left = nil
        local op_token = nil

        if not this.current_token or this.current_token.type_id == Token.EOF then return end

        -- Handle parentheses
        if this.current_token.type_id == Token.LPAREN then
            this:advance()

            left = func(this)

            -- if not left then
            --     return nil,"ERROR: Expected expression inside parentheses"
            -- end

            if this.current_token and this.current_token.type_id == Token.RPAREN then
                this:advance()
             -- else
             --    return nil,"ERROR: Mismatched or missing closing parenthesis."
            end
        end

        while this.current_token and is_type_present(ops, this.current_token.type_id) do
            op_token = this.current_token
            this:advance()

            -- Get left operand
            if not left then
                left = func(this)
                if not left and (this.current_token.type_id == Token.INT or this.current_token.type_id == Token.FLOAT) then
                    left = Nodes.NumberNode.new(this.current_token)
                    this:advance()
                end
            end

            local right = func(this)

            -- Handle unary negative
            if op_token.type_id == Token.SUB then
                if not right then
                    if this.current_token and this.current_token.type_id == Token.RPAREN then
                        local negative_value_token = Token.new(left.token.type_id, "-" .. left.token.value)
                        return Nodes.NumberNode.new(negative_value_token)
                    end
                end
            end

            -- Get right operand
            if not right and (this.current_token.type_id == Token.INT or this.current_token.type_id == Token.FLOAT) then
                right = Nodes.NumberNode.new(this.current_token)
                this:advance()
            end

            if not left then
                left = get(func,this)
                if left then
                    self:advance()
                    if self.current_token.type_id == Token.INT or self.current_token.type_id == Token.FLOAT then
                        right = Nodes.NumberNode.new(this.current_token)
                        self:advance()
                        return Nodes.BinOp.new(left,op_token,right)
                    end
                end
            end

            if not right then
                return nil,string.format("ERROR: Expected 2 operands for operation: %s", op_token.value)
            end

            -- Create binary operation node
            left = Nodes.BinOp.new(left, op_token, right)

            -- Store initial operator token for later usage
            if not initial_op_token then
                initial_op_token = op_token
            end
        end

        return left
    end

    local final_left,err = get(func, self)

    if err then return nil,err end

    if not final_left then return end

    local final_right,err = get(func, self)

    if err then return nil,err end

    if final_right then
        return Nodes.BinOp.new(final_left, initial_op_token, final_right)
    end

    return final_left
end

function Parser:term()
    return self:bin_op(self.factor,bin_ops)
end

function Parser:validate_parentheses(tokens)
    local paren_count = 0

    for _, token in ipairs(tokens) do
        if token.type_id == Token.LPAREN then
            paren_count = paren_count + 1
        elseif token.type_id == Token.RPAREN then
            paren_count = paren_count - 1

            if paren_count < 0 then
                print("ERROR: Too many closing parentheses.")
                return false
            end
        end
    end

    if paren_count > 0 then
        print("ERROR: Unmatched opening parenthesis.")
        return false
    end

    return true 
end

function Parser:decl_var()
    if not self.current_token then return end

    if not self:validate_parentheses(self.tokens) then
        return nil,"Error: unbalanced parentheses in defvar statement" 
    end

    if self.current_token.type_id == Token.DEFVAR then
        self:advance()

        local id_tok = self.current_token
        
        if id_tok.type_id ~= Token.IDENTIFIER  then
            return nil,"ERROR: No identi provided"
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

function Parser:decl_attr()
    if not self.current_token then return end

    if self.current_token.type_id == Token.ATTRIBUTE then
        self:advance()
        local id_tok = self.current_token

        if not id_tok or id_tok.type_id ~= Token.IDENTIFIER then
            return nil,"Attribute expects Identifier"
        end

        self:advance()

        local value_node = self:expr()

        if not value_node then
            if self.current_token.type_id == Token.PRIM_TYPE then
                value_node = self.current_token
            elseif self.current_token.type_id == Token.IDENTIFIER then
                return nil,string.format("ERROR: :%s %s ERR_TYPE = WHAT",id_tok.value,self.current_token.value)
            end
        end

        local type_ = value_node and (value_node.type_id == Nodes.NODE_NUMBER and value_node.token.type_id or value_node and value_node.type_id)
        local value = value_node and (value_node.type_id == Nodes.NODE_NUMBER and value_node.token.value or value_node) 

        if value then
            return Nodes.Declaration.new("ATTRDECL",id_tok.value,type_,value)
        else
            return Nodes.Declaration.new("ATTRDECL",id_tok.value,Token.INT,1)
        end
    end
end

function Parser:expr()
    local term,err = self:term()

    if err then return nil,err end

    if term then return term end

    local expr = self:factor()

    if expr then
        return expr
    end
end

function Parser:parse()
    local ast = {}

    while self.current_token do

        if self.current_token.type_id == Token.DEFVAR then
            local declaration,err = self:decl_var()

            if err then return {},err end

            if declaration then
                table.insert(ast,declaration)
            end
        elseif self.current_token.type_id == Token.ATTRIBUTE then
            local attribute,err = self:decl_attr()

            if err then return {},err end

            if attribute then
                table.insert(ast,attribute)
            end
        elseif self.current_token.type_id == Token.INT then
            local expr,err = self:expr()

            if err then return {},err end

            if expr then
                table.insert(ast,expr)
            end
        elseif is_type_present(bin_ops,self.current_token.type_id) then
            local expr,err = self:expr()

            if err then return {},err end

            if expr then
                table.insert(ast,expr)
            end
        else
            local expr,err = self:expr()

            if err then return {},err end

            if expr then
                table.insert(ast,expr)
            end
        end

        if self.current_token.type_id == Token.RPAREN then
            self:advance()
        end

        if not self.current_token or self.current_token.type_id == Token.EOF then
            break
        end 
    end

    return ast,nil 
end

return Parser_Static
