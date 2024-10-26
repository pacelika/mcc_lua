local SymbolTable = {}

function SymbolTable.append_node(node)
    SymbolTable[node.name] = node
end

return SymbolTable
