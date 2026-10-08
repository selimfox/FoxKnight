"""Hand-placed native-grid material study; no image resize/downsample input."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
P = {
    "ink": "#172230", "joint": "#202D3D", "deep": "#29394E",
    "shade": "#304258", "stone": "#3A4E64", "light": "#50667A",
    "edge": "#687F91", "glint": "#7F93A1", "moss0": "#28423F",
    "moss1": "#426359", "moss2": "#65816D",
}


def make(fill="joint", w=32, h=32):
    im = Image.new("RGBA", (w, h), P[fill])
    return im, ImageDraw.Draw(im)


def poly(d, points, color):
    d.polygon(points, fill=P[color])


def line(d, points, color, width=1):
    d.line(points, fill=P[color], width=width)


def rect(d, box, color):
    d.rectangle(box, fill=P[color])


def floor_a():
    """Four large dressed stones, deliberately crossing 16px cell divisions."""
    im, d = make()
    poly(d, [(0, 0), (18, 0), (20, 2), (19, 11), (16, 14), (0, 13)], "stone")
    poly(d, [(23, 0), (31, 0), (31, 15), (29, 17), (22, 16), (21, 13)], "shade")
    poly(d, [(0, 16), (14, 17), (16, 20), (15, 31), (0, 31)], "shade")
    poly(d, [(19, 19), (23, 18), (31, 19), (31, 31), (18, 31)], "stone")
    poly(d, [(0, 0), (18, 0), (19, 2), (16, 3), (0, 3)], "light")
    poly(d, [(23, 0), (31, 0), (31, 2), (24, 2)], "light")
    poly(d, [(0, 16), (14, 17), (13, 19), (0, 19)], "light")
    poly(d, [(19, 20), (23, 19), (30, 20), (29, 22), (18, 22)], "light")
    line(d, [(0, 1), (12, 1)], "edge")
    line(d, [(24, 1), (30, 1)], "edge")
    line(d, [(1, 17), (8, 17)], "edge")
    line(d, [(20, 20), (25, 20)], "edge")
    line(d, [(2, 12), (12, 13), (15, 13)], "deep")
    line(d, [(23, 15), (27, 16), (30, 15)], "deep")
    line(d, [(0, 30), (13, 30)], "deep")
    line(d, [(20, 30), (30, 30)], "deep")
    line(d, [(17, 5), (15, 7), (15, 9), (13, 10)], "deep")
    line(d, [(15, 9), (17, 11)], "deep")
    rect(d, (3, 7, 7, 8), "light")
    rect(d, (4, 22, 8, 23), "stone")
    return im


def floor_b():
    """Offset wider fractures and one cohesive seam-bound moss mass."""
    im, d = make()
    poly(d, [(0, 0), (12, 0), (14, 3), (13, 13), (0, 14)], "shade")
    poly(d, [(17, 0), (31, 0), (31, 10), (27, 14), (16, 13)], "stone")
    poly(d, [(0, 17), (9, 16), (12, 19), (11, 31), (0, 31)], "stone")
    poly(d, [(15, 17), (29, 16), (31, 19), (31, 31), (14, 31)], "shade")
    poly(d, [(0, 0), (11, 0), (13, 2), (11, 3), (0, 3)], "light")
    poly(d, [(17, 0), (31, 0), (31, 3), (18, 3)], "light")
    poly(d, [(0, 17), (8, 17), (11, 18), (9, 20), (0, 20)], "light")
    poly(d, [(16, 18), (29, 17), (31, 19), (27, 21), (15, 21)], "light")
    line(d, [(0, 1), (8, 1)], "edge")
    line(d, [(19, 1), (28, 1)], "edge")
    line(d, [(1, 18), (7, 18)], "edge")
    line(d, [(19, 18), (25, 18)], "edge")
    line(d, [(1, 13), (9, 13)], "deep")
    line(d, [(17, 12), (23, 13), (28, 12)], "deep")
    line(d, [(2, 30), (10, 30)], "deep")
    line(d, [(16, 30), (30, 30)], "deep")
    poly(d, [(26, 10), (29, 11), (28, 15), (24, 15)], "deep")
    line(d, [(25, 14), (22, 17), (23, 20)], "joint")
    line(d, [(22, 17), (19, 16)], "joint")
    poly(d, [(0, 29), (0, 24), (2, 24), (3, 21), (5, 23), (7, 23), (8, 27), (6, 31)], "moss0")
    poly(d, [(0, 28), (1, 25), (3, 25), (4, 23), (5, 25), (7, 25), (6, 29)], "moss1")
    rect(d, (1, 26, 2, 26), "moss2")
    rect(d, (4, 25, 5, 25), "moss2")
    return im


def wall():
    """Upper coping and front face occupy 32x32 native / 64x64 world."""
    im, d = make("ink")
    poly(d, [(0, 0), (31, 0), (31, 12), (29, 14), (0, 13)], "shade")
    poly(d, [(0, 0), (31, 0), (31, 4), (28, 5), (1, 5)], "edge")
    poly(d, [(1, 2), (28, 2), (27, 3), (2, 4)], "glint")
    poly(d, [(0, 6), (29, 6), (30, 9), (29, 11), (1, 11)], "stone")
    rect(d, (2, 7, 12, 8), "light")
    rect(d, (19, 8, 26, 8), "light")
    line(d, [(0, 13), (20, 13), (22, 14), (29, 14)], "ink", 2)
    poly(d, [(0, 16), (31, 16), (31, 31), (0, 31)], "deep")
    poly(d, [(0, 16), (31, 16), (31, 20), (27, 21), (0, 21)], "shade")
    line(d, [(0, 18), (31, 18)], "light")
    poly(d, [(0, 22), (17, 22), (18, 24), (18, 30), (0, 30)], "stone")
    poly(d, [(20, 22), (31, 21), (31, 30), (20, 30)], "shade")
    line(d, [(0, 23), (15, 23)], "light", 2)
    line(d, [(21, 23), (29, 23)], "light")
    line(d, [(18, 24), (18, 30)], "joint")
    line(d, [(0, 30), (31, 30)], "ink", 2)
    rect(d, (4, 26, 7, 26), "light")
    return im


def save(im, name):
    im.save(OUT / f"v3_{name}_source.png")
    im.resize((64, 64), Image.Resampling.NEAREST).save(OUT / f"v3_{name}_world.png")


def main():
    a, b, w = floor_a(), floor_b(), wall()
    for name, im in (("floor_a", a), ("floor_b", b), ("wall_section", w)):
        save(im, name)
        assert im.size == (32, 32)
        assert set(im.getchannel("A").getdata()) == {255}
        assert len(set(im.getdata())) <= len(P)
        print(f"{name}: 32x32 native; {len(set(im.getdata()))} opaque palette colors")
    preview = Image.new("RGBA", (160, 128), P["ink"])
    for x in range(5):
        preview.alpha_composite(w, (x * 32, 0))
    layout = ((0, 0, 1, 0, 0), (0, 1, 0, 0, 1), (1, 0, 0, 1, 0))
    for y, row in enumerate(layout, 1):
        for x, v in enumerate(row):
            preview.alpha_composite((a, b)[v], (x * 32, y * 32))
    preview.save(OUT / "v3_material_preview_native.png")
    for scale, name in ((2, "world"), (6, "inspection")):
        preview.resize((160 * scale, 128 * scale), Image.Resampling.NEAREST).save(
            OUT / f"v3_material_preview_{name}.png")


if __name__ == "__main__":
    main()
