"""Helpers for the tests that compile a tool from TeX2img's sources and run it.

The standard user defaults of a command-line tool are named after its executable, and CFFIXED_USER_HOME does not move
them. Each tool gets a name of its own for each run, and the test checks that the tool never made that domain: the code
under test is given in-memory defaults (tests/MemoryDefaults.swift), and no test removes or changes any domain.
"""
import subprocess
import uuid


def unique_tool_name(base):
    """A name for the tool of this run; its user defaults domain must not exist yet."""
    name = f"tex2img-test-{base}-{uuid.uuid4().hex}"
    if domain_exists(name):
        raise SystemExit(f"the user defaults domain {name} exists already; the test does not use or change it")
    return name


def domain_exists(name):
    """Whether a user defaults domain exists (`defaults read` only reads)."""
    return subprocess.run(["defaults", "read", name], capture_output=True).returncode == 0


def check_untouched(name):
    """0 if the tool left no user defaults domain, 1 (with a message) if it wrote one; the domain is not removed."""
    if domain_exists(name):
        print(f"FAIL: the tool wrote to the standard user defaults (domain {name}); it is left for inspection")
        return 1
    return 0
