#!/usr/bin/env python3
"""
AssemblyWeb Framework - A Python web framework powered by Assembly HTTP server
[KREATIVITAS] Framework Backend Implementation
"""

import os
import sys
import json
import subprocess
import threading
import time
import signal
from pathlib import Path
from typing import Dict, List, Callable, Any, Optional
from dataclasses import dataclass
from functools import wraps

@dataclass
class Route:
    """Route definition"""
    path: str
    method: str
    handler: Callable
    middleware: List[Callable] = None

class AssemblyWebFramework:
    """
    AssemblyWeb Framework - Express.js-like framework for Python
    Uses Assembly HTTP server as the core engine
    """
    
    def __init__(self, name: str = "AssemblyWebApp"):
        self.name = name
        self.routes: List[Route] = []
        self.middleware_stack: List[Callable] = []
        self.static_dirs: Dict[str, str] = {}
        self.config = {
            'port': 8080,
            'host': 'localhost',
            'debug': False,
            'auto_reload': False
        }
        self.server_process = None
        self.is_running = False
        
    def route(self, path: str, methods: List[str] = None):
        """Decorator for defining routes"""
        if methods is None:
            methods = ['GET']
            
        def decorator(handler):
            for method in methods:
                route = Route(path=path, method=method, handler=handler)
                self.routes.append(route)
            return handler
        return decorator
    
    def get(self, path: str):
        """Decorator for GET routes"""
        return self.route(path, ['GET'])
    
    def post(self, path: str):
        """Decorator for POST routes"""
        return self.route(path, ['POST'])
    
    def put(self, path: str):
        """Decorator for PUT routes"""
        return self.route(path, ['PUT'])
    
    def delete(self, path: str):
        """Decorator for DELETE routes"""
        return self.route(path, ['DELETE'])
    
    def use(self, middleware: Callable):
        """Add middleware to the stack"""
        self.middleware_stack.append(middleware)
    
    def static(self, route: str, directory: str):
        """Serve static files"""
        self.static_dirs[route] = directory
    
    def before_request(self, handler: Callable):
        """Decorator for before request middleware"""
        self.middleware_stack.insert(0, handler)
        return handler
    
    def after_request(self, handler: Callable):
        """Decorator for after request middleware"""
        self.middleware_stack.append(handler)
        return handler
    
    def generate_assembly_routes(self) -> str:
        """Generate Assembly code for defined routes"""
        assembly_code = []
        
        # Generate route handling code
        for i, route in enumerate(self.routes):
            assembly_code.append(f"""
# Route {i}: {route.method} {route.path}
route_{i}_path: .ascii "{route.path} "
route_{i}_path_len = . - route_{i}_path

handle_route_{i}:
    # Call Python handler for route {i}
    movq $python_handler_{i}, %rdi
    call execute_python_handler
    ret
""")
        
        return "\n".join(assembly_code)
    
    def generate_route_table(self) -> str:
        """Generate route table for Assembly server"""
        table_entries = []
        
        for i, route in enumerate(self.routes):
            table_entries.append(f"""
    # {route.method} {route.path}
    movq $route_{i}_path, %rdi
    movq $route_{i}_path_len, %rcx
    call strncmp
    cmpq $0, %rax
    je handle_route_{i}
""")
        
        return "\n".join(table_entries)
    
    def create_python_bridge(self):
        """Create bridge between Assembly server and Python handlers"""
        bridge_code = f"""
import sys
import json
import importlib.util
from pathlib import Path

# Load the main application
spec = importlib.util.spec_from_file_location("app", "{sys.argv[0]}")
app_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app_module)

# Route handlers mapping
route_handlers = {{
"""
        
        for i, route in enumerate(self.routes):
            handler_name = route.handler.__name__
            bridge_code += f'    {i}: app_module.{handler_name},\n'
        
        bridge_code += """
}

def execute_handler(route_id, request_data):
    '''Execute Python route handler'''
    try:
        handler = route_handlers.get(route_id)
        if handler:
            result = handler(request_data)
            return result
        return {"error": "Handler not found", "status": 404}
    except Exception as e:
        return {"error": str(e), "status": 500}

if __name__ == "__main__":
    route_id = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    request_data = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    result = execute_handler(route_id, request_data)
    print(json.dumps(result))
"""
        
        # Write bridge file
        with open("python_bridge.py", "w") as f:
            f.write(bridge_code)
    
    def compile_server(self):
        """Compile the Assembly server with generated routes"""
        print("🔧 Compiling Assembly HTTP server with routes...")
        
        # Generate route code
        route_code = self.generate_assembly_routes()
        route_table = self.generate_route_table()
        
        # Create enhanced server with Python integration
        enhanced_server = f"""
# Enhanced Assembly server with Python integration
.include "http_server.s"

{route_code}

# Enhanced request parsing with Python integration
enhanced_parse_request:
    # Parse request and determine route
    call parse_http_request
    
    # Route table
{route_table}
    
    # Default 404
    jmp send_404_response

# Execute Python handler
execute_python_handler:
    # %rdi contains handler ID
    pushq %rbp
    movq %rsp, %rbp
    
    # Fork process to execute Python
    movq $57, %rax                 # sys_fork
    syscall
    
    cmpq $0, %rax
    je python_child_process
    
    # Parent process - wait for child
    movq $61, %rax                 # sys_wait4
    syscall
    
    # Read result from Python process
    call read_python_result
    
    popq %rbp
    ret

python_child_process:
    # Execute Python bridge
    # Implementation details...
    movq $60, %rax                 # sys_exit
    movq $0, %rdi
    syscall

read_python_result:
    # Read JSON result from Python handler
    # Parse and send HTTP response
    ret
"""
        
        # Write enhanced server
        with open("enhanced_server.s", "w") as f:
            f.write(enhanced_server)
        
        # Compile
        try:
            subprocess.run(["as", "--64", "-o", "enhanced_server.o", "enhanced_server.s"], check=True)
            subprocess.run(["ld", "-m", "elf_x86_64", "-o", "enhanced_server", "enhanced_server.o"], check=True)
            print("✅ Assembly server compiled successfully")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Compilation failed: {e}")
            return False
    
    def start_server(self):
        """Start the Assembly HTTP server"""
        if self.is_running:
            print("⚠️ Server is already running")
            return
        
        # Create Python bridge
        self.create_python_bridge()
        
        # Compile server if needed
        if not Path("enhanced_server").exists():
            if not self.compile_server():
                print("❌ Failed to start server: compilation error")
                return
        
        print(f"🚀 Starting {self.name} on port {self.config['port']}...")
        
        try:
            # Start Assembly server process
            self.server_process = subprocess.Popen(
                ["sudo", "./enhanced_server"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Give server time to start
            time.sleep(1)
            
            # Check if server started successfully
            if self.server_process.poll() is None:
                self.is_running = True
                print(f"✅ Server started successfully!")
                print(f"🌐 Server running at http://{self.config['host']}:{self.config['port']}")
                self.print_routes()
            else:
                stdout, stderr = self.server_process.communicate()
                print(f"❌ Server failed to start")
                print(f"Error: {stderr.decode()}")
                
        except Exception as e:
            print(f"❌ Failed to start server: {e}")
    
    def stop_server(self):
        """Stop the Assembly HTTP server"""
        if not self.is_running:
            print("⚠️ Server is not running")
            return
        
        print("⏹️ Stopping server...")
        
        if self.server_process:
            self.server_process.terminate()
            self.server_process.wait()
            self.server_process = None
        
        # Kill any remaining processes
        try:
            subprocess.run(["sudo", "pkill", "-f", "enhanced_server"], check=False)
        except:
            pass
        
        self.is_running = False
        print("✅ Server stopped")
    
    def restart_server(self):
        """Restart the server"""
        self.stop_server()
        time.sleep(1)
        self.start_server()
    
    def print_routes(self):
        """Print registered routes"""
        print("\n📋 Registered Routes:")
        print("=" * 50)
        
        grouped_routes = {}
        for route in self.routes:
            if route.path not in grouped_routes:
                grouped_routes[route.path] = []
            grouped_routes[route.path].append(route.method)
        
        for path, methods in grouped_routes.items():
            methods_str = ", ".join(methods)
            print(f"  {path:<20} {methods_str}")
        
        if self.static_dirs:
            print("\n📁 Static Routes:")
            for route, directory in self.static_dirs.items():
                print(f"  {route:<20} -> {directory}")
        
        print("=" * 50)
    
    def run(self, host: str = None, port: int = None, debug: bool = False):
        """Run the application"""
        if host:
            self.config['host'] = host
        if port:
            self.config['port'] = port
        if debug:
            self.config['debug'] = debug
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        self.start_server()
        
        if self.is_running:
            try:
                # Keep main thread alive
                while self.is_running:
                    time.sleep(1)
            except KeyboardInterrupt:
                print("\n🔄 Shutting down gracefully...")
                self.stop_server()
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\n📡 Received signal {signum}")
        self.stop_server()
        sys.exit(0)

# Middleware decorators and utilities
class Request:
    """Request object"""
    def __init__(self, data: dict):
        self.method = data.get('method', 'GET')
        self.path = data.get('path', '/')
        self.headers = data.get('headers', {})
        self.body = data.get('body', '')
        self.query = data.get('query', {})

class Response:
    """Response object"""
    def __init__(self):
        self.status_code = 200
        self.headers = {'Content-Type': 'text/html'}
        self.body = ''
    
    def json(self, data: dict):
        """Send JSON response"""
        self.headers['Content-Type'] = 'application/json'
        self.body = json.dumps(data)
        return self
    
    def html(self, content: str):
        """Send HTML response"""
        self.headers['Content-Type'] = 'text/html'
        self.body = content
        return self
    
    def status(self, code: int):
        """Set status code"""
        self.status_code = code
        return self

# Middleware functions
def cors_middleware(request, response, next_func):
    """CORS middleware"""
    response.headers.update({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    })
    return next_func()

def auth_middleware(request, response, next_func):
    """Authentication middleware"""
    token = request.headers.get('Authorization')
    if not token or not token.startswith('Bearer '):
        response.status(401).json({'error': 'Authentication required'})
        return response
    return next_func()

def logging_middleware(request, response, next_func):
    """Request logging middleware"""
    start_time = time.time()
    result = next_func()
    duration = time.time() - start_time
    print(f"📝 {request.method} {request.path} - {response.status_code} ({duration:.3f}s)")
    return result

# Template engine
class TemplateEngine:
    """Simple template engine"""
    
    @staticmethod
    def render(template_path: str, context: dict = None) -> str:
        """Render template with context"""
        if context is None:
            context = {}
        
        try:
            with open(template_path, 'r') as f:
                template = f.read()
            
            # Simple variable substitution
            for key, value in context.items():
                template = template.replace(f'{{{{{key}}}}}', str(value))
            
            return template
        except FileNotFoundError:
            return f"<h1>Template not found: {template_path}</h1>"

# Example usage and demo application
def create_demo_app():
    """Create a demo application"""
    app = AssemblyWebFramework("AssemblyWeb Demo")
    
    # Add middleware
    app.use(logging_middleware)
    app.use(cors_middleware)
    
    # Static files
    app.static('/static', './www')
    
    @app.get('/')
    def index(request):
        """Homepage"""
        return Response().html("""
        <!DOCTYPE html>
        <html>
        <head>
            <title>AssemblyWeb Framework Demo</title>
            <style>
                body { font-family: Arial; margin: 40px; }
                .header { background: #667eea; color: white; padding: 20px; border-radius: 10px; }
                .content { margin: 20px 0; }
                .api-demo { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🔧 AssemblyWeb Framework</h1>
                <p>Python web framework powered by Assembly HTTP server</p>
            </div>
            
            <div class="content">
                <h2>Framework Features</h2>
                <ul>
                    <li>🚀 Assembly HTTP server core</li>
                    <li>🐍 Python route handlers</li>
                    <li>🎯 Express.js-like API</li>
                    <li>🔧 Built-in middleware support</li>
                    <li>📊 Template engine</li>
                    <li>🔒 Authentication & CORS</li>
                </ul>
                
                <h2>API Demo</h2>
                <div class="api-demo">
                    <strong>GET /api/hello</strong> - Simple JSON API<br>
                    <button onclick="fetch('/api/hello').then(r=>r.json()).then(console.log)">Test API</button>
                </div>
                
                <div class="api-demo">
                    <strong>POST /api/data</strong> - POST endpoint<br>
                    <button onclick="fetch('/api/data',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({test:true})}).then(r=>r.json()).then(console.log)">Test POST</button>
                </div>
                
                <div class="api-demo">
                    <strong>GET /api/stats</strong> - Server statistics<br>
                    <button onclick="fetch('/api/stats').then(r=>r.json()).then(console.log)">Get Stats</button>
                </div>
            </div>
            
            <script>
                console.log('🔧 AssemblyWeb Framework Demo loaded');
            </script>
        </body>
        </html>
        """)
    
    @app.get('/api/hello')
    def api_hello(request):
        """Simple API endpoint"""
        return Response().json({
            'message': 'Hello from AssemblyWeb Framework!',
            'framework': 'AssemblyWeb',
            'core': 'Assembly x86-64',
            'handler': 'Python'
        })
    
    @app.post('/api/data')
    def api_post_data(request):
        """POST API endpoint"""
        return Response().json({
            'message': 'Data received successfully',
            'received_data': request.body,
            'method': request.method,
            'timestamp': int(time.time())
        })
    
    @app.get('/api/stats')
    def api_stats(request):
        """Server statistics API"""
        return Response().json({
            'server': 'AssemblyWeb Framework',
            'uptime': int(time.time()),
            'routes_registered': len(app.routes),
            'middleware_count': len(app.middleware_stack),
            'status': 'running'
        })
    
    @app.get('/template-demo')
    def template_demo(request):
        """Template rendering demo"""
        context = {
            'title': 'Template Demo',
            'framework': 'AssemblyWeb',
            'features': ['Fast', 'Lightweight', 'Assembly-powered']
        }
        
        template = """
        <html>
        <head><title>{{title}}</title></head>
        <body>
            <h1>{{title}}</h1>
            <p>Welcome to {{framework}}!</p>
        </body>
        </html>
        """
        
        # Simple template rendering
        rendered = template
        for key, value in context.items():
            if isinstance(value, list):
                value = ', '.join(value)
            rendered = rendered.replace(f'{{{{{key}}}}}', str(value))
        
        return Response().html(rendered)
    
    return app

# CLI interface
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='AssemblyWeb Framework')
    parser.add_argument('--demo', action='store_true', help='Run demo application')
    parser.add_argument('--port', type=int, default=8080, help='Port to run on')
    parser.add_argument('--host', default='localhost', help='Host to bind to')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    
    args = parser.parse_args()
    
    if args.demo:
        print("🚀 Starting AssemblyWeb Framework Demo")
        app = create_demo_app()
        app.run(host=args.host, port=args.port, debug=args.debug)
    else:
        print("AssemblyWeb Framework")
        print("Usage: python framework.py --demo")

# Export main classes
__all__ = ['AssemblyWebFramework', 'Request', 'Response', 'TemplateEngine',
           'cors_middleware', 'auth_middleware', 'logging_middleware']