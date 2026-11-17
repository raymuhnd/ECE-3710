from pathlib import Path
import argparse

IMMEDIATE_OPCODES = {
    "ANDI": 0x1,
    "ORI": 0x2,
    "XORI": 0x3,
    "ADDI": 0x5,
    "SUBI": 0x9,
    "CMPI": 0xB,
    "MOVI": 0xD,
    "LUI": 0xF
}


def encode_immediate(operation, operands, labels):
    if len(operands) != 2:
        raise ValueError(
            f"{operation} requires an immediate and a register"
        )

    value_text = operands[0]

    if value_text in labels:
        immediate = labels[value_text]
    else:
        immediate = int(value_text, 0)

    register_text = operands[1].lower()
    valid_registers = [f"r{i}" for i in range(16)]

    if register_text not in valid_registers:
        raise ValueError(f"Invalid register: {register_text}")

    destination = int(register_text[1:])

    if operation in ("ADDI", "SUBI", "CMPI"):
        if not -128 <= immediate <= 127:
            raise ValueError(
                f"{operation} immediate must be between -128 and 127"
            )
    else:
        if not 0 <= immediate <= 255:
            raise ValueError(
                f"{operation} immediate must be between 0 and 255"
            )

    opcode = IMMEDIATE_OPCODES[operation]
    immediate_bits = immediate & 0xFF

    return (opcode << 12) | (destination << 8) | immediate_bits

REGISTER_OPCODES = {
    "AND": 0x1,
    "OR": 0x2,
    "XOR": 0x3,
    "ADD": 0x5,
    "SUB": 0x9,
    "CMP": 0xB,
    "MOV": 0xD
}


def encode_register(operation, operands):
    if len(operands) != 2:
        raise ValueError(f"{operation} requires two registers")

    source_text = operands[0].lower()
    destination_text = operands[1].lower()

    valid_registers = [f"r{i}" for i in range(16)]

    if source_text not in valid_registers:
        raise ValueError(f"Invalid register: {source_text}")

    if destination_text not in valid_registers:
        raise ValueError(f"Invalid register: {destination_text}")

    source = int(source_text[1:])
    destination = int(destination_text[1:])

    opcode = REGISTER_OPCODES[operation]

    return (destination << 8) | (opcode << 4) | source

def encode_shift(operation, operands):
    if len(operands) != 2:
        raise ValueError(f"{operation} requires two operands")

    valid_registers = [f"r{i}" for i in range(16)]
    destination_text = operands[1].lower()

    if destination_text not in valid_registers:
        raise ValueError(f"Invalid register: {destination_text}")

    destination = int(destination_text[1:])

    if operation == "LSH":
        source_text = operands[0].lower()

        if source_text not in valid_registers:
            raise ValueError(f"Invalid register: {source_text}")

        source = int(source_text[1:])

        return (0x8 << 12) | (destination << 8) | (0x4 << 4) | source

    elif operation == "LSHI":
        amount = int(operands[0], 0)

        if not -16 <= amount <= 15:
            raise ValueError("LSHI amount must be between -16 and 15")

        amount_bits = amount & 0x1F

        return (0x8 << 12) | (destination << 8) | amount_bits

    else:
        raise ValueError(f"Unknown shift operation: {operation}")

def encode_memory(operation, operands):
    if len(operands) != 2:
        raise ValueError(f"{operation} requires two registers")

    data_text = operands[0].lower()
    address_text = operands[1].lower()

    valid_registers = [f"r{i}" for i in range(16)]

    if data_text not in valid_registers:
        raise ValueError(f"Invalid register: {data_text}")

    if address_text not in valid_registers:
        raise ValueError(f"Invalid register: {address_text}")

    data_register = int(data_text[1:])
    address_register = int(address_text[1:])

    if operation == "LOAD":
        extension = 0x0
    elif operation == "STOR":
        extension = 0x4
    else:
        raise ValueError(f"Unknown memory operation: {operation}")

    return (
        (0x4 << 12)
        | (data_register << 8)
        | (extension << 4)
        | address_register
    )

