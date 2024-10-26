local AsmGen = {}
local Nodes = require "src.ast_node"
local Token = require "src.token"
local SymbolTable = require "src.symbol_table"

local ContentCursor = require "src.content_cursor"

function AsmGen.new(ast)
    local self = setmetatable({
        ast = ast,
        current_node = nil,
        cursor = ContentCursor.new(0,0,0,nil,nil),
        asm = ""
    },{
        __index = AsmGen
    })

    self:advance()

    return self
end

function AsmGen:advance()
    if self.cursor.index > #self.ast then
        self.current_node = nil
        return
    end

    self.cursor:advance()
    self.current_node = self.ast[self.cursor.index]
end

local function find_attr(t,what)
    for _,v in pairs(t) do
        if v.name == what then return v end
    end
end

local function sum(bin_node)
    if bin_node.op_token.type_id == Token.PLUS then
        return bin_node.left_node.token.value + bin_node.right_node.token.value
    elseif bin_node.op_token.type_id == Token.SUB then
        return bin_node.left_node.token.value - bin_node.right_node.token.value
    elseif bin_node.op_token.type_id == Token.MUL then
        return bin_node.left_node.token.value * bin_node.right_node.token.value
    elseif bin_node.op_token.type_id == Token.DIV then
        return bin_node.left_node.token.value / bin_node.right_node.token.value
    end
end

function AsmGen:make_variables()
    for var_name,decl_data in pairs(SymbolTable.variables) do
        local type_attr = find_attr(decl_data.arguments,"type")
        local value_attr = find_attr(decl_data.arguments,"value")
        local value = nil

        if value_attr and value_attr.type_id == Nodes.BINOP then
            value = sum(value_attr.value)
        elseif value_attr then
            value = value_attr.value
        else
            value = decl_data.value
        end

        local var_type = nil

        if type_attr then
            var_type = type_attr.value
        end

        if var_type then
            if var_type.value == "byte" then
                var_type = "db"
            elseif var_type.value == "word" then
                var_type = "dw"
            elseif var_type.value == "dword" then
                var_type = "dd"
            else
                var_type = "dd"
            end
        else
            var_type = "dd"
        end

        self.asm = self.asm..string.format("\t%s: %s %s\n",var_name,var_type,value)
    end
end

function AsmGen:read_ast()
    while self.current_node do
        if self.current_node.type_id == Nodes.NODE_BINOP then
            if self.current_node.left_node.token and self.current_node.right_node.token then
                
                -- mul check
                if self.current_node.op_token.type_id == Token.MUL or self.current_node.op_token.type_id == Token.DIV then
                    self.asm = self.asm..string.format("\tmov eax,%s\n",self.current_node.left_node.token.value)
                    self.asm = self.asm..string.format("\tmov ebx,%s\n",self.current_node.right_node.token.value)
                else
                    self.asm = self.asm..string.format("\tmov ebx,%s\n",self.current_node.left_node.token.value)
                    self.asm = self.asm..string.format("\tmov ecx,%s\n",self.current_node.right_node.token.value)
                end
                -- mul check end

            elseif self.current_node.left_node.type_id == Nodes.VAR_REF then
                self.asm = self.asm..string.format("\tmov ebx,[%s]\n",self.current_node.left_node.name)
                self.asm = self.asm..string.format("\tmov ecx,[%s]\n",self.current_node.right_node.name)
            end
            if (self.current_node.op_token.type_id == Token.PLUS) then
                self.asm = self.asm.."\tadd ebx,ecx\n\n"
            elseif (self.current_node.op_token.type_id == Token.SUB) then
                self.asm = self.asm.."\tsub ebx,ecx\n\n"
            elseif (self.current_node.op_token.type_id == Token.MUL) then
                self.asm = self.asm.."\tmul ebx\n\n"
                self.asm = self.asm.."\tmov ebx,eax\n\n"
            elseif (self.current_node.op_token.type_id == Token.DIV) then
                self.asm = self.asm.."\tdiv ebx\n\n"
                self.asm = self.asm.."\tmov ebx,eax\n\n"
            end
        elseif self.current_node.type_id == Nodes.NODE_NUMBER then
            self.asm = self.asm..string.format("\tmov ebx,%s\n",self.current_node.token.value)
        elseif self.current_node.type_id == Nodes.VAR_REF then
            self.asm = self.asm..string.format("\tmov ebx,[%s]\n",self.current_node.name)
        end
        self:advance()
    end
end

return AsmGen
