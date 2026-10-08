"""Editable pixel UI master. Run with Pillow to regenerate native/ and export/ PNGs."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
NATIVE, EXPORT = ROOT / "native", ROOT / "export"
NATIVE.mkdir(exist_ok=True)
EXPORT.mkdir(exist_ok=True)
P = dict(void="#101520", seam="#171D2B", wall="#252D40", stone="#30394F",
         hi="#47546A", edge="#65748B", gd="#706344", gold="#B8A36C",
         gh="#D9C78C", ivory="#E7E1CE", disabled="#566071")

def make(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)

def rect(d, x, y, w, h, color):
    if w > 0 and h > 0:
        d.rectangle((x, y, x + w - 1, y + h - 1), fill=color)

def frame(d, x, y, w, h, a, b, c):
    rect(d, x, y, w, h, a)
    rect(d, x + 1, y + 1, w - 2, h - 2, b)
    rect(d, x + 2, y + 2, w - 4, h - 4, c)

def save(name, image):
    assert {alpha for _, alpha in image.getchannel("A").getcolors(256)} <= {0, 255}, name
    image.save(NATIVE / (name + ".png"), optimize=True)
    upscaled = image.resize((image.width * 2, image.height * 2), Image.Resampling.NEAREST)
    upscaled.save(EXPORT / (name + ".png"), optimize=True)
    assert Image.open(NATIVE / (name + ".png")).size == image.size
    assert Image.open(EXPORT / (name + ".png")).tobytes() == upscaled.tobytes()

def menu():
    im, d = make((480, 270))
    rect(d, 0, 0, 480, 270, P["void"])
    rect(d, 0, 0, 480, 33, P["seam"])
    rect(d, 0, 30, 480, 2, P["wall"])
    rect(d, 0, 229, 480, 41, P["seam"])
    rect(d, 0, 229, 480, 2, P["wall"])
    for x, y, w, h in [(0, 32, 67, 197), (413, 32, 67, 197),
                       (0, 66, 40, 130), (440, 66, 40, 130)]:
        rect(d, x, y, w, h, P["wall"])
    for y in range(36, 225, 18):
        for x in range(-12 if (y // 18) % 2 else 2, 480, 32):
            if x < 70 or x > 397:
                rect(d, x, y, 29, 1, P["hi"])
                rect(d, x + 29, y, 1, 15, P["seam"])
    rect(d, 75, 35, 330, 191, P["seam"])
    rect(d, 76, 36, 328, 189, P["void"])
    rect(d, 95, 31, 290, 1, P["hi"])
    rect(d, 95, 225, 290, 1, P["hi"])
    save("menu_base", im)

    im, d = make((480, 270))
    for x, side in [(78, 1), (402, -1)]:
        rect(d, x if side == 1 else x - 24, 37, 25, 2, P["edge"])
        rect(d, x if side == 1 else x - 1, 37, 2, 24, P["edge"])
        rect(d, x if side == 1 else x - 24, 223, 25, 2, P["edge"])
        rect(d, x if side == 1 else x - 1, 201, 2, 24, P["edge"])
    d.polygon([(234, 27), (237, 27), (245, 16), (248, 16), (240, 29), (237, 31)], fill=P["gh"])
    rect(d, 222, 31, 36, 1, P["gd"])
    rect(d, 230, 33, 20, 1, P["gd"])
    for x in [102, 374]:
        rect(d, x, 45, 2, 2, P["gd"])
        rect(d, x, 217, 2, 2, P["gd"])
    save("menu_ornaments", im)

def buttons():
    im, d = make((120, 135))
    variants = [(P["stone"], P["edge"], P["wall"], P["gd"]),
                (P["hi"], P["gold"], P["wall"], P["gh"]),
                (P["wall"], P["gh"], P["seam"], P["gold"]),
                (P["stone"], P["gh"], P["wall"], P["ivory"]),
                (P["wall"], P["disabled"], P["seam"], P["disabled"])]
    for i, (body, line, dark, accent) in enumerate(variants):
        y = i * 27
        frame(d, 0, y, 120, 27, dark, line, body)
        rect(d, 4, y + 4, 112, 1, P["edge"] if i < 4 else P["disabled"])
        rect(d, 4, y + 22, 112, 1, dark)
        for x in (8, 109): rect(d, x, y + 12, 3, 3, accent)
        if i == 2: rect(d, 5, y + 5, 110, 2, dark)
        if i == 3:
            rect(d, 2, y + 2, 116, 1, P["ivory"])
            rect(d, 2, y + 24, 116, 1, P["ivory"])
    save("button_states", im)

def panels():
    for name, accent in [("hud_panel_9slice", P["edge"]),
                         ("result_panel_9slice", P["gold"])]:
        im, d = make((32, 32))
        frame(d, 0, 0, 32, 32, P["seam"], accent, P["void"])
        rect(d, 3, 3, 26, 1, P["hi"])
        rect(d, 3, 28, 26, 1, P["wall"])
        rect(d, 3, 3, 1, 26, P["hi"])
        rect(d, 28, 3, 1, 26, P["wall"])
        for x in (5, 25):
            for y in (5, 25): rect(d, x, y, 2, 2, accent)
        save(name, im)
    im, d = make((260, 18))
    rect(d, 0, 2, 260, 14, P["seam"])
    rect(d, 1, 3, 258, 12, P["void"])
    rect(d, 3, 3, 254, 1, P["edge"])
    for x in (0, 257): rect(d, x, 0, 3, 18, P["hi"])
    save("hint_ribbon", im)
    im, d = make((168, 8))
    rect(d, 0, 3, 168, 1, P["gd"])
    rect(d, 75, 2, 18, 3, P["hi"])
    rect(d, 82, 0, 4, 7, P["gold"])
    save("result_divider", im)

def icons():
    im, d = make((16, 48))
    d.polygon([(3, 14), (5, 14), (12, 7), (14, 2), (12, 3), (8, 9)], fill=P["ivory"])
    rect(d, 2, 11, 7, 2, P["gold"])
    rect(d, 3, 12, 2, 3, P["gd"])
    d.polygon([(8, 18), (14, 24), (8, 30), (2, 24)], fill=P["edge"])
    d.polygon([(8, 20), (12, 24), (8, 28), (4, 24)], fill=P["void"])
    rect(d, 7, 23, 2, 2, P["ivory"])
    for x, y, w, h in [(3, 37, 9, 2), (2, 39, 2, 6), (4, 45, 8, 2),
                       (12, 40, 2, 5), (9, 35, 2, 4), (7, 37, 2, 2)]:
        rect(d, x, y, w, h, P["ivory"])
    save("icons_blade_target_retry", im)

DIGITS = ["111/101/101/101/111", "010/110/010/010/111",
          "111/001/111/100/111", "111/001/111/001/111",
          "101/101/111/001/001", "111/100/111/001/111",
          "111/100/111/101/111", "111/001/010/010/010",
          "111/101/111/101/111", "111/101/111/001/111"]
def digits():
    im, d = make((60, 9))
    for n, glyph in enumerate(DIGITS):
        for y, row in enumerate(glyph.split("/")):
            for x, bit in enumerate(row):
                if bit == "1": rect(d, n * 6 + x + 1, y + 2, 1, 1, P["ivory"])
    save("digits_0_to_9", im)

if __name__ == "__main__":
    menu()
    buttons()
    panels()
    icons()
    digits()
