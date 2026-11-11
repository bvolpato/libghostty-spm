#include "ghostty.h"

static void write_buffer(void *GHOSTTY_NULLABLE context,
                         const uint8_t *GHOSTTY_NONNULL bytes, size_t length) {
    (void)context;
    (void)bytes;
    (void)length;
}

static void resize(void *GHOSTTY_NULLABLE context, uint16_t columns,
                   uint16_t rows, uint32_t width, uint32_t height) {
    (void)context;
    (void)columns;
    (void)rows;
    (void)width;
    (void)height;
}

void exercise_host_io(void) {
    ghostty_surface_config_s config = {0};
    config.userdata = NULL;
    config.receive_userdata = NULL;
    config.receive_buffer = NULL;
    config.receive_resize = NULL;
    config.receive_buffer = write_buffer;
    config.receive_resize = resize;
    const uint8_t byte = 0;
    config.receive_buffer(NULL, &byte, 1);
    config.receive_resize(NULL, 80, 24, 800, 600);
}
