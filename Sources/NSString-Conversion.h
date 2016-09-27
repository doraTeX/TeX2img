#import <Foundation/Foundation.h>

@interface NSString (Conversion)
// あ ⇄ ア
-(NSString*)stringByReplacingHiraganaWithKatakana;
-(NSString*)stringByReplacingKatakanaWithHiragana;

// １ ⇄ 1
-(NSString*)stringByReplacingHankakuSujiWithZenkakuSuji;
-(NSString*)stringByReplacingZenkakuSujiWithHankakuSuji;

// Ａ ⇄ A, ａ ⇄ a
-(NSString*)stringByReplacingHankakuAlphWithZenkakuAlph;
-(NSString*)stringByReplacingZenkakuAlphWithHankakuAlph;

// Unicode文字 ⇄ ajmacros
-(NSString*)stringByReplacingUnicodeCharactersWithAjMacros;
-(NSString*)stringByReplacingAjMacrosWithUnicodeCharacters;

// ① ⇄ \ajMaru // 0..50
-(NSString*)stringByReplacingMaruSujiWithAjMaru;
-(NSString*)stringByReplacingAjMaruWithMaruSuji;

// ❶ ⇄ \ajKuroMaru // 0..20
-(NSString*)stringByReplacingKuroMaruSujiWithAjKuroMaru;
-(NSString*)stringByReplacingAjKuroMaruWithKuroMaruSuji;

// ⑴ ⇄ \ajKakko // 1..20
-(NSString*)stringByReplacingKakkoSujiWithAjKakko;
-(NSString*)stringByReplacingAjKakkoWithMakkoSuji;

// Ⓐ ⇄ \ajMaruAlph, ⓐ ⇄ \ajMarualph // 1..26
-(NSString*)stringByReplacingMaruAlphWithAjMaruAlph;
-(NSString*)stringByReplacingAjMaruAlphWithMaruAlph;

// 🄐 ⇄ \ajKakkoAlph, ⒜ ⇄ \ajKakkoalph // 1..26
-(NSString*)stringByReplacingKakkoAlphWithAjKakkoAlph;
-(NSString*)stringByReplacingAjKakkoAlphWithKakkoAlph;

// 🅐 ⇄ \ajKuroMaruAlph // 1..26
-(NSString*)stringByReplacingKuroMaruAlphWithAjKuroMaruAlph;
-(NSString*)stringByReplacingAjKuroMaruAlphWithKuroMaruAlph;

// 🄰 ⇄ \ajKakuAlph // 1..26
-(NSString*)stringByReplacingKakuAlphWithAjKakuAlph;
-(NSString*)stringByReplacingAjKakuAlphWithKakuAlph;

// 🅰 ⇄ \ajKuroKakuAlph // 1..26
-(NSString*)stringByReplacingKuroKakuAlphWithAjKuroKakuAlph;
-(NSString*)stringByReplacingAjKuroKakuAlphWithKuroKakuAlph;

// Ⅰ ⇄ \ajRoman, ⅰ ⇄ \ajroman // 1..12
-(NSString*)stringByReplacingRomanWithAjRoman;
-(NSString*)stringByReplacingAjRomanWithRoman;

// ⒈ ⇄ \ajPeriod // 1..9
-(NSString*)stringByReplacingPeriodWithAjPeriod;
-(NSString*)stringByReplacingAjPeriodWithPeriod;

// ㈪ ⇄ \ajKakkoYobi // 1..9
-(NSString*)stringByReplacingKakkoYobiWithAjKakkoYobi;
-(NSString*)stringByReplacingAjKakkoYobiWithKakkoYobi;

// ㊊ ⇄ \ajMaruYobi // 1..9
-(NSString*)stringByReplacingMaruYobiWithAjMaruYobi;
-(NSString*)stringByReplacingAjMaruYobiWithMaruYobi;

// ⓵ ⇄ \ajNijuMaru // 1..10
-(NSString*)stringByReplacingNijuMaruWithAjNijuMaru;
-(NSString*)stringByReplacingAjNijuMaruWithNijuMaru;

// ♳ ⇄ \ajRecycle // 0..11
-(NSString*)stringByReplacingRecycleWithAjRecycle;
-(NSString*)stringByReplacingAjRecycleWithRecycle;

// ㋐ ⇄ \ajMaruKata // 1..47 (48の「ン」は Unicode にない）
-(NSString*)stringByReplacingMaruKataWithAjMaruKata;
-(NSString*)stringByReplacingAjMaruKataWithMaruKata;

// ㈠ ⇄ \ajKakkoKansuji // 1..10
-(NSString*)stringByReplacingKakkoKansujiWithAjKakkoKansuji;
-(NSString*)stringByReplacingAjKakkoKansujiWithKakkoKansuji;

// ㊀ ⇄ \ajMaruKansuji // 1..10
-(NSString*)stringByReplacingMaruKansujiWithAjMaruKansuji;
-(NSString*)stringByReplacingAjMaruKansujiWithMaruKansuji;

// ㍿ ⇄ \ajLig{株式会社}
-(NSString*)stringByReplacingLigWithAjLig;
-(NSString*)stringByReplacingAjLigWithLig;

@end

