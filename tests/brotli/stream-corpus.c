/* 公開デコードAPIを小さな入力・出力断片で呼び、正常データと決定的変異を検査。 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <brotli/decode.h>

static void decode(const uint8_t *data, size_t length, int valid) {
    BrotliDecoderState *s = BrotliDecoderCreateInstance(NULL, NULL, NULL);
    assert(s);
    size_t pos = 0, total = 0;
    BrotliDecoderResult result = BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT;
    for (int step = 0; step < 100000; ++step) {
        size_t in = pos < length ? 1 : 0;
        const uint8_t *next = data + pos;
        uint8_t output[31];
        uint8_t *out = output;
        size_t available = sizeof(output);
        result = BrotliDecoderDecompressStream(s, &in, &next, &available, &out, &total);
        pos = (size_t)(next - data);
        if (result == BROTLI_DECODER_RESULT_ERROR || result == BROTLI_DECODER_RESULT_SUCCESS) break;
        if (pos == length && result == BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT) break;
        if (total > 1024 * 1024) break;
    }
    if (valid) assert(result == BROTLI_DECODER_RESULT_SUCCESS);
    BrotliDecoderDestroyInstance(s);
}
int main(int argc, char **argv) {
    assert(BrotliDecoderVersion() == 0x01002001);
    unsigned cases = 0;
    for (int arg = 1; arg < argc; ++arg) {
        FILE *f = fopen(argv[arg], "rb"); assert(f);
        fseek(f, 0, SEEK_END); long size = ftell(f); rewind(f);
        assert(size >= 0 && size < 100000);
        uint8_t *data = malloc((size_t)size + 1); assert(data);
        assert(fread(data, 1, (size_t)size, f) == (size_t)size); fclose(f);
        decode(data, (size_t)size, 1); ++cases;
        for (size_t i = 0; i < (size_t)size && i < 128; ++i) {
            decode(data, i, 0); ++cases;
            for (unsigned bit = 0; bit < 8; ++bit) {
                data[i] ^= 1u << bit;
                decode(data, (size_t)size, 0); ++cases;
                data[i] ^= 1u << bit;
            }
        }
        free(data);
    }
    printf("PASS: %u streaming corpus cases; Brotli 1.2.1\n", cases);
    return 0;
}
