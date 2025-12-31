#!/usr/bin/env python3
"""
Factorio AI Agent Runner

Runs Claude Code as a child agent with proper process management.
Ensures only ONE agent can run at a time.
"""

import os
import sys
import signal
import subprocess
import atexit
import fcntl
from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent.resolve()
LOCK_FILE = PROJECT_DIR / ".agent.lock"
PID_FILE = PROJECT_DIR / ".agent.pid"
AGENT_LOG = PROJECT_DIR / ".agent-output.jsonl"
CLAUDE_BIN = Path.home() / ".claude" / "local" / "claude"

claude_process = None

def kill_existing_agents():
    """Kill any existing Claude agents from previous runs."""
    if PID_FILE.exists():
        try:
            pid = int(PID_FILE.read_text().strip())
            # Try to kill the existing process
            try:
                os.kill(pid, signal.SIGKILL)
                print(f"Killed existing agent (PID {pid})")
            except ProcessLookupError:
                pass  # Already dead
            except PermissionError:
                print(f"Warning: Could not kill PID {pid}")
        except (ValueError, FileNotFoundError):
            pass
        finally:
            PID_FILE.unlink(missing_ok=True)

def cleanup():
    """Clean up on exit."""
    global claude_process
    if claude_process and claude_process.poll() is None:
        print(f"\nKilling Claude (PID {claude_process.pid})...")
        claude_process.terminate()
        try:
            claude_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            claude_process.kill()
    PID_FILE.unlink(missing_ok=True)

def signal_handler(signum, frame):
    """Handle termination signals."""
    cleanup()
    sys.exit(0)

def acquire_lock():
    """Acquire exclusive lock using flock."""
    lock_fd = open(LOCK_FILE, 'w')
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return lock_fd
    except BlockingIOError:
        print("ERROR: Another agent runner is already holding the lock")
        print("Kill existing agents first or wait for them to finish")
        sys.exit(1)

def main():
    global claude_process

    # Parse nudge from command line
    nudge = sys.argv[1] if len(sys.argv) > 1 else None

    # Kill any existing agents first
    kill_existing_agents()

    # Acquire exclusive lock
    lock_fd = acquire_lock()
    print("Lock acquired")

    # Set up signal handlers and cleanup
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    atexit.register(cleanup)

    print("=" * 40)
    print("  Factorio AI Agent")
    print("=" * 40)
    print()
    print("Starting Claude Code...")
    if nudge:
        print(f"Nudge: {nudge}")
    print()

    # Build command
    cmd = [
        str(CLAUDE_BIN),
        "--continue",
        "--dangerously-skip-permissions",
        "--verbose",
        "--print",
        "--output-format", "stream-json",
        "--add-dir", str(PROJECT_DIR),
    ]

    if nudge:
        cmd.extend(["--append-system-prompt", f"URGENT HINT: {nudge}"])

    # Start Claude as subprocess
    workdir = PROJECT_DIR / "agent-workspace"
    prompt = f"You are a Factorio AI agent playing Factorio. Run commands from {PROJECT_DIR} directory."

    with open(AGENT_LOG, 'a') as log_file:
        claude_process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            cwd=workdir,
            text=True,
            bufsize=1
        )

        # Write the CLAUDE PID (not ours) to the PID file
        PID_FILE.write_text(str(claude_process.pid))
        print(f"Claude started (PID {claude_process.pid})")

        # Send initial prompt
        claude_process.stdin.write(prompt + "\n")
        claude_process.stdin.flush()

        # Stream output
        try:
            for line in claude_process.stdout:
                print(line, end='')
                log_file.write(line)
                log_file.flush()
        except KeyboardInterrupt:
            pass

        claude_process.wait()
        print(f"\nClaude exited with code {claude_process.returncode}")

    # Release lock
    fcntl.flock(lock_fd, fcntl.LOCK_UN)
    lock_fd.close()

if __name__ == "__main__":
    main()
