
mFilesVariables macro 

    filenameBuffer db 100h dup(0)
    filereadbuffer db 100h dup("$")
    filehandle dw 0

    openFileError db "Error al abrir el archivo", 0dh, 0ah, "$"
    readFileError db "Error al leer el archivo", 0dh, 0ah, "$"
    closeFileError db "Error al cerrar el archivo", 0dh, 0ah, "$"
    selectedFile db "Archvivo seleccionado: ", "$"

    columnRequest db "Columna para ", "$"
    headerRequest db "Encabezado para ", "$"
    columnRequestDelimiter db " : ", "$"
    noValidColumn db "No es una columna valida", 0dh, 0ah, "$"

    insertColumnOrder db 0bh dup(0)
    lastColumnOrderIndex db 0
    lastInsertedRowNumber db 0
    insertNumberBuffer db 100h dup(0)
    breakInsertLoop db 0

    charBuffer db 0
    charBufferEnd db "$"

    ; Html variables

    pageHeader db "<!DOCTYPE html>", 0ah, "<html>", 0ah, "<head>", 0ah, "<title>Data Sheet</title>", 0ah, "</head>", 0ah, "<body>", 0ah

    dateHeader db "<h1> Fecha de generacion: "
    dateFooter db "</h1>", 0ah

    hourHeader db "<h2> Hora de generacion: "
    hourFooter db "</h2>", 0ah

    tableHeader db "<table border='1'>", 0ah

    trOpen db "<tr>", 0ah
    trClose db "</tr>", 0ah

    tdOpen db "<td>"
    tdClose db "</td>", 0ah

    tableFooter db "</table>", 0ah

    pageFooter db "</body>", 0ah, "</html>", 0ah

    dateDelimiter db "/"
    hourDelimiter db ":"

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

; --------------------------------- IMPORT FILE ---------------------------------

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
    mov CX, 00
    mov DX, offset filenameBuffer ; Filename
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
        pop si
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
    push si

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

    mov ax , 0
    mov al, [si]
    cmp al, 'A'
    jl error

    cmp al, 'K'
    jg error

    sub al, 'A' ; Convert to column index

    mov cx, 0
    mov cl, [lastColumnOrderIndex] ; ah is the last column order index

    cmp cl, 0bh ; If the last column order index is 11, then we have reached the maximum columns
    je error

    mov di, cx ; di is now the last column order index

    mov insertColumnOrder[di], al

    mov ax, di
    add ax, 1
    mov [lastColumnOrderIndex], al ; Save the last column order index

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

            mov cx, 0
            mov cl, insertColumnOrder[si] ; Column index
            
            mov ax, 0
            mov al, [lastInsertedRowNumber] ; ROWS -> AX

            mov bx, 0bh
            mul bx ; ROWS * 11d

            add ax, cx ; ROWS * 11d + COLS

            ; Because the datasheet is a 2 byte array, we need to multiply the index by 2
            mov bx, 2
            mul bx ; (row * numCols + col) * 2

            ; Insert the value
            mov si, ax ; si is now the address of the cell
            mov ax, [numberReference]
            mov datasheet[si], ax

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
                mov ax, 0
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

; ---------------------------------------- EXPORT FILE ----------------------------------------

; Description: Export the datasheet to a .htm file
; Input: [1] number reference, [2] Column reference, [3] Filename buffer
; Return: dx = 0 if success, dx = 1 if error. If success create the file 
mExportFile macro 

    local error, success, end, invalid_range, request_headers_loop, open_file_error, close_file

    ; Valid range
    mov ax, [numberReference]
    mov dx, 0
    mov dl, [cellColReference]

    cmp ax, 0
    jl invalid_range

    dec ax

    add ax, dx
    cmp ax, 0ah
    jg error

    ; Save headers
    mResetFileReadBuffer ; just for reuse the buffer

    mov cx, [numberReference]
    mov dl, [cellColReference]
    add dl, "A"
    lea di, filereadbuffer
    request_headers_loop:

        mPrint headerRequest
        mPrintChar dl
        mPrint columnRequestDelimiter

        mGetHeader
        mPrint newLine

        inc dl

        dec cx
        jnz request_headers_loop


    ; Create file
    mov cx, 0 ; Read-only
    mov dx, offset filenameBuffer
    mov ah, 3ch
    int 21h
    jc error

    mov [filehandle], ax

    ; Write html start
    mWriteHtmlStart
    
    ; Write the hour and date
    mWriteDateAndHour

    ; Write the datasheet
    mWriteDatasheet

    ; Write html end
    mWriteHtmlEnd

    ; Close file
    jmp success

    open_file_error:
        mov dx, 1
        jmp close_file

    close_file:
        push ax
        push bx

        mov bx, [filehandle]
        mov ah, 3eh
        int 21h

        pop bx
        pop ax
        jmp end

    success:
        mov dx, 0
        jmp close_file

    invalid_range:
        mPrint invalidRangeError
        mPrint newLine
        jmp error

    error:
        mov dx, 1
        jmp end

    end:

