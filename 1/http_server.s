# HTTP Web Server Assembly x86-64
# Target: Linux x86-64
# Fitur: TCP Socket, Fork, HTTP Parsing, Static Files, Routing

.section .data
    # Server configuration
    server_port: .word 8080
    backlog: .long 10
    
    # Socket address structure
    server_addr:
        .word 2                    # AF_INET
        .word 0x901f              # Port 8080 (network byte order)
        .long 0                   # INADDR_ANY
        .space 8                  # padding
    
    # HTTP Response templates
    http_200_header: .ascii "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n"
    http_200_header_len = . - http_200_header
    
    http_404_response: .ascii "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<html><body><h1>404 Not Found</h1></body></html>"
    http_404_response_len = . - http_404_response
    
    http_405_response: .ascii "HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<html><body><h1>405 Method Not Allowed</h1></body></html>"
    http_405_response_len = . - http_405_response
    
    # Default HTML content
    default_html: .ascii "<html><head><title>Assembly HTTP Server</title></head><body><h1>Welcome to Assembly HTTP Server!</h1><p>This server is written in x86-64 Assembly</p><ul><li><a href='/'>Home</a></li><li><a href='/about'>About</a></li><li><a href='/test'>Test</a></li></ul></body></html>"
    default_html_len = . - default_html
    
    about_html: .ascii "<html><head><title>About - Assembly HTTP Server</title></head><body><h1>About</h1><p>HTTP Server dibuat menggunakan Assembly x86-64</p><p>Fitur:</p><ul><li>TCP Socket Listening</li><li>Fork Child Process</li><li>HTTP Methods: GET, POST, PUT, DELETE</li><li>Static File Serving</li><li>Simple Routing</li></ul><a href='/'>Back to Home</a></body></html>"
    about_html_len = . - about_html
    
    test_html: .ascii "<html><head><title>Test - Assembly HTTP Server</title></head><body><h1>Test Page</h1><p>This is a test page for routing demonstration.</p><form method='POST' action='/test'><input type='text' name='data' placeholder='Enter some data'><button type='submit'>Submit POST</button></form><a href='/'>Back to Home</a></body></html>"
    test_html_len = . - test_html
    
    post_response: .ascii "<html><head><title>POST Response</title></head><body><h1>POST Request Received</h1><p>Your POST request was processed successfully!</p><a href='/'>Back to Home</a></body></html>"
    post_response_len = . - post_response
    
    # Messages
    server_start_msg: .ascii "Assembly HTTP Server starting on port 8080...\n"
    server_start_msg_len = . - server_start_msg
    
    client_connect_msg: .ascii "Client connected\n"
    client_connect_msg_len = . - client_connect_msg
    
    # HTTP method strings for comparison
    method_get: .ascii "GET "
    method_post: .ascii "POST "
    method_put: .ascii "PUT "
    method_delete: .ascii "DELETE "
    
    # Path strings
    path_root: .ascii "/ "
    path_about: .ascii "/about "
    path_test: .ascii "/test "
    
    # File buffer
    .bss
    request_buffer: .space 4096
    file_buffer: .space 8192
    socket_fd: .space 4
    client_fd: .space 4

.section .text
.globl _start

_start:
    # Print server start message
    movq $1, %rax                  # sys_write
    movq $1, %rdi                  # stdout
    movq $server_start_msg, %rsi
    movq $server_start_msg_len, %rdx
    syscall
    
    # Create socket
    movq $41, %rax                 # sys_socket
    movq $2, %rdi                  # AF_INET
    movq $1, %rsi                  # SOCK_STREAM
    movq $0, %rdx                  # protocol
    syscall
    
    cmpq $0, %rax
    jl exit_error
    movq %rax, socket_fd
    
    # Set socket options (SO_REUSEADDR)
    movq $54, %rax                 # sys_setsockopt
    movq socket_fd, %rdi
    movq $1, %rsi                  # SOL_SOCKET
    movq $2, %rdx                  # SO_REUSEADDR
    movq $1, %r10                  # optval = 1
    movq $4, %r8                   # optlen
    syscall
    
    # Bind socket
    movq $49, %rax                 # sys_bind
    movq socket_fd, %rdi
    movq $server_addr, %rsi
    movq $16, %rdx                 # sizeof(sockaddr_in)
    syscall
    
    cmpq $0, %rax
    jl exit_error
    
    # Listen
    movq $50, %rax                 # sys_listen
    movq socket_fd, %rdi
    movq backlog, %rsi
    syscall
    
    cmpq $0, %rax
    jl exit_error

accept_loop:
    # Accept connection
    movq $43, %rax                 # sys_accept
    movq socket_fd, %rdi
    movq $0, %rsi                  # addr (NULL)
    movq $0, %rdx                  # addrlen (NULL)
    syscall
    
    cmpq $0, %rax
    jl accept_loop
    movq %rax, client_fd
    
    # Print client connect message
    movq $1, %rax                  # sys_write
    movq $1, %rdi                  # stdout
    movq $client_connect_msg, %rsi
    movq $client_connect_msg_len, %rdx
    syscall
    
    # Fork process
    movq $57, %rax                 # sys_fork
    syscall
    
    cmpq $0, %rax
    je handle_client               # child process
    
    # Parent process - close client socket and continue accepting
    movq $3, %rax                  # sys_close
    movq client_fd, %rdi
    syscall
    jmp accept_loop

