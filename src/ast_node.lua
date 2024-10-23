local Nodes = {}

Nodes.NumberNode = {}
Nodes.BinOp = {}

function Nodes.NumberNode.new(token)
    return setmetatable({
        token = token,
    },{__index = Nodes.NumberNode})
end

function Nodes.NumberNode:tostring()
    if not self.token or not self.token.value then return "<nan>" end
    return string.format("%s: %s",self.token:typeid_tostring(),self.token.value)
end

function Nodes.BinOp.new(left_node,op_token,right_node)
    return setmetatable({
        left_node = left_node,
        op_token = op_token,
        right_node = right_node
    },{__index = Nodes.BinOp})
end

function Nodes.BinOp:tostring()
    if not self.left_node or not self.right_node or not self.op_token then
        return print("ERROR: cannot perform tostring on BinOp node.")
    end

    return string.format("(%s, %s, %s)",self.op_token.value,self.left_node:tostring() or "<LEFTNODE>",self.right_node:tostring() or "<RIGHTNODE>")
end

return Nodes
