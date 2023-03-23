mDatasheetVariables macro
    columnHeader db '      A      B      C      D      E      F      G      H      I      J      K', "$"
    promptIndicator db ">> ", "$"

    datasheet dw 0fdh dup(0)
    datasheetNumRows equ 17
    datasheetNumCols equ 0b

    ; ---- Commands ----

    ; Cell operations 
    
    ; Arithmetic operations
    commandSetCell db "GUARDAR", "$"
    
    commandSum db "SUMA", "$"
    commandSubstract db "RESTA", "$"
    commandMultiply db "MULTIPLICAR", "$"
    commandDivide db "DIVIDIR", "$"
    commandPower db "POTENCIA", "$"

    ; Logical operations
    commandOr db "OLOGICO", "$"
    commandAnd db "YLOGICO", "$"
    commandNot db "NOLOGICO", "$"
    commandXor db "OXLOGICO", "$"

    ; range operations

    commandFill db "LLENAR", "$"
    commandAverage db "PROMEDIO", "$"
    commandMin db "MINIMO", "$"
    commandMax db "MAXIMO", "$"

    ; General operations
    commandSeparator db "Y", "$"
    commandIn db "EN", "$"
    commandBetween db "ENTRE", "$"
    commandFrom db "DESDE", "$"
    commandTo db "HASTA", "$"
    commandExponent db "A LA", "$"
    commandFileDelimiter db "SEPARADO POR COMA", "$"
    commandFileDestination db "HACIA, "$"


    ; input/output operations
    commandImport db "IMPORTAR", "$"
    commandExport db "EXPORTAR", "$"

endm

mProccessCommand macro

endm

mPrintDatasheet macro 

    local print_row, print_cell

    ; Register protection
    push ax
    push bx
    push cx
    push dx
    push si

    ; Print the row header
    mPrint columnHeader
    mPrint newLine

    ; Print the row
    mov cx, datasheetNumRows ; row counter
    mov si, 0 ; cell index
    mov ax, 0 ; row index
    print_row:
        ; Print the column header
        inc ax
        push ax
        mNumberToString
        lea dx, numberString
        add dx, 4
        mPrintAddress dx

        ; Print the row
        push cx ; Save the row counter
        mov cx, datasheetNumCols ; column counter

        print_cell:
            ; Print the cell
            mPrint whiteSpace
            mov ax, datasheet[si]
            mNumberToString
            mPrint numberString
            ; Increment the cell counter
            add si, 2

            ; Decrement the column counter
            dec cx
            jnz print_cell

        ; print new line
        mPrint newLine

        ; Restore the row counter
        pop cx
        pop ax

        dec cx
        jnz print_row

    ; Restore register protection
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

endm