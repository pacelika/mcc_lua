local SymbolTable = {
    variables = {}
}

function SymbolTable.append_node(node)
    SymbolTable.variables[node.name] = node
end

return SymbolTable
