
mWaitForEnter macro
    LOCAL press_enter
    press_enter:
        mov AH, 08h
        int 21h
        cmp AL, 0dh
        jne press_enter
endm