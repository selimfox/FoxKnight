"""Hand-placed shallow-water and edge-decoration native pixel forms.

The 48px water study is a 3x3 group of editable 16px source cells; the 64x32
decor atlas has 4x2 independent 16px cells. No high-resolution input is used.
"""
from PIL import Image, ImageDraw
from pixel_stone_forms import P

W = {"shore":"#435B68", "wet":"#36515E", "deep":"#254354",
     "body":"#315869", "lift":"#467383", "moon":"#739DA6",
     "glint":"#9CC0BD", "foam":"#587F87", "rubble":"#334456"}


def water_and_mask():
    """Shore pixels and reflective water pixels are separate binary masks."""
    outer = Image.new("L", (48,48), 0)
    od = ImageDraw.Draw(outer)
    od.polygon([(9,0),(39,0),(43,3),(47,11),(47,30),(44,37),
                (36,41),(31,46),(11,47),(3,43),(0,32),(0,11),(4,4)], fill=255)
    inner = Image.new("L", (48,48), 0)
    md = ImageDraw.Draw(inner)
    md.polygon([(12,3),(36,3),(41,7),(45,13),(44,28),(40,35),
                (34,39),(29,43),(13,44),(6,40),(3,31),(3,13),(7,7)], fill=255)
    # Native palette clusters: dark bed, shallow surface, three broken moon marks.
    color = Image.new("RGBA", (48,48), W["shore"])
    d = ImageDraw.Draw(color)
    d.polygon([(5,14),(13,4),(36,4),(44,13),(44,28),(40,35),
               (34,39),(29,44),(13,44),(4,32)], fill=W["deep"])
    d.polygon([(8,12),(18,6),(39,8),(42,16),(38,22),(17,24),(6,21)], fill=W["body"])
    d.polygon([(2,29),(9,23),(26,26),(39,23),(44,31),(38,37),
               (28,40),(11,40),(6,37)], fill=W["wet"])
    d.polygon([(6,15),(16,11),(27,11),(31,13),(25,16),(12,17)], fill=W["lift"])
    d.line([(10,13),(17,12),(21,13),(26,12)], fill=W["moon"], width=1)
    d.line([(12,15),(18,15)], fill=W["glint"])
    d.polygon([(28,29),(34,28),(39,30),(36,32),(28,32)], fill=W["lift"])
    d.line([(30,29),(35,29)], fill=W["moon"])
    d.line([(12,36),(17,34),(21,35)], fill=W["foam"])
    d.line([(24,38),(29,37)], fill=W["moon"])
    d.line([(4,24),(7,24)], fill=W["foam"])
    color.putalpha(outer)
    reflection = Image.new("RGBA", (48,48), (255,255,255,0))
    reflection.putalpha(inner)
    assert set(color.getchannel("A").getdata()) == {0,255}
    assert set(reflection.getchannel("A").getdata()) == {0,255}
    return color, reflection


def decor():
    atlas = Image.new("RGBA", (64,32), (0,0,0,0))
    # Each 16x16 cell is independently authorable and uses binary transparency.
    for col,row,kind in ((0,0,"rubble"),(1,0,"moss"),(2,0,"seam"),(3,0,"chips"),
                         (0,1,"damp"),(1,1,"vine"),(2,1,"rubble2"),(3,1,"spore")):
        im = Image.new("RGBA", (16,16), (0,0,0,0))
        d = ImageDraw.Draw(im)
        if kind == "rubble":
            d.polygon([(0,14),(3,12),(5,13),(8,9),(11,10),(15,14),(15,15),(0,15)], fill=P["under"])
            d.polygon([(6,12),(8,9),(11,10),(10,13)], fill=P["mid"])
            d.line([(7,10),(9,10)], fill=P["lit"])
        elif kind == "moss":
            d.polygon([(0,15),(1,10),(4,9),(5,6),(9,8),(11,12),(15,13),(15,15)], fill=P["moss0"])
            d.polygon([(2,13),(4,9),(7,9),(10,13),(14,14)], fill=P["moss1"])
            d.rectangle((5,9,7,9), fill=P["moss2"])
        elif kind == "seam":
            d.line([(0,8),(4,7),(7,9),(9,12),(13,13)], fill=P["joint"])
            d.rectangle((2,8,5,9), fill=P["under"])
            d.rectangle((10,12,12,12), fill=P["shade"])
        elif kind == "chips":
            d.polygon([(2,12),(5,11),(7,13),(9,12),(13,13),(14,15),(1,15)], fill=P["under"])
            d.line([(3,12),(5,12)], fill=P["lit"])
            d.rectangle((9,13,11,13), fill=P["mid"])
        elif kind == "damp":
            d.polygon([(0,15),(0,11),(3,9),(5,10),(8,8),(12,11),(15,10),(15,15)], fill=W["wet"])
            d.line([(3,11),(6,10),(8,11)], fill=W["shore"])
        elif kind == "vine":
            d.line([(8,0),(8,4),(6,7),(7,11),(5,14)], fill=P["moss0"], width=2)
            d.polygon([(7,4),(3,3),(4,7),(7,8)], fill=P["moss1"])
            d.polygon([(8,8),(12,7),(11,11),(7,12)], fill=P["moss1"])
            d.rectangle((4,4,5,4), fill=P["moss2"])
        elif kind == "rubble2":
            d.polygon([(1,15),(2,11),(6,10),(8,12),(12,9),(14,12),(15,15)], fill=P["shade"])
            d.line([(3,11),(5,10)], fill=P["lit"])
            d.line([(11,11),(13,10)], fill=P["mid"])
        else:
            d.rectangle((2,13,5,14), fill=P["moss0"])
            d.rectangle((5,11,8,12), fill=P["moss1"])
            d.rectangle((10,14,12,14), fill=P["moss0"])
            d.rectangle((6,11,7,11), fill=P["moss2"])
        atlas.alpha_composite(im, (col*16,row*16))
    assert set(atlas.getchannel("A").getdata()) == {0,255}
    return atlas


