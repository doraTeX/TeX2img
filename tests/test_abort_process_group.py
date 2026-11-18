#!/usr/bin/env python3
"""Runs the real abortCompilation(_:) and the quit handler (applicationWillTerminate) of the GUI (ControllerG) on a
stub, against commands shaped like a TeX run: a shell that runs a program which runs another program.

- Abort stops all of them, not only the shell (K5 of the 2026-11-17 audit; Process.terminate() reaches the group).
- Abort also stops programs that ignore SIGTERM (TeXShop 1c7c4a81: SIGTERM to the group, then SIGKILL).
- Quitting during a generation stops its commands in the same way, within a second (decision D3 of 11-18), also when
  Abort has just begun to stop them (F1 of the 1st audit of the port).
No window is opened; the settings are not saved (the stub records the call). The commands run a waiting program that
the test compiles under a name of its own, in its own folder: only its processes are looked for and stopped.
"""
from pathlib import Path
import subprocess
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]


def extract_method(source, marker):
    text = source.read_text()
    if marker not in text:
        return ''
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]


controller = ROOT / 'Sources/Controllers/ControllerG.swift'
methods = '\n'.join(extract_method(controller, marker) for marker in
                    ('@IBAction func abortCompilation(', 'private func takeRunningCommand(', 'private func applicationWillTerminate('))
MAIN = r'''
import AppKit

let autoSavedProfileName = "*AutoSavedProfile*"
final class StubProfiles {
    var saved = false
    func updateProfile(_ profile: [String: Any], forName name: String) {}
    func saveProfiles() { saved = true }
}

final class Stub: NSObject {
    let taskStateLock = NSLock()
    var taskKilled = false
    var runningTask: Process?
    var runningGroup: pid_t = 0
    var generationThreadRunning = false
    var stoppingCommands: [(task: Process, group: pid_t)] = []
    let profileController = StubProfiles()
    func closeColorPanel() {}
    func closeFontPanel() {}
    func currentProfile() -> [String: Any] { [:] }
    __METHODS__
}

func running(_ pattern: String) -> Bool {
    let pgrep = Process()
    pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    pgrep.arguments = ["-f", pattern]
    pgrep.standardOutput = FileHandle.nullDevice
    try! pgrep.run()
    pgrep.waitUntilExit()
    return pgrep.terminationStatus == 0
}

func kill(_ pattern: String) {
    let pkill = Process()
    pkill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
    pkill.arguments = ["-9", "-f", pattern]
    try? pkill.run()
    pkill.waitUntilExit()
}

let waiter = CommandLine.arguments[1]
var caseNumber = 0

/// Starts the command as ControllerG.execCommand does (the group is recorded after launch) and stops it.
/// With quits, the commands must be gone when the handler returns: the app ends right after it, and a stop that is
/// still going on in the background ends with it.
func check(_ name: String, ignoresTERM: Bool, quits: Bool = false, stop: (Stub) -> Void) -> Bool {
    caseNumber += 1
    let marker = "\(waiter) 30\(caseNumber)"
    let stub = Stub()
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    // As Converter runs TeX: exports, then the program, whose own child does the work. With ignoresTERM, the
    // program and its child ignore SIGTERM (as a program run by shell escape may).
    let inner = ignoresTERM ? "trap '' TERM; \(marker); true" : "\(marker); true"
    task.arguments = ["-c", "export TEX2IMG_TEST=1; /bin/sh -c \"\(inner)\" 2>&1"]
    try! task.run()
    stub.runningTask = task
    stub.runningGroup = getpgid(task.processIdentifier) == task.processIdentifier ? task.processIdentifier : 0
    stub.generationThreadRunning = true
    for _ in 0..<50 where !running(marker) { usleep(100_000) }
    guard running(marker) else { print("FAIL \(name): the command did not start"); kill(marker); return false }
    let start = Date()
    stop(stub)
    let returned = Date().timeIntervalSince(start)
    var stopped = false
    for _ in 0..<(quits ? 2 : 20) { if !running(marker) { stopped = true; break }; usleep(100_000) }
    if !stopped {
        kill(marker)
        print("FAIL \(name): \(quits ? "when the quit handler returned" : "after 2 s"), the program that the shell ran is still running")
        return false
    }
    guard stub.taskKilled && stub.runningTask == nil else { print("FAIL \(name): the command was not taken"); return false }
    if returned > 1.5 { print("FAIL \(name): took \(returned) s"); return false }
    print("PASS \(name) (returned after \(String(format: "%.2f", returned)) s)")
    return true
}

@main struct Main {
    static func main() {
        var ok = true
        ok = check("Abort stops the shell and the programs it started", ignoresTERM: false) { $0.abortCompilation(NSNull()) } && ok
        ok = check("Abort stops programs that ignore SIGTERM", ignoresTERM: true) { $0.abortCompilation(NSNull()) } && ok
        ok = check("Quitting during a generation stops its commands", ignoresTERM: true, quits: true) { stub in
            stub.applicationWillTerminate()
            if !stub.profileController.saved { print("FAIL: the settings were not saved at quit") }
        } && ok
        ok = check("Quitting just after Abort finishes stopping the commands", ignoresTERM: true, quits: true) { stub in
            stub.abortCompilation(NSNull())
            usleep(50_000)
            stub.generationThreadRunning = true
            stub.applicationWillTerminate()
        } && ok
        exit(ok ? 0 : 1)
    }
}
'''.replace('__METHODS__', methods.replace('private func ', 'func '))

with tempfile.TemporaryDirectory(prefix='tex2img-abort-') as tmp:
    work = Path(tmp)
    (work / 'main.swift').write_text(MAIN)
    waiter = work / f'tex2img-test-waiter-{uuid.uuid4().hex}'
    (work / 'waiter.c').write_text('#include <stdlib.h>\n#include <unistd.h>\nint main(int c, char **v) { sleep(c > 1 ? atoi(v[1]) : 300); return 0; }\n')
    subprocess.run(['xcrun', 'clang', str(work / 'waiter.c'), '-o', str(waiter)], check=True)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(work / 'main.swift'), str(ROOT / 'Sources/Utility/Utility.swift'),
                    str(ROOT / 'Sources/Extensions/Foundation/Pipe-Extension.swift'),
                    '-o', str(work / 'abort')], check=True)
    sys.exit(subprocess.run([str(work / 'abort'), str(waiter)], timeout=120).returncode)
