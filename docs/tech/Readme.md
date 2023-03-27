# **Práctica 4**
### Universidad de San Carlos de Guatemala
### Facultad de Ingeniería
### Escuela de Ciencias y Sistemas
### Arquitectura de Computadores y Ensambladores 1
### Sección B
<br></br>

## **Manual Técnico**
<br></br>

| Nombre | Carnet | 
| --- | --- |
| Damián Ignacio Peña Afre | 202110568 |
----

# **Descripción General**

Este proyecto consiste en desarrollar un programa en lenguaje ensamblador para la arquitectura x86 de Intel. El lenguaje ensamblador, también conocido como Assembly, es un lenguaje de bajo nivel que permite escribir programas que interactúan directamente con el hardware de la computadora. El lenguaje ensamblador se utiliza típicamente para tareas de bajo nivel, como la programación de dispositivos de entrada/salida, controladores de dispositivos, sistemas operativos y aplicaciones de tiempo real.

El proyecto se desarrollará en el contexto de la plataforma Microsoft Windows y se utilizará el conjunto de instrucciones x86 de Intel. El objetivo del programa es procesar una lista de números enteros y mostrar por pantalla su suma, su media y su valor máximo.

A continuación se presentará una descripción técnica del código en lenguaje ensamblador.


# **Descripción Técnica**

# main.asm

El archivo `main.asm` contiene el punto de entrada del programa y es responsable de inicializar las variables y llamar a las funciones principales del programa. El lenguaje utilizado es MASM (Microsoft Macro Assembler), que es un lenguaje de bajo nivel utilizado para escribir programas en lenguaje de máquina.

La sección ".data" del archivo contiene las variables globales utilizadas por el programa, que se dividen en diferentes categorías: variables de hoja de cálculo, cadenas de caracteres, variables de entrada, variables de archivo y variables de rango.

La sección ".code" contiene el código del programa, que se inicia con la etiqueta "startup" y finaliza con la etiqueta "end". El programa comienza mostrando un mensaje inicial en pantalla y espera a que el usuario presione la tecla Enter. A continuación, se muestra la hoja de cálculo en pantalla y se solicita al usuario que ingrese una operación. Si el usuario ingresa una operación válida, se llama a la función correspondiente en el archivo de ensamblador correspondiente. Si el usuario ingresa "SALIR", el programa termina y muestra un mensaje de despedida en pantalla.

```asm	

; Práctica 4 - Arquitectura de Compiladores y ensambladores 1
; Made By: Damián Ignacio Pena Afre
; ID: 202110568
; Section: B
; Description: Excel with ASM

; --------------------- INCLUDES ---------------------

include utils.asm
include inputs.asm
include strings.asm
include excel.asm
include files.asm
include range.asm

.model small
.stack
.radix 16

.data

; --------------------- VARIABLES ---------------------

initialMessage db  "Universidad de San Carlos de Guatemala", 0dh, 0ah,"Facultad de Ingenieria", 0dh, 0ah,"Escuela de Ciencias y Sistemas", 0dh, 0ah,"Arquitectura de Compiladores y ensabladores 1", 0dh, 0ah,"Seccion B", 0dh, 0ah,"Damian Ignacio Pena Afre", 0dh, 0ah,"202110568", 0dh, 0ah,"Presiona ENTER", 0dh, 0ah, "$"
newLine db 0ah, "$"
whiteSpace db 20h, "$"

; - DATASHEET -
mDatasheetVariables

; - STRINGS -
mStringVariables

; - INPUTS -
mInputVariables

; - FILES -
mFilesVariables

; - RANGE -
mRangeVariables

.code

.startup
    
    initial_messsage: 
        mPrint initialMessage
        mPrint newLine

        mWaitForEnter
        mPrint newLine

    datasheet_sequence:
        mPrintDatasheet
        mPrint promptIndicator
        mEvalPromt

        jmp datasheet_sequence

    mOperations ; Operations labels

end_program:
    mov al, 0
    mov ah, 4ch                         
    int 21h

end

```

# utils.asm

El archivo `utils.asm` contiene una serie de macros útiles que pueden ser usadas por otros módulos del programa.

La macro mPrint se encarga de imprimir en la consola el contenido de una cadena de caracteres. Recibe como argumento la dirección de memoria donde se encuentra almacenada la cadena y utiliza la interrupción 21h del sistema para mostrarla.

La macro mPrintAddress imprime en la consola la dirección de memoria que se le pasa como argumento.

La macro mPrint8Reg se encarga de imprimir en la consola el valor de un registro de 8 bits. Recibe como argumento el nombre del registro y utiliza la macro mNumberToString para convertir el valor del registro a una cadena de caracteres.

La macro mPrintDWVariable se encarga de imprimir en la consola el valor de una variable de tipo DWORD. Recibe como argumento la dirección de memoria de la variable y utiliza la macro mNumberToString para convertir el valor de la variable a una cadena de caracteres.

