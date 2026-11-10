import Foundation

// Checks ConsoleOutputDecoder (TeXShop's line-by-line console reading). Run through tests/test_console_output.py.

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

func pieces(_ chunks: [[UInt8]], encoding: String.Encoding) -> String {
    let decoder = ConsoleOutputDecoder(encoding: encoding)
    return chunks.map { decoder.append(Data($0)) }.joined() + decoder.finish()
}

let utf8 = Array("日本語のログ\n".utf8)
// A character divided by the pipe is kept for the next piece, at every position.
for cut in 1..<utf8.count {
    check(pieces([Array(utf8[..<cut]), Array(utf8[cut...])], encoding: .utf8) == "日本語のログ\n", "UTF-8 divided at byte \(cut)")
}
// TeX breaks a long line inside a character: the break moves to before the character.
let broken: [UInt8] = Array("abc".utf8) + [0xE3, 0x81] + [0x0A] + [0x82] + Array("def\n".utf8)
check(ConsoleOutputDecoder.displayString(Data(broken), encoding: .utf8) == "abc\nあdef\n", "line break inside a character")
for cut in 1..<broken.count {
    check(pieces([Array(broken[..<cut]), Array(broken[cut...])], encoding: .utf8) == "abc\nあdef\n", "broken character divided at \(cut)")
}
// Shift JIS output, with a UTF-8 file name on another line.
let sjis = ConsoleOutputDecoder.encoding(forKanji: PTEX_ENCODING_SJIS)
let japanese = Array("! 未定義のコマンド\n".data(using: sjis)!) + Array("(./ファイル.tex)\n".utf8)
check(ConsoleOutputDecoder.displayString(Data(japanese), encoding: sjis) == "! 未定義のコマンド\n(./ファイル.tex)\n", "Shift JIS and UTF-8 lines")
for cut in 1..<japanese.count {
    check(pieces([Array(japanese[..<cut]), Array(japanese[cut...])], encoding: sjis) == "! 未定義のコマンド\n(./ファイル.tex)\n", "Shift JIS divided at \(cut)")
}
// Bytes that are not UTF-8 spoil only their own line.
// A line mostly in UTF-8 shows U+FFFD for the bad byte; a line without UTF-8 characters is read in Latin 9.
let mixed = Array("ok\n".utf8) + Array("日".utf8) + [0xFF] + Array("本\n".utf8) + [0x61, 0xFF, 0x62, 0x0A] + Array("日本\n".utf8)
check(ConsoleOutputDecoder.displayString(Data(mixed), encoding: .utf8) == "ok\n日\u{FFFD}本\naÿb\n日本\n", "invalid bytes stay on their line")
// When output pauses, an unfinished Shift JIS line is shown; an unfinished character waits.
let decoder = ConsoleOutputDecoder(encoding: sjis)
check(decoder.append(Data("? 入力待ち".data(using: sjis)!)).isEmpty, "an unfinished line waits for the rest")
check(decoder.flushPause() == "? 入力待ち", "the line is shown after a pause")
let partial = ConsoleOutputDecoder(encoding: .utf8)
check(partial.append(Data([0x61, 0xE3, 0x81])) == "a" && partial.flushPause().isEmpty && partial.append(Data([0x82])) == "あ",
      "a divided character waits across a pause")
// Latin 9 is the last resort.
check(ConsoleOutputDecoder.displayString(Data([0xA4, 0x0A]), encoding: .utf8) == "€\n", "Latin 9")

// ConsolePipeReader: the output of a running command is shown as it comes, in order, and a process that keeps
// the pipe open does not stop the reading.
final class Collected: @unchecked Sendable {
    private let lock = NSLock()
    private var text = ""
    private var firstTime: Date?
    func add(_ piece: String) {
        lock.lock(); defer { lock.unlock() }
        if firstTime == nil { firstTime = Date() }
        text += piece
    }
    var value: (String, Date?) { lock.lock(); defer { lock.unlock() }; return (text, firstTime) }
}
func run(_ script: String, timeout: TimeInterval = 2) -> (output: String, first: TimeInterval?, total: TimeInterval) {
    let task = Process()
    let pipe = Pipe()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", script]
    task.standardOutput = pipe
    task.standardError = pipe
    let collected = Collected()
    let reader = ConsolePipeReader(handle: pipe.fileHandleForReading, decoder: ConsoleOutputDecoder(encoding: .utf8),
                                   showsPausedLine: true) { collected.add($0) }
    let start = Date()
    try! task.run()
    task.waitUntilExit()
    reader.finish(timeout: timeout)
    let (text, first) = collected.value
    return (text, first.map { $0.timeIntervalSince(start) }, Date().timeIntervalSince(start))
}
let slow = run("echo first; sleep 1; echo second")
check(slow.output == "first\nsecond\n", "slow output: \(slow.output)")
check((slow.first ?? 9) < 0.7, "the first line is shown before the command ends (after \(slow.first ?? -1) s)")
let many = run("i=1; while [ $i -le 20000 ]; do echo \"line $i 日本語\"; i=$((i+1)); done")
check(many.output == (1...20000).map { "line \($0) 日本語\n" }.joined(), "20000 lines arrive whole and in order")
let lingering = run("echo kept; (sleep 6 >/dev/null &) ; sleep 6 &", timeout: 0.5)
check(lingering.output == "kept\n", "output before a lingering process: \(lingering.output)")
check(lingering.total < 3, "a process that keeps the pipe open does not hold the reader (\(lingering.total) s)")
print("Console output regression tests passed")