handle_client:
    # Child process - handle the client request
    
    # Close server socket in child
    movq $3, %rax                  # sys_close
    movq socket_fd, %rdi
    syscall
    
    # Read request
    movq $0, %rax                  # sys_read
    movq client_fd, %rdi
    movq $request_buffer, %rsi
    movq $4095, %rdx
    syscall
    
    # Null-terminate the request
    movq $request_buffer, %rdi
    addq %rax, %rdi
    movb $0, (%rdi)
    
    # Parse HTTP method and path
    call parse_http_request
    
    # Close client socket
    movq $3, %rax                  # sys_close
    movq client_fd, %rdi
    syscall
    
    # Exit child process
    movq $60, %rax                 # sys_exit
    movq $0, %rdi
    syscall

parse_http_request:
    # Parse HTTP request and route accordingly
    movq $request_buffer, %rsi
    
    # Check HTTP method
    # Check GET
    movq $method_get, %rdi
    movq $4, %rcx
    call strncmp
    cmpq $0, %rax
    je handle_get
    
    # Check POST
    movq $request_buffer, %rsi
    movq $method_post, %rdi
    movq $5, %rcx
    call strncmp
    cmpq $0, %rax
    je handle_post
    
    # Check PUT
    movq $request_buffer, %rsi
    movq $method_put, %rdi
    movq $4, %rcx
    call strncmp
    cmpq $0, %rax
    je handle_put
    
    # Check DELETE
    movq $request_buffer, %rsi
    movq $method_delete, %rdi
    movq $7, %rcx
    call strncmp
    cmpq $0, %rax
    je handle_delete
    
    # Method not supported
    jmp send_405_response

handle_get:
    # Parse path after "GET "
    movq $request_buffer, %rsi
    addq $4, %rsi                  # Skip "GET "
    
    # Check root path "/ "
    movq $path_root, %rdi
    movq $2, %rcx
    call strncmp
    cmpq $0, %rax
    je send_root_page
    
    # Check about path "/about "
    movq $request_buffer, %rsi
    addq $4, %rsi
    movq $path_about, %rdi
    movq $7, %rcx
    call strncmp
    cmpq $0, %rax
    je send_about_page
    
    # Check test path "/test "
    movq $request_buffer, %rsi
    addq $4, %rsi
    movq $path_test, %rdi
    movq $6, %rcx
    call strncmp
    cmpq $0, %rax
    je send_test_page
    
    # Path not found
    jmp send_404_response

handle_post:
    # Handle POST requests
    movq $request_buffer, %rsi
    addq $5, %rsi                  # Skip "POST "
    
    # Check test path for POST
    movq $path_test, %rdi
    movq $6, %rcx
    call strncmp
    cmpq $0, %rax
    je send_post_response
    
    # POST to other paths - send 404
    jmp send_404_response

handle_put:
    # Handle PUT requests - simple implementation
    jmp send_post_response

handle_delete:
    # Handle DELETE requests - simple implementation
    jmp send_post_response

send_root_page:
    # Send HTTP 200 header
    movq $1, %rax                  # sys_write
    movq client_fd, %rdi
    movq $http_200_header, %rsi
    movq $http_200_header_len, %rdx
    syscall
    
    # Send HTML content
    movq $1, %rax                  # sys_write
    movq client_fd, %rdi
    movq $default_html, %rsi
    movq $default_html_len, %rdx
    syscall
    ret

send_about_page:
    # Send HTTP 200 header
    movq $1, %rax
    movq client_fd, %rdi
    movq $http_200_header, %rsi
    movq $http_200_header_len, %rdx
    syscall
    
    # Send about HTML content
    movq $1, %rax
    movq client_fd, %rdi
    movq $about_html, %rsi
    movq $about_html_len, %rdx
    syscall
    ret

send_test_page:
    # Send HTTP 200 header
    movq $1, %rax
    movq client_fd, %rdi
    movq $http_200_header, %rsi
    movq $http_200_header_len, %rdx
    syscall
    
    # Send test HTML content
    movq $1, %rax
    movq client_fd, %rdi
    movq $test_html, %rsi
    movq $test_html_len, %rdx
    syscall
    ret

send_post_response:
    # Send HTTP 200 header
    movq $1, %rax
    movq client_fd, %rdi
    movq $http_200_header, %rsi
    movq $http_200_header_len, %rdx
    syscall
    
    # Send POST response HTML
    movq $1, %rax
    movq client_fd, %rdi
    movq $post_response, %rsi
    movq $post_response_len, %rdx
    syscall
    ret

send_404_response:
    movq $1, %rax                  # sys_write
    movq client_fd, %rdi
    movq $http_404_response, %rsi
    movq $http_404_response_len, %rdx
    syscall
    ret

send_405_response:
    movq $1, %rax                  # sys_write
    movq client_fd, %rdi
    movq $http_405_response, %rsi
    movq $http_405_response_len, %rdx
    syscall
    ret

# String comparison function
# Input: %rsi = string1, %rdi = string2, %rcx = length
# Output: %rax = 0 if equal, non-zero if different
strncmp:
    pushq %rcx
    pushq %rsi
    pushq %rdi
    
strncmp_loop:
    cmpq $0, %rcx
    je strncmp_equal
    
    movb (%rsi), %al
    movb (%rdi), %bl
    cmpb %al, %bl
    jne strncmp_different
    
    incq %rsi
    incq %rdi
    decq %rcx
    jmp strncmp_loop
    
strncmp_equal:
    movq $0, %rax
    jmp strncmp_end
    
strncmp_different:
    movq $1, %rax
    
strncmp_end:
    popq %rdi
    popq %rsi
    popq %rcx
    ret

exit_error:
    movq $60, %rax                 # sys_exit
    movq $1, %rdi                  # exit code 1
    syscall