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

        if value_attr and value_attr.value.type_id == Nodes.NODE_BINOP then
            value = sum(value_attr.value)
        elseif value_attr and value_attr.value.type_id ~= Nodes.NODE_BINOP then
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

function AsmGen:load_2_value_reg(data)
    self.asm = self.asm..string.format("\tmov %s,%s\n",data.reg0 or "ebx",data.arg0)
    self.asm = self.asm..string.format("\tmov %s,%s\n",data.reg1 or "ecx",data.arg1)
end

function AsmGen:read_ast()
    while self.current_node do
        local node = self.current_node

        if node.type_id == Nodes.NODE_BINOP then
            if node.left_node.token and node.right_node.token then
            local data = {arg0 = node.left_node.token.value,arg1 = node.right_node.token.value}

            if node.op_token.type_id == Token.MUL or node.op_token.type_id == Token.DIV then
                data.reg0 = "eax"
                data.reg1 = "ebx"
                self:load_2_value_reg(data)
            else
                self:load_2_value_reg(data)
            end
                
            elseif node.left_node.type_id == Nodes.VAR_REF then
                local data = {arg0 = string.format("[%s]",node.left_node.name),arg1 = string.format("[%s]",node.right_node.name)}

                if node.op_token.type_id == Token.MUL or node.op_token.type_id == Token.DIV then
                    data.reg0 = "eax"
                    data.reg1 = "ebx"
                    self:load_2_value_reg(data)
                else
                    self:load_2_value_reg(data)
                end
            end
            if (node.op_token.type_id == Token.PLUS) then
                self.asm = self.asm.."\tadd ebx,ecx\n"
            elseif (self.current_node.op_token.type_id == Token.SUB) then
                self.asm = self.asm.."\tsub ebx,ecx\n"
            elseif (node.op_token.type_id == Token.MUL) then
                self.asm = self.asm.."\tmul ebx\n"
                self.asm = self.asm.."\tmov ebx,eax\n\n"
            elseif (node.op_token.type_id == Token.DIV) then
                self.asm = self.asm.."\tdiv ebx\n"
                self.asm = self.asm.."\tmov ebx,eax\n"
            end
        elseif node.type_id == Nodes.NODE_NUMBER then
            self.asm = self.asm..string.format("\tmov ebx,%s\n",node.token.value)
        elseif self.current_node.type_id == Nodes.VAR_REF then
            self.asm = self.asm..string.format("\tmov ebx,[%s]\n",node.name)
        end
        self:advance()
    end
end

return AsmGen
