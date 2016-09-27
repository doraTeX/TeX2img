#import "NSString-Conversion.h"
#import "NSMutableString-Extension.h"

@implementation NSString (Conversion)

// あ → ア
-(NSString*)stringByReplacingHiraganaWithKatakana
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (unichar i=0x0001; i<=0x0056; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x3040 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x30A0 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    return str;
}

// ア → あ
-(NSString*)stringByReplacingKatakanaWithHiragana;
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (unichar i=0x0001; i<=0x0056; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x30A0 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x3040 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    return str;
}

// 1 → １
-(NSString*)stringByReplacingHankakuSujiWithZenkakuSuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=0; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x0030 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0xFF10 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    return str;
}

// １ → 1
-(NSString*)stringByReplacingZenkakuSujiWithHankakuSuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=0; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0xFF10 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x0030 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// A → Ａ, a → ａ
-(NSString*)stringByReplacingHankakuAlphWithZenkakuAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // A → Ａ
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x0040 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0xFF20 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    // a → ａ
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x0060 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0xFF40 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    return str;
}

// Ａ → A, ａ → a
-(NSString*)stringByReplacingZenkakuAlphWithHankakuAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // Ａ → A
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0xFF20 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x0040 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    // ａ → a
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0xFF40 + i)];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x0060 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    return str;
}

// Unicode文字 → ajmacros
-(NSString*)stringByReplacingUnicodeCharactersWithAjMacros
{
    return self.stringByReplacingMaruSujiWithAjMaru
    .stringByReplacingKuroMaruSujiWithAjKuroMaru
    .stringByReplacingKakkoSujiWithAjKakko
    .stringByReplacingMaruAlphWithAjMaruAlph
    .stringByReplacingKakkoAlphWithAjKakkoAlph
    .stringByReplacingKuroMaruAlphWithAjKuroMaruAlph
    .stringByReplacingKakuAlphWithAjKakuAlph
    .stringByReplacingKuroKakuAlphWithAjKuroKakuAlph
    .stringByReplacingRomanWithAjRoman
    .stringByReplacingPeriodWithAjPeriod
    .stringByReplacingKakkoYobiWithAjKakkoYobi
    .stringByReplacingMaruYobiWithAjMaruYobi
    .stringByReplacingNijuMaruWithAjNijuMaru
    .stringByReplacingRecycleWithAjRecycle
    .stringByReplacingMaruKataWithAjMaruKata
    .stringByReplacingKakkoKansujiWithAjKakkoKansuji
    .stringByReplacingMaruKansujiWithAjMaruKansuji
    .stringByReplacingLigWithAjLig;
}

// ajmacros → Unicode文字
-(NSString*)stringByReplacingAjMacrosWithUnicodeCharacters
{
    return self.stringByReplacingAjMaruWithMaruSuji
    .stringByReplacingAjKuroMaruWithKuroMaruSuji
    .stringByReplacingAjKakkoWithMakkoSuji
    .stringByReplacingAjMaruAlphWithMaruAlph
    .stringByReplacingAjKakkoAlphWithKakkoAlph
    .stringByReplacingAjKuroMaruAlphWithKuroMaruAlph
    .stringByReplacingAjKakuAlphWithKakuAlph
    .stringByReplacingAjKuroKakuAlphWithKuroKakuAlph
    .stringByReplacingAjRomanWithRoman
    .stringByReplacingAjPeriodWithPeriod
    .stringByReplacingAjKakkoYobiWithKakkoYobi
    .stringByReplacingAjMaruYobiWithMaruYobi
    .stringByReplacingAjNijuMaruWithNijuMaru
    .stringByReplacingAjRecycleWithRecycle
    .stringByReplacingAjMaruKataWithMaruKata
    .stringByReplacingAjKakkoKansujiWithKakkoKansuji
    .stringByReplacingAjMaruKansujiWithMaruKansuji
    .stringByReplacingAjLigWithLig;
}


