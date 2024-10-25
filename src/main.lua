local Lexer = require "src.lexer"
local Parser = require "src.parser"
local should_print_tokens = false

local file_name = arg[1]

if not file_name then
    return print "ERROR: no input file provided"
end

local source_file = io.open(file_name,"r")

if not source_file then
    return print(string.format("ERROR: could not open file: %s",file_name))
end

local source_code = source_file:read("*all")
source_file:close()

local lexer = Lexer.new(source_code,file_name)
local err = lexer:tokenize()

if err then
    return print(err:what())
end

if should_print_tokens then
    print("-------------------------------\n")

    print "["
        for _,token in ipairs(lexer.tokens) do
            print("  "..token:typeid_tostring() .. (token.value and ": " or "") .. (token.value or ""))
        end
    print "]"
end

local parser = Parser.new(lexer.tokens)
local ast,ast_err = parser:parse()

if ast_err then return print(ast_err) end

if ast then
    for _ , node in pairs(ast) do
        print(node:tostring())
    end
end


-- io.output(io.open("dist/out.s","w+"))
-- io.write(output)