La macro mPrintDBVariable se encarga de imprimir en la consola el valor de una variable de tipo BYTE. Recibe como argumento la dirección de memoria de la variable y utiliza la macro mNumberToString para convertir el valor de la variable a una cadena de caracteres.

```asm	

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

mPrint8Reg macro reg

    push ax
    push dx

    mov ax, 0
    mov al, reg
    mNumberToString
    mPrint numberString

    pop dx
    pop ax

endm

mPrintDWVariable macro variable
    push ax
    push dx

    mov ax, [variable]
    mNumberToString
    mPrint numberString

    pop dx
    pop ax
endm

            
mPrintDBVariable macro variable
    push ax
    push dx

    mov ax, 0
    mov al, [variable]
    mNumberToString
    mPrint numberString

    pop dx
    pop ax
endm

```

# inputs.asm

El archivo `inputs.asm` contiene diversas macros para manejar entradas del usuario y procesarlas en el programa.

* `mInputVariables` define las variables necesarias para almacenar las entradas del usuario.
* `mWaitForEnter` espera a que el usuario presione la tecla Enter.
* `mWaitForInput` espera a que el usuario ingrese una entrada y la almacena en commandBuffer.
* `mSkipWhiteSpaces` salta todos los espacios en blanco desde la posición actual del puntero hasta el primer caracter no vacío.
* `mSkipUntilWhiteSpaces` salta todos los caracteres desde la posición actual del puntero hasta el primer espacio en blanco que encuentre.
* `mPrintChar` imprime un caracter.

```asm	

    mInputVariables macro

commandBuffer db 100h dup('$')
comamandEnd dw '$'
charValue db 0
charEnd db '$'

endm


; Description: Waits for the user to press enter
mWaitForEnter macro
    LOCAL press_enter

    push ax

    press_enter:
        mov AH, 08h
        int 21h
        cmp AL, 0dh
        jne press_enter

    pop ax
endm


; Description: Waits for user input and stores it in the commandBuffer
;              Resets the commandBuffer before reading the input
; Input: None
; Output: None
mWaitForInput macro

    local reinit_loop

    push ax
    push bx
    push cx
    push dx

    ; reinit buffer
    mov cx, 100h
    mov si, 0
    mov al, '$'

    reinit_loop:
        mov commandBuffer[si], al
        inc si
        loop reinit_loop

    mov si, 0
    mov commandBuffer[si], 0feh

    lea dx, commandBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

endm

; Description: Skips all white spaces until the first non white space character
; Input: SI - absolute address of the buffer
; Output: SI - absoulte address of the first non white space character
mSkipWhiteSpaces macro

    local skip_white_spaces, end
    push ax

    ; skip white spaces
    skip_white_spaces:
        mov al, [si]
        cmp al, ' '
        jne end
        inc si
    end:
        pop ax

endm

mSkipUntilWhiteSpaces macro

    local skip_until_white_spaces, end

    push ax

    ; skip until white spaces
    skip_until_white_spaces:
        mov al, [si]
        cmp al, ' '
        je end
        mPrintAddress si
        mWaitForEnter
        inc si
    end:
        pop ax
endm


mPrintChar macro char

    push ax
    push si
    push dx
    
    mov [charValue], char
    mov [charEnd], '$'

    mPrint charValue

    pop dx
    pop si
    pop ax

endm

```

# excel.asm

Se describirán a continuación las macros más importantes que se encuentran en el archivo `excel.asm`.

`mEvalCommand`

Esta es una macro que evalúa si un buffer de entrada contiene un comando específico. Se utiliza para comparar el comando ingresado por el usuario con los comandos reconocidos por el programa. El argumento "command" es la dirección del comando a reconocer.

La macro carga la dirección del comando en "di" y su longitud en "cx", luego utiliza "mCompareStrings" para comparar el comando con el buffer de entrada. Si el comando es reconocido, "dx" se establece en 0 y "si" se ajusta para saltar el comando en el buffer de entrada. Si el comando no es reconocido, "dx" se establece en 1.

```asm

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

```

`mEvalReference`

Esta macro utiliza tres macros diferentes para verificar si el buffer de entrada contiene una referencia válida. Primero, verifica si es una referencia de retorno (si contiene el carácter *). Luego, verifica si es una referencia de celda (si contiene letras seguidas de números). Finalmente, verifica si es una referencia de número (si contiene solo números). Si el buffer de entrada no contiene una referencia válida, se establece el valor de dx en 0. Si es una referencia de retorno, se establece en 1, si es una referencia de celda, se establece en 2, y si es una referencia de número, se establece en 3. El puntero si se establece en la posición final de la referencia, y el valor de ax se establece en el valor numérico de la referencia si es una referencia de número.

