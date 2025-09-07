#!/usr/bin/env python3
"""
ESPHome name length checker for pre-commit hooks.
Validates that ESPHome device names are <= 24 characters.
"""
import argparse
import sys
from pathlib import Path

import yaml


def check_esphome_name_length(file_path: Path) -> bool:
    """
    Check if ESPHome name in the given YAML file is <= 24 characters.

    Args:
        file_path: Path to the YAML file to check

    Returns:
        True if valid, False if invalid
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            # Use safe_load to handle ESPHome's custom tags
            try:
                data = yaml.safe_load(f)
            except yaml.YAMLError as e:
                print(f"  ⚠️  Could not parse YAML in {file_path}: {e}")
                return True  # Skip files with YAML errors (let yamllint handle them)

        if not data or not isinstance(data, dict):
            print(f"  No valid YAML structure found in {file_path}")
            return True

        # Check if esphome section exists
        esphome_config = data.get("esphome")
        if not esphome_config:
            print(f"  No esphome section found in {file_path}")
            return True

        # Get the name value
        esphome_name = esphome_config.get("name")
        if not esphome_name:
            print(f"  No esphome name found in {file_path}")
            return True

        print(f"  Found esphome name: '{esphome_name}'")

        # Check if it's a substitution like ${name}
        if (
            isinstance(esphome_name, str)
            and esphome_name.startswith("${")
            and esphome_name.endswith("}")
        ):
            # Extract substitution variable name (e.g., ${name} -> name)
            sub_var = esphome_name[2:-1]  # Remove ${ and }
            print(f"  ESPHome name uses substitution: ${{{sub_var}}}")

            # Look for the substitution value
            substitutions = data.get("substitutions", {})
            if sub_var in substitutions:
                sub_value = substitutions[sub_var]
                print(f"  Substitution resolves to: '{sub_value}'")
                final_name = sub_value
            else:
                print(f"  ⚠️  Could not resolve substitution ${{{sub_var}}}")
                return True  # Skip validation if substitution can't be resolved
        else:
            # Direct name value
            final_name = str(esphome_name)

        name_length = len(final_name)
        print(f"  Final ESPHome name: '{final_name}' (length: {name_length})")

        if name_length > 24:
            error_msg = (
                f"❌ ERROR: ESPHome name '{final_name}' is {name_length} "
                f"characters long (max 24 allowed)"
            )
            print(error_msg)
            print(f"  File: {file_path}")
            print("  ESPHome device names are limited to 24 characters to ensure compatibility")
            return False
        else:
            print(f"✅ ESPHome name length OK ({name_length}/24 characters)")
            return True

    except Exception as e:
        print(f"  ⚠️  Error processing {file_path}: {e}")
        return True  # Skip files with errors


def main():
    parser = argparse.ArgumentParser(description="Check ESPHome name length")
    parser.add_argument("files", nargs="*", help="YAML files to check")
    args = parser.parse_args()

    if not args.files:
        print("No files provided")
        return 0

    exit_code = 0
    for file_path in args.files:
        path = Path(file_path)
        print(f"Checking ESPHome name length in: {path}")

        if not check_esphome_name_length(path):
            exit_code = 1

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
