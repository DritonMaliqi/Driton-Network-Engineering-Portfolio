from pathlib import Path
from datetime import datetime

from scenario_engine import generate_scenario
from evidence_engine import get_evidence
from console_engine import get_common_outputs, get_hint, command_not_found
from evaluator_engine import evaluate_diagnosis, evaluate_multi_fault, calculate_final_score, get_rating


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "output"
OUTPUT_DIR.mkdir(exist_ok=True)


def choose(title, options):
    print()
    print(title)
    print("-" * 50)

    for index, option in enumerate(options, start=1):
        print(f"{index}. {option}")

    while True:
        value = input("\nSelect option: ").strip()

        if value.isdigit():
            number = int(value)

            if 1 <= number <= len(options):
                return options[number - 1]

        print("Invalid selection. Try again.")


def print_scenario(scenario, track):
    print()
    print("=" * 68)
    print(" NETFORGE NETWORK LAB GENERATOR v6.3")
    print("=" * 68)
    print()
    print(f"LAB ID : {scenario.lab_id}")
    print(f"TRACK  : {track}")
    print(f"LEVEL  : {scenario.level}")
    print(f"TOPIC  : {scenario.topic}")

    print()
    print("INCIDENT")
    print("-" * 68)
    print(scenario.incident)

    print()
    print("SYMPTOM")
    print("-" * 68)
    print(scenario.symptom)

    print()
    print("DEVICES")
    print("-" * 68)

    for device in scenario.devices:
        print(f"- {device.name} | {device.role}")

    print()
    print("YOUR TASK")
    print("-" * 68)
    print("Investigate the incident using troubleshooting commands.")
    print("Identify the root cause and determine the corrective action.")


def normalize_command(command):
    return " ".join(
        command.lower().strip().split()
    )


def interactive_troubleshooting(scenario):
    evidence = get_evidence(scenario.topic, scenario.level)
    common_outputs = get_common_outputs(scenario.topic)

    combined = {}

    for command, output in evidence.items():
        combined[normalize_command(command)] = (command, output)

    for command, output in common_outputs.items():
        combined[normalize_command(command)] = (command, output)

    command_history = []
    hints_used = 0

    print()
    print("=" * 68)
    print(" REALISTIC TROUBLESHOOTING CONSOLE")
    print("=" * 68)

    print()
    print("Enter troubleshooting commands.")
    print()
    print("Special commands:")
    print("  help     - console help")
    print("  history  - command history")
    print("  hint     - request troubleshooting hint")
    print("  diagnose - submit root-cause analysis")
    print("  exit     - leave the lab")

    while True:
        command = input("\nNETFORGE> ").strip()

        if not command:
            continue

        normalized = normalize_command(command)

        if normalized == "help":
            print()
            print("AVAILABLE COMMANDS FOR THIS LAB")
            print("-" * 68)

            for original_command, _ in combined.values():
                print(f"  {original_command}")

            print()
            print("Special commands:")
            print("  history")
            print("  hint")
            print("  diagnose")
            print("  exit")
            continue

        if normalized == "history":
            print()
            print("COMMAND HISTORY")
            print("-" * 68)

            if not command_history:
                print("No commands entered yet.")
            else:
                for index, item in enumerate(command_history, 1):
                    print(f"{index}. {item}")

            continue

        if normalized == "hint":
            print()
            print("HINT")
            print("-" * 68)
            print(get_hint(scenario.topic, hints_used))
            hints_used += 1
            continue

        if normalized == "exit":
            print()
            print("Lab session ended.")
            return False

        if normalized == "diagnose":
            return submit_diagnosis(
                scenario,
                command_history,
                0,
                hints_used
            )

        command_history.append(command)

        if normalized in combined:
            original_command, output = combined[normalized]

            print()
            print(f"$ {original_command}")
            print("-" * 68)

            if output:
                print(output)
            else:
                print("<no matching configuration/output>")

        else:
            print()

            if normalized.startswith("ping "):
                target = command.split(maxsplit=1)[1]

                print(f"Pinging {target}...")
                print(
                    "% No simulated path is defined for "
                    "this destination in the current lab."
                )
            else:
                print(command_not_found(command))

