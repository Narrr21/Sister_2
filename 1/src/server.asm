; server.s - HTTP Web Server (x86-64 Linux, NASM)
; This version has a simplified GET handler and better logging.

section .data
    ; Server config
    backlog         dd 10

    ; sockaddr_in
    server_addr:
        dw 2              ; AF_INET
        dw 0x901f         ; port 8080
        dd 0              ; INADDR_ANY
        dq 0              ; padding

    read_timeout:
        tv_sec  dq 5      ; 5 detik
        tv_usec dq 0      ; 0 mikrodetik

    ; HTTP error responses
    http_404_response db "HTTP/1.1 404 Not Found",13,10,"Content-Type: text/html",13,10,"Connection: close",13,10,13,10,"<html><body><h1>404 Not Found</h1></body></html>"
    http_404_response_len equ $-http_404_response

    http_405_response db "HTTP/1.1 405 Method Not Allowed",13,10,"Content-Type: text/html",13,10,"Connection: close",13,10,13,10,"<html><body><h1>405 Method Not Allowed</h1></body></html>"
    http_405_response_len equ $-http_405_response

    ; HTTP method strings
    method_get  db "GET "
    method_post db "POST "
    method_put  db "PUT "      
    method_del  db "DELETE "   

    ; Base dir + default
    www_dir db "./www/",0
    www_dir_len equ 6
    default_file db "index.html",0
    default_file_len equ 10

    ; Debug Messages
    log_get_msg     db "Routing GET request...", 10, 0
    log_post_msg    db "Routing POST request...", 10, 0
    log_put_msg     db "Routing PUT request...", 10, 0
    log_del_msg    db "Routing DEL request...", 10, 0

section .bss
    request_buffer resb 4096
    socket_fd      resq 1
    client_fd      resq 1
    opt_val        resd 1

section .text
global _start
global www_dir, www_dir_len, default_file, default_file_len
global http_404_response, http_404_response_len, client_fd
global log_msg_simple
extern send_page
extern log_msg
extern handle_submit
extern handle_put
extern handle_delete 

_start:
    ; socket
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    test rax, rax
    js exit_error
    mov [socket_fd], rax

    ; setsockopt
    mov dword [opt_val], 1
    mov rax, 54
    mov rdi, [socket_fd]
    mov rsi, 1
    mov rdx, 2
    mov r10, opt_val
    mov r8, 4
    syscall

    ; bind
    mov rax, 49
    mov rdi, [socket_fd]
    mov rsi, server_addr
    mov rdx, 16
    syscall
    test rax, rax
    js exit_error

    ; listen
    mov rax, 50
    mov rdi, [socket_fd]
    mov rsi, [backlog]
    syscall
    test rax, rax
    js exit_error

accept_loop:
    ; accept
    mov rax, 43
    mov rdi, [socket_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js accept_loop
    mov [client_fd], rax

    ; fork
    mov rax, 57
    syscall
    test rax, rax
    jnz .parent

    ; child process
    call handle_client
    mov rax, 60
    xor rdi, rdi
    syscall

.parent:
    ; close client in parent
    mov rax, 3
    mov rdi, [client_fd]
    syscall
    jmp accept_loop

handle_client:
    ; set timeout
    mov rax, 54
    mov rdi, [client_fd]
    mov rsi, 1
    mov rdx, 20
    mov r10, read_timeout
    mov r8, 16
    syscall

    ; read request
    mov rax, 0
    mov rdi, [client_fd]
    mov rsi, request_buffer
    mov rdx, 4095
    syscall
    test rax, rax
    jle .close_and_ret
    mov r15, rax
    mov byte [request_buffer + rax], 0

    ; log raw request
    lea rdi, [request_buffer]
    mov rsi, r15
    call log_msg

    ; parse HTTP
    call parse_http_request

.close_and_ret:
    mov rax, 3
    mov rdi, [client_fd]
    syscall
    ret

parse_http_request:
    ; check GET
    mov rsi, request_buffer
    mov rdi, method_get
    mov rcx, 4
    call strncmp
    test rax, rax
    jz handle_get

    ; check POST
    mov rsi, request_buffer
    mov rdi, method_post
    mov rcx, 5
    call strncmp
    test rax, rax
    jz handle_post

    ; check PUT
    mov rsi, request_buffer
    mov rdi, method_put
    mov rcx, 4
    call strncmp
    test rax, rax
    jz handle_put_request

    ; check DELETE
    mov rsi, request_buffer
    mov rdi, method_del
    mov rcx, 7
    call strncmp
    test rax, rax
    jz handle_delete_request

    jmp send_405_response

handle_get:
    lea rdi, [log_get_msg]
    ; call log_msg_simple
    lea rsi, [request_buffer+4]
    call send_page
    ret

handle_post:
    lea rdi, [log_post_msg]
    ; call log_msg_simple
    mov rdi, [client_fd]
    lea rsi, [request_buffer]
    mov rdx, r15
    call handle_submit
    ret

handle_put_request:
    lea rdi, [log_put_msg]
    ; call log_msg_simple
    mov rdi, [client_fd]
    lea rsi, [request_buffer]
    mov rdx, r15
    call handle_put
    ret

handle_delete_request:
    lea rdi, [log_del_msg]
    ; call log_msg_simple
    mov rdi, [client_fd]
    call handle_delete
    ret

send_404_response:
    mov rax, 1
    mov rdi, [client_fd]
    mov rsi, http_404_response
    mov rdx, http_404_response_len
    syscall
    ret

send_405_response:
    mov rax, 1
    mov rdi, [client_fd]
    mov rsi, http_405_response
    mov rdx, http_405_response_len
    syscall
    ret

strncmp:
    repe cmpsb
    setz al
    movzx rax, al
    dec rax
    ret

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

log_msg_simple:
    push rdi
    push rsi
    push rdx
    mov rsi, rdi
    call simple_strlen
    mov rdx, rax
    call log_msg
    pop rdx
    pop rsi
    pop rdi
    ret

simple_strlen:
    xor rax, rax
.len_loop:
    cmp byte [rsi + rax], 0
    je .len_done
    inc rax
    jmp .len_loop
.len_done:
    ret
