"""Build editable native-grid courtyard metatile atlases from original pixel forms.

Source images have 16 px cells. Godot images are exact nearest-neighbor 2x
exports, with one source pixel occupying one aligned 2x2 world-pixel block.
This script refuses to overwrite delivered art unless explicitly passed --force.
"""

import argparse
from pathlib import Path

from PIL import Image

from pixel_stone_forms import (P, floor_a, floor_b, floor_quiet,
                               floor_quiet_b, floor_quiet_c, floor_quiet_d,
                               floor_wet, floor_worn, wall,
                               wall_border)
from pixel_water_edge_forms import decor, shore_overlay, water_and_mask


OUT = Path(__file__).resolve().parent
CELL = 16
SCALE = 2


def atlas(columns, rows, cells):
    result = Image.new("RGBA", (columns * 48, rows * 48), (0, 0, 0, 0))
    for (column, row), tile in cells.items():
        assert tile.size == (48, 48)
        result.alpha_composite(tile, (column * 48, row * 48))
    return result


def validate_native(image, name):
    assert image.width % CELL == 0 and image.height % CELL == 0, name
    assert set(image.getchannel("A").get_flattened_data()).issubset({0, 255}), name
    assert image.mode == "RGBA", name


def write_pair(stem, source, force):
    validate_native(source, stem)
    native = OUT / f"{stem}_source.png"
    game = OUT / f"{stem}.png"
    if not force and (native.exists() or game.exists()):
        raise FileExistsError(f"{native} or {game} already exists; pass --force to rebuild")
    enlarged = source.resize((source.width * SCALE, source.height * SCALE),
                              Image.Resampling.NEAREST)
    # Verify the export still contains aligned, exact 2x2 pixels.
    for y in range(source.height):
        for x in range(source.width):
            rgba = source.getpixel((x, y))
            assert all(enlarged.getpixel((x * SCALE + dx, y * SCALE + dy)) == rgba
                       for dx in range(SCALE) for dy in range(SCALE))
    source.save(native)
    enlarged.save(game)
    print(f"{stem}: {source.size} native -> {enlarged.size} world")


def build(force=False, only=None):
    # Each 48x48 source module is a contiguous 3x3 TileSet group. The atlas
    # layout starts with 3 columns x 2 rows of complete modules; row-major TileSet
    # module origins are (0,0), (3,0), (6,0), (0,3), (3,3), (6,3).
    floor = atlas(3, 3, {
        (0, 0): floor_quiet(),
        (1, 0): floor_quiet_b(),
        (2, 0): floor_a(),
        (0, 1): floor_b(),
        (1, 1): floor_worn(),
        (2, 1): floor_wet(),
        (0, 2): floor_quiet_c(),
        (1, 2): floor_quiet_d(),
        (2, 2): floor_quiet_c(),
    })
    walls = atlas(2, 1, {(0, 0): wall(), (1, 0): wall(False)})
    border = wall_border()
    water, mask = water_and_mask()
    edges = decor()
    shore = shore_overlay()
    images = (
        ("courtyard_floor_macro", floor),
        ("courtyard_wall_macro", walls),
        ("courtyard_wall_border", border),
        ("courtyard_water_macro", water),
        ("courtyard_water_reflection_macro", mask),
        ("courtyard_edge_decor", edges),
        ("courtyard_water_shore", shore),
    )
    if only is not None:
        images = tuple((stem, image) for stem, image in images if stem == only)
        if not images:
            raise ValueError(f"Unknown atlas: {only}")
    # Refuse the whole batch before writing anything if any destination exists.
    preview_path = OUT / "courtyard_module_assembly_preview.png" if only is None else None
    if not force:
        occupied = [str(OUT / f"{stem}{suffix}.png")
                    for stem, _ in images for suffix in ("_source", "")
                    if (OUT / f"{stem}{suffix}.png").exists()]
        if preview_path is not None and preview_path.exists():
            occupied.append(str(preview_path))
        if occupied:
            raise FileExistsError("Existing output; use --force: " + ", ".join(occupied))
    for stem, image in images:
        write_pair(stem, image, force)

    if only is not None:
        return

    # Assembly preview is QA only, never a game background. Keep exact grid.
    preview = Image.new("RGBA", (240, 192), P["void"])
    for x, tile in enumerate((floor_quiet(), floor_quiet_b(), floor_a(), floor_b(),
                              floor_worn())):
        preview.alpha_composite(tile, (x * 48, 48))
    for x, tile in enumerate((floor_quiet_b(), floor_quiet(), floor_quiet_b(),
                              floor_quiet(), floor_quiet_b())):
        preview.alpha_composite(tile, (x * 48, 96))
    for x, tile in enumerate((floor_wet(), floor_quiet_b(), floor_quiet(),
                              floor_b(), floor_quiet())):
        preview.alpha_composite(tile, (x * 48, 144))
    for x, tile in enumerate((wall(False), wall(), wall(False), wall(), wall(False))):
        preview.alpha_composite(tile, (x * 48, 0))
    preview.resize((480, 384), Image.Resampling.NEAREST).save(preview_path)
    print("QA preview only:", preview_path.name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true",
                        help="rebuild and overwrite the exact named art outputs")
    parser.add_argument("--only", choices=("courtyard_floor_macro",
                       "courtyard_wall_macro", "courtyard_wall_border",
                       "courtyard_water_macro", "courtyard_water_reflection_macro",
                       "courtyard_edge_decor", "courtyard_water_shore"),
                        help="build just one atlas without touching other outputs")
    args = parser.parse_args()
    build(args.force, args.only)
