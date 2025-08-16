# Makefile untuk HTTP Server Assembly x86-64
# Target: Linux x86-64

ASM = as
LD = ld
SERVER_SRC = http_server.s
SERVER_OBJ = http_server.o
SERVER_BIN = http_server

ASMFLAGS = --64 -g
LDFLAGS = -m elf_x86_64

.PHONY: all clean run test

all: $(SERVER_BIN)
	chmod +x ./$(SERVER_BIN)

$(SERVER_OBJ): $(SERVER_SRC)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(SERVER_BIN): $(SERVER_OBJ)
	$(LD) $(LDFLAGS) -o $@ $<

clean:
	rm -f $(SERVER_OBJ) $(SERVER_BIN)

run: $(SERVER_BIN)
	./$(SERVER_BIN)

test: $(SERVER_BIN)
	@echo "Starting server in background..."
	./$(SERVER_BIN) &
	@sleep 10
	@echo "Testing GET /"
	curl -i http://localhost:8080/
	@echo -e "\n\nTesting GET /about"
	curl -i http://localhost:8080/about
	@echo -e "\n\nTesting GET /test"
	curl -i http://localhost:8080/test
	@echo -e "\n\nTesting POST /test"
	curl -i -X POST -d "data=hello" http://localhost:8080/test
	@echo -e "\n\nTesting 404 error"
	curl -i http://localhost:8080/notfound
	@echo -e "\n\nKilling server..."
	sudo pkill -f http_server
	make clean

help:
	@echo "Available commands:"
	@echo "  make all        - Build the server"
	@echo "  make clean      - Clean build files"
	@echo "  make run        - Run the server"
	@echo "  make test       - Build and test the server"
	@echo "  make help       - Show this help"