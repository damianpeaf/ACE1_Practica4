mPrint macro variable
    mov dx, offset variable
    mov ah, 09h
    int 21h
endm


mPrintAddress macro address
    mov dx, address
    mov ah, 09h
    int 21h
endm


            
            