SRCDIR = src
BINDIR = bin

ASM = nasm
ASMFLAGS = -f elf64
CC = gcc
CFLAGS = -Wall -O2 -c

TARGET = $(BINDIR)/server

SOURCES_ASM = $(wildcard $(SRCDIR)/*.asm)
SOURCES_C = $(wildcard $(SRCDIR)/*.c)

OBJS = $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.o,$(SOURCES_ASM))
OBJS += $(patsubst $(SRCDIR)/%.c,$(BINDIR)/%.o,$(SOURCES_C))


.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(OBJS) | $(BINDIR)
	$(CC) -o $@ $^ -nostartfiles -no-pie

$(BINDIR):
	@mkdir -p $(BINDIR)

$(BINDIR)/%.o: $(SRCDIR)/%.asm | $(BINDIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(BINDIR)/%.o: $(SRCDIR)/%.c | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $<

run: all
	@echo "Starting server on :8080 ..."
	./$(TARGET)

clean:
	rm -rf $(BINDIR)
	rm -f server.log submitted.txt
