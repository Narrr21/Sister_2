# Static File Server Module untuk HTTP Server Assembly
# Tambahan untuk mendukung file serving

.section .data
    # File paths
    www_root: .ascii "./www/"
    www_root_len = . - www_root
    
    # MIME types
    mime_html: .ascii "Content-Type: text/html\r\n"
    mime_html_len = . - mime_html
    
    mime_css: .ascii "Content-Type: text/css\r\n"
    mime_css_len = . - mime_css
    
    mime_js: .ascii "Content-Type: application/javascript\r\n"
    mime_js_len = . - mime_js
    
    mime_img: .ascii "Content-Type: image/jpeg\r\n"
    mime_img_len = . - mime_img
    
    mime_png: .ascii "Content-Type: image/png\r\n"
    mime_png_len = . - mime_png
    
    mime_default: .ascii "Content-Type: text/plain\r\n"
    mime_default_len = . - mime_default
    
    # File extensions
    ext_html: .ascii ".html"
    ext_css: .ascii ".css"
    ext_js: .ascii ".js"
    ext_jpg: .ascii ".jpg"
    ext_png: .ascii ".png"
    
    # Error messages
    file_not_found_msg: .ascii "File not found: "
    file_not_found_msg_len = . - file_not_found_msg

.section .bss
    file_path: .space 256
    file_size: .space 8

.section .text

# Function: serve_static_file
# Input: %rdi = path string
# Output: serves file to client_fd
serve_static_file:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    
    # Build full file path
    # Copy www_root to file_path
    movq $file_path, %rdi
    movq $www_root, %rsi
    movq $www_root_len, %rcx
    call memcpy
    
    # Append requested path (skip leading /)
    popq %rcx                      # Restore original path
    pushq %rcx
    incq %rcx                      # Skip '/'
    movq $file_path, %rdi
    addq $www_root_len, %rdi
    call strcat
    
    # Try to open file
    movq $2, %rax                  # sys_open
    movq $file_path, %rdi
    movq $0, %rsi                  # O_RDONLY
    syscall
    
    cmpq $0, %rax
    jl serve_file_not_found
    
    movq %rax, %r10                # Save file descriptor
    
    # Get file size using fstat
    movq $5, %rax                  # sys_fstat
    movq %r10, %rdi
    movq $file_buffer, %rsi        # Use buffer as stat struct
    syscall
    
    # File size is at offset 48 in stat struct
    movq 48(%rsi), %r11            # File size
    
    # Send HTTP 200 header with appropriate MIME type
    call send_file_header
    
    # Read and send file in chunks
send_file_loop:
    cmpq $0, %r11
    jle send_file_done
    
    # Calculate chunk size (min of remaining bytes and buffer size)
    movq %r11, %rdx
    cmpq $8192, %rdx
    jle read_chunk
    movq $8192, %rdx
    
read_chunk:
    # Read chunk from file
    movq $0, %rax                  # sys_read
    movq %r10, %rdi                # file descriptor
    movq $file_buffer, %rsi
    syscall                        # %rdx already set
    
    cmpq $0, %rax
    jle send_file_done
    
    # Send chunk to client
    movq %rax, %r12                # Save bytes read
    movq $1, %rax                  # sys_write
    movq client_fd, %rdi
    movq $file_buffer, %rsi
    movq %r12, %rdx
    syscall
    
    subq %r12, %r11                # Update remaining bytes
    jmp send_file_loop

send_file_done:
    # Close file
    movq $3, %rax                  # sys_close
    movq %r10, %rdi
    syscall
    
    jmp serve_static_end

serve_file_not_found:
    call send_404_response

serve_static_end:
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    popq %rbp
    ret

# Function: send_file_header
# Determines MIME type and sends appropriate header
send_file_header:
    # Send basic HTTP header
    movq $1, %rax
    movq client_fd, %rdi
    movq $http_200_start, %rsi
    movq $http_200_start_len, %rdx
    syscall
    
    # Determine MIME type from file extension
    call get_mime_type
    
    # Send MIME type header
    movq $1, %rax
    movq client_fd, %rdi
    # %rsi and %rdx set by get_mime_type
    syscall
    
    # Send end of headers
    movq $1, %rax
    movq client_fd, %rdi
    movq $header_end, %rsi
    movq $header_end_len, %rdx
    syscall
    
    ret

# Function: get_mime_type
# Input: file_path contains the file path
# Output: %rsi = mime type string, %rdx = mime type length
get_mime_type:
    # Find file extension
    movq $file_path, %rdi
    call find_extension
    
    # Compare with known extensions
    cmpq $0, %rax
    je mime_default_type
    
    # Check .html
    movq %rax, %rsi
    movq $ext_html, %rdi
    movq $5, %rcx
    call strncmp
    cmpq $0, %rax
    je mime_html_type
    
    # Check .css
    movq %rax, %rsi
    movq $ext_css, %rdi
    movq $4, %rcx
    call strncmp
    cmpq $0, %rax
    je mime_css_type
    
    # Check .js
    movq %rax, %rsi
    movq $ext_js, %rdi
    movq $3, %rcx
    call strncmp
    cmpq $0, %rax
    je mime_js_type
    
    # Default to text/plain
    jmp mime_default_type

mime_html_type:
    movq $mime_html, %rsi
    movq $mime_html_len, %rdx
    ret

mime_css_type:
    movq $mime_css, %rsi
    movq $mime_css_len, %rdx
    ret

mime_js_type:
    movq $mime_js, %rsi
    movq $mime_js_len, %rdx
    ret

mime_default_type:
    movq $mime_default, %rsi
    movq $mime_default_len, %rdx
    ret

# Function: find_extension
# Input: %rdi = file path
# Output: %rax = pointer to extension or 0 if not found
find_extension:
    movq %rdi, %rax
    movq $0, %rcx                  # Extension position
    
find_ext_loop:
    movb (%rax), %bl
    cmpb $0, %bl
    je find_ext_done
    
    cmpb $'.', %bl
    jne find_ext_continue
    movq %rax, %rcx                # Save potential extension start
    
find_ext_continue:
    incq %rax
    jmp find_ext_loop
    
find_ext_done:
    movq %rcx, %rax
    ret

# Utility functions
memcpy:
    # %rdi = dest, %rsi = src, %rcx = count
    pushq %rcx
    cld
    rep movsb
    popq %rcx
    ret

strcat:
    # %rdi = dest (at end position), %rsi = src
    pushq %rax
strcat_loop:
    movb (%rsi), %al
    movb %al, (%rdi)
    cmpb $0, %al
    je strcat_done
    incq %rsi
    incq %rdi
    jmp strcat_loop
strcat_done:
    popq %rax
    ret

.section .data
    http_200_start: .ascii "HTTP/1.1 200 OK\r\n"
    http_200_start_len = . - http_200_start
    
    header_end: .ascii "\r\n"
    header_end_len = . - header_end