def submit_diagnosis(
    scenario,
    command_history,
    score,
    hints_used
):
    print()
    print("=" * 68)
    print(" ROOT CAUSE ANALYSIS")
    print("=" * 68)

    diagnosis = input(
        "\nWhat is the root cause? "
    ).strip()

    fix = input(
        "What corrective action would you take? "
    ).strip()

    evaluation = evaluate_multi_fault(
        scenario.topic,
        diagnosis,
        fix,
        scenario.level
    )

    if evaluation is None:
        evaluation = evaluate_diagnosis(
            scenario.topic,
            diagnosis,
            fix
        )

    final_score = calculate_final_score(
        evaluation["total"],
        len(command_history),
        hints_used
    )

    rating = get_rating(final_score)

    print()
    print("=" * 68)
    print(" INSTRUCTOR ANSWER")
    print("=" * 68)

    print()
    print("EXPECTED ROOT CAUSE:")
    print(scenario.fault)

    print()
    print("EXPECTED TROUBLESHOOTING COMMAND:")
    print(scenario.expected_command)

    print()
    print("EXPECTED FIX:")
    print(scenario.expected_fix)

    print()
    print("YOUR DIAGNOSIS:")
    print(diagnosis if diagnosis else "<none>")

    print()
    print("YOUR CORRECTIVE ACTION:")
    print(fix if fix else "<none>")

    print()
    print("EVALUATION")
    print("-" * 68)

    print(
        f"ROOT CAUSE SCORE : "
        f"{evaluation['diagnosis_score']}/60"
    )

    print(
        f"FIX SCORE        : "
        f"{evaluation['fix_score']}/40"
    )

    print(
        f"COMMANDS USED    : "
        f"{len(command_history)}"
    )

    print(
        f"HINTS USED       : "
        f"{hints_used}"
    )

    print(
        f"FINAL LAB SCORE  : "
        f"{final_score}/100"
    )

    print(
        f"RATING           : "
        f"{rating}"
    )

    return True

def save_scenario(scenario, track):
    file_path = OUTPUT_DIR / f"{scenario.lab_id}.txt"

    evidence = get_evidence(scenario.topic, scenario.level)

    content = [
        "NETFORGE NETWORK LAB GENERATOR",
        "=" * 68,
        f"LAB ID: {scenario.lab_id}",
        f"TRACK: {track}",
        f"LEVEL: {scenario.level}",
        f"TOPIC: {scenario.topic}",
        "",
        "INCIDENT:",
        scenario.incident,
        "",
        "SYMPTOM:",
        scenario.symptom,
        "",
        "DEVICES:",
    ]

    for device in scenario.devices:
        content.append(
            f"- {device.name} | {device.role}"
        )

    content.extend([
        "",
        "TROUBLESHOOTING EVIDENCE",
        "-" * 68,
    ])

    for command, output in evidence.items():
        content.append("")
        content.append(f"$ {command}")
        content.append(output)

    content.extend([
        "",
        "INSTRUCTOR / ANSWER KEY",
        "-" * 68,
        f"FAULT: {scenario.fault}",
        f"EXPECTED COMMAND: {scenario.expected_command}",
        f"EXPECTED FIX: {scenario.expected_fix}",
    ])

    file_path.write_text(
        "\n".join(content),
        encoding="utf-8"
    )

    return file_path


def main():
    print()
    print("=" * 68)
    print(" NETFORGE NETWORK LAB GENERATOR v6.3")
    print("=" * 68)

    track = choose(
        "CERTIFICATION TRACK",
        ["CCNA", "CCNP"]
    )

    level = choose(
        "DIFFICULTY LEVEL",
        ["Easy", "Medium", "Hard"]
    )

    topic = choose(
        "TROUBLESHOOTING TOPIC",
        [
            "VLAN",
            "TRUNK",
            "DHCP",
            "OSPF",
            "RANDOM",
        ]
    )

    lab_id = datetime.now().strftime(
        "LAB-%Y%m%d-%H%M%S"
    )

    scenario = generate_scenario(
        lab_id=lab_id,
        topic=topic,
        level=level,
        track=track,
    )

    print_scenario(
        scenario,
        track,
    )

    saved = save_scenario(
        scenario,
        track,
    )

    interactive_troubleshooting(
        scenario
    )

    print()
    print("Lab documentation saved to:")
    print(saved)
    print()


if __name__ == "__main__":
    main()











