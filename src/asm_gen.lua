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
            self.asm = self.asm..string.format("\tmov ebx,%s\n",self.current_node.left_node.token.value)
            self.asm = self.asm..string.format("\tmov ecx,%s\n",self.current_node.right_node.token.value)
            if (self.current_node.op_token.type_id == Token.PLUS) then
                self.asm = self.asm.."\tadd ebx,ecx\n\n"
            end
        elseif self.current_node.type_id == Nodes.VAR_REF then
            self.asm = self.asm..string.format("\tmov ebx,[%s]\n",self.current_node.name)
        end
        self:advance()
    end
end

return AsmGen
