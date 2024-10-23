local Lexer = require "src.lexer"
local Parser = require "src.parser"
local should_print_tokens = false

local lexer = Lexer.new("(* (+ 1 2) (- 5 6)) (* 21 69)","Playground")
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

if should_print_tokens then
    print("-------------------------------\n")

    print "["
        for _,token in ipairs(lexer.tokens) do
            print("  "..token:typeid_tostring() .. ": " .. token.value)
        end
    print "]"
end

-- io.output(io.open("dist/out.s","w+"))
-- io.write(output)
