from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/art/generated/FoxKnight_8bit_atlas_v1.png"
OUTPUT = ROOT / "assets/art/generated/sprites"

# The generated atlas follows a 4x4 layout, but a few action/effect silhouettes
# intentionally extend beyond a mathematical quarter. These non-overlapping
# windows preserve the complete art before trimming transparent margins.
WINDOWS = {
    "fox_idle": (0, 0, 313, 313),
    "fox_walk": (313, 0, 626, 313),
    "fox_ready": (626, 0, 900, 313),
    "fox_dash_slash": (900, 0, 1254, 313),
    "enemy_idle": (0, 313, 313, 626),
    "enemy_walk": (313, 313, 600, 626),
    "enemy_hit": (600, 313, 900, 626),
    "enemy_death": (900, 313, 1254, 626),
    "slash_trail": (0, 626, 405, 939),
    "hit_spark": (405, 626, 625, 939),
    "death_burst": (625, 626, 940, 939),
    "retry_icon": (940, 626, 1254, 939),
    "floor_tile": (0, 939, 313, 1254),
    "wall_tile": (313, 939, 626, 1254),
    "one_cut_icon": (626, 939, 939, 1254),
    "enemy_target_icon": (939, 939, 1254, 1254),
}


def main() -> None:
    atlas = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)

    for name, window in WINDOWS.items():
        image = atlas.crop(window)
        alpha_box = image.getchannel("A").getbbox()
        if alpha_box is None:
            raise RuntimeError(f"{name} has no visible pixels")

        left, top, right, bottom = alpha_box
        padding = 4
        crop_box = (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
        trimmed = image.crop(crop_box)
        trimmed.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {trimmed.width}x{trimmed.height}")


if __name__ == "__main__":
    main()
