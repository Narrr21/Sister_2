; render_template.s - Simple template rendering engine

global render_page

extern client_fd
extern http_404_response
extern http_404_response_len

section .data
    template_path   db "./www/template.html", 0
    data_path       db "submitted.txt", 0
    placeholder     db "{{content}}"
    placeholder_len equ $ - placeholder

    ; Standard HTML header
    HDR_HTML db "HTTP/1.1 200 OK",13,10,"Content-Type: text/html",13,10,"Connection: close",13,10,13,10
    HDR_HTML_LEN equ $-HDR_HTML

section .bss
    template_buf    resb 8192  ; Buffer for template.html
    data_buf        resb 8192  ; Buffer for submitted.txt
    response_buf    resb 16384 ; Buffer for the final rendered output

section .text

; render_page()
; Renders template.html with data from submitted.txt
render_page:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    ; --- 1. Read the template file into template_buf ---
    lea rdi, [template_path]
    lea rsi, [template_buf]
    call read_file_into_buffer
    test rax, rax
    js .fail_404      ; If read failed, send 404
    mov r12, rax      ; r12 = template_len

    ; --- 2. Read the data file into data_buf ---
    lea rdi, [data_path]
    lea rsi, [data_buf]
    call read_file_into_buffer
    ; If data file doesn't exist, rax will be 0, which is fine.
    mov r13, rax      ; r13 = data_len

    ; --- 3. Render the template ---
    lea rdi, [template_buf]     ; Source: template
    mov rsi, r12                ; Source length
    lea rdx, [placeholder]      ; String to find
    mov rcx, placeholder_len    ; Length of string to find
    lea r8, [data_buf]          ; Replacement string
    mov r9, r13                 ; Replacement length
    lea r10, [response_buf]     ; Destination buffer
    call find_and_replace
    ; rax will contain the final length of the rendered response

    ; --- 4. Send the response ---
    ; Send the HTTP header first
    mov rdx, rax ; save final length
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [HDR_HTML]
    mov rdx, HDR_HTML_LEN
    syscall

    ; Send the rendered body
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [response_buf]
    pop rdx ; restore final length
    syscall

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret

.fail_404:
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [http_404_response]
    mov rdx, http_404_response_len
    syscall
    jmp .cleanup

; -----------------------------------------------------------------
; read_file_into_buffer(rdi=path, rsi=buffer) -> rax=bytes_read or -1
; -----------------------------------------------------------------
read_file_into_buffer:
    ; open(path, O_RDONLY)
    mov rax, 2
    xor rsi, rsi
    syscall
    test rax, rax
    js .read_fail

    mov r14, rax ; save fd

    ; read(fd, buffer, 8191)
    mov rax, 0
    mov rdi, r14
    pop rsi ; get buffer from stack
    mov rdx, 8191
    syscall
    ; rax now holds bytes_read or -1

    ; close(fd)
    push rax ; save bytes_read
    mov rax, 3
    mov rdi, r14
    syscall
    pop rax ; restore bytes_read

    ret
.read_fail:
    mov rax, -1
    ret

; -----------------------------------------------------------------
; find_and_replace(rdi=src, rsi=src_len, rdx=find, rcx=find_len,
;                  r8=repl, r9=repl_len, r10=dest) -> rax=final_len
; -----------------------------------------------------------------
find_and_replace:
    mov r11, r10 ; r11 = current write pointer for dest
    mov r14, rdi ; r14 = current read pointer for src
    mov r15, rsi ; r15 = bytes remaining in src

.main_loop:
    cmp r15, rcx
    jl .copy_remainder ; Not enough bytes left to match 'find' string

    ; Compare memory at current read pos with 'find' string
    push rdi
    push rsi
    mov rdi, r14
    mov rsi, rdx
    push rcx
    repe cmpsb
    pop rcx
    pop rsi
    pop rdi
    jz .found_match

    ; No match, so copy one byte from src to dest
    movsb
    dec r15
    jmp .main_loop

.found_match:
    ; We found the placeholder. Copy the replacement string to dest.
    push rdi
    push rsi
    mov rdi, r11
    mov rsi, r8
    mov rcx, r9
    rep movsb
    mov r11, rdi ; Update write pointer
    pop rsi
    pop rdi

    ; Advance the source read pointer past the placeholder
    add r14, rcx
    sub r15, rcx
    jmp .main_loop

.copy_remainder:
    ; Copy any remaining bytes from src to dest
    test r15, r15
    jz .done
    mov rcx, r15
    rep movsb

.done:
    ; Calculate final length
    sub r11, r10
    mov rax, r11
    ret
