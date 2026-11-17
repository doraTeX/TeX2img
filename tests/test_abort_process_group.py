#!/usr/bin/env python3
"""Runs the real abortCompilation(_:) of the GUI (ControllerG) on a stub, against a command shaped like a TeX run:
a shell that runs a program which runs another program. Abort must stop all of them, not only the shell.
No window is opened.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def extract_method(source, marker):
    text = source.read_text()
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]


method = extract_method(ROOT / 'Sources/Controllers/ControllerG.swift', '@IBAction func abortCompilation(')
MAIN = r'''
import AppKit

final class Stub: NSObject {
    let taskStateLock = NSLock()
    var taskKilled = false
    var runningTask: Process?
    __METHOD__
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

@main struct Main {
    static func main() {
        let marker = "/bin/sleep 4\(getpid() % 1000 + 1000)"
        let stub = Stub()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        // As Converter runs TeX: exports, then the program, whose own child does the work.
        task.arguments = ["-c", "export TEX2IMG_TEST=1; /bin/sh -c '\(marker); true' 2>&1"]
        try! task.run()
        stub.runningTask = task
        for _ in 0..<50 where !running(marker) { usleep(100_000) }
        precondition(running(marker), "the command did not start")
        stub.abortCompilation(NSNull())
        task.waitUntilExit()
        var stopped = false
        for _ in 0..<30 { if !running(marker) { stopped = true; break }; usleep(100_000) }
        if !stopped {
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            kill.arguments = ["-f", marker]
            try? kill.run()
            kill.waitUntilExit()
            print("FAIL: after Abort, the program that the shell ran is still running")
            exit(1)
        }
        precondition(stub.taskKilled && stub.runningTask == nil)
        print("PASS: Abort stops the shell and the programs it started")
    }
}
'''.replace('__METHOD__', method)

with tempfile.TemporaryDirectory(prefix='tex2img-abort-') as tmp:
    work = Path(tmp)
    (work / 'main.swift').write_text(MAIN)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(work / 'main.swift'), str(ROOT / 'Sources/Utility/Utility.swift'),
                    str(ROOT / 'Sources/Extensions/Foundation/Pipe-Extension.swift'),
                    '-o', str(work / 'abort')], check=True)
    sys.exit(subprocess.run([str(work / 'abort')], timeout=60).returncode)
