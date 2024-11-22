# famoso Makefile do grandessíssimo Prof Maziero
# https://wiki.inf.ufpr.br/maziero/doku.php?id=prog2:o_sistema_make
# https://wiki.inf.ufpr.br/maziero/doku.php?id=c:o_sistema_make

# Compiler and optimization flags
CC = gcc

# Optimization flags
OPTFLAGS = -O3 -march=native -fno-fast-math -flto -fuse-linker-plugin

# OpenMP flags
OMPFLAGS = -fopenmp

# Warning flags
WARNFLAGS = -Wall -Wextra -pedantic -Wno-unused-parameter

# Debug flags (when needed)
DBGFLAGS = -g -DDEBUG

# Architecture-specific optimizations (uncomment and modify based on your CPU)
#ARCHFLAGS = -mavx2 -mfma  # For modern Intel/AMD processors
#ARCHFLAGS = -mcpu=native  # For ARM processors

# Combine all flags
CFLAGS = $(OPTFLAGS) $(OMPFLAGS) $(WARNFLAGS) $(ARCHFLAGS)
LDFLAGS = $(OPTFLAGS) $(OMPFLAGS)
LIBS = -lm -lgsl -lgslcblas

# Source files and objects
SRCS = func.c c_ctl.c SPI.c
OBJS = $(SRCS:.c=.o)

# Default target
all: SPI clean mv

# Linking
SPI: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

# Generic compilation rule
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Debug build
debug: OPTFLAGS = -O0 -ggdb3
debug: CFLAGS += -DDEBUG
debug: clean all

# Profile build
profile: CFLAGS += -pg
profile: LDFLAGS += -pg
profile: clean all

# Clean rules
clean:
	-rm -f $(OBJS)

# Move executable to bin directory
mv:
	mkdir -p ../bin
	mv SPI ../bin/

# Deep clean
purge: clean
	-rm -f ../bin/SPI

# Set OpenMP threads (can be overridden from command line)
export OMP_NUM_THREADS ?= 4

# Help target
help:
	@echo "Available targets:"
	@echo "  all     : Build optimized executable (default)"
	@echo "  debug   : Build with debug symbols"
	@echo "  profile : Build with profiling support"
	@echo "  clean   : Remove object files"
	@echo "  purge   : Remove all generated files"
	@echo "  help    : Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  OMP_NUM_THREADS : Number of OpenMP threads (default: 4)"

.PHONY: all clean debug profile purge help mv
