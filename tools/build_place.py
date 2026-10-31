"""Build Roblox places with Rojo's Roblox-aware serializers.

Requires Rojo 7.5.1 on PATH, or an explicit --rojo executable path.
"""
import argparse
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def build(rojo):
    if not shutil.which(rojo):
        raise SystemExit(
            "Rojo não encontrado. Instale o Rojo 7.5.1 ou use "
            "--rojo /caminho/para/rojo. O arquivo pronto em dist/ "
            "pode ser aberto no Studio sem instalar Rojo."
        )
    target_dir = ROOT / "dist"
    target_dir.mkdir(exist_ok=True)
    for extension in ("rbxl", "rbxlx"):
        target = target_dir / f"LendasDoAnime.{extension}"
        subprocess.run(
            [rojo, "build", str(ROOT / "default.project.json"), "--output", str(target)],
            cwd=ROOT,
            check=True,
        )
        print(target)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo", help="Executável do Rojo (padrão: PATH)")
    build(parser.parse_args().rojo)
