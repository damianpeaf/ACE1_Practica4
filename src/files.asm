
mFilesVariables macro 

    filenameBuffer db 100h dup(0)
    filereadbuffer db 100h dup("$")
    filehandle dw 0

    openFileError db "Error al abrir el archivo", 0dh, 0ah, "$"
    readFileError db "Error al leer el archivo", 0dh, 0ah, "$"
    closeFileError db "Error al cerrar el archivo", 0dh, 0ah, "$"
    selectedFile db "Archvivo seleccionado: ", "$"

    columnRequest db "Columna para ", "$"
    columnRequestDelimiter db " : ", "$"
    noValidColumn db "No es una columna valida", 0dh, 0ah, "$"

    testFileName db "test.csv ", "$" ; !!!!!!!!!

    insertColumnOrder db 0bh dup(0)
    lastColumnOrderIndex db 0
    lastInsertedRowNumber db 0
    insertNumberBuffer db 100h dup(0)
    breakInsertLoop db 0
endm


; Description: Get the filename of the file from the command buffer 
; Parameters:  SI - Current position in the command buffer [filename]
;              Saves the filename in the filenameBuffer
mGetFileName macro

    local copy_char_loop, copy_char_loop_end, reset_filename_buffer_loop

    push di
    push ax
    push cx

    lea di, filenameBuffer

    ; Reset the filename buffer
    mov cx, 100h
    mov al, 0
    reset_filename_buffer_loop:
        mov [di], al
        inc di
        loop reset_filename_buffer_loop

    lea di, filenameBuffer

    copy_char_loop:
        mov al, [si]

        cmp al, '$'
        je copy_char_loop_end

        cmp al, 0dh
        je copy_char_loop_end

        cmp al, ' '
        je copy_char_loop_end

        mov [di], al ; Copy the character
        inc di
        inc si
        jmp copy_char_loop

    copy_char_loop_end:
        mov al, '$'
        inc di
        mov [di], al
        mPrint selectedFile
        mPrint filenameBuffer
        mPrint newLine

        pop cx
        pop ax
        pop di
endm


; Description: Open a file for reading
; Parameters:  filenameBuffer - The filename of the file to open
;              filehandle - The filehandle of the opened file
; Return:  dx (0 if success, 1 if error)
mReadImportFile macro

    local close_file, open_file_error,replace_comma_with_end,no_replace_comma, end, success, reset_filereadbuffer_loop, read_file_error, close_file_error, extract_headers_loop_end, ask_headers_order_loop

    ; register protection
    push ax
    push bx
    push cx
    push si

    ;  OPEN FILE
    clc
    mov CX, 00
    ; mov DX, offset filenameBuffer ; Filename
    mov DX, offset testFileName ; !!!!!!!!
    mov AL, 00 ; Read only
    mov AH, 3dh ; Open
    int 21
    jc open_file_error
    mov [filehandle], AX ; Save the filehandle

    mExtractLineFromCSV
    cmp dx, 1
    je read_file_error

    cmp dx, 2
    je read_file_error
    ; ????

    ; ASK FOR HEADER ORDER
    mResetColumnOrder ; Reset the column order
    mov [lastColumnOrderIndex], 0 ; Reset the last column order index

    lea di, filereadbuffer ; start of the headers
    ask_headers_order_loop:
        mPrint columnRequest
        mPrintAddress di
        mPrint columnRequestDelimiter

        mEvalColumn
        cmp dx, 1
        je read_file_error


        mPrint newLine
        ; Move to the next header
        move_to_next_header_loop:
            mov al, [di]
            inc di
            cmp al, '$'
            je move_to_next_header_loop_end

            jmp move_to_next_header_loop

        move_to_next_header_loop_end:
            mov al, [di]
            cmp al, '$'
            je ask_headers_order_loop_end

            jmp ask_headers_order_loop

    ask_headers_order_loop_end:

    ; Insert the values

    mInsertValues
    cmp dx, 1
    je read_file_error

    jmp success
    
    open_file_error:
        mPrint openFileError
        mPrint newLine
        ; Error code in ax
        mNumberToString
        mPrint numberString
        mPrint newLine
        
        mov dx, 1
        jmp end

    read_file_error:
        mPrint readFileError
        mov dx, 1
        jmp close_file

    close_file_error:
        mPrint closeFileError
        mov dx, 1
        jmp end

    success:
        mov dx, 0
        jmp close_file

    close_file:
        ; Close the file
        mov bx, [filehandle]
        mov AH, 3eh
        int 21
        jc close_file_error

    end:
        ; register restoration
        pop cx
        pop bx
        pop ax

endm


mResetFileReadBuffer macro
    local reset_filereadbuffer_loop
    ; Reset filereadbuffer
    mov cx, 100h
    mov al, '$'
    lea di, filereadbuffer

    reset_filereadbuffer_loop:
        mov [di], al
        inc di
        loop reset_filereadbuffer_loop
endm

mResetColumnOrder macro
    local reset_column_order_loop

    push di
    push ax
    push cx

    ; Reset the column order
    mov cx, 0bh
    mov al, 0
    lea di, insertColumnOrder

    reset_column_order_loop:
        mov [di], al
        inc di
        loop reset_column_order_loop
    pop si
    pop cx
    pop ax
    pop di
endm

