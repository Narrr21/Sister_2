; handle_delete.asm - Handles DELETE requests to remove a file.

global handle_delete

extern client_fd, log_msg_simple

section .data
    target_file     db "submitted.txt", 0
    log_delete_msg  db "Action: Handling DELETE request for submitted.txt", 10, 0

    ; HTTP 204 No Content Response (Success)
    http_204_response db "HTTP/1.1 204 No Content",13,10,"Connection: close",13,10,13,10
    http_204_len equ $ - http_204_response

    ; HTTP 404 Not Found (If file doesn't exist)
    http_404_response db "HTTP/1.1 404 Not Found",13,10,"Connection: close",13,10,13,10
    http_404_len equ $ - http_404_response

section .text

handle_delete:
    ; rdi = client_fd
    push rbp
    mov rbp, rsp

    lea rdi, [log_delete_msg]
    call log_msg_simple

    ; --- 1. Attempt to delete the file using unlink syscall ---
    mov rax, 87              ; sys_unlink
    lea rdi, [target_file]
    syscall

    ; rax will be 0 on success, or a negative error code
    test rax, rax
    jz .success

.fail_404:
    ; Assume failure means file not found
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [http_404_response]
    mov rdx, http_404_len
    syscall
    jmp .cleanup

.success:
    ; --- 2. Send 204 No Content response ---
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [http_204_response]
    mov rdx, http_204_len
    syscall

.cleanup:
    mov rsp, rbp
    pop rbp
    ret