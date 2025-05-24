# Define the C compiler to use
CC = gcc
# Define compiler flags: -Wall for all warnings, -g for debug info
CFLAGS = -Wall -g

# Source files
SRCS = main.c my_lib.c

# Object files (automatically derived from source files)
OBJS = $(SRCS:.c=.o)

# The name of the final executable
TARGET = my_program

# .PHONY rule to prevent 'all' and 'clean' from conflicting with actual files of those names
.PHONY: all clean

# Default target: builds the executable
all: $(TARGET)

# Rule to link object files into the final executable
$(TARGET): $(OBJS)
	@echo "All object files compiled. Taking a small break before linking..."
	sleep 2 # Pause for 2 seconds before linking
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET)
	@echo "Linking complete!"

# Rule to compile each .c file into a .o object file
# $< refers to the first prerequisite (the .c file)
# $@ refers to the target (the .o file)
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@
	sleep 1 # Pause for 1 second after each compilation
	@echo "Finished compiling $<."

# Rule to clean up generated files
clean:
	@echo "Cleaning up generated files..."
	rm -f $(OBJS) $(TARGET)
	@echo "Cleanup complete."
