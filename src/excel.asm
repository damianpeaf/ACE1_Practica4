mDatasheetVariables macro
    columnHeader           db '      A      B      C      D      E      F      G      H      I      J      K', "$"
    promptIndicator        db ">> ", "$"

    datasheet              dw 0fdh dup(0)
    datasheetNumRows       equ 17
    datasheetNumCols       equ 0b

    ; ---- References ----
    ; NOTE: Valid numbers are from [-32767 - 32767]
    returnReference        dw 1 ; Return reference, resultant number [*]
    cellRowReference       db 0 ; row of the cell reference    [0d - 22d] [0h - 16h]
    cellColReference       db 0 ; column of the cell reference [0d - 10d] [0h - 0ah]
    cellIndexReference     dw 0 ; cell index of the cell reference
    numberReference        dw 0 ; Sign number reference 

    ; ---- Commands ----

    ; Cell operations 
    commandSetCell         db "GUARDAR"
    
    ; Arithmetic operations
    
    commandSum             db "SUMA"
    commandSubstract       db "RESTA"
    commandMultiply        db "MULTIPLICAR"
    commandDivide          db "DIVIDIR"
    commandPower           db "POTENCIA"

    ; Logical operations
    commandOr              db "OLOGICO"
    commandAnd             db "YLOGICO"
    commandNot             db "NOLOGICO"
    commandXor             db "OXLOGICO"

    ; range operations

    commandFill            db "LLENAR"
    commandAverage         db "PROMEDIO"
    commandMin             db "MINIMO"
    commandMax             db "MAXIMO"

    ; General operations
    commandSeparator       db "Y"
    commandIn              db "EN"
    commandBetween         db "ENTRE"
    commandFrom            db "DESDE"
    commandTo              db "HASTA"
    commandExponent        db "A LA"
    commandFileDelimiter   db "SEPARADO POR COMA"
    commandFileDestination db "HACIA"
    commandExit            db "SALIR"

    ; input/output operations
    commandImport          db "IMPORTAR"
    commandExport          db "EXPORTAR"

    ; ---- Errors ----
    notRecognized          db "Comando no reconocido", "$"
    sourceReferenceError   db "Error en la referencia de origen", "$"
    destinationReferenceError db "Error en la referencia de destino", "$"
    destinationCellError   db "Error en la celda de destino", "$"


    debug                  db "!", "$"

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
    mPrint newLine
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
        push cx ; Save the row counter
        mNumberToString
        lea dx, numberString
        add dx, 4
        mPrintAddress dx

        ; Print the row
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

mEvalPromt macro
    
    ; Wait for the user to input a command
    mWaitForInput 
    mPrint newLine
    lea si, commandBuffer ; Load the input buffer address
    add si, 2 ; Skip the max length and the current length

    ; SET CELL
    mEvalCommand commandSetCell
    cmp dx, 0
    je set_operation

    ; IMPORT File
    mEvalCommand commandImport
    cmp dx, 0
    je import_file

    ; Sum
    mEvalCommand commandSum
    cmp dx, 0
    je sum_operation

    ; TODO: Rest of the commands

    ; EXIT
    mEvalCommand commandExit
    cmp dx, 0
    je end_program

    ; If the command is not recognized
    mPrint notRecognized
    mWaitForEnter

endm


