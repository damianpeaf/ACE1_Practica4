mStringVariables macro
    numberString db 6 dup (?)
    numberStringEnd db "$"
    
    stringRepresentationErrorMessage db "Error: The number is too big to be represented", 0dh, 0ah, "$"
    
    negativeNumber db 0

    rowHeader db 2 dup (?)
    rowHeaderEnd db "$"
endm


; Description: Converts a sign number of 16 bits to an ascii representation string
; Input : AX - number to convert
; Output: DX - 0 if no error, 1 if error
;         numberString - the string representation of the number
mNumberToString macro

    LOCAL convert_positive, convert_negative, extract_digit, representation_error, fill_with_0, set_digit, end, empty_stack, set_negative
    
    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cx, 0

    ; Comparte if its a negative number
    cmp ax, 0
    jge convert_positive

    convert_negative:

        mov [negativeNumber], 1 ; Set the negative number flag to 1
        inc cx

        ; Convert to positive
        neg ax
        jmp convert_positive
    
    convert_positive:
        mov bx, 0ah

        extract_digit:
            mov dx, 0 ; Clear the dx register [Remainder]
            div bx ; Divide the AX number by 10 and store the remainder in dx
            add dl, '0' ; Convert the remainder to ascii
            push dx ; Push the remainder to the stack
            inc cx ; Increment the digit counter
            cmp ax, 0 ; Check if the number is 0
            jne extract_digit ; If not, extract the next digit

    ; No representable number
    cmp cx, 6
    jg representation_error

    ; ------------------- Fill the string -------------------
    mov si, 0

    ; Fill with 0 every digit that is not used
    mov dx, 6
    sub dx, cx
    cmp dx, 0
    jz set_negative

    fill_with_0:
        mov numberString[si], '0'
        inc si
        dec dx
        jnz fill_with_0

    set_negative:

    ; If the number is negative, add the '-' sign
    cmp [negativeNumber], 1
    jne set_digit
    mov numberString[si], '-'
    inc si
    dec cx

    ; Copy the digits to the string
    set_digit:
        pop dx
        mov numberString[si], dl
        inc si
        loop set_digit

    mov dx, 0 ; NO ERROR
    jmp end

    representation_error:
        mPrint stringRepresentationErrorMessage

        ; empty the stack
        empty_stack:
            pop dx
            loop empty_stack

        mov dx, 1 ; ERROR

    end:
        ; REGISTER RESTORATION
        pop si
        pop dx
        pop cx
        pop bx
        pop ax

endm


; Description: Prints a a number from 0 to 24 formated as 2 digit string
; Input : AX - number to print
; Output: -
mPrintRowHeader macro

    LOCAL print_digit, end

    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push dx

    mov bx, 0a
    mov dx, 0

    print_digit:
        div bx
        add dl, '0'
        push dx
        cmp ax, 0
        jne print_digit

    end:
        pop dx
        mov rowHeader[0], dl
        pop dx
        mov rowHeader[1], dl

        mPrint rowHeader

        ; REGISTER RESTORATION
        pop dx
        pop cx
        pop bx
        pop ax

endm
