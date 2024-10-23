local Lexer = require "src.lexer"
local Parser = require "src.parser"

local lexer = Lexer.new("10 * 3 5 / 5 69 + 21 5","Playground")
local err = lexer:tokenize()

if err then
    return print(err:what())
end

local parser = Parser.new(lexer.tokens)
local ast = parser:parse()

if ast then
    for key, node in pairs(ast) do
        print(node:tostring())
    end
end

-- print("-------------------------------\n")

-- print "["
--     for _,token in ipairs(lexer.tokens) do
--         print("  "..token:typeid_tostring() .. ": " .. token.value)
--     end
-- print "]"

-- io.output(io.open("dist/out.s","w+"))
-- io.write(output)
