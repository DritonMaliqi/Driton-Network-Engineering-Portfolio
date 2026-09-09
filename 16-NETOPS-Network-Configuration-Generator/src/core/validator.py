import ipaddress
import re


class ValidationResult:
    def __init__(self):
        self.errors = []
        self.warnings = []

    @property
    def valid(self):
        return len(self.errors) == 0


class NetworkValidator:

    @staticmethod
    def validate_vlan_id(value):
        result = ValidationResult()

        try:
            vlan = int(value)

            if vlan < 1 or vlan > 4094:
                result.errors.append(
                    "VLAN ID must be between 1 and 4094."
                )

        except (ValueError, TypeError):
            result.errors.append(
                "VLAN ID must be numeric."
            )

        return result

    @staticmethod
    def validate_ipv4(value, field_name="IP Address"):
        result = ValidationResult()

        try:
            ipaddress.ip_address(value)

        except ValueError:
            result.errors.append(
                f"{field_name} is not a valid IPv4 address."
            )

        return result

    @staticmethod
    def validate_asn(value):
        result = ValidationResult()

        try:
            asn = int(value)

            if asn < 1 or asn > 4294967295:
                result.errors.append(
                    "ASN must be between 1 and 4294967295."
                )

        except (ValueError, TypeError):
            result.errors.append(
                "ASN must be numeric."
            )

        return result

    @staticmethod
    def validate_hostname(value):
        result = ValidationResult()

        if not value:
            result.errors.append(
                "Hostname cannot be empty."
            )
            return result

        pattern = r"^[A-Za-z0-9][A-Za-z0-9._-]*$"

        if not re.match(pattern, value):
            result.errors.append(
                "Hostname contains invalid characters."
            )

        return result
    @staticmethod
    def validate_cidr(value, field_name="Network"):
        result = ValidationResult()

        if value is None or str(value).strip() == "":
            result.errors.append(
                f"{field_name} cannot be empty."
            )
            return result

        try:
            network = ipaddress.ip_network(
                str(value).strip(),
                strict=False
            )

            if network.version != 4:
                result.errors.append(
                    f"{field_name} must be an IPv4 network."
                )

        except ValueError:
            result.errors.append(
                f"{field_name} is not a valid IPv4 CIDR network."
            )

        return result

    @staticmethod
    def validate_subnet_mask(value, field_name="Subnet Mask"):
        result = ValidationResult()

        if value is None or str(value).strip() == "":
            result.errors.append(
                f"{field_name} cannot be empty."
            )
            return result

        mask = str(value).strip()

        try:
            ipaddress.IPv4Network(
                f"0.0.0.0/{mask}"
            )

        except ValueError:
            result.errors.append(
                f"{field_name} is not a valid IPv4 subnet mask."
            )

        return result

    @staticmethod
    def validate_interface_name(value, field_name="Interface"):
        result = ValidationResult()

        if value is None or str(value).strip() == "":
            result.errors.append(
                f"{field_name} cannot be empty."
            )
            return result

        interface = str(value).strip()

        pattern = r"^[A-Za-z][A-Za-z0-9._:/-]*$"

        if not re.match(pattern, interface):
            result.errors.append(
                f"{field_name} contains invalid characters."
            )

        return result

    @staticmethod
    def validate_port(value, field_name="Port"):
        result = ValidationResult()

        try:
            port = int(value)

            if port < 1 or port > 65535:
                result.errors.append(
                    f"{field_name} must be between 1 and 65535."
                )

        except (ValueError, TypeError):
            result.errors.append(
                f"{field_name} must be numeric."
            )

        return result

    @staticmethod
    def validate_required(value, field_name="Field"):
        result = ValidationResult()

        if value is None or str(value).strip() == "":
            result.errors.append(
                f"{field_name} is required."
            )

        return result