// ① → \ajMaru // 0..50
-(NSString*)stringByReplacingMaruSujiWithAjMaru
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    NSString *src;
    NSString *dest;
    
    src = [NSString stringWithFormat:@"%C", (unichar)0x24EA];
    dest = @"\\ajMaru{0}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    for (int i=1; i<=20; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x2460 + i - 1)];
        dest = [NSString stringWithFormat:@"\\ajMaru{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    for (int i=21; i<=35; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x3251 + i - 21)];
        dest = [NSString stringWithFormat:@"\\ajMaru{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    for (int i=36; i<=50; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x32B1 + i - 36)];
        dest = [NSString stringWithFormat:@"\\ajMaru{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    return str;
}

// \ajMaru → ① // 0..50
-(NSString*)stringByReplacingAjMaruWithMaruSuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    NSString *src;
    NSString *dest;
    
    src = @"\\ajMaru{0}";
    dest = [NSString stringWithFormat:@"%C", (unichar)0x24EA];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajMaru0";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    for (int i=1; i<=20; i++) {
        src = [NSString stringWithFormat:@"\\ajMaru{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x2460 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        src = [NSString stringWithFormat:@"\\ajMaru%d", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x2460 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=21; i<=35; i++) {
        src = [NSString stringWithFormat:@"\\ajMaru{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x3251 + i - 21)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    for (int i=36; i<=50; i++) {
        src = [NSString stringWithFormat:@"\\ajMaru{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x32B1 + i - 36)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    return str;
}

// ❶ → \ajKuroMaru // 0..20
-(NSString*)stringByReplacingKuroMaruSujiWithAjKuroMaru
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    NSString *src;
    NSString *dest;
    
    src = [NSString stringWithFormat:@"%C", (unichar)0x24FF];
    dest = @"\\ajKuroMaru{0}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    for (int i=1; i<=10; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x2776 + i - 1)];
        dest = [NSString stringWithFormat:@"\\ajKuroMaru{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    for (int i=11; i<=20; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x24EB + i - 11)];
        dest = [NSString stringWithFormat:@"\\ajKuroMaru{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    return str;
}

// \ajKuroMaru → ❶ // 0..20
-(NSString*)stringByReplacingAjKuroMaruWithKuroMaruSuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    NSString *src;
    NSString *dest;
    
    src = @"\\ajKuroMaru{0}";
    dest = [NSString stringWithFormat:@"%C", (unichar)0x24FF];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajKuroMaru0";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    for (int i=1; i<=10; i++) {
        src = [NSString stringWithFormat:@"\\ajKuroMaru{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x2776 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        src = [NSString stringWithFormat:@"\\ajKuroMaru%d", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x2776 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=11; i<=20; i++) {
        src = [NSString stringWithFormat:@"\\ajKuroMaru{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x24EB + i - 11)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    return str;
}

// ⑴ → \ajKakko // 1..20
-(NSString*)stringByReplacingKakkoSujiWithAjKakko
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=20; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x2474 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKakko{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajKakko → ⑴ // 1..20
-(NSString*)stringByReplacingAjKakkoWithMakkoSuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=20; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakko{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2474 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakko%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2474 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// Ⓐ → \ajMaruAlph, ⓐ → \ajMarualph  // 1..26
-(NSString*)stringByReplacingMaruAlphWithAjMaruAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x24B6 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajMaruAlph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x24D0 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajMarualph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    return str;
}

// \ajMaruAlph → Ⓐ, \ajMarualph → ⓐ // 1..26
-(NSString*)stringByReplacingAjMaruAlphWithMaruAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMaruAlph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x24B6 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMaruAlph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x24B6 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMarualph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x24D0 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMarualph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x24D0 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// 🄐 → \ajKakkoAlph, ⒜ → \ajKakkoalph // 1..26
-(NSString*)stringByReplacingKakkoAlphWithAjKakkoAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // 🄐 → \ajKakkoAlph
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD10 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKakkoAlph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    // ⒜ → \ajKakkoalph
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x249C + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKakkoalph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    return str;
}

// \ajKakkoAlph → 🄐, \ajKakkoalph → ⒜ // 1..26
-(NSString*)stringByReplacingAjKakkoAlphWithKakkoAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // \ajKakkoAlph → 🄐
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakkoAlph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD10 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakkoAlph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD10 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    // \ajKakkoalph → ⒜
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakkoalph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x249C + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakkoalph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x249C + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}


// 🅐 → \ajKuroMaruAlph // 1..26
-(NSString*)stringByReplacingKuroMaruAlphWithAjKuroMaruAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD50 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKuroMaruAlph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajKuroMaruAlph → 🅐 // 1..26
-(NSString*)stringByReplacingAjKuroMaruAlphWithKuroMaruAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKuroMaruAlph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD50 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKuroMaruAlph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD50 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    return str;
}

// 🄰 → \ajKakuAlph // 1..26
-(NSString*)stringByReplacingKakuAlphWithAjKakuAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD30 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKakuAlph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajKakuAlph → 🄰 // 1..26
-(NSString*)stringByReplacingAjKakuAlphWithKakuAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakuAlph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD30 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakuAlph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD30 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// 🅰 → \ajKuroKakuAlph // 1..26
-(NSString*)stringByReplacingKuroKakuAlphWithAjKuroKakuAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD70 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKuroKakuAlph{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajKuroKakuAlph → 🅰 // 1..26
-(NSString*)stringByReplacingAjKuroKakuAlphWithKuroKakuAlph
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=26; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKuroKakuAlph{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD70 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKuroKakuAlph%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C%C", (unichar)0xD83C, (unichar)(0xDD70 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// Ⅰ → \ajRoman, ⅰ → \ajroman // 1..12
-(NSString*)stringByReplacingRomanWithAjRoman
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // Ⅰ → \ajRoman
    for (int i=1; i<=12; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x2160 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajRoman{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    // ⅰ → \ajroman
    for (int i=1; i<=12; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x2170 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajroman{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    return str;
}

// \ajRoman → Ⅰ, \ajroman → ⅰ // 1..12
-(NSString*)stringByReplacingAjRomanWithRoman
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // \ajRoman → Ⅰ
    for (int i=1; i<=12; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajRoman{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2160 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajRoman%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2160 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    // \ajroman → ⅰ
    for (int i=1; i<=12; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajroman{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2170 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajroman%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2170 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// ⒈ → \ajPeriod // 1..9
-(NSString*)stringByReplacingPeriodWithAjPeriod
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x2488 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajPeriod{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajPeriod → ⒈ // 1..9
-(NSString*)stringByReplacingAjPeriodWithPeriod
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajPeriod{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2488 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajPeriod%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2488 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    return str;
}

// ㈪ → \ajKakkoYobi // 1..9
-(NSString*)stringByReplacingKakkoYobiWithAjKakkoYobi
{
    NSString *src;
    NSString *dest;
    
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // ㈰
    src = [NSString stringWithFormat:@"%C", (unichar)(0x3230)];
    dest = @"\\ajKakkoYobi{1}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    // ㈪ ～ ㈯
    for (int i=2; i<=7; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x322A + i - 2)];
        dest = [NSString stringWithFormat:@"\\ajKakkoYobi{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    // ㈷
    src = [NSString stringWithFormat:@"%C", (unichar)(0x3237)];
    dest = @"\\ajKakkoYobi{8}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    // ㉁
    src = [NSString stringWithFormat:@"%C", (unichar)(0x3241)];
    dest = @"\\ajKakkoYobi{9}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    return str;
}

// \ajKakkoYobi → ㈪ // 1..9
-(NSString*)stringByReplacingAjKakkoYobiWithKakkoYobi
{
    NSString *src;
    NSString *dest;
    
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // ㈰
    src = @"\\ajKakkoYobi{1}";
    dest = [NSString stringWithFormat:@"%C", (unichar)(0x3230)];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajKakkoYobi1";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    // ㈪ ～ ㈮
    for (int i=2; i<=7; i++) {
        src = [NSString stringWithFormat:@"\\ajKakkoYobi{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x322A + i - 2)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

        src = [NSString stringWithFormat:@"\\ajKakkoYobi%d", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
}
    
    // ㈷
    src = @"\\ajKakkoYobi{8}";
    dest = [NSString stringWithFormat:@"%C", (unichar)(0x3237)];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajKakkoYobi8";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    // ㉁
    src = @"\\ajKakkoYobi{9}";
    dest = [NSString stringWithFormat:@"%C", (unichar)(0x3241)];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajKakkoYobi9";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    return str;
}

// ㊊ → \ajMaruYobi // 1..9
-(NSString*)stringByReplacingMaruYobiWithAjMaruYobi
{
    NSString *src;
    NSString *dest;
    
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // ㊐
    src = [NSString stringWithFormat:@"%C", (unichar)(0x3290)];
    dest = @"\\ajKakkoYobi{1}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    // ㊊ ～ ㊏
    for (int i=2; i<=7; i++) {
        src = [NSString stringWithFormat:@"%C", (unichar)(0x328A + i - 2)];
        dest = [NSString stringWithFormat:@"\\ajKakkoYobi{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    
    // ㊗
    src = [NSString stringWithFormat:@"%C", (unichar)(0x3297)];
    dest = @"\\ajKakkoYobi{8}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    // ㊡
    src = [NSString stringWithFormat:@"%C", (unichar)(0x3297)];
    dest = @"\\ajKakkoYobi{9}";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    
    return str;
}

// \ajMaruYobi → ㊊ // 1..9
-(NSString*)stringByReplacingAjMaruYobiWithMaruYobi
{
    NSString *src;
    NSString *dest;
    
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    // ㊐
    src = @"\\ajKakkoYobi{1}";
    dest = [NSString stringWithFormat:@"%C", (unichar)(0x3290)];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajKakkoYobi1";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    // ㊊ ～ ㊏
    for (int i=2; i<=7; i++) {
        src = [NSString stringWithFormat:@"\\ajKakkoYobi{%d}", i];
        dest = [NSString stringWithFormat:@"%C", (unichar)(0x328A + i - 2)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

        src = [NSString stringWithFormat:@"\\ajKakkoYobi%d", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    // ㊗
    src = @"\\ajKakkoYobi{8}";
    dest = [NSString stringWithFormat:@"%C", (unichar)(0x3297)];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];

    src = @"\\ajKakkoYobi8";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    
    // ㊡
    src = @"\\ajKakkoYobi{9}";
    dest = [NSString stringWithFormat:@"%C", (unichar)(0x3297)];
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    
    src = @"\\ajKakkoYobi9";
    [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    
    return str;
}

// ⓵ → \ajNijuMaru // 1..10
-(NSString*)stringByReplacingNijuMaruWithAjNijuMaru
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=10; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x24F5 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajNijuMaru{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajNijuMaru → ⓵ // 1..10
-(NSString*)stringByReplacingAjNijuMaruWithNijuMaru
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=10; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajNijuMaru{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x24F5 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajNijuMaru%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x24F5 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    return str;
}

// ♳ → \ajRecycle // 0..11
-(NSString*)stringByReplacingRecycleWithAjRecycle
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=0; i<=11; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x2672 + i)];
        NSString *dest = [NSString stringWithFormat:@"\\ajRecycle{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajRecycle → ♳ // 0..11
-(NSString*)stringByReplacingAjRecycleWithRecycle
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    for (int i=0; i<=11; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajRecycle{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2672 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    for (int i=0; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajRecycle%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x2672 + i)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// ㋐ → \ajMaruKata // 1..47 (48の「ン」は Unicode にない）
-(NSString*)stringByReplacingMaruKataWithAjMaruKata
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=47; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x32D0 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajMaruKata{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajMaruKata → ㋐ // 1..47 (48の「ン」は Unicode にない）
-(NSString*)stringByReplacingAjMaruKataWithMaruKata
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=47; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMaruKata{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x32D0 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMaruKata%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x32D0 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// ㈠ → \ajKakkoKansuji // 1..10
-(NSString*)stringByReplacingKakkoKansujiWithAjKakkoKansuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=10; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x3220 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajKakkoKansuji{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajKakkoKansuji → ㈠ // 1..10
-(NSString*)stringByReplacingAjKakkoKansujiWithKakkoKansuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    for (int i=1; i<=10; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakkoKansuji{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x3220 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }
    
    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajKakkoKansuji%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x3220 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// ㊀ → \ajMaruKansuji // 1..10
-(NSString*)stringByReplacingMaruKansujiWithAjMaruKansuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    for (int i=1; i<=10; i++) {
        NSString *src = [NSString stringWithFormat:@"%C", (unichar)(0x3280 + i - 1)];
        NSString *dest = [NSString stringWithFormat:@"\\ajMaruKansuji{%d}", i];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:YES];
    }
    return str;
}

// \ajMaruKansuji → ㊀ // 1..10
-(NSString*)stringByReplacingAjMaruKansujiWithMaruKansuji
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    for (int i=1; i<=10; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMaruKansuji{%d}", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x3280 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    for (int i=1; i<=9; i++) {
        NSString *src = [NSString stringWithFormat:@"\\ajMaruKansuji%d", i];
        NSString *dest = [NSString stringWithFormat:@"%C", (unichar)(0x3280 + i - 1)];
        [str replaceAllOccurrencesOfString:src withString:dest addingPercentForEndOfLine:NO];
    }

    return str;
}

// ㍿ → \ajLig{株式会社}
-(NSString*)stringByReplacingLigWithAjLig
{
    NSMutableString *str = [NSMutableString stringWithString:self];
    
    [str replaceAllOccurrencesOfString:@"㍾" withString:@"\\ajLig{明治}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍽" withString:@"\\ajLig{大正}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍼" withString:@"\\ajLig{昭和}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍻" withString:@"\\ajLig{平成}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍉" withString:@"\\ajLig{ミリ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌔" withString:@"\\ajLig{キロ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌢" withString:@"\\ajLig{センチ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍍" withString:@"\\ajLig{メートル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌘" withString:@"\\ajLig{グラム}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"トン" withString:@"\\ajLig{}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌃" withString:@"\\ajLig{アール}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌶" withString:@"\\ajLig{ヘクタール}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍑" withString:@"\\ajLig{リットル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍗" withString:@"\\ajLig{ワット}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌍" withString:@"\\ajLig{カロリー}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌦" withString:@"\\ajLig{ドル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌣" withString:@"\\ajLig{セント}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌫" withString:@"\\ajLig{パーセント}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍊" withString:@"\\ajLig{ミリバール}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌻" withString:@"\\ajLig{ページ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌖" withString:@"\\ajLig{キロメートル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌕" withString:@"\\ajLig{キログラム}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌃" withString:@"\\ajLig{アール}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍗" withString:@"\\ajLig{ワット}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍂" withString:@"\\ajLig{ホーン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌹" withString:@"\\ajLig{ヘルツ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌻" withString:@"\\ajLig{ページ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌀" withString:@"\\ajLig{アパート}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌱" withString:@"\\ajLig{ビル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍇" withString:@"\\ajLig{マンション}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌞" withString:@"\\ajLig{コーポ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌪" withString:@"\\ajLig{ハイツ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍿" withString:@"\\ajLig{株式会社}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌅" withString:@"\\ajLig{インチ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌳" withString:@"\\ajLig{フィート}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍎" withString:@"\\ajLig{ヤード}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌹" withString:@"\\ajLig{ヘルツ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍂" withString:@"\\ajLig{ホーン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌞" withString:@"\\ajLig{コーポ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌪" withString:@"\\ajLig{ハイツ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌁" withString:@"\\ajLig{アルファ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌂" withString:@"\\ajLig{アンペア}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌄" withString:@"\\ajLig{イニング}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌆" withString:@"\\ajLig{ウォン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌈" withString:@"\\ajLig{エーカー}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌇" withString:@"\\ajLig{エスクード}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌊" withString:@"\\ajLig{オーム}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌉" withString:@"\\ajLig{オンス}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌌" withString:@"\\ajLig{カラット}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌎" withString:@"\\ajLig{ガロン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌏" withString:@"\\ajLig{ガンマ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌐" withString:@"\\ajLig{ギガ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌑" withString:@"\\ajLig{ギニー}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌒" withString:@"\\ajLig{キュリー}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌓" withString:@"\\ajLig{ギルダー}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌗" withString:@"\\ajLig{キロワット}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌙" withString:@"\\ajLig{グラムトン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌚" withString:@"\\ajLig{クルゼイロ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌛" withString:@"\\ajLig{クローネ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌜" withString:@"\\ajLig{ケース}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌝" withString:@"\\ajLig{コルナ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌟" withString:@"\\ajLig{サイクル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌠" withString:@"\\ajLig{サンチーム}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌡" withString:@"\\ajLig{シリング}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌤" withString:@"\\ajLig{ダース}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌥" withString:@"\\ajLig{デシ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌨" withString:@"\\ajLig{ナノ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌩" withString:@"\\ajLig{ノット}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌭" withString:@"\\ajLig{バーレル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌮" withString:@"\\ajLig{ピアストル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌯" withString:@"\\ajLig{ピクル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌰" withString:@"\\ajLig{ピコ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌲" withString:@"\\ajLig{ファラッド}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌴" withString:@"\\ajLig{ブッシェル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌵" withString:@"\\ajLig{フラン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌼" withString:@"\\ajLig{ベータ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌷" withString:@"\\ajLig{ペソ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌸" withString:@"\\ajLig{ペニヒ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌺" withString:@"\\ajLig{ペンス}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌽" withString:@"\\ajLig{ポイント}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍁" withString:@"\\ajLig{ホール}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌾" withString:@"\\ajLig{ボルト}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㌿" withString:@"\\ajLig{ホン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍀" withString:@"\\ajLig{ポンド}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍃" withString:@"\\ajLig{マイクロ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍄" withString:@"\\ajLig{マイル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍅" withString:@"\\ajLig{マッハ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍆" withString:@"\\ajLig{マルク}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍈" withString:@"\\ajLig{ミクロン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍋" withString:@"\\ajLig{メガ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍌" withString:@"\\ajLig{メガトン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍏" withString:@"\\ajLig{ヤール}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍐" withString:@"\\ajLig{ユアン}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍒" withString:@"\\ajLig{リラ}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍔" withString:@"\\ajLig{ルーブル}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍓" withString:@"\\ajLig{ルピー}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍕" withString:@"\\ajLig{レム}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍖" withString:@"\\ajLig{レントゲン}" addingPercentForEndOfLine:YES];
    
    [str replaceAllOccurrencesOfString:@"㊤" withString:@"\\ajLig{○上}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊥" withString:@"\\ajLig{○中}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊦" withString:@"\\ajLig{○下}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊧" withString:@"\\ajLig{○左}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊨" withString:@"\\ajLig{○右}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"〶" withString:@"\\ajLig{○〒}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊰" withString:@"\\ajLig{○夜}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊭" withString:@"\\ajLig{○企}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊩" withString:@"\\ajLig{○医}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊯" withString:@"\\ajLig{○協}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊔" withString:@"\\ajLig{○名}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊪" withString:@"\\ajLig{○宗}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊘" withString:@"\\ajLig{○労}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊫" withString:@"\\ajLig{○学}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊒" withString:@"\\ajLig{○有}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊑" withString:@"\\ajLig{○株}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊓" withString:@"\\ajLig{○社}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊬" withString:@"\\ajLig{○監}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊮" withString:@"\\ajLig{○資}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊖" withString:@"\\ajLig{○財}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊞" withString:@"\\ajLig{○印}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊙" withString:@"\\ajLig{○秘}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊝" withString:@"\\ajLig{○優}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊟" withString:@"\\ajLig{○注}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊠" withString:@"\\ajLig{○項}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊡" withString:@"\\ajLig{○休}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊛" withString:@"\\ajLig{○女}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊚" withString:@"\\ajLig{○男}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊣" withString:@"\\ajLig{○正}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊢" withString:@"\\ajLig{○写}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊗" withString:@"\\ajLig{○祝}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊜" withString:@"\\ajLig{○適}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㊕" withString:@"\\ajLig{○特}" addingPercentForEndOfLine:YES];

    [str replaceAllOccurrencesOfString:@"㈱" withString:@"\\ajLig{(株)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈲" withString:@"\\ajLig{(有)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈹" withString:@"\\ajLig{(代)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㉃" withString:@"\\ajLig{(至)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈽" withString:@"\\ajLig{(企)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈿" withString:@"\\ajLig{(協)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈴" withString:@"\\ajLig{(名)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈸" withString:@"\\ajLig{(労)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈳" withString:@"\\ajLig{(社)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈼" withString:@"\\ajLig{(監)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㉂" withString:@"\\ajLig{(自)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈾" withString:@"\\ajLig{(資)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈶" withString:@"\\ajLig{(財)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈵" withString:@"\\ajLig{(特)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈻" withString:@"\\ajLig{(学)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㉀" withString:@"\\ajLig{(祭)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈺" withString:@"\\ajLig{(呼)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㈷" withString:@"\\ajLig{(祝)}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㉁" withString:@"\\ajLig{(休)}" addingPercentForEndOfLine:YES];
    
    [str replaceAllOccurrencesOfString:@"ゔ" withString:@"\\ajLig{う゛}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ヷ" withString:@"\\ajLig{ワ゛}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ヸ" withString:@"\\ajLig{ヰ゛}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ヹ" withString:@"\\ajLig{ヱ゛}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ヺ" withString:@"\\ajLig{ヲ゛}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ゕ" withString:@"\\ajLig{小か}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ゖ" withString:@"\\ajLig{小け}" addingPercentForEndOfLine:YES];

    [str replaceAllOccurrencesOfString:@"㎜" withString:@"\\ajLig{mm}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎝" withString:@"\\ajLig{cm}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎞" withString:@"\\ajLig{km}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎎" withString:@"\\ajLig{mg}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎏" withString:@"\\ajLig{kg}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏄" withString:@"\\ajLig{cc}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎡" withString:@"\\ajLig{m2}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"№" withString:@"\\ajLig{No.}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏍" withString:@"\\ajLig{K.K.}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎠" withString:@"\\ajLig{cm2}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎢" withString:@"\\ajLig{km2}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎤" withString:@"\\ajLig{cm3}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎥" withString:@"\\ajLig{m3}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎗" withString:@"\\ajLig{dl}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"ℓ" withString:@"\\ajLig{l}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎘" withString:@"\\ajLig{kl}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎳" withString:@"\\ajLig{ms}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎲" withString:@"\\ajLig{micros}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎱" withString:@"\\ajLig{ns}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎰" withString:@"\\ajLig{ps}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎅" withString:@"\\ajLig{KB}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎆" withString:@"\\ajLig{MB}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎇" withString:@"\\ajLig{GB}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏋" withString:@"\\ajLig{HP}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎐" withString:@"\\ajLig{Hz}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎖" withString:@"\\ajLig{ml}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"℡" withString:@"\\ajLig{Tel}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏌" withString:@"\\ajLig{in}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎟" withString:@"\\ajLig{mm2}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎣" withString:@"\\ajLig{mm3}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎦" withString:@"\\ajLig{km3}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎈" withString:@"\\ajLig{cal}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎉" withString:@"\\ajLig{kcal}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏈" withString:@"\\ajLig{dB}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"℉" withString:@"\\ajLig{F}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏂" withString:@"\\ajLig{a.m.}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏘" withString:@"\\ajLig{p.m.}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㍱" withString:@"\\ajLig{hPa}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎍" withString:@"\\ajLig{microg}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㎛" withString:@"\\ajLig{microm}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"㏗" withString:@"\\ajLig{pH}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"〄" withString:@"\\ajLig{JIS}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"℧" withString:@"\\ajLig{mho}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"€" withString:@"\\ajLig{euro}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"‼" withString:@"\\ajLig{!!}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"⁇" withString:@"\\ajLig{??}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"⁈" withString:@"\\ajLig{?!}" addingPercentForEndOfLine:YES];
    [str replaceAllOccurrencesOfString:@"⁉" withString:@"\\ajLig{!?}" addingPercentForEndOfLine:YES];
    
    [str replaceAllOccurrencesOfString:@"〼" withString:@"\\ajMasu " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"ゟ" withString:@"\\ajYori " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"ヿ" withString:@"\\ajKoto " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"〽" withString:@"\\ajUta " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"⌘" withString:@"\\ajCommandKey " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"⏎" withString:@"\\ajReturnKey " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"✓" withString:@"\\ajCheckmark " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"␣" withString:@"\\ajVisibleSpace " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☗" withString:@"\\ajSenteMark " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☖" withString:@"\\ajGoteMark " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♣" withString:@"\\ajClub " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♡" withString:@"\\ajHeart " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♠" withString:@"\\ajSpade " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♢" withString:@"\\ajDiamond " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♧" withString:@"\\ajvarClub " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♥" withString:@"\\ajvarHeart " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♤" withString:@"\\ajvarSpade " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♦" withString:@"\\ajvarDiamond " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☎" withString:@"\\ajPhone " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"〠" withString:@"\\ajPostal " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"〶" withString:@"\\ajvarPostal " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☀" withString:@"\\ajSun " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☁" withString:@"\\ajCloud " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☂" withString:@"\\ajUmbrella " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"☃" withString:@"\\ajSnowman " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"〄" withString:@"\\ajJIS " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"♨" withString:@"\\ajHotSpring " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"﹆" withString:@"\\ajWhiteSesame " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"﹅" withString:@"\\ajBlackSesame " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"❀" withString:@"\\ajWhiteFlorette " addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"✿" withString:@"\\ajBlackFlorette " addingPercentForEndOfLine:NO];
    
    return str;
}

// \ajLig{株式会社} → ㍿
-(NSString*)stringByReplacingAjLigWithLig
{
    NSMutableString *str = [NSMutableString stringWithString:self];

    [str replaceAllOccurrencesOfString:@"\\ajLig{明治}" withString:@"㍾" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{大正}" withString:@"㍽" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{昭和}" withString:@"㍼" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{平成}" withString:@"㍻" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ミリ}" withString:@"㍉" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{キロ}" withString:@"㌔" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{センチ}" withString:@"㌢" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{メートル}" withString:@"㍍" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{グラム}" withString:@"㌘" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{}" withString:@"トン" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{アール}" withString:@"㌃" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヘクタール}" withString:@"㌶" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{リットル}" withString:@"㍑" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ワット}" withString:@"㍗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{カロリー}" withString:@"㌍" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ドル}" withString:@"㌦" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{セント}" withString:@"㌣" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{パーセント}" withString:@"㌫" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ミリバール}" withString:@"㍊" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ページ}" withString:@"㌻" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{キロメートル}" withString:@"㌖" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{キログラム}" withString:@"㌕" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{アール}" withString:@"㌃" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ワット}" withString:@"㍗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ホーン}" withString:@"㍂" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヘルツ}" withString:@"㌹" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ページ}" withString:@"㌻" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{アパート}" withString:@"㌀" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ビル}" withString:@"㌱" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{マンション}" withString:@"㍇" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{コーポ}" withString:@"㌞" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ハイツ}" withString:@"㌪" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{株式会社}" withString:@"㍿" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{インチ}" withString:@"㌅" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{フィート}" withString:@"㌳" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヤード}" withString:@"㍎" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヘルツ}" withString:@"㌹" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ホーン}" withString:@"㍂" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{コーポ}" withString:@"㌞" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ハイツ}" withString:@"㌪" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{アルファ}" withString:@"㌁" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{アンペア}" withString:@"㌂" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{イニング}" withString:@"㌄" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ウォン}" withString:@"㌆" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{エーカー}" withString:@"㌈" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{エスクード}" withString:@"㌇" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{オーム}" withString:@"㌊" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{オンス}" withString:@"㌉" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{カラット}" withString:@"㌌" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ガロン}" withString:@"㌎" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ガンマ}" withString:@"㌏" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ギガ}" withString:@"㌐" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ギニー}" withString:@"㌑" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{キュリー}" withString:@"㌒" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ギルダー}" withString:@"㌓" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{キロワット}" withString:@"㌗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{グラムトン}" withString:@"㌙" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{クルゼイロ}" withString:@"㌚" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{クローネ}" withString:@"㌛" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ケース}" withString:@"㌜" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{コルナ}" withString:@"㌝" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{サイクル}" withString:@"㌟" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{サンチーム}" withString:@"㌠" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{シリング}" withString:@"㌡" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ダース}" withString:@"㌤" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{デシ}" withString:@"㌥" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ナノ}" withString:@"㌨" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ノット}" withString:@"㌩" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{バーレル}" withString:@"㌭" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ピアストル}" withString:@"㌮" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ピクル}" withString:@"㌯" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ピコ}" withString:@"㌰" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ファラッド}" withString:@"㌲" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ブッシェル}" withString:@"㌴" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{フラン}" withString:@"㌵" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ベータ}" withString:@"㌼" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ペソ}" withString:@"㌷" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ペニヒ}" withString:@"㌸" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ペンス}" withString:@"㌺" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ポイント}" withString:@"㌽" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ホール}" withString:@"㍁" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ボルト}" withString:@"㌾" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ホン}" withString:@"㌿" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ポンド}" withString:@"㍀" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{マイクロ}" withString:@"㍃" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{マイル}" withString:@"㍄" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{マッハ}" withString:@"㍅" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{マルク}" withString:@"㍆" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ミクロン}" withString:@"㍈" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{メガ}" withString:@"㍋" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{メガトン}" withString:@"㍌" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヤール}" withString:@"㍏" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ユアン}" withString:@"㍐" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{リラ}" withString:@"㍒" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ルーブル}" withString:@"㍔" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ルピー}" withString:@"㍓" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{レム}" withString:@"㍕" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{レントゲン}" withString:@"㍖" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\ajLig{○上}" withString:@"㊤" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○中}" withString:@"㊥" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○下}" withString:@"㊦" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○左}" withString:@"㊧" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○右}" withString:@"㊨" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○〒}" withString:@"〶" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○夜}" withString:@"㊰" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○企}" withString:@"㊭" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○医}" withString:@"㊩" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○協}" withString:@"㊯" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○名}" withString:@"㊔" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○宗}" withString:@"㊪" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○労}" withString:@"㊘" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○学}" withString:@"㊫" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○有}" withString:@"㊒" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○株}" withString:@"㊑" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○社}" withString:@"㊓" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○監}" withString:@"㊬" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○資}" withString:@"㊮" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○財}" withString:@"㊖" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○印}" withString:@"㊞" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○秘}" withString:@"㊙" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○優}" withString:@"㊝" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○注}" withString:@"㊟" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○項}" withString:@"㊠" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○休}" withString:@"㊡" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○女}" withString:@"㊛" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○男}" withString:@"㊚" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○正}" withString:@"㊣" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○写}" withString:@"㊢" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○祝}" withString:@"㊗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○適}" withString:@"㊜" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{○特}" withString:@"㊕" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\○上" withString:@"㊤" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○中" withString:@"㊥" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○下" withString:@"㊦" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○左" withString:@"㊧" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○右" withString:@"㊨" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○〒" withString:@"〶" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○夜" withString:@"㊰" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○企" withString:@"㊭" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○医" withString:@"㊩" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○協" withString:@"㊯" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○名" withString:@"㊔" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○宗" withString:@"㊪" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○労" withString:@"㊘" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○学" withString:@"㊫" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○有" withString:@"㊒" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○株" withString:@"㊑" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○社" withString:@"㊓" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○監" withString:@"㊬" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○資" withString:@"㊮" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○財" withString:@"㊖" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○印" withString:@"㊞" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○秘" withString:@"㊙" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○優" withString:@"㊝" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○注" withString:@"㊟" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○項" withString:@"㊠" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○休" withString:@"㊡" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○女" withString:@"㊛" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○男" withString:@"㊚" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○正" withString:@"㊣" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○写" withString:@"㊢" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○祝" withString:@"㊗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○適" withString:@"㊜" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\○特" withString:@"㊕" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\ajLig{(株)}" withString:@"㈱" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(有)}" withString:@"㈲" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(代)}" withString:@"㈹" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(至)}" withString:@"㉃" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(企)}" withString:@"㈽" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(協)}" withString:@"㈿" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(名)}" withString:@"㈴" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(労)}" withString:@"㈸" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(社)}" withString:@"㈳" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(監)}" withString:@"㈼" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(自)}" withString:@"㉂" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(資)}" withString:@"㈾" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(財)}" withString:@"㈶" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(特)}" withString:@"㈵" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(学)}" withString:@"㈻" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(祭)}" withString:@"㉀" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(呼)}" withString:@"㈺" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(祝)}" withString:@"㈷" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{(休)}" withString:@"㉁" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\（株）" withString:@"㈱" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（有）" withString:@"㈲" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（代）" withString:@"㈹" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（至）" withString:@"㉃" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（企）" withString:@"㈽" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（協）" withString:@"㈿" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（名）" withString:@"㈴" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（労）" withString:@"㈸" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（社）" withString:@"㈳" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（監）" withString:@"㈼" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（自）" withString:@"㉂" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（資）" withString:@"㈾" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（財）" withString:@"㈶" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（特）" withString:@"㈵" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（学）" withString:@"㈻" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（祭）" withString:@"㉀" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（呼）" withString:@"㈺" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（祝）" withString:@"㈷" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\（休）" withString:@"㉁" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\ajLig{う゛}" withString:@"ゔ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ワ゛}" withString:@"ヷ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヰ゛}" withString:@"ヸ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヱ゛}" withString:@"ヹ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ヲ゛}" withString:@"ヺ" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\゛う" withString:@"ゔ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\゛ワ" withString:@"ヷ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\゛ヰ" withString:@"ヸ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\゛ヱ" withString:@"ヹ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\゛ヲ" withString:@"ヺ" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\ajLig{小か}" withString:@"ゕ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{小け}" withString:@"ゖ" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\！か" withString:@"ゕ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\！け" withString:@"ゖ" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfString:@"\\ajLig{mm}" withString:@"㎜" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{cm}" withString:@"㎝" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{km}" withString:@"㎞" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{mg}" withString:@"㎎" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{kg}" withString:@"㎏" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{cc}" withString:@"㏄" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{m2}" withString:@"㎡" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{No.}" withString:@"№" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{K.K.}" withString:@"㏍" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{cm2}" withString:@"㎠" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{km2}" withString:@"㎢" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{cm3}" withString:@"㎤" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{m3}" withString:@"㎥" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{dl}" withString:@"㎗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{l}" withString:@"ℓ" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{kl}" withString:@"㎘" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ms}" withString:@"㎳" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{micros}" withString:@"㎲" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ns}" withString:@"㎱" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ps}" withString:@"㎰" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{KB}" withString:@"㎅" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{MB}" withString:@"㎆" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{GB}" withString:@"㎇" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{HP}" withString:@"㏋" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{Hz}" withString:@"㎐" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{ml}" withString:@"㎖" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{Tel}" withString:@"℡" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{in}" withString:@"㏌" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{mm2}" withString:@"㎟" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{mm3}" withString:@"㎣" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{km3}" withString:@"㎦" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{cal}" withString:@"㎈" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{kcal}" withString:@"㎉" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{dB}" withString:@"㏈" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{F}" withString:@"℉" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{a.m.}" withString:@"㏂" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{p.m.}" withString:@"㏘" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{hPa}" withString:@"㍱" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{microg}" withString:@"㎍" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{microm}" withString:@"㎛" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{pH}" withString:@"㏗" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{JIS}" withString:@"〄" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{mho}" withString:@"℧" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{euro}" withString:@"€" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{!!}" withString:@"‼" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{??}" withString:@"⁇" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{?!}" withString:@"⁈" addingPercentForEndOfLine:NO];
    [str replaceAllOccurrencesOfString:@"\\ajLig{!?}" withString:@"⁉" addingPercentForEndOfLine:NO];
    
    [str replaceAllOccurrencesOfPattern:@"\\\\ajMasu\\s*" withString:@"〼"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajYori\\s*" withString:@"ゟ"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajKoto\\s*" withString:@"ヿ"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajUta\\s*" withString:@"〽"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajCommandKey\\s*" withString:@"⌘"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajReturnKey\\s*" withString:@"⏎"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajCheckmark\\s*" withString:@"✓"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajVisibleSpace\\s*" withString:@"␣"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajSenteMark\\s*" withString:@"☗"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajGoteMark\\s*" withString:@"☖"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajClub\\s*" withString:@"♣"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajHeart\\s*" withString:@"♡"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajSpade\\s*" withString:@"♠"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajDiamond\\s*" withString:@"♢"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajvarClub\\s*" withString:@"♧"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajvarHeart\\s*" withString:@"♥"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajvarSpade\\s*" withString:@"♤"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajvarDiamond\\s*" withString:@"♦"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajPhone\\s*" withString:@"☎"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajPostal\\s*" withString:@"〠"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajvarPostal\\s*" withString:@"〶"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajSun\\s*" withString:@"☀"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajCloud\\s*" withString:@"☁"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajUmbrella\\s*" withString:@"☂"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajSnowman\\s*" withString:@"☃"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajJIS\\s*" withString:@"〄"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajHotSpring\\s*" withString:@"♨"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajWhiteSesame\\s*" withString:@"﹆"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajBlackSesame\\s*" withString:@"﹅"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajWhiteFlorette\\s*" withString:@"❀"];
    [str replaceAllOccurrencesOfPattern:@"\\\\ajBlackFlorette\\s*" withString:@"✿"];

    return str;
}


@end
