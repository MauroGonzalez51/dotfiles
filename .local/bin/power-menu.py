#!/usr/bin/env python3

import subprocess
from dataclasses import dataclass
from enum import Enum
from typing import List


@dataclass
class PowerOption:
    label: str
    icon: str
    command: List[str]


class PowerActions(Enum):
    SHUTDOWN = PowerOption(
        label="Shutdown", icon="\uf011", command=["systemctl", "poweroff"]
    )

    REBOOT = PowerOption(
        label="Reboot", icon="\udb81\udc53", command=["systemctl", "reboot"]
    )

    LOGOUT = PowerOption(
        label="Log Out", icon="\udb81\uddfd", command=["hyprctl", "dispatch", "exit"]
    )

    SUSPEND = PowerOption(
        label="Suspend", icon="\uf186", command=["systemctl", "suspend"]
    )

    LOCK = PowerOption(label="Lock", icon="\uea75", command=["hyprlock"])


def main() -> None:
    menu_items = [
        f"{action.value.icon} {action.value.label}" for action in PowerActions
    ]
    menu_text = "\n".join(menu_items).encode("utf-16", "surrogatepass").decode("utf-16")

    try:
        (result,) = (
            subprocess.run(
                ["wofi", "--dmenu", "--insensitive"],
                input=menu_text,
                capture_output=True,
                text=True,
            ),
        )

        if result.returncode == 0 and result.stdout.strip():
            choice = result.stdout.strip()

            for action in PowerActions:
                option = action.value

                if f"{option.icon} {option.label}" == choice:
                    subprocess.run(option.command)
                    break
    except Exception as exception:
        print(f"[exception] {exception}")


if __name__ == "__main__":
    main()