endm



mGetHeader macro 

    local copy_char, end

    push si
    push ax

    mWaitForInput
    lea si, commandBuffer
    add si, 2

    copy_char:
        mov al, [si]

        ; Check end of command buffer
        cmp al, 0
        je end

        cmp al, 0ah ; LF
        je end

        cmp al, 0dh ; CR
        je end

        cmp al, '$'
        je end

        mov [di], al
        inc di
        inc si
        jmp copy_char


    end:

    inc di ; left $ beetwen headers

    pop ax
    pop si

endm


mWriteHtmlStart macro 

    mov bx, [filehandle]
    mov cx, sizeof pageHeader
    lea dx, pageHeader
    mov ah, 40h
    int 21h

endm

mWriteHtmlEnd macro 

    mov bx, [filehandle]
    mov cx, sizeof pageFooter
    lea dx, pageFooter
    mov ah, 40h
    int 21h

endm

mWriteDateAndHour macro 

    ; ----- DATE -----
    mov bx, [filehandle]
    mov cx, sizeof dateHeader
    lea dx, dateHeader
    mov ah, 40h
    int 21h

    mov ah, 2ah
    int 21h
    ; DL = day, DH = month, CX = year

    ; Write day
    mov ax, 0
    mov al, dl
    mWrite2DigitNumber

    mWriteDelimiter dateDelimiter

    ; Write month
    mov ah, 2ah
    int 21h
    mov ax, 0
    mov al, dh
    mWrite2DigitNumber

    mWriteDelimiter dateDelimiter

    ; Write year
    mov ah, 2ah
    int 21h
    mov ax, cx
    mWrite2DigitNumber

    mov bx, [filehandle]
    mov cx, sizeof dateFooter
    lea dx, dateFooter
    mov ah, 40h
    int 21h


    ; ----- HOUR -----

    mov bx, [filehandle]
    mov cx, sizeof hourHeader
    lea dx, hourHeader
    mov ah, 40h
    int 21h

    mov ah, 2ch
    int 21h
    ; CH = hour, CL = minute, DH = second

    ; Write hour
    mov ax, 0
    mov al, ch
    mWrite2DigitNumber

    mWriteDelimiter hourDelimiter

    ; Write minute
    mov ah, 2ch
    int 21h
    mov ax, 0
    mov al, cl
    mWrite2DigitNumber

    mWriteDelimiter hourDelimiter

    ; Write second
    mov ah, 2ch
    int 21h
    mov ax, 0
    mov al, dh
    mWrite2DigitNumber
    
    mov bx, [filehandle]
    mov cx, sizeof hourFooter
    lea dx, hourFooter
    mov ah, 40h
    int 21h

endm


mWriteDelimiter macro delimiter
    mov bx, [filehandle]
    mov cx, sizeof delimiter
    lea dx, delimiter
    mov ah, 40h
    int 21h
endm

; Put in ax the number to write
mWrite2DigitNumber macro

    mNumberToString
    lea dx, numberString
    add dx, 4 ; Last 2 digits of the day
    mov bx, [filehandle]
    mov cx, 2
    mov ah, 40h
    int 21h

endm

mWriteDatasheet macro

    local headers_loop, end_headers_loop,write_header

    ; Table start
    mov bx, [filehandle]
    mov cx, sizeof tableHeader
    lea dx, tableHeader
    mov ah, 40h
    int 21h

    ; Write the headers
    mWriteTag trOpen

    lea si, filereadbuffer
    headers_loop:
        
        mWriteTag tdOpen

        mPrintAddress si
        mWaitForEnter

        ; Write the header
        write_header:
            mov al, [si]
            
            cmp al, '$' ; next header
            je next_header

            cmp al, 0
            je next_header

            mWriteChar al

            inc si
            jmp write_header


        next_header:
            mWriteTag tdClose
            inc si
            mov al, [si]
            cmp al, '$' ; Double $
            je end_headers_loop

            jmp headers_loop


    end_headers_loop:
    mWriteTag trClose

endm

mWriteTag macro tag
    mov bx, [filehandle]
    mov cx, sizeof tag
    lea dx, tag
    mov ah, 40h
    int 21h 
endm


mWriteChar macro char
    mov [charBuffer], char
    mov bx, [filehandle]
    mov cx, 1
    mov dx, offset charBuffer
    mov ah, 40h
    int 21h
endm