```asm	

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

```	
`mCheckReturnReference`

Esta macro se encarga de evaluar si el buffer de entrada contiene una referencia de tipo "retorno" [ * ]. En caso de que la referencia sea válida, establece el valor de la variable dx en 1 y el valor de la variable ax en el valor de la referencia. Si la referencia no es válida, establece el valor de la variable dx en 0.

```asm
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


```

`mCheckCellReference`

Este macro evalúa si el búfer de entrada contiene una referencia [*, Celda, Número]. Si la referencia es válida, establece el registro DX para indicar el tipo de referencia encontrado (0 para inválida, 1 para referencia *, 2 para referencia de celda, 3 para referencia de número), el registro AX para almacenar el valor de la referencia (si es una referencia de número), y modifica el registro SI para que apunte a la posición final de la referencia. Si la referencia es inválida, el registro DX se establece en 0.

```asm
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

```

`mCheckNumberReference`

Este es un macro que evalúa si el búfer de entrada contiene una referencia numérica [Number] y modifica el buffer de entrada si es una referencia numérica o no lo modifica si no lo es.

La entrada del macro es la dirección del búfer de entrada en SI.

El macro devuelve una salida a través de DX y AX. DX indica si la entrada es una referencia numérica (1) o no (0). AX contiene la referencia numérica si la entrada es una referencia numérica.

El macro utiliza otros dos macros auxiliares: mResetNumberString y mStringToNumber.

El macro realiza la siguiente lógica:

* Primero, se inicializan los contadores y variables necesarios.
* Luego, se comprueba si el número es negativo.
* A continuación, se comprueba si el primer carácter del número es un dígito válido. Si no lo es, se sale del macro sin modificar el buffer y se indica que no es una referencia numérica.
* Si es un dígito válido, se empieza a guardar el número en una cadena temporal (numberString) y se va avanzando en el búfer de entrada hasta llegar al final del número o de la cadena.
* Si la cadena temporal supera los 6 caracteres, se indica que no es una referencia numérica y se sale del macro.
* Si se ha llegado al final del número o de la cadena, se convierte la cadena temporal en un número y se guarda en AX. Si la conversión falla, se indica que no es una referencia numérica y se sale del macro.
* Si se ha llegado al final del número y se ha conseguido convertir la cadena temporal en un número, se indica que es una referencia numérica y se devuelve el número en AX.

```asm	
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



```


# files.asm

`mGetFilename`

Descripción: Obtiene el nombre de archivo del buffer de comandos y lo guarda en el buffer de nombres de archivo (filenameBuffer).

Parámetros: SI - posición actual en el buffer de comandos [nombre de archivo]
Guarda el nombre de archivo en filenameBuffer.

Funcionamiento:

Reserva espacio en la pila para los registros DI, AX y CX.
Establece el registro DI al comienzo del buffer de nombres de archivo (filenameBuffer).
Reinicia el buffer de nombres de archivo estableciendo todos sus bytes en 0.
Establece el registro DI nuevamente al comienzo del buffer de nombres de archivo (filenameBuffer).
Copia cada caracter del buffer de comandos al buffer de nombres de archivo hasta que se encuentre con un byte nulo, un retorno de carro o un espacio.
Coloca el byte nulo al final del nombre de archivo en el buffer de nombres de archivo.
Imprime el nombre de archivo en la pantalla usando la macro mPrint.
Restaura los valores de los registros CX, AX y DI.
Finaliza la macro.
Nota: Se asume que el buffer de comandos tiene el formato correcto para extraer el nombre de archivo.


```asm
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


```	

`mReadImportFile`

Realiza una serie de operaciones relacionadas con la manipulación de archivos CSV. El primer macro llamado "mGetFileName" se encarga de obtener el nombre del archivo a través de un buffer de comandos y guarda el nombre del archivo en un buffer llamado "filenameBuffer". El segundo macro llamado "mReadImportFile" se encarga de abrir un archivo CSV para su lectura, extraer las líneas y encabezados de columnas y luego procesar los datos en el archivo. Si hay algún error, el programa imprime mensajes de error en la pantalla. 


```asm	

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



```


`mExportFile`

Esta macro exporta los datos de la hoja de cálculo a un archivo .htm. Toma como entrada la referencia de número de la celda, la referencia de columna y el nombre del archivo. Devuelve dx=0 si tiene éxito y dx=1 si hay un error. Si tiene éxito, se crea el archivo.

Primero se comprueba si la referencia de celda y columna se encuentran dentro del rango válido. A continuación, se guardan los encabezados en un búfer y se pide al usuario que los ordene. Luego, se crea el archivo y se escribe el encabezado HTML, la fecha y hora, la hoja de cálculo y el cierre de HTML. Finalmente, se cierra el archivo y se devuelve el código de éxito o error.

```asm	
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

```