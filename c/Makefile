CC = gcc
CFLAGS = -Wall -O2
TARGET = calendar

all: $(TARGET)

$(TARGET): calendar.c
	$(CC) $(CFLAGS) -o $(TARGET) calendar.c

clean:
	rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)
