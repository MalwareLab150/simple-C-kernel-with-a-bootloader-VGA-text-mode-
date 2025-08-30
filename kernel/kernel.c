#include <stdint.h>

static volatile uint16_t* const VGA = (uint16_t*)0xB8000;
enum { COLS = 80, ROWS = 25 };

static void clear(void) {
    for (int i = 0; i < COLS * ROWS; ++i) {
        VGA[i] = (uint16_t)(' ' | (0x07u << 8));
    }
}

static void Print(int row, int col, const char* s) {
    int idx = row * COLS + col;
    while (*s) {
        VGA[idx++] = (uint16_t)((uint8_t)*s | (0x04 << 8)); // 0X04 = RED (https://en.wikipedia.org/wiki/BIOS_color_attributes)
        s++;
    }
}

void kmain(void) {
    clear();
    Print(0, 0, "HELLO");


}