mOperations macro
    
    set_operation:

        mSkipWhiteSpaces

        ; Reference [*, Cell, Number]
        mEvalReference
        cmp dx, 0
        je set_source_reference_error
        jmp eval_destination

        set_source_reference_error:
            mPrint sourceReferenceError
            mWaitForEnter
            jmp end_set_operation

        eval_destination:
            mov bx, ax ; Save the source reference in bx
            mSkipWhiteSpaces

            mEvalCommand commandIn
            cmp dx, 1
            je set_command_error

            mSkipWhiteSpaces

            mCheckCellReference ; Here the prev ax reference is lost
            cmp dx, 0
            je set_destination_cell_error

            mov di, [cellIndexReference]
            mov datasheet[di], bx
            jmp end_set_operation

        set_destination_cell_error:
            mPrint destinationCellError
            mWaitForEnter
            jmp end_set_operation

        set_command_error:
            mPrint notRecognized
            mWaitForEnter
            jmp end_set_operation

        end_set_operation:
            jmp datasheet_sequence

    import_file:
        mSkipWhiteSpaces

        ; Get the file name
        mGetFileName
        mSkipWhiteSpaces
        mEvalCommand commandFileDelimiter
        cmp dx, 1
        je import_file_error

        test_file:
        ; Open and read the file
        mReadImportFile
        cmp dx, 1
        je read_file_error


        jmp end_import_file


        import_file_error:
            mPrint notRecognized
        read_file_error:
            mWaitForEnter
            jmp end_import_file

        end_import_file:
            jmp datasheet_sequence


    sum_operation:
        mGenericCellOperation
        ; Compute the sum
        add ax, dx

        ; Save the result in the 'return' reference
        mov [returnReference], ax
        jmp end_operation

    operation_source_referece_error:
        mPrint sourceReferenceError
        mWaitForEnter
        jmp end_operation

    operation_destination_referece_error:
        mPrint destinationReferenceError
        mWaitForEnter
        jmp end_operation

    operation_invalid_command:
        mPrint notRecognized
        mWaitForEnter
        jmp end_operation

    end_operation:
        jmp datasheet_sequence
endm

; Description: Get the 'source' and 'destination' references
; Return: ax - source reference, dx - destination reference
mGenericCellOperation macro
    mSkipWhiteSpaces
    
    mEvalReference
    cmp dx, 0
    je operation_source_referece_error
    push ax ; Save the source reference

    mSkipWhiteSpaces
    mEvalCommand commandSeparator
    cmp dx, 1
    je operation_invalid_command

    mSkipWhiteSpaces

    mEvalReference ; Evaluate the second number
    cmp dx, 0
    je operation_destination_referece_error

    mov dx, ax ; Save the second number in dx
    pop ax ; Restore the first number in ax
endm

; Description: Evaluates if the input buffer contains the command
; Input: si - input buffer address
; Return: dx - 0 -> command recognized
;            - 1 -> command not recognized
mEvalCommand macro command
    
    local recognized, end
    lea di, command ; Load the command address
    mov cx, sizeof command ; Load the command length
    
    ; Compare the input buffer with the command
    mCompareStrings
    
    ; If the command is recognized
    cmp dx, 0
    je recognized
    mov dx, 1
    jmp end

    recognized:
        add si, cx ; Skip the command
        mov dx, 0
    end:

endm


; Description: Evaluates if the input buffer contains a reference [*, Cell, Number]
; Input: si - input buffer address
; Output: dx - 0 -> invalid reference
;            - 1 -> * reference
;            - 2 -> Cell reference
;            - 3 -> Number reference
;         si - points to final position of the reference
;         ax - number reference
mEvalReference macro

    local return_reference, cell_reference, number_reference, end

    ; Check if it is a cell reference
    mCheckReturnReference
    cmp dx, 1
    je return_reference

    ; Check if it is a cell reference
    mCheckCellReference
    cmp dx, 1
    je cell_reference

    ; Check if it is a number reference
    mCheckNumberReference
    cmp dx, 1
    je number_reference

    mov dx, 0 ; Set the default value to invalid reference
    jmp end

    return_reference:
        mov dx, 1
        jmp end

    cell_reference:
        mov dx, 2
        jmp end

    number_reference:
        mov dx, 3
        jmp end
    
    end:

endm


; Description: Evaluates if the input buffer contains a return [*] reference
; Input: si - input buffer address [NO MODIFICATION]
; Output: dx - 0 -> invalid reference
;            - 1 -> * reference
;         ax - reference
mCheckReturnReference macro
    local return_reference, end

    push ax
    mov al, [si] ; Load the first character

    ; Check *
    cmp al, '*'
    je return_reference

    ; If it is not a return reference
    mov dx, 0
    pop ax
    jmp end

    return_reference:
        pop ax
        mov ax, [returnReference]
        mov dx, 1
        inc si ; Skip the reference

    end:

endm

; Description: Evaluates if the input buffer contains a cell reference [Cell]
; Input: si - input buffer address. [MODIFICATES] if it is a cell reference
;                                   [NO MODIFICATION] if it is not a cell reference
; Output: dx - 0 -> invalid reference
;            - 1 -> Cell reference
;         ax - reference
mCheckCellReference macro

    local cell_reference, no_cell_reference, end

    push bx
    push ax
    push si 

    ; Valid column
    mov al, [si] ; Load the first character
    cmp al, 'A'
    jl no_cell_reference

    cmp al, 'K'
    jg no_cell_reference

    sub al, 'A' ; Convert to column index

    mov dx, 0
    mov dl, al ; Save the column index
    mov [cellColReference], dl

    inc si ; Skip the column
    ; Valid row
    mCheckNumberReference
    cmp dx, 0
    je no_cell_reference
    mov [numberReference], bx ; restore the prev value of numberReference
    dec ax ; Now in AX we have the row number in 0 based index

    ; validate the row number
    cmp ax, 0
    jl no_cell_reference

    cmp ax, datasheetNumRows
    jge no_cell_reference

    ; Save the cell row/col
    mov [cellRowReference], al

    ; Compute the cell index [col + row * numCols]

    ; save AH, AL
    mov bx, 0
    mov bx, datasheetNumCols

    mul bx ; row * numCols

    mov dx, 0
    mov dl, [cellColReference] ; col
    add ax, dx ; row * numCols + col

    ; Because the datasheet is a 2 byte array, we need to multiply the index by 2
    mov bx, 2
    mul bx ; (row * numCols + col) * 2

    mov [cellIndexReference], ax

    cell_reference:
        mov dx, 1
        pop ax ; Restore prev value SI on AX, modify SI
        pop ax ; Restore prev value AX on AX, modify AX
        mov bx, [cellIndexReference]
        mov ax, datasheet[bx]
        jmp end

    no_cell_reference:
        mov dx, 0
        pop si
        pop ax
        jmp end

    end:
        pop bx

endm


; Description: Evaluates if the input buffer contains a number reference [Number]
; Input: si - input buffer address. [MODIFICATES] if it is a number reference
;                                   [NO MODIFICATION] if it is not a number reference
; Output: dx - 0 -> invalid reference
;            - 1 -> Number reference
;         ax - reference
mCheckNumberReference macro
    local num_reference, no_num_reference, end, negative, convert_number, eval_digit

    push bx
    push di
    push si

    ; String destination
    mResetNumberString
    mov di, 0 ; string relative address

    ; Check if it is a negative number
    mov al, [si] ; Load the first character
    cmp al, '-'
    je negative

    mov [negativeNumber], 0

    eval_digit:
        mov al, [si] ; Load character
        cmp al, '0'
        jl no_num_reference

        cmp al, '9'
        jg no_num_reference

        mov numberString[di], al ; Save the digit

        inc si ; Skip the digit
        inc di ; Next string position

        ; Check if it is the end of the number (white space)
        mov al, [si] ; Load character
        ; Check if it is the end of the string
        cmp al, '$'
        je convert_number

        cmp al, 0dh
        je convert_number

        cmp al, ' '
        je convert_number

        cmp al, ',' ; For CSV files
        je convert_number

        cmp di, 6 ; Destination String Max length
        jge no_num_reference

        jmp eval_digit

    num_reference:
        mov dx, 1
        pop ax ; Restore prev value SI on AX, modify SI
        mov ax, [numberReference]
        jmp end

    no_num_reference:
        mov dx, 0
        pop si
        jmp end

    negative:
        mov [negativeNumber], 1
        inc si ; Skip the negative sign
        jmp eval_digit

    convert_number:
        mStringToNumber
        cmp dx, 0
        je num_reference
        jmp no_num_reference

    end:
        pop di
        pop bx

endm