BRANCH_CONDITIONS = {
    "BEQ": 0x0,
    "BNE": 0x1,
    "BCS": 0x2,
    "BCC": 0x3,
    "BHI": 0x4,
    "BLS": 0x5,
    "BGT": 0x6,
    "BLE": 0x7,
    "BFS": 0x8,
    "BFC": 0x9,
    "BLO": 0xA,
    "BHS": 0xB,
    "BLT": 0xC,
    "BGE": 0xD,
    "BUC": 0xE
}

JUMP_CONDITIONS = {}

for branch_name, condition in BRANCH_CONDITIONS.items():
    jump_name = "J" + branch_name[1:]
    JUMP_CONDITIONS[jump_name] = condition

def encode_branch(operation, operands, labels, address):
    if len(operands) != 1:
        raise ValueError(f"{operation} requires one target")

    target_text = operands[0]

    if target_text in labels:
        target_address = labels[target_text]
    else:
        try:
            target_address = int(target_text, 0)
        except ValueError:
            raise ValueError(f"Unknown branch target: {target_text}")

    displacement = target_address - address

    if not -128 <= displacement <= 127:
        raise ValueError(
            f"Branch to {target_text} is too far: "
            f"displacement is {displacement}"
        )

    condition = BRANCH_CONDITIONS[operation]
    displacement_bits = displacement & 0xFF

    return (0xC << 12) | (condition << 8) | displacement_bits


def encode_jump(operation, operands):
    if len(operands) != 1:
        raise ValueError(f"{operation} requires one target register")

    register_text = operands[0].lower()
    valid_registers = [f"r{i}" for i in range(16)]

    if register_text not in valid_registers:
        raise ValueError(f"Invalid register: {register_text}")

    target_register = int(register_text[1:])
    condition = JUMP_CONDITIONS[operation]

    return (
        (0x4 << 12)
        | (condition << 8)
        | (0xC << 4)
        | target_register
    )


def encode_jal(operands):
    if len(operands) != 2:
        raise ValueError("JAL requires a link register and a target register")

    link_text = operands[0].lower()
    target_text = operands[1].lower()
    valid_registers = [f"r{i}" for i in range(16)]

    if link_text not in valid_registers:
        raise ValueError(f"Invalid register: {link_text}")

    if target_text not in valid_registers:
        raise ValueError(f"Invalid register: {target_text}")

    link_register = int(link_text[1:])
    target_register = int(target_text[1:])

    return (
        (0x4 << 12)
        | (link_register << 8)
        | (0x8 << 4)
        | target_register
    )

parser = argparse.ArgumentParser(
    description="Assemble a program for our CR16 CPU"
)

parser.add_argument(
    "input",
    type=Path,
    help="Assembly file to read"
)

parser.add_argument(
    "-o", "--output",
    type=Path,
    required=True,
    help="Hex file to create"
)

parser.add_argument(
    "--check",
    type=Path,
    help="Optional reference hex file"
)

args = parser.parse_args()

input_file = args.input
output_file = args.output

if output_file.resolve() == input_file.resolve():
    raise ValueError("Output must not overwrite the assembly source")

if args.check and output_file.resolve() == args.check.resolve():
    raise ValueError("Output must not overwrite the reference hex file")

with open(input_file, "r") as file:
    lines = file.readlines()

cleaned_lines = []

for line in lines:
    line = line.split(";", 1)[0]
    line = line.strip()

    if line:
        cleaned_lines.append(line)

parsed_lines = []

for line in cleaned_lines:
    label = None

    # Separate a label from the rest of the line.
    if ":" in line:
        label, line = line.split(":", 1)
        label = label.strip()
        line = line.strip()

    operation = None
    operands = []

    # A label might have no instruction after it.
    if line:
        parts = line.split(None, 1)
        operation = parts[0].upper()

        if len(parts) > 1:
            for operand in parts[1].split(","):
                operands.append(operand.strip())

    parsed_lines.append({
        "label": label,
        "operation": operation,
        "operands": operands
    })

current_address = 0
labels = {}

