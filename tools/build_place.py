"""Build Roblox places with Rojo's Roblox-aware serializers.

Requires Rojo 7.5.1 and Lune 0.8.9, or explicit executable paths.
"""
import argparse
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def build(rojo, lune):
    if not shutil.which(rojo):
        raise SystemExit(
            "Rojo não encontrado. Instale o Rojo 7.5.1 ou use "
            "--rojo /caminho/para/rojo. O arquivo pronto em dist/ "
            "pode ser aberto no Studio sem instalar Rojo."
        )
    if not shutil.which(lune):
        raise SystemExit("Lune não encontrado. Instale o Lune 0.8.9 ou use --lune /caminho/para/lune.")
    subprocess.run([lune, "run", "tools/build_world.luau"], cwd=ROOT, check=True)
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
    parser.add_argument("--lune", default="lune", help="Executável do Lune (padrão: PATH)")
    args = parser.parse_args()
    build(args.rojo, args.lune)
