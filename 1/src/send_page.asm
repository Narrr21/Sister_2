; send_page.s - Main router for all GET requests. (FIXED)

global send_page

; extern symbols
extern www_dir, www_dir_len, default_file, default_file_len
extern http_404_response, http_404_response_len, client_fd
extern log_msg_simple, log_msg

section .data
    ; --- Paths and strings for routing ---
    submitted_txt_path  db "/submitted.txt", 0
    submitted_filename  db "submitted.txt", 0

    ; --- For Template Rendering ---
    template_path   db "./www/template.html", 0
    content_suffix  db ".content.html", 0
    placeholder     db "{{content}}", 0
    placeholder_len equ $ - placeholder
    base_index      db "index", 0

    ; --- For Static File Serving ---
    HDR_HTML db "HTTP/1.1 200 OK",13,10,"Content-Type: text/html",13,10,"Connection: close",13,10,13,10
    HDR_HTML_LEN equ $-HDR_HTML
    HDR_TEXT db "HTTP/1.1 200 OK",13,10,"Content-Type: text/plain",13,10,"Connection: close",13,10,13,10
    HDR_TEXT_LEN equ $-HDR_TEXT
    HDR_CSS  db "HTTP/1.1 200 OK",13,10,"Content-Type: text/css",13,10,"Connection: close",13,10,13,10
    HDR_CSS_LEN  equ $-HDR_CSS
    HDR_JS   db "HTTP/1.1 200 OK",13,10,"Content-Type: application/javascript",13,10,"Connection: close",13,10,13,10
    HDR_JS_LEN   equ $-HDR_JS
    DOT_CSS  db ".css", 0
    DOT_JS   db ".js", 0

    ; --- Debug Messages ---
    log_prefix_cleaned_path db "DEBUG: Cleaned request path: ", 0
    log_prefix_content_path db "DEBUG: Constructed content path: ", 0
    log_prefix_static_path  db "DEBUG: Constructed static path: ", 0
    log_render_msg   db "Action: Rendering HTML template.", 10, 0
    log_static_msg   db "Action: Serving static file.", 10, 0
    log_data_msg     db "Action: Serving submitted.txt.", 10, 0

section .bss
    sp_file_path    resb 256
    sp_filebuf      resb 8192
    template_buf    resb 8192
    data_buf        resb 8192
    response_buf    resb 16384
    content_path    resb 256

section .text

send_page:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r13, rsi ; Save original path pointer

    ; --- 1. Clean the path from the request ---
    mov r14, rsi
.clean_path_loop:
    mov al, [r14]
    test al, al
    jz .path_cleaned
    cmp al, ' '
    je .path_cleaned
    inc r14
    jmp .clean_path_loop
.path_cleaned:
    mov byte [r14], 0

    lea rdi, [log_prefix_cleaned_path]
    mov rsi, r13
    call log_debug_msg

    ; --- 2. Main Routing Logic ---
    lea rdi, [submitted_txt_path]
    mov rsi, r13
    call strcmp_sp
    test rax, rax
    jz .serve_submitted_txt

    lea rdi, [DOT_CSS]
    mov rsi, r13
    call strstr_sp
    test rax, rax
    jnz .serve_static_file

    lea rdi, [DOT_JS]
    mov rsi, r13
    call strstr_sp
    test rax, rax
    jnz .serve_static_file

    lea rdi, [log_render_msg]
    call log_msg_simple
    call render_html_template
    jmp .cleanup

.serve_submitted_txt:
    lea rdi, [log_data_msg]
    call log_msg_simple
    call serve_raw_text_file
    jmp .cleanup

.serve_static_file:
    lea rdi, [log_static_msg]
    call log_msg_simple
    call serve_static_file_logic
    jmp .cleanup

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; =================================================================
; ROUTE HANDLERS
; =================================================================
serve_raw_text_file:
    lea rdi, [submitted_filename]
    lea rsi, [HDR_TEXT]
    mov rdx, HDR_TEXT_LEN
    call send_file_content
    ret

serve_static_file_logic:
    lea rdi, [sp_file_path]
    lea rsi, [www_dir]
    call strcpy_simple
    mov rsi, r13
    cmp byte [rsi], '/'
    jne .no_slash
    inc rsi
.no_slash:
    call strcat_sp

    lea rdi, [log_prefix_static_path]
    lea rsi, [sp_file_path]
    call log_debug_msg

    lea rdi, [DOT_CSS]
    mov rsi, r13
    call strstr_sp
    test rax, rax
    jnz .send_css_header

.send_js_header:
    lea rdi, [sp_file_path]
    lea rsi, [HDR_JS]
    mov rdx, HDR_JS_LEN
    call send_file_content
    ret

.send_css_header:
    lea rdi, [sp_file_path]
    lea rsi, [HDR_CSS]
    mov rdx, HDR_CSS_LEN
    call send_file_content
    ret

render_html_template:
    ; --- 1. Determine the base name of the content file ---
    mov rsi, r13
    cmp byte [rsi], '/'
    jne .build_content_path
    cmp byte [rsi+1], 0
    jne .build_content_path
    ; If path is "/", the base name is "index"
    lea rdi, [content_path]
    lea rsi, [base_index]
    call strcpy_simple
    jmp .add_suffix

.build_content_path:
    ; For paths like "/about.html", copy "about.html"
    mov rdi, content_path
    mov rsi, r13
    cmp byte [rsi], '/'
    jne .no_leading_slash
    inc rsi ; Skip leading '/'
.no_leading_slash:
    call strcpy_simple

    ; --- 2. Truncate at ".html" to get the base name ---
    mov r14, content_path
