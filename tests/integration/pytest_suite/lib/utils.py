from __future__ import annotations

import subprocess
from typing import Iterable, Mapping, Sequence


def run_command(
    command: Sequence[str],
    *,
    env: Mapping[str, str],
    check: bool = True,
    capture_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Run a shell command with the provided environment."""
    return subprocess.run(  # noqa: PLW1510 (subprocess.run default)
        command,
        env=env,
        check=check,
        text=True,
        capture_output=capture_output,
    )


def build_set_args(pairs: Mapping[str, str | int | bool]) -> Iterable[str]:
    """Convert a mapping into Helm --set arguments."""
    for key, value in pairs.items():
        yield "--set"
        yield f"{key}={value}"
