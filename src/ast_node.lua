local Nodes = {}

local Token = require "src.token"

Nodes.NumberNode = {}
Nodes.BinOp = {}
Nodes.Declaration = {}

Nodes.VarRef = {}

Nodes.NODE_NUMBER = 0
Nodes.NODE_BINOP = 1
Nodes.NODE_DECLARATION = 2

Nodes.Declaration.DECL_VAR = 0
Nodes.Declaration.DECL_ATTR = 1

function Nodes.NumberNode.new(token)
    return setmetatable({
        token = token,
        type_id = Nodes.NODE_NUMBER
    },{__index = Nodes.NumberNode})
end

function Nodes.NumberNode:tostring()
    if not self.token or not self.token.value then return "<nan>" end
    return string.format("%s: %s",self.token:typeid_tostring(),self.token.value)
end

function Nodes.VarRef.new(name)
    return setmetatable({
        name = name,
    },{
        __index = Nodes.VarRef
    })
end

function Nodes.VarRef:tostring()
    return string.format("(VAR: %s)",self.name)
end

function Nodes.Declaration.new(decl_type,name,d_type,value)
    return setmetatable({
        type_id = Nodes.NODE_DECLARATION,
        decl_type = decl_type,
        name = name,
        d_type = d_type,
        value = value,
        arguments = {}
    },{
        __index = Nodes.Declaration
    })
end

function Nodes.Declaration:tostring()
    local type_ = type(self.value) == "table" and Nodes.nodetype_tostring(self.d_type) or Token.typeid_tostring(self.d_type)

    return string.format("{\n  decl_type: %s,\n  name: %s,\n  type: %s,\n  value: %s\n}",Nodes.Declaration.decltype_tostring(self.decl_type),self.name,type_,type(self.value) == "table" and self.value:tostring() or self.value) 
end

function Nodes.BinOp.new(left_node,op_token,right_node)
    return setmetatable({
        type_id = Nodes.NODE_BINOP,
        left_node = left_node,
        op_token = op_token,
        right_node = right_node
    },{__index = Nodes.BinOp})
end

function Nodes.BinOp:tostring()
    local issues = 0

    if not self.left_node then
        issues = issues+1
        print("ERROR: left_node is nil")
    end

    if not self.right_node then
        issues = issues+1
        print("ERROR: right_node is nil")
    end

    if not self.op_token then
        issues = issues+1
        print("ERROR: op_token is nil")
    end

    if issues > 0 then
        return
    end

    return string.format("(%s, %s, %s)",self.op_token:tostring(),self.left_node:tostring() or "left?",self.right_node:tostring() or "right?")
end

function Nodes.Declaration.decltype_tostring(id)
    if id == Nodes.Declaration.DECL_VAR then
        return "DECL_VAR"
    elseif id == Nodes.Declaration.DECL_ATTR then
        return "DECL_ATTR"
    end

    error("UNKNOWN_DECLARATION")
end

function Nodes.nodetype_tostring(id)
    if id == Nodes.NODE_NUMBER then
        return "NumberNode"
    elseif id == Nodes.NODE_BINOP then
        return "BinOpNode"
    elseif id == Nodes.NODE_DECLARATION then
        return "DeclNode"
    end

    -- error("UnknownNode")
end

return Nodes
