#!/usr/bin/env python3
"""Runs the real ControllerG.execCommand with the real Abort (abortCompilation, takeRunningCommand,
exitCurrentThreadIfTaskKilled, stopTracking) on a stub, and aborts while the command is being prepared: when the command
line is written to the output, and when the profile is read for the output's encoding (F1 of the 2nd audit of the
TeXShop port). An Abort before the launch must keep the command from running; without an Abort, it runs.
The command only creates a file in the test's own folder. No window is shown.
"""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def extract_method(source, marker):
    text = source.read_text()
    if marker not in text:
        return ''  # beginTracking: only in the code before the fix
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end].replace('private func ', 'func ')


controller = ROOT / 'Sources/Controllers/ControllerG.swift'
methods = '\n'.join(extract_method(controller, marker) for marker in (
    'func execCommand(_ command: String,', 'private func stopTracking(', 'func exitCurrentThreadIfTaskKilled(',
    'private func takeRunningCommand(', '@IBAction func abortCompilation(', 'private func beginTracking('))

MAIN = r'''
import AppKit

final class Probe: NSObject {
    let taskStateLock = NSLock()
    var taskKilled = false
    var generationAborted = false
    var runningTask: Process?
    var runningGroup: pid_t = 0
    var stoppingCommands: [(task: Process, group: pid_t)] = []
    var outputPipe: Pipe?
    static let commandEnvironment = ProcessInfo.processInfo.environment
    /// Where to abort: "output" (the command line is written), "profile" (the encoding is read), or "" (never).
    var abortAt = ""
    var finished: [ExitStatus] = []
    func appendOutputAndScroll(_ text: String, quiet: Bool) {
        if abortAt == "output" && text.hasPrefix("$ ") { abortCompilation(NSNull()) }
    }
    func currentProfile() -> Profile {
        if abortAt == "profile" { abortCompilation(NSNull()) }
        return [:]
    }
    func performOnMainThread(waitUntilDone: Bool = true, _ work: @escaping () -> Void) { work() }
    func flushPendingOutputOnMainThread() {}
    func generationDidFinish(_ status: ExitStatus) { finished.append(status) }
    __METHODS__
}

@main struct Main {
    static func main() {
        let folder = CommandLine.arguments[1]
        var failures = 0
        for abortAt in ["", "output", "profile"] {
            let marker = folder + "/ran-" + (abortAt.isEmpty ? "none" : abortAt)
            let probe = Probe()
            probe.abortAt = abortAt
            let result = probe.execCommand("/usr/bin/touch", atDirectory: folder, withArguments: ["'\(marker)'"], quiet: false)
            usleep(300_000)
            let ran = FileManager.default.fileExists(atPath: marker)
            if abortAt.isEmpty {
                if !(ran && result) { print("FAIL: without Abort the command ran: \(ran), result \(result)"); failures += 1 }
            } else {
                if ran || result { print("FAIL: Abort at the \(abortAt): the command ran: \(ran), result \(result)"); failures += 1 }
                if probe.finished != [.aborted] { print("FAIL: Abort at the \(abortAt): finished \(probe.finished)"); failures += 1 }
            }
            print("\(abortAt.isEmpty ? "no Abort" : "Abort at the " + abortAt): ran \(ran), result \(result), finished \(probe.finished)")
        }
        exit(failures == 0 ? 0 : 1)
    }
}
'''.replace('__METHODS__', methods)

with tempfile.TemporaryDirectory(prefix='tex2img-launch-race-') as tmp:
    work = Path(tmp).resolve()
    (work / 'main.swift').write_text(MAIN)
    sources = ['Sources/Utility/Utility.swift', 'Sources/Utility/ConsoleOutputDecoder.swift', 'Sources/Core/Types.swift',
               'Sources/Extensions/Foundation/NSDictionary-Extension.swift', 'Sources/Extensions/Foundation/Pipe-Extension.swift',
               'Sources/Extensions/AppKit/NSColor-Extension.swift']
    # Only the keys and encodings of GlobalConstants.swift; the rest needs the whole app.
    constants = work / 'constants.swift'
    with open(ROOT / 'Sources/Core/GlobalConstants.swift') as source:
        constants.write_text('import Foundation\n' + ''.join(line for line in source
            if re.match(r'(let \w+Key = "[^"]*"|typealias Profile|let PTEX_ENCODING_\w+ = )', line)))
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-name', 'LaunchRace', str(work / 'main.swift'), str(constants),
                    *[str(ROOT / s) for s in sources], '-o', str(work / 'race')], check=True)
    output = work / 'out'
    output.mkdir()
    result = subprocess.run([str(work / 'race'), str(output)], capture_output=True, text=True, timeout=60)
    print(result.stdout + result.stderr, end='')
    sys.exit(0 if result.returncode == 0 else 1)
