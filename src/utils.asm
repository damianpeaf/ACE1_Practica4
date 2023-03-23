mPrint macro variable
    push ax
    push dx

    mov dx, offset variable
    mov ah, 09h
    int 21h

    pop dx
    pop ax
endm


mPrintAddress macro address
    mov dx, address
    mov ah, 09h
    int 21h
endm


            
            