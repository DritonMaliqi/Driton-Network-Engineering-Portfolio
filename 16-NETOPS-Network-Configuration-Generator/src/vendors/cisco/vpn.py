from core.models import ConfigSection
from core.validator import NetworkValidator


def generate_ipsec_site_to_site(
    peer_ip,
    pre_shared_key,
    local_network,
    local_wildcard,
    remote_network,
    remote_wildcard,
    outside_interface="GigabitEthernet0/0",
    crypto_map_name="NETOPS-MAP",
    crypto_map_sequence=10
):
    peer_result = NetworkValidator.validate_ipv4(
        peer_ip,
        "VPN Peer IP"
    )

    local_result = NetworkValidator.validate_ipv4(
        local_network,
        "Local Network"
    )

    remote_result = NetworkValidator.validate_ipv4(
        remote_network,
        "Remote Network"
    )

    errors = []
    errors.extend(peer_result.errors)
    errors.extend(local_result.errors)
    errors.extend(remote_result.errors)

    if errors:
        raise ValueError("\n".join(errors))

    if not pre_shared_key:
        raise ValueError("Pre-shared key is required.")

    lines = [
        "!",
        "crypto isakmp policy 10",
        " encr aes 256",
        " hash sha256",
        " authentication pre-share",
        " group 14",
        " lifetime 86400",
        "!",
        f"crypto isakmp key {pre_shared_key} address {peer_ip}",
        "!",
        "crypto ipsec transform-set NETOPS-SET esp-aes 256 esp-sha-hmac",
        " mode tunnel",
        "!",
        "ip access-list extended NETOPS-VPN-TRAFFIC",
        f" permit ip {local_network} {local_wildcard} {remote_network} {remote_wildcard}",
        "!",
        f"crypto map {crypto_map_name} {crypto_map_sequence} ipsec-isakmp",
        f" set peer {peer_ip}",
        " set transform-set NETOPS-SET",
        " match address NETOPS-VPN-TRAFFIC",
        "!",
        f"interface {outside_interface}",
        f" crypto map {crypto_map_name}",
        "!"
    ]

    return ConfigSection(
        vendor="Cisco",
        platform="IOS/IOS-XE",
        technology="IPsec VPN",
        name=f"Site-to-Site VPN to {peer_ip}",
        config="\n".join(lines)
    )
