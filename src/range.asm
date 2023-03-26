
mRangeVariables macro

    initialCoords    dw  0 ; [col, row]
    targetCoords     dw  0 ; [col, row]
    auxCoords        dw  0 ; [col, row]

    rangeType        dw  0 ; 0 = invalid, 1 = horizontal, 2 = vertical
    rangeIterations  dw  0 ; Number of cells to iterate through
    rangeDirection   dw  0 ; 0 = invalid, 1 = positive, 2 = negative
    currentIteration dw 0 ; Current iteration

endm

; Description: Evals the range direction and sets the appropriate flags
; Input: AX initial cell [col, row], DX target cell [col, row]
mRangeDirecton macro

    local horizontal, vertical, invalid, end, negative_horizontal, negative_vertical

    ; Save the initial and target cell coordinates
    mov [initialCoords], bx
    mov [auxCoords], bx
    mov [targetCoords], dx

    ; Differences
    sub dl, bl ; Row Distance ( target - initial )
    sub dh, bh  ; Column Distance ( target - initial )

    ; Horizontal
    cmp dl, 0
    je horizontal

    ; Vertical
    cmp dh, 0
    je vertical

    ; Invalid
    jmp invalid

    horizontal:
    
    mov [rangeType], 1

    mov cx, 0
    cmp dh, 0
    jl negative_horizontal

    mov [rangeDirection], 1 ; positive -> right
    mov cl, dh ; Cells to move

    mov [rangeIterations], cx

    jmp end

    negative_horizontal:

    mov [rangeDirection], 2 ; negative -> left
    neg dh
    mov cl, dh ; Cells to move

    mov [rangeIterations], cx

    jmp end


    vertical:

    mov [rangeType], 2
    
    mov cx, 0
    cmp dl, 0
    jl negative_vertical

    mov [rangeDirection], 1 ; positive -> down
    mov cl, dl ; Cells to move

    mov [rangeIterations], cx

    jmp end

    negative_vertical:

    mov [rangeDirection], 2 ; negative -> up
    neg dl
    mov cl, dl ; Cells to move

    mov [rangeIterations], cx

    jmp end
    
    invalid:

    mov [rangeType], 0
    mov [rangeDirection], 0
    mov [rangeIterations], 0

    jmp end

    end:
        mov [currentIteration], 0

endm

; Description: Gets the next cell in the range
; Output: SI next cell Absolute Address of the datasheet, from the initial to the target cell
;         DX 0 if have not reached the end of the range, 1 if have reached the end of the range
mGetNextRangeCoord macro

    local compute_address, next_coords, horizontal, vertical, end, right_horizontal, left_horizontal, down_vertical, up_vertical, end_cycle, save

    compute_address:
        mov ax, [auxCoords]

        mov dl, ah ; COLS
        
        mov ah, 0
        mov dh, 0

        mov bx, 0bh
        mul bx ; ROWS * 11d

        add ax, dx ; ROWS * 11d + COLS

        ; Because the datasheet is a 2 byte array, we need to multiply the index by 2
        mov bx, 2
        mul bx ; (row * numCols + col) * 2

        push ax ; Save the address

    next_coords:
        mov ax, [auxCoords] ; [col, row]

        ; Horizontal
        cmp [rangeType], 1
        je horizontal

        ; Vertical
        cmp [rangeType], 2
        je vertical

        horizontal:
            cmp [rangeDirection], 1 ; right
            je right_horizontal

            cmp [rangeDirection], 2 ; left
            je left_horizontal
        
        right_horizontal:
            inc ah ; same row, next column
            jmp save

        left_horizontal:
            dec al ; same row, previous column
            jmp save

        vertical:
            cmp [rangeDirection], 1 ; down
            je down_vertical

            cmp [rangeDirection], 2 ; up
            je up_vertical

        down_vertical:
            inc al ; next row, same column
            jmp save

        up_vertical:
            dec ah ; previous row, same column
            jmp save

    save:
        mov [auxCoords], ax ; Update the auxiliar coords

        pop si ; Get the address

        mov cx, [currentIteration] 
        inc cx
        mov [currentIteration], cx ; Update the current iteration

        cmp cx, [rangeIterations]
        ja end_cycle

        mov dx, 0 ; Not end of range
        jmp end

        end_cycle:
            mov dx, 1 ; End of range

    end:


endm