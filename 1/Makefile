# Define source and binary directories
SRCDIR = src
BINDIR = bin

# --- Compiler and Assembler Definitions ---
ASM = nasm
ASMFLAGS = -f elf64
CC = gcc
CFLAGS = -Wall -O2 -c

# --- Project Files ---
# Define the final executable path
TARGET = $(BINDIR)/server

# Define the source files
SOURCES_ASM = $(wildcard $(SRCDIR)/*.asm)
SOURCES_C = $(wildcard $(SRCDIR)/*.c)

# Automatically generate the list of object files to be placed in the bin directory
OBJS = $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.o,$(SOURCES_ASM))
OBJS += $(patsubst $(SRCDIR)/%.c,$(BINDIR)/%.o,$(SOURCES_C))


# --- Build Rules ---
.PHONY: all run clean

# Default rule: build the target executable
# This depends on the final server binary
all: $(TARGET)

# Rule to link all object files from the bin directory into the final executable
# The '| $(BINDIR)' is an order-only prerequisite, ensuring the directory is created first.
# -nostartfiles: Don't link the standard C startup files (which contain _start).
# -no-pie: Create a regular, position-dependent executable.
$(TARGET): $(OBJS) | $(BINDIR)
	$(CC) -o $@ $^ -nostartfiles -no-pie

# Rule to create the bin directory if it doesn't exist
$(BINDIR):
	@mkdir -p $(BINDIR)

# --- MODIFIED RULES to output files to the 'bin' directory ---

# Generic rule to compile any .asm file from src into a .o file in the bin directory
$(BINDIR)/%.o: $(SRCDIR)/%.asm | $(BINDIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Generic rule to compile any .c file from src into a .o file in the bin directory
$(BINDIR)/%.o: $(SRCDIR)/%.c | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $<


# --- Utility Rules ---

# Rule to run the server. Depends on 'all' to ensure it's built first.
run: all
	@echo "Starting server on :8080 ..."
	./$(TARGET)

# Rule to clean up build files. 'rm -rf' removes the directory and its contents.
# --- FIXED: Removed *.content.html to prevent deleting source content ---
clean:
	rm -rf $(BINDIR)
	rm -f server.log submitted.txt
