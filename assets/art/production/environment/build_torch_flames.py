"""Author four torch animation cels on a strict 16-pixel grid.

The native 16x16 sheet is the edit source. The 2x sheet is nearest-neighbour
only; neither vector rasterisation nor interpolated scaling is involved.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
INK = (48, 37, 42, 255)
EMBER = (173, 67, 36, 255)
ORANGE = (240, 127, 42, 255)
GOLD = (255, 190, 73, 255)
CORE = (255, 236, 157, 255)
IRON = (78, 80, 94, 255)
IRON_EDGE = (149, 148, 149, 255)

# Each tuple is a native-pixel row: left, right, palette. The bottom three
# rows remain rooted in the fire bowl; the shoulders and tips move by cel.
CELS = [
    [(7, 7, EMBER), (7, 8, ORANGE), (6, 8, EMBER), (7, 9, GOLD),
     (5, 9, ORANGE), (8, 9, ORANGE), (5, 10, ORANGE), (6, 10, GOLD), (8, 10, GOLD),
     (4, 11, EMBER), (5, 11, ORANGE), (6, 11, GOLD), (7, 11, CORE), (8, 11, GOLD), (9, 11, ORANGE),
     (4, 12, EMBER), (5, 12, ORANGE), (6, 12, GOLD), (7, 12, CORE), (8, 12, GOLD), (9, 12, ORANGE), (10, 12, EMBER),
     (4, 13, EMBER), (5, 13, ORANGE), (6, 13, GOLD), (7, 13, CORE), (8, 13, GOLD), (9, 13, ORANGE), (10, 13, EMBER),
     (5, 14, EMBER), (6, 14, ORANGE), (7, 14, GOLD), (8, 14, ORANGE), (9, 14, EMBER)],
    [(6, 6, EMBER), (6, 7, ORANGE), (7, 7, EMBER), (6, 8, GOLD),
     (5, 9, ORANGE), (6, 9, GOLD), (8, 9, ORANGE), (4, 10, EMBER), (5, 10, ORANGE), (6, 10, GOLD), (8, 10, GOLD),
     (4, 11, EMBER), (5, 11, ORANGE), (6, 11, GOLD), (7, 11, CORE), (8, 11, GOLD), (9, 11, ORANGE),
     (4, 12, EMBER), (5, 12, ORANGE), (6, 12, GOLD), (7, 12, CORE), (8, 12, GOLD), (9, 12, ORANGE), (10, 12, EMBER),
     (4, 13, EMBER), (5, 13, ORANGE), (6, 13, GOLD), (7, 13, CORE), (8, 13, GOLD), (9, 13, ORANGE), (10, 13, EMBER),
     (5, 14, EMBER), (6, 14, ORANGE), (7, 14, GOLD), (8, 14, ORANGE), (9, 14, EMBER)],
    [(8, 5, EMBER), (8, 6, ORANGE), (7, 7, GOLD), (8, 7, GOLD),
     (7, 8, ORANGE), (8, 8, GOLD), (9, 8, EMBER), (5, 9, EMBER), (7, 9, GOLD), (8, 9, CORE),
     (5, 10, ORANGE), (6, 10, GOLD), (7, 10, CORE), (8, 10, GOLD), (9, 10, ORANGE),
     (4, 11, EMBER), (5, 11, ORANGE), (6, 11, GOLD), (7, 11, CORE), (8, 11, GOLD), (9, 11, ORANGE),
     (4, 12, EMBER), (5, 12, ORANGE), (6, 12, GOLD), (7, 12, CORE), (8, 12, GOLD), (9, 12, ORANGE), (10, 12, EMBER),
     (4, 13, EMBER), (5, 13, ORANGE), (6, 13, GOLD), (7, 13, CORE), (8, 13, GOLD), (9, 13, ORANGE), (10, 13, EMBER),
     (5, 14, EMBER), (6, 14, ORANGE), (7, 14, GOLD), (8, 14, ORANGE), (9, 14, EMBER)],
    [(7, 6, EMBER), (7, 7, ORANGE), (8, 7, GOLD), (7, 8, GOLD),
     (6, 8, EMBER), (8, 8, GOLD), (5, 9, ORANGE), (6, 9, GOLD), (7, 9, CORE), (9, 9, ORANGE),
     (4, 10, EMBER), (5, 10, ORANGE), (6, 10, GOLD), (7, 10, CORE), (8, 10, GOLD), (9, 10, ORANGE),
     (4, 11, EMBER), (5, 11, ORANGE), (6, 11, GOLD), (7, 11, CORE), (8, 11, GOLD), (9, 11, ORANGE),
     (4, 12, EMBER), (5, 12, ORANGE), (6, 12, GOLD), (7, 12, CORE), (8, 12, GOLD), (9, 12, ORANGE), (10, 12, EMBER),
     (4, 13, EMBER), (5, 13, ORANGE), (6, 13, GOLD), (7, 13, CORE), (8, 13, GOLD), (9, 13, ORANGE), (10, 13, EMBER),
     (5, 14, EMBER), (6, 14, ORANGE), (7, 14, GOLD), (8, 14, ORANGE), (9, 14, EMBER)],
]


def main() -> None:
    native = Image.new("RGBA", (64, 20), (0, 0, 0, 0))
    for frame, pixels in enumerate(CELS):
        for x, y, color in pixels:
            native.putpixel((frame * 16 + x, y), color)
        # Draw the metal cup on the same grid and cel as the fire. The first
        # flame row touches this rim, so there cannot be a floating gap.
        for y, left, right, color in [
            (15, 4, 11, EMBER), (16, 2, 13, INK),
            (17, 3, 12, IRON_EDGE), (18, 4, 11, IRON), (19, 5, 10, INK),
        ]:
            for x in range(left, right + 1):
                native.putpixel((frame * 16 + x, y), color)
        for x in range(5, 11):
            native.putpixel((frame * 16 + x, 16), GOLD)
    native.save(ROOT / "torch_flame_frames_source.png")
    native.resize((128, 40), Image.Resampling.NEAREST).save(ROOT / "torch_flame_frames.png")


if __name__ == "__main__":
    main()