; Description: Get the column number [0-10] from the command buffer
; Return: Save the column number in the insertColumnOrder buffer
mEvalColumn macro

    local error, end, success

    push di ; will point to the insertColumnOrder buffer
    push si ; will point to the command buffer
    push ax

    mWaitForInput
    lea si, commandBuffer
    inc si ; Move to char count

    mov al, [si]
    cmp al, 1
    jne error

    inc si ; Move to the first char

    mov al, [si]
    cmp al, 'A'
    jl error

    cmp al, 'K'
    jg error

    sub al, 'A' ; Convert to column index

    mov bx, 0
    mov bl, [lastColumnOrderIndex] ; ah is the last column order index

    cmp bl, 0bh ; If the last column order index is 11, then we have reached the maximum columns
    je error

    mov di, bx ; di is now the last column order index

    mov insertColumnOrder[di], al

    inc bl
    mov [lastColumnOrderIndex], bl ; Save the last column order index

    success:
        mov dx, 0
        jmp end

    error:
        mov dx, 1
        mPrint noValidColumn
        jmp end

    end:
        pop ax
        pop si
        pop di
endm


mInsertValues macro 

    local end, success, error, extract_values_loop,final_iteration, continue

    mov [lastColumnOrderIndex], 0 ; Reset the last column order index
    mov [lastInsertedRowNumber], 0 ; Reset the last inserted row number
    mov [breakInsertLoop], 0 ; Reset the break insert loop flag
    extract_values_loop:
        mExtractLineFromCSV
        cmp dx, 2 ; EOF
        je final_iteration
        jmp continue

        final_iteration:
            mov [breakInsertLoop], 1 ; Reset the break insert loop flag

        continue:
            lea si, filereadbuffer ; si start of the filereadbuffer
        
        eval_value:
            ; EVAL THE VALUES

            mCheckNumberReference
            cmp dx, 0
            je error

            ; Now in numberReference we have the value to insert

            push di
            push si

            ; Compute the cell address
            mov ax, 0
            mov al, [lastColumnOrderIndex]
            
            mov si, ax ; si is now the last column order index
            mov ax, 0
            mov al, insertColumnOrder[si] ; Column index
            mov dx, ax

            mov ax, 0
            mov al, [lastInsertedRowNumber] ; Row index

            mComputeDataSheetIndex ; Now in BX we have the datasheet index

            ; Insert the value
            mov ax, [numberReference]
            mov datasheet[BX], ax

            mPrintDatasheet
            mWaitForEnter

            pop si
            pop di 

            ; Move to the next column
            mov al, [si]
            cmp al, '$'
            je eval_next_column

            eval_next_column:
                mov al, [si+1]
                cmp al, '$' ; end of the row
                je eval_next_row

                ; then we have a comma
                ; move to the next column
                mov al, [lastColumnOrderIndex]
                inc al
                mov [lastColumnOrderIndex], al

                inc si ; Move to the next char
                jmp eval_value

            eval_next_row:

                ; increment the row number
                mov al, [lastInsertedRowNumber]
                inc al
                mov [lastInsertedRowNumber], al

                ; Reset the column order index
                mov [lastColumnOrderIndex], 0

                ; Check if we have to break the loop
                mov al, [breakInsertLoop]
                cmp al, 1
                je success

                jmp extract_values_loop
    success:
        mov dx, 0
        jmp end
     
    error:
        mov dx, 1
        jmp end

    end:
endm

; Description: Extract a line from the csv file
; Return: Save the line in the filereadbuffer, and replace ',' with $
;         dx = 0 if success, dx = 1 if error, dx = 2 if eof
mExtractLineFromCSV macro

    local extract_form_csv, extract_form_csv_end, replace_comma_with_end, no_replace_comma, error, success, eof

    ; Reset filereadbuffer
    mResetFileReadBuffer

    lea di, filereadbuffer

    ;  READ CHAR BY CHAR the headers
    extract_form_csv:
        mov BX, [filehandle] ; Filehandle
        mov CX, 1 ; Read 1 byte
        mov DX, DI ; Buffer
        mov AH, 3fh
        int 21
        jc error

        ; Check if EOF
        cmp ax, 1
        jne eof

        ; Evaluate the read character
        mov al, [di]

        ; If the character is a new line, then we have read the headers
        cmp al, '$'
        je success

        cmp al, 0dh ; CR
        je success

        cmp al, 0ah ; LF
        je success

        cmp al, 0 ; EOF
        je success

        ; Because if a csv, replace the comma with a $
        cmp al, ','
        je replace_comma_with_end
        jmp no_replace_comma

        replace_comma_with_end:
            mov al, '$'
            mov [di], al

        no_replace_comma:
            inc di
            jmp extract_form_csv

    eof:
        mov dx, 2
        jmp extract_form_csv_end
    
    error:
        mov dx, 1
        jmp extract_form_csv_end

    success:
        ; Read the last char of the line
        mov BX, [filehandle] ; Filehandle
        mov CX, 1 ; Read 1 byte
        mov DX, DI ; Buffer
        mov AH, 3fh
        int 21

        mov al, '$' ; End of the headers
        mov [di], al

        mov dx, 0
        jmp extract_form_csv_end

    extract_form_csv_end:

endm


; Entry:  DX  -> Col
;         AX  -> Row
; return: BX  -> Datasheet index
mComputeDataSheetIndex macro
    mov bx, 0
    mov bx, datasheetNumCols

    mul bx ; row * numCols

    add ax, dx ; row * numCols + col

    ; Because the datasheet is a 2 byte array, we need to multiply the index by 2
    mov bx, 2
    mul bx ; (row * numCols + col) * 2

    mov bx, ax
endm