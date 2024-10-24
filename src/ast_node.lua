local Nodes = {}

Nodes.NumberNode = {}
Nodes.BinOp = {}
Nodes.Declaration = {}

Nodes.NODE_NUMBER= 0
Nodes.NODE_BINOP = 1
Nodes.NODE_DECLARATION = 2

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

function Nodes.Declaration.new(decl_type,name,d_type,value)
    return setmetatable({
        type_id = Nodes.NODE_DECLARATION,
        decl_type = decl_type,
        name = name,
        d_type = d_type,
        value = value
    },{
        __index = Nodes.Declaration
    })
end

function Nodes.Declaration:tostring()
    return string.format("{\n\tdecl_type: %s,\n\tname: %s,\n\td_type: %s,\n\tvalue: %s\n}",self.decl_type,self.name,self.d_type,type(self.value) == "table" and self.value:tostring() or self.value) 
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

    return string.format("(%s, %s, %s)",self.op_token.value,self.left_node:tostring() or "<LEFTNODE>",self.right_node:tostring() or "<RIGHTNODE>")
end

return Nodes
