from dataclasses import dataclass, field
from typing import List


@dataclass
class ConfigSection:
    vendor: str
    platform: str
    technology: str
    name: str
    config: str
    warnings: List[str] = field(default_factory=list)

    def is_valid(self) -> bool:
        return bool(self.config.strip())
