/* CVE-2026-111497 の修正条件を直接検証する。
 * 公式修正 b418fa81: 不正な block switch を入力不足と区別し、処理を止める。
 * 公開PoCではなく、デコーダ内部状態を作る回帰テスト。1.2.0では失敗する。
 * decode.cを直接含め、ASan/UBSanで実際の修正関数と呼出元を検査する。 */
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "dec/decode.c"

int main(void) {
    const int expected_error = -17; /* BROTLI_DECODER_ERROR_FORMAT_BLOCK_SWITCH */
    for (int safe = 0; safe <= 1; ++safe) {
        for (int n = 0; n <= 1; ++n) {
            BrotliDecoderState *s = BrotliDecoderCreateInstance(NULL, NULL, NULL);
            assert(s);
            s->block_type_trees = calloc(3 * (BROTLI_HUFFMAN_MAX_SIZE_258 +
                BROTLI_HUFFMAN_MAX_SIZE_26), sizeof(HuffmanCode));
            assert(s->block_type_trees);
            s->block_len_trees = s->block_type_trees + 3 * BROTLI_HUFFMAN_MAX_SIZE_258;
            for (int tree = 0; tree < 3; ++tree) {
                s->num_block_types[tree] = n;
                assert(DecodeBlockTypeAndLength(safe, s, tree) == expected_error);
            }
            assert(DecodeLiteralBlockSwitchInternal(safe, s) == expected_error);
            assert(DecodeCommandBlockSwitchInternal(safe, s) == expected_error);
            assert(DecodeDistanceBlockSwitchInternal(safe, s) == expected_error);
            /* 上位ループまでエラーが伝播し、書き込みや無限ループに進まないこと。 */
            const uint8_t input[64] = {0};
            BrotliInitBitReader(&s->br);
            BrotliBitReaderSetInput(&s->br, input, sizeof(input));
            s->state = BROTLI_STATE_COMMAND_BEGIN;
            s->block_length[1] = 0;
            assert(ProcessCommandsInternal(safe, s) == expected_error);
            BrotliDecoderDestroyInstance(s);
        }
    }
    printf("PASS: invalid block switch, all 3 tree types, fast/safe paths and command loop; version=0x%08x\n", BrotliDecoderVersion());
    return 0;
}
