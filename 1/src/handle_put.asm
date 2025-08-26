; handle_put.asm - Handles PUT requests to overwrite a file.

global handle_put

extern client_fd, log_msg_simple
extern find_http_body, simple_strlen

section .data
    target_file     db "submitted.txt", 0
    log_put_msg     db "Action: Handling PUT request for submitted.txt", 10, 0

    ; HTTP 201 Created Response
    http_201_response db "HTTP/1.1 201 Created",13,10,"Connection: close",13,10,13,10
    http_201_len equ $ - http_201_response

    ; HTTP 500 Internal Server Error Response
    http_500_response db "HTTP/1.1 500 Internal Server Error",13,10,13,10
    http_500_len equ $ - http_500_response

section .text

handle_put:
    ; rdi = client_fd, rsi = request_buffer, rdx = request_len
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r14, rsi ; Save request buffer pointer
    mov r15, rdx ; Save request length

    lea rdi, [log_put_msg]
    call log_msg_simple

    ; Find the start of the HTTP body
    mov rdi, r14
    mov rsi, r15
    call find_http_body
    test rax, rax
    jz .fail_500 ; If no body found, it's an error
    mov r12, rax ; r12 = pointer to start of body

    ; Calculate body length
    sub r15, r12 ; total_len - start_of_body_offset
    add r12, r14 ; Get absolute address of body
    mov r13, r15 ; r13 = body_length

    ; Open the file (O_WRONLY | O_CREAT | O_TRUNC)
    mov rax, 2               ; sys_open
    lea rdi, [target_file]
    mov rsi, 0101o | 01o     ; O_CREAT | O_WRONLY
    mov rdx, 0644o           ; Mode (rw-r--r--)
    syscall
    test rax, rax
    js .fail_500
    mov r14, rax ; Save file descriptor

    ; Write the body to the file
    mov rax, 1      ; sys_write
    mov rdi, r14    ; fd
    mov rsi, r12    ; body buffer
    mov rdx, r13    ; body length
    syscall

    ; Close the file
    mov rax, 3      ; sys_close
    mov rdi, r14
    syscall

    ; Send 201 Created response
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [http_201_response]
    mov rdx, http_201_len
    syscall
    jmp .cleanup

.fail_500:
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [http_500_response]
    mov rdx, http_500_len
    syscall

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret

; A helper to find the start of the body (\r\n\r\n)
find_http_body:
    ; rdi = buffer, rsi = length
    mov rcx, rsi
    sub rcx, 3
    xor rax, rax
.loop:
    cmp rcx, 0
    jle .not_found
    cmp dword [rdi + rax], 0x0a0d0a0d ; Check for \r\n\r\n
    je .found
    inc rax
    dec rcx
    jmp .loop
.found:
    add rax, 4 ; Point to the start of the body content
    ret
.not_found:
    xor rax, rax ; Return 0 on failure
    ret