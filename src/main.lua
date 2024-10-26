local Lexer = require "src.lexer"
local Parser = require "src.parser"
local should_print_tokens = false
local AsmGen = require "src.asm_gen"

local file_name = arg[1]
local intent = arg[2]

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
    local dash_count = 64

    print("\t\t\t\tTokens")
    print(string.rep("-",dash_count))

    print "["
        for _,token in ipairs(lexer.tokens) do
            print("  "..token:typeid_tostring() .. (token.value and ": " or "") .. (token.value or ""))
        end
    print "]"

    print(string.rep("-",dash_count))
end

local parser = Parser.new(lexer.tokens)
local ast,ast_err = parser:parse()

if ast_err then return print(ast_err) end

if ast then
    local asm_gen = AsmGen.new(ast)

    if intent ~= "gen" then
        for _ , node in pairs(ast) do
            print(node:tostring())
        end
    end

    asm_gen.asm = asm_gen.asm .. "section .text\n"
    asm_gen.asm = asm_gen.asm .. "global _start\n"
    asm_gen.asm = asm_gen.asm .. "_start:\n"

    asm_gen:read_ast()

    -- asm_gen.asm = asm_gen.asm .. "\n"
    asm_gen.asm = asm_gen.asm .. "\tmov eax,1\n"
    asm_gen.asm = asm_gen.asm .. "\tint 0x80\n"

    if intent == "gen" then
        print(asm_gen.asm)
        io.output(io.open("dist/out.s","w+"))
        io.write(asm_gen.asm)
    end
end

