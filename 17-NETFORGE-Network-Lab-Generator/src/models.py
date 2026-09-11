from dataclasses import dataclass, field
from typing import List


@dataclass
class Device:
    name: str
    role: str


@dataclass
class LabScenario:
    lab_id: str
    level: str
    topic: str
    incident: str
    symptom: str
    devices: List[Device]

    fault: str
    expected_command: str
    expected_fix: str

    faults: List[str] = field(default_factory=list)
    expected_commands: List[str] = field(default_factory=list)
    expected_fixes: List[str] = field(default_factory=list)

    def all_faults(self):
        if self.faults:
            return self.faults

        return [self.fault]

    def all_expected_commands(self):
        if self.expected_commands:
            return self.expected_commands

        return [self.expected_command]

    def all_expected_fixes(self):
        if self.expected_fixes:
            return self.expected_fixes

        return [self.expected_fix]
