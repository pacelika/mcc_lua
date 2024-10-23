local Nodes = {}

Nodes.NumberNode = {}
Nodes.BinOp = {}

function Nodes.NumberNode.new(token)
    return setmetatable({
        token = token,
    },{__index = Nodes.NumberNode})
end

function Nodes.NumberNode:tostring()
    return string.format("NumberNode: %s: %s",self.token:typeid_tostring(),self.token.value)
end

function Nodes.BinOp.new(left_node,op_token,right_node)
    return setmetatable({
        left_node = left_node,
        op_token = op_token,
        right_node = right_node
    },{__index = Nodes.BinOp})
end

function Nodes.BinOp:tostring()
    return string.format("BinOp: (%s, %s, %s)",self.left_node.token.value,self.op_token.value,self.right_node.token.value)
end

return Nodes
