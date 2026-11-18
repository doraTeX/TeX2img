"""Copies actions of the product's ControllerG into the stand-in ControllerG of an editor test, so that the test runs
the real code of the action (ControllerG.swift needs the whole app and is not compiled into the tests)."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MARKER = "    // @@CONTROLLER ACTIONS@@\n"


def method(source, start):
    i = source.index(start)
    return source[i:source.index("\n    }\n", i) + 6] + "\n"


def insert(fixture, starts):
    """Replaces the marker line of the fixture with the product's methods that begin with the given text."""
    with open(os.path.join(ROOT, "Sources/Controllers/ControllerG.swift"), encoding="utf-8") as f:
        source = f.read()
    assert fixture.count(MARKER) == 1, "the stand-in ControllerG has no marker for the actions"
    return fixture.replace(MARKER, "".join(method(source, start) for start in starts))