for entry in parsed_lines:
    label = entry["label"]
    operation = entry["operation"]
    operands = entry["operands"]

    # A label names the current address.
    if label is not None:
        if label in labels:
            raise ValueError(f"Duplicate label: {label}")

        labels[label] = current_address

    # A line containing only a label uses no memory.
    if operation is None:
        continue

    # .org changes where the next word will be placed.
    if operation == ".ORG":
        if len(operands) != 1:
            raise ValueError(".org requires one address")

        current_address = int(operands[0], 0)
        continue

    # Remember where this instruction or data will go.
    entry["address"] = current_address

    if operation == ".WORD":
        if not operands:
            raise ValueError(".word requires at least one value")

        current_address += len(operands)
    else:
        current_address += 1

for name, address in labels.items():
    print(f"{name}: {address} (0x{address:04X})")

memory = {}

for entry in parsed_lines:
    operation = entry["operation"]
    operands = entry["operands"]

    # These entries do not produce machine-code words.
    if operation is None or operation == ".ORG":
        continue

    address = entry["address"]

    if operation == ".WORD":
        words = []

        for operand in operands:
            if operand in labels:
                value = labels[operand]
            else:
                value = int(operand, 0)

            if not -32768 <= value <= 65535:
                raise ValueError(f"Data value does not fit in 16 bits: {value}")

            words.append(value & 0xFFFF)

    else:
        if operation in IMMEDIATE_OPCODES:
            machine_code = encode_immediate(operation, operands, labels)
        elif operation in REGISTER_OPCODES:
            machine_code = encode_register(operation, operands)
        elif operation in ("LSH", "LSHI"):
            machine_code = encode_shift(operation, operands)
        elif operation in ("LOAD", "STOR"):
            machine_code = encode_memory(operation, operands)
        elif operation in BRANCH_CONDITIONS:
            machine_code = encode_branch(
                operation, operands, labels, address
            )
        elif operation in JUMP_CONDITIONS:
            machine_code = encode_jump(operation, operands)
        elif operation == "JAL":
            machine_code = encode_jal(operands)
        else:
            raise ValueError(f"Unsupported operation: {operation}")

        words = [machine_code]

    for offset, word in enumerate(words):
        word_address = address + offset

        if not 0 <= word_address < 1024:
            raise ValueError(f"Address outside RAM: {word_address}")

        if word_address in memory:
            raise ValueError(
                f"Two words assigned to address 0x{word_address:04X}"
            )

        memory[word_address] = word

with open(output_file, "w") as file:
    previous_address = None

    for address, word in sorted(memory.items()):
        if previous_address is None or address != previous_address + 1:
            file.write(f"@{address:03X}\n")

        file.write(f"{word:04X}\n")
        previous_address = address

print(f"\nWrote {len(memory)} words to:")
print(output_file)

def read_hex_file(path):
    contents = {}
    address = 0

    with open(path, "r") as file:
        for line in file:
            line = line.split("//", 1)[0]
            line = line.split(";", 1)[0]
            line = line.strip()

            for token in line.split():
                if token.startswith("@"):
                    address = int(token[1:], 16)
                else:
                    word = int(token, 16)

                    if not 0 <= word <= 0xFFFF:
                        raise ValueError(f"Invalid 16-bit word: {token}")

                    if address in contents:
                        raise ValueError(
                            f"Duplicate address in {path}: 0x{address:04X}"
                        )

                    contents[address] = word
                    address += 1

    return contents


if args.check is not None:
    generated_memory = read_hex_file(output_file)
    reference_memory = read_hex_file(args.check)

    all_addresses = sorted(
        set(generated_memory) | set(reference_memory)
    )

    differences = []

    for address in all_addresses:
        generated = generated_memory.get(address)
        expected = reference_memory.get(address)

        if generated != expected:
            differences.append(address)

            generated_text = (
                "missing" if generated is None else f"{generated:04X}"
            )
            expected_text = (
                "missing" if expected is None else f"{expected:04X}"
            )

            print(
                f"Mismatch at {address:04X}: "
                f"generated={generated_text}, expected={expected_text}"
            )

    if differences:
        raise ValueError(
            f"Verification failed at {len(differences)} address(es)"
        )

    print(
        f"PASS: all {len(reference_memory)} populated words "
        f"match {args.check}"
    )