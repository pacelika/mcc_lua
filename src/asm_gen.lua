local AsmGen = {}
local Nodes = require "src.ast_node"
local Token = require "src.token"

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

function AsmGen:read_ast()
    while self.current_node do
        if self.current_node.type_id == Nodes.NODE_BINOP then
            if self.current_node.left_node.token and self.current_node.right_node.token then
                if self.current_node.op_token.type_id == Token.MUL or self.current_node.op_token.type_id == Token.DIV then
                    self.asm = self.asm..string.format("\tmov eax,%s\n",self.current_node.left_node.token.value)
                    self.asm = self.asm..string.format("\tmov ebx,%s\n",self.current_node.right_node.token.value)
                else
                    self.asm = self.asm..string.format("\tmov ebx,%s\n",self.current_node.left_node.token.value)
                    self.asm = self.asm..string.format("\tmov ecx,%s\n",self.current_node.right_node.token.value)
                end
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
