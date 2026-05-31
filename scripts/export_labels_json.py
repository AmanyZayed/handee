import json
from pathlib import Path


DEFAULT_SIGN_MAP_PATH = Path("assets/models/sign_to_prediction_index_map.json")
DEFAULT_OUTPUT_PATH = Path("assets/models/labels.json")


def main() -> None:
    if not DEFAULT_SIGN_MAP_PATH.exists():
        raise FileNotFoundError(
            f"Missing label map: {DEFAULT_SIGN_MAP_PATH}. "
            "Expected the repo sign-to-index JSON exported from training."
        )

    sign_to_index = json.loads(DEFAULT_SIGN_MAP_PATH.read_text(encoding="utf-8"))
    index_to_sign = {
        str(index): sign
        for sign, index in sorted(
            sign_to_index.items(),
            key=lambda item: int(item[1]),
        )
    }

    DEFAULT_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    DEFAULT_OUTPUT_PATH.write_text(
        json.dumps(index_to_sign, ensure_ascii=True, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"Wrote {DEFAULT_OUTPUT_PATH} with {len(index_to_sign)} labels.")


if __name__ == "__main__":
    main()
