def normalize(text):
    return " ".join(text.lower().strip().split())


def keyword_score(text, required_groups):
    text = normalize(text)

    if not text:
        return 0

    matched = 0

    for group in required_groups:
        if any(keyword in text for keyword in group):
            matched += 1

    return matched


def evaluate_diagnosis(topic, diagnosis, fix):
    topic = topic.upper()

    if "VLAN" in topic:
        diagnosis_groups = [
            ["fa0/2", "fastethernet0/2"],
            ["vlan 1"],
            ["vlan 10"],
        ]

        fix_groups = [
            ["fa0/2", "fastethernet0/2"],
            ["switchport access vlan 10", "access vlan 10"],
        ]

    elif "TRUNK" in topic:
        diagnosis_groups = [
            ["vlan 10"],
            ["trunk"],
            ["missing", "not allowed", "removed"],
        ]

        fix_groups = [
            ["trunk"],
            ["vlan 10"],
            ["allowed vlan add 10", "allowed vlan 10"],
        ]

    elif "OSPF" in topic:
        diagnosis_groups = [
            ["ospf"],
            ["area"],
            ["area 0"],
            ["area 1"],
        ]

        fix_groups = [
            ["same area", "matching area"],
            ["area 0", "area 1"],
        ]

    elif "DHCP" in topic:
        diagnosis_groups = [
            ["dhcp"],
            ["helper", "relay"],
            ["missing", "incorrect", "wrong"],
        ]

        fix_groups = [
            ["ip helper-address", "helper-address"],
            ["dhcp"],
        ]

    else:
        return {
            "diagnosis_score": 0,
            "fix_score": 0,
            "total": 0,
        }

    diagnosis_matches = keyword_score(
        diagnosis,
        diagnosis_groups
    )

    fix_matches = keyword_score(
        fix,
        fix_groups
    )

    diagnosis_score = round(
        60 * diagnosis_matches / len(diagnosis_groups)
    )

    fix_score = round(
        40 * fix_matches / len(fix_groups)
    )

    return {
        "diagnosis_score": diagnosis_score,
        "fix_score": fix_score,
        "total": diagnosis_score + fix_score,
    }


def calculate_final_score(
    diagnosis_score,
    commands_used,
    hints_used
):
    score = diagnosis_score

    # A troubleshooting lab should require some evidence collection.
    if commands_used == 0:
        score -= 25

    elif commands_used == 1:
        score -= 15

    elif commands_used == 2:
        score -= 5

    # Excessive command usage also reduces efficiency.
    if commands_used > 5:
        score -= (commands_used - 5) * 2

    # Hints reduce the final score.
    score -= hints_used * 5

    return max(0, min(100, score))

def get_rating(score):
    if score >= 90:
        return "Excellent"

    if score >= 75:
        return "Good"

    if score >= 60:
        return "Pass"

    return "Needs Improvement"



def evaluate_multi_fault(topic, diagnosis, fix, level):
    if level.lower() != "hard":
        return None

    text_diag = normalize(diagnosis)
    text_fix = normalize(fix)
    topic = topic.upper()

    if "VLAN" in topic:
        fault1 = (
            ("fa0/2" in text_diag or "fastethernet0/2" in text_diag)
            and "vlan 1" in text_diag
            and "vlan 10" in text_diag
        )

        fault2 = (
            "vlan 10" in text_diag
            and "trunk" in text_diag
            and (
                "missing" in text_diag
                or "not allowed" in text_diag
                or "removed" in text_diag
            )
        )

        fix1 = (
            ("fa0/2" in text_fix or "fastethernet0/2" in text_fix)
            and "vlan 10" in text_fix
        )

        fix2 = (
            "trunk" in text_fix
            and "vlan 10" in text_fix
            and (
                "allowed" in text_fix
                or "add" in text_fix
            )
        )

        root_score = 0
        fix_score = 0

        if fault1:
            root_score += 30

        if fault2:
            root_score += 30

        if fix1:
            fix_score += 20

        if fix2:
            fix_score += 20

        return {
            "fault1": fault1,
            "fault2": fault2,
            "fix1": fix1,
            "fix2": fix2,
            "diagnosis_score": root_score,
            "fix_score": fix_score,
            "total": root_score + fix_score,
        }

    if "OSPF" in topic:
        fault1 = (
            "ospf" in text_diag
            and "area" in text_diag
            and "area 0" in text_diag
            and "area 1" in text_diag
        )

        fault2 = (
            (
                "branch" in text_diag
                or "192.168.30.0" in text_diag
                or "lan" in text_diag
            )
            and (
                "not advertised" in text_diag
                or "missing" in text_diag
                or "network statement" in text_diag
                or "not in ospf" in text_diag
            )
        )

        fix1 = (
            "area" in text_fix
            and (
                ("same area" in text_fix or "same ospf area" in text_fix)
                or "matching area" in text_fix
                or (
                    "area 0" in text_fix
                    and "area 1" in text_fix
                )
            )
        )

        fix2 = (
            (
                "192.168.30.0" in text_fix
                or "branch" in text_fix
                or "lan" in text_fix
            )
            and (
                "network" in text_fix
                or "advertise" in text_fix
                or "ospf" in text_fix
            )
        )

        root_score = 0
        fix_score = 0

        if fault1:
            root_score += 30

        if fault2:
            root_score += 30

        if fix1:
            fix_score += 20

        if fix2:
            fix_score += 20

        return {
            "fault1": fault1,
            "fault2": fault2,
            "fix1": fix1,
            "fix2": fix2,
            "diagnosis_score": root_score,
            "fix_score": fix_score,
            "total": root_score + fix_score,
        }

    return None