.find_dot_loop:
    mov al, [r14]
    test al, al
    jz .no_dot
    cmp al, '.'
    je .dot_found
    inc r14
    jmp .find_dot_loop
.dot_found:
    mov byte [r14], 0 ; Truncate at dot
.no_dot:

.add_suffix:
    ; --- 3. Append ".content.html" to the base name ---
    lea rsi, [content_suffix]
    lea rdi, [content_path]
    call strcat_sp

    lea rdi, [log_prefix_content_path]
    lea rsi, [content_path]
    call log_debug_msg

    ; --- 4. Read template and data files ---
    lea rdi, [template_path]
    lea rsi, [template_buf]
    call read_file_into_buffer
    test rax, rax
    js send_404
    mov r12, rax

    lea rdi, [content_path]
    lea rsi, [data_buf]
    call read_file_into_buffer
    test rax, rax
    js send_404
    mov r13, rax

    ; --- 5. Render and send ---
    lea rdi, [template_buf]
    mov rsi, r12
    lea rdx, [placeholder]
    mov rcx, placeholder_len
    lea r8, [data_buf]
    mov r9, r13
    lea r10, [response_buf]
    call find_and_replace
    mov r15, rax

    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [HDR_HTML]
    mov rdx, HDR_HTML_LEN
    syscall

    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [response_buf]
    mov rdx, r15
    syscall
    ret

; =================================================================
; HELPER FUNCTIONS
; =================================================================
send_file_content:
    push rsi
    push rdx
    mov rax, 2
    xor rsi, rsi
    syscall
    test rax, rax
    js send_404
    mov r12, rax

    pop rdx
    pop rsi
    mov rax, 1
    mov rdi, [client_fd]
    syscall

.read_loop:
    mov rax, 0
    mov rdi, r12
    lea rsi, [sp_filebuf]
    mov rdx, 8192
    syscall
    test rax, rax
    jle .close_file
    mov rdx, rax
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [sp_filebuf]
    syscall
    jmp .read_loop

.close_file:
    mov rax, 3
    mov rdi, r12
    syscall
    ret

send_404:
    mov rax, 1
    mov rdi, [client_fd]
    lea rsi, [http_404_response]
    mov rdx, http_404_response_len
    syscall
    ret

; --- CORRECTED read_file_into_buffer ---
; rdi = path, rsi = buffer
read_file_into_buffer:
    push rdi ; Save registers we will modify
    push rsi

    ; open(path, O_RDONLY)
    mov rax, 2
    ; rdi (path) is already set
    xor rsi, rsi ; O_RDONLY
    syscall
    test rax, rax
    js .read_fail
    mov r14, rax ; save fd

    ; read(fd, buffer, 8191)
    mov rax, 0
    mov rdi, r14 ; fd
    pop rsi      ; Restore the buffer address from the stack
    mov rdx, 8191
    syscall
    ; rax now holds bytes_read or -1

    push rax ; save bytes_read

    ; close(fd)
    mov rax, 3
    mov rdi, r14
    syscall

    pop rax ; restore bytes_read
    pop rdi ; restore original rdi (path)
    ret

.read_fail:
    pop rsi
    pop rdi
    mov rax, -1
    ret

find_and_replace:
    mov r11, r10
    mov r14, rdi
    mov r15, rsi
.main_loop:
    cmp r15, rcx
    jl .copy_remainder
    push rcx
    push rdi
    push rsi
    mov rdi, r14
    mov rsi, rdx
    repe cmpsb
    mov r12, rcx
    pop rsi
    pop rdi
    pop rcx
    test r12, r12
    jz .found_match
    mov al, [r14]
    mov [r11], al
    inc r14
    inc r11
    dec r15
    jmp .main_loop
.found_match:
    mov rdi, r11
    mov rsi, r8
    push rcx
    mov rcx, r9
    rep movsb
    mov r11, rdi
    pop rcx
    add r14, rcx
    sub r15, rcx
    jmp .main_loop
.copy_remainder:
    test r15, r15
    jz .done
    mov rcx, r15
    mov rdi, r11
    mov rsi, r14
    rep movsb
    mov r11, rdi
.done:
    sub r11, r10
    mov rax, r11
    ret

; --- String helpers ---
strcpy_simple:
.loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .loop
    dec rdi
    ret

strcat_sp:
.find_end:
    cmp byte [rdi], 0
    je .do_copy
    inc rdi
    jmp .find_end
.do_copy:
    call strcpy_simple
    ret

strcmp_sp:
.loop:
    mov al, [rdi]
    mov ah, [rsi]
    cmp al, ah
    jne .noteq
    test al, al
    jz .eq
    inc rdi
    inc rsi
    jmp .loop
.noteq:
    mov rax, -1
    ret
.eq:
    xor rax, rax
    ret

strstr_sp:
    push rdi
    push rsi
    push rcx
    push rdx
.haystack_loop:
    mov al, [rsi]
    test al, al
    jz .not_found
    cmp al, [rdi]
    jne .next_char
    push rsi
    push rdi
    call strcmp_sp
    pop rdi
    pop rsi
    test rax, rax
    jz .found
.next_char:
    inc rsi
    jmp .haystack_loop
.found:
    mov rax, rsi
    jmp .end
.not_found:
    xor rax, rax
.end:
    pop rdx
    pop rcx
    pop rsi
    pop rdi
    ret

log_debug_msg:
    push rdi
    push rsi
    push rdx
    mov rdi, [rsp+16]
    call log_msg_simple
    mov rdi, [rsp+8]
    call log_msg_simple
    pop rdx
    pop rsi
    pop rdi
    ret
