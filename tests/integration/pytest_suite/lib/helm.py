from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping

from .utils import build_set_args, run_command


@dataclass
class HelmRelease:
    """Simple helper around helm upgrade/install/uninstall."""

    name: str
    chart_path: Path
    namespace: str
    env: Mapping[str, str]

    def install(
        self,
        *,
        values_files: Iterable[Path] | None = None,
        set_values: Mapping[str, str | int | bool] | None = None,
        timeout: str = "600s",
    ) -> None:
        command = [
            "helm",
            "upgrade",
            "--install",
            self.name,
            str(self.chart_path),
            "--namespace",
            self.namespace,
            "--create-namespace",
            "--wait",
            "--timeout",
            timeout,
        ]

        for values_file in values_files or []:
            command.extend(["-f", str(values_file)])

        if set_values:
            command.extend(build_set_args(set_values))

        run_command(command, env=self.env)

    def uninstall(self) -> None:
        run_command(
            [
                "helm",
                "uninstall",
                self.name,
                "--namespace",
                self.namespace,
            ],
            env=self.env,
            check=False,
        )
