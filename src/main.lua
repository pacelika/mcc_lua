local Lexer = require "src.lexer"

local lexer = Lexer.new("(404) 3.14","Playground")

local err = lexer:tokenize()

if err then
    return print(err:what())
end

for _,token in ipairs(lexer.tokens) do
    print(token:typeid_tostring() .. ": " .. token.value)
end

-- io.output(io.open("dist/out.s","w+"))
-- io.write(output)
