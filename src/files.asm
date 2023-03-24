
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

    local open_file_error,replace_comma_with_end,no_replace_comma, end, success, reset_filereadbuffer_loop, read_file_error, close_file_error, extract_headers_loop_end, ask_headers_order_loop

    ; register protection
    push ax
    push bx
    push cx

    ;  OPEN FILE
    clc
    mov CX, 00
    mov DX, offset filenameBuffer ; Filename
    mov AL, 00 ; Read only
    mov AH, 3dh ; Open
    int 21
    jc open_file_error
    mov [filehandle], AX ; Save the filehandle


    ; Reset filereadbuffer
    mov cx, 100h
    mov al, '$'
    lea di, filereadbuffer

    reset_filereadbuffer_loop:
        mov [di], al
        inc di
        loop reset_filereadbuffer_loop

    lea di, filereadbuffer

    ;  READ CHAR BY CHAR the headers
    extract_headers_loop:
        mov BX, [filehandle] ; Filehandle
        mov CX, 1 ; Read 1 byte
        mov DX, DI ; Buffer
        mov AH, 3fh
        int 21
        jc read_file_error

        ; Evaluate the read character
        mov al, [di]

        ; If the character is a new line, then we have read the headers
        cmp al, '$'
        je extract_headers_loop_end

        cmp al, 0dh ; CR
        je extract_headers_loop_end

        cmp al, 0ah ; LF
        je extract_headers_loop_end

        ; Because if a csv, replace the comma with a $
        cmp al, ','
        je replace_comma_with_end
        jmp no_replace_comma

        replace_comma_with_end:
            mov al, '$'
            mov [di], al

        no_replace_comma:
            inc di
            jmp extract_headers_loop

    extract_headers_loop_end:
    mov al, '$' ; End of the headers
    mov [di], al

    ; ASK FOR HEADER ORDER
    lea di, filereadbuffer ; start of the headers
    ask_headers_order_loop:
        mPrint columnRequest
        mPrintAddress di
        mPrint columnRequestDelimiter
        mWaitForEnter
        mPrint newLine

        ; TODO - EVAL Column order

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
    mWaitForEnter
    ;  close
    mov bx, [filehandle]
    mov AH, 3eh
    int 21
    jc close_file_error
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
        jmp end

    close_file_error:
        mPrint closeFileError
        mov dx, 1
        jmp end

    success:
        mov dx, 0
        jmp end

    end:
        ; register restoration
        pop cx
        pop bx
        pop ax

endm