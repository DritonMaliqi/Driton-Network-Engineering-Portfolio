from typing import List
from .models import ConfigSection


class ConfigurationBuilder:
    def __init__(self):
        self.sections: List[ConfigSection] = []

    def add_section(self, section: ConfigSection):
        if section.is_valid():
            self.sections.append(section)

    def clear(self):
        self.sections.clear()

    def section_count(self) -> int:
        return len(self.sections)

    def build(self) -> str:
        if not self.sections:
            return ""

        output = []

        for index, section in enumerate(self.sections, start=1):
            output.append("!")
            output.append(
                f"! SECTION {index}: "
                f"{section.vendor} / "
                f"{section.platform} / "
                f"{section.technology} / "
                f"{section.name}"
            )
            output.append("!")
            output.append(section.config.strip())

        output.append("!")
        output.append("! END OF GENERATED CONFIGURATION")
        output.append("!")

        return "\n".join(output)
