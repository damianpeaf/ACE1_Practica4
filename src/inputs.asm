mInputVariables macro

commandBuffer db 100h dup('$')

endm



mWaitForEnter macro
    LOCAL press_enter
    press_enter:
        mov AH, 08h
        int 21h
        cmp AL, 0dh
        jne press_enter
endm

mWaitForInput macro

    local reinit_loop

    push ax
    push bx
    push cx
    push dx

    ; reinit buffer
    mov cx, 0feh
    mov si, 2
    mov al, '$'

    reinit_loop:
        mov commandBuffer[si], al
        inc si
        loop reinit_loop

    lea dx, commandBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

endm