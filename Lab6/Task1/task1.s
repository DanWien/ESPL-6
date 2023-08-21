section .data
    newline db 0xA
    newline_len equ 1
    BUFFER_SIZE equ 1024
    Infile times BUFFER_SIZE db 0
    Outfile times BUFFER_SIZE db 0
    input_fd dd 0
    output_fd dd 1

section .text
global main
global encode
extern strlen

encode:
    ; Save registers
    pusha

    ; Prepare for the read system call
    mov eax, 3          ; read system call number
    mov ebx, [input_fd] ; file descriptor (input_fd)
    mov ecx, Infile     ; buffer for input
    mov edx, BUFFER_SIZE ; buffer size
    int 0x80

    ; Check if read has reached EOF
    cmp eax, 0
    je encode_end

    ; Save the number of bytes read
    mov edi, eax

    ; Perform the encoding here (modify the buffer in-place)
    mov ebx, Infile      ; Set ebx to the start of the buffer
    mov ecx, edi         ; Set ecx to the number of bytes read
    encode_loop:
        cmp ecx, 0       ; Check if ecx (remaining bytes) is zero
        je encode_done   ; If ecx is zero, exit the loop

        ; Check if the character is between 'A' and 'z'
        cmp byte [ebx], 'A'
        jl skip_encode
        cmp byte [ebx], 'z'
        jg skip_encode

        ; Increment the character by one
        add byte [ebx], 1
        

    skip_encode:
        ; Move to the next character
        inc ebx
        dec ecx
        jmp encode_loop

    encode_done:

    ; Prepare for the write system call
    mov eax, 4           ; write system call number
    mov ebx, [output_fd] ; file descriptor (output_fd)
    mov ecx, Infile     ; buffer for output (same as input buffer in this case)
    mov edx, edi        ; number of bytes to write
    int 0x80

    ; Restore registers
    popa

    ; Call the encode function again (loop)
    jmp encode

encode_end:
    ; Restore registers and return
    popa
    ret


main:
    push ebp
    mov ebp, esp

    ; Save registers
    pusha

    ; Get argc and argv from the stack
    mov ecx, [ebp + 8]  ; argc
    mov esi, [ebp + 12] ; argv

    ; Initialize input and output file descriptors
    mov byte [input_fd], 0
    mov byte [output_fd], 1

    ; Parse command line arguments
    mov edi, 1
    parse_argv_loop:
        cmp edi, ecx
        jge parse_argv_end

        ; Get the argument string pointer
        lea ebx, [esi + edi * 4]
        mov ebx, [ebx]
        cmp ebx, 0
        je parse_argv_end
        push ebx
        call strlen
        add esp, 4
        push ebx
        ; Prepare for the write system call
        mov edx, eax        ; string length
        mov ecx, ebx        ; string pointer
        mov ebx, 1          ; file descriptor (stdout)
        mov eax, 4          ; write system call number
        int 0x80

        ; Write newline character
        mov ecx, newline
        mov edx, newline_len
        mov ebx, 1          ; file descriptor (stdout)
        mov eax, 4          ; write system call number
        int 0x80

        pop ebx

        ; Check if the string starts with '-'
        inc edi
        cmp byte [ebx], '-'
        jne parse_argv_loop

        ; Check for -i or -o options
        inc ebx
        cmp byte [ebx], 'i'
        je open_input_file
        cmp byte [ebx], 'o'
        je open_output_file


    open_input_file:
        mov eax, 5 ; open system call number
        inc ebx
        push ecx
        mov ecx , 0 
        int 0x80
        mov dword [input_fd], eax
        pop ecx
        jmp parse_argv_loop

    open_output_file:
        mov eax, 5 ; open system call number
        inc ebx
        mov ecx , 0x42 ; O_CREAT | O_TRUNC | O_WRONLY
        mov edx , 0666o
        int 0x80
        mov dword [output_fd], eax
        jmp parse_argv_loop

    parse_argv_end:
        ; Call the encode function
        call encode

        ; Close the input file if it's not stdin
        cmp dword [input_fd], 0
        je skip_close_input
        mov eax, 6 ; close system call number
        mov ebx, [input_fd]
        int 0x80
    skip_close_input:

        ; Close the output file if it's not stdout
        cmp dword [output_fd], 1
        je skip_close_output
        mov eax, 6 ; close system call number
        mov ebx, [output_fd]
        int 0x80
    skip_close_output:

        ; Restore registers and return
        popa
        mov esp, ebp
        pop ebp
        mov eax,1
        xor ebx,ebx
        int 0x80