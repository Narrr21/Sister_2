; submit.s - Handles POST, saves data, and redirects the client.
global handle_submit

section .data
    upload_file         db "submitted.txt", 0

    ; --- NEW: HTTP 302 Redirect Response ---
    ; This tells the browser to navigate to /submitted.html
    http_redirect       db "HTTP/1.1 302 Found", 13, 10, "Location: /submitted.html", 13, 10, "Connection: close", 13, 10, 13, 10
    http_redirect_len   equ $ - http_redirect

    ; --- For parsing the request ---
    crlf_crlf           db 13, 10, 13, 10
    crlf_crlf_len       equ $ - crlf_crlf
    content_len_hdr     db "Content-Length: "
    content_len_hdr_len equ $ - content_len_hdr

section .text
handle_submit:
    ; ABI:
    ; rdi: client_fd
    ; rsi: pointer to request buffer
    ; rdx: length of request in buffer

    push r15
    push r14
    push r13
    push r12
    push rbx
    push rbp

    mov r15, rdi      ; Save client_fd
    mov r14, rsi      ; Save request buffer pointer
    mov r13, rdx      ; Save request length

    ; --- 1. Find Content-Length header ---
    mov rdi, r14
    mov rsi, r13
    mov rdx, content_len_hdr
    mov rcx, content_len_hdr_len
    call memmem
    test rax, rax
    jz .send_redirect ; If header not found, just redirect

    add rax, content_len_hdr_len

    ; --- 2. Convert ASCII number to integer (body_length) ---
    xor rbx, rbx      ; rbx will hold the body_length
    mov rsi, rax
.atoi_loop:
    movzx rcx, byte [rsi]
    cmp cl, '0'
    jl .atoi_done
    cmp cl, '9'
    jg .atoi_done
    sub cl, '0'
    imul rbx, 10
    add rbx, rcx
    inc rsi
    jmp .atoi_loop
.atoi_done:

    ; --- 3. Find the start of the HTTP body ---
    mov rdi, r14
    mov rsi, r13
    mov rdx, crlf_crlf
    mov rcx, crlf_crlf_len
    call memmem
    test rax, rax
    jz .send_redirect ; If body not found, just redirect

    add rax, 4        ; Move pointer past the "\r\n\r\n"
    mov rbp, rax      ; rbp = pointer to the start of the body

    ; --- 4. Decode, open file, and write the body ---
    ; First, remove the "text=" prefix
    add rbp, 5        ; Move data pointer past "text="
    sub rbx, 5        ; Decrease total length by 5

    ; Second, decode the data (replace '+' with ' ')
    mov rdi, rbp      ; Pointer to the data
    mov rsi, rbx      ; Length of the data
    call url_decode_inplace

    ; Now, open the file for writing
    mov rax, 2
    lea rdi, [rel upload_file]
    ; flags: O_WRONLY | O_CREAT | O_TRUNC
    mov rsi, 0101o | 01000o
    mov rdx, 0644o    ; permissions
    syscall
    test rax, rax
    js .send_redirect ; If open fails, just redirect

    ; Write the decoded data to the file
    mov rdi, rax      ; File descriptor
    mov rsi, rbp      ; Pointer to the decoded body
    mov rdx, rbx      ; Length of the body
    mov rax, 1        ; sys_write
    syscall

    ; Close the file
    mov rdi, rax      ; syscall returns fd in rax, use it for close
    mov rax, 3        ; sys_close
    syscall

.send_redirect:
    ; --- 5. Send the redirect response to the browser ---
    mov rax, 1
    mov rdi, r15      ; client_fd
    lea rsi, [rel http_redirect]
    mov rdx, http_redirect_len
    syscall

.cleanup:
    pop rbp
    pop rbx
    pop r12
    pop r13
    pop r14
    pop r15
    ret

; -----------------------------------------------------------------------------
; url_decode_inplace(rdi=buffer, rsi=len)
; Decodes a simple URL-encoded string in place. Replaces '+' with ' '.
; -----------------------------------------------------------------------------
url_decode_inplace:
    mov rcx, rsi ; Use rcx as loop counter
.decode_loop:
    test rcx, rcx
    jz .decode_done
    cmp byte [rdi], '+'
    jne .next_char
    mov byte [rdi], ' ' ; Replace '+' with a space
.next_char:
    inc rdi
    dec rcx
    jmp .decode_loop
.decode_done:
    ret

; --- Safe, length-limited substring search (memmem) ---
; rdi: haystack, rsi: haystack_len, rdx: needle, rcx: needle_len
; returns pointer to match in rax, or 0 if not found
memmem:
    push rdi
    push rsi
    push rdx
    push rcx
    mov r8, rdi
    mov r9, rsi
.haystack_loop:
    cmp r9, rcx
    jl .not_found

    mov rdi, r8
    mov rsi, rdx
    push rcx
    repe cmpsb
    pop rcx
    jz .found

    inc r8
    dec r9
    jmp .haystack_loop
.found:
    mov rax, r8
    jmp .end
.not_found:
    xor rax, rax
.end:
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret
