"""Original 48x48 menu portrait for the same E fox as the world sprite.

All shapes are drawn in native integer pixels; no concept or world sprite is
read, reduced or traced. The shared palette preserves the character identity.
"""

from pathlib import Path
from PIL import Image, ImageDraw
from build_e_characters import P

ROOT = Path(__file__).resolve().parent
im = Image.new("RGBA", (48,48), (0,0,0,0))
d = ImageDraw.Draw(im)
def q(c,*pts): d.polygon(pts,fill=P[c])
def l(c,pts,w=1): d.line(pts,fill=P[c],width=w)
def p(c,x,y): d.point((x,y),fill=P[c])

# Unequal ears and small exposed shoulder guards anchor this to the world fox.
q("edge",(8,17),(6,9),(8,2),(10,1),(14,3),(19,11),(18,20))
q("fur_dark",(9,15),(8,7),(10,3),(13,5),(17,12),(16,18))
q("fur",(10,14),(9,7),(11,4),(15,9),(16,15))
q("inner_ear",(10,11),(10,7),(12,5),(14,10),(14,13))
q("edge",(28,16),(33,6),(38,1),(41,4),(42,14),(39,21),(32,19))
q("fur_dark",(30,15),(34,7),(38,3),(40,5),(40,15),(37,19))
q("fur",(32,14),(35,7),(38,4),(39,6),(39,15),(35,17))
q("inner_ear",(35,12),(36,7),(38,5),(39,9),(38,14))

# Bust behind the face: small steel facets, ample orange neck and red cloth.
q("edge",(10,35),(17,33),(34,34),(40,38),(44,47),(4,47),(6,40))
q("steel_dark",(5,43),(10,38),(15,39),(15,47),(4,47))
q("steel",(6,43),(10,39),(13,40),(13,45),(6,46))
q("steel_lit",(8,41),(10,40),(12,41),(9,42))
q("steel_dark",(36,39),(40,39),(43,44),(43,47),(35,47))
q("steel",(37,40),(40,41),(42,44),(41,46),(36,44))
q("fur_dark",(18,37),(33,37),(35,45),(16,45))

# E's soft slanted forehead and clustered fur, open lower face for cheeks.
q("edge",(17,11),(22,10),(29,11),(35,14),(39,18),(41,22),
  (42,26),(44,28),(44,33),(41,36),(37,39),(30,41),
  (18,41),(12,39),(7,35),(4,32),(5,28),(5,23),(8,17),(12,14))
q("fur_dark",(17,12),(23,11),(29,12),(35,15),(39,19),(40,23),
  (42,28),(42,33),(37,37),(30,40),(18,40),(11,37),
  (6,32),(6,26),(8,19),(12,15))
q("fur",(16,14),(23,12),(29,13),(34,15),(38,19),(39,25),
  (40,30),(37,35),(29,38),(19,38),(12,35),(8,31),
  (7,26),(9,20),(12,17))
q("fur_lit",(16,15),(22,13),(28,14),(32,16),(36,20),(37,25),
  (35,30),(31,32),(19,32),(13,29),(10,24),(12,19))
q("fur_peak",(18,15),(22,13),(27,14),(29,16),(26,17),(20,16))
q("fur_dark",(34,19),(38,21),(39,27),(37,31),(35,26))
p("fur_peak",20,12); p("fur_lit",21,11)

# A left lobe with two fur points and a shorter, higher right lobe. Orange
# channels run down between them, avoiding a uniform horizontal white band.
q("cream_dark",(5,27),(9,26),(13,28),(17,29),(20,33),(19,37),
  (15,39),(10,36),(7,34),(4,32),(6,30))
q("cream",(6,28),(10,27),(13,29),(16,30),(18,34),(17,37),
  (12,37),(8,33))
q("cream_lit",(7,29),(10,28),(14,30),(15,33),(13,35),(9,32))
p("cream_lit",4,30); p("cream",5,33)
q("cream_dark",(31,31),(34,28),(39,26),(43,27),(45,30),
  (43,33),(40,36),(35,39),(30,38))
q("cream",(32,31),(35,28),(40,27),(43,29),(41,33),(37,37),(32,37))
q("cream_lit",(34,30),(38,28),(42,29),(40,32),(36,35))
p("cream_lit",44,29); p("cream",43,34)
q("fur",(17,28),(20,30),(19,33),(17,31))
q("fur",(32,27),(34,28),(31,32),(30,30))
q("fur",(19,29),(23,30),(24,34),(21,35),(18,32))
q("cream_dark",(22,33),(26,31),(31,31),(36,33),(35,37),
  (30,39),(24,39),(21,36))
q("cream",(24,33),(27,32),(32,32),(35,34),(34,37),
  (29,38),(25,37),(23,35))
q("cream_lit",(26,33),(29,32),(33,33),(34,35),(30,37),(26,36))

# Eyes share the world sprite's slanted upper lids and single white glints.
l("fur_dark",[(13,22),(16,21),(19,22)])
q("eye",(15,24),(17,23),(19,24),(20,27),(18,29),(16,28))
q("cream_lit",(16,24),(18,24),(19,26),(18,28),(16,27))
q("iris",(16,25),(19,25),(19,27),(17,28))
l("eye",[(18,26),(18,28)])
p("cream_white",17,25)
l("fur_dark",[(31,21),(34,20),(37,23)])
q("eye",(32,23),(34,22),(36,23),(36,27),(34,29),(32,27))
q("cream_lit",(33,23),(35,23),(35,27),(33,27))
q("iris",(32,24),(35,24),(35,27),(33,28))
l("eye",[(34,25),(34,28)])
p("cream_white",33,24)

# Short rightward muzzle, tiny black nose and quiet, confident smile.
q("eye",(30,32),(32,32),(33,33),(32,34),(30,34))
p("steel_dark",30,32)
l("deep",[(31,35),(30,37),(28,38),(26,37)])
p("fur_dark",25,36)

# Diagonal scarf folds, rather than a rectangular neck band.
q("scarf_dark",(12,40),(18,41),(28,41),(37,39),(40,41),
  (39,44),(32,47),(21,47),(12,45),(10,42))
q("scarf",(12,41),(19,42),(29,43),(37,40),(38,42),
  (33,45),(23,46),(14,43))
l("scarf_lit",[(14,41),(20,43),(29,44),(35,42)])
q("scarf_dark",(10,42),(14,45),(17,47),(7,47),(8,45))
l("scarf_lit",[(10,44),(12,46)])

assert set(im.tobytes()[3::4]) <= {0,255}
im.save(ROOT/"e_fox_menu_portrait_native_48.png")
for scale in (2,4):
    im.resize((48*scale,48*scale),Image.Resampling.NEAREST).save(
        ROOT/f"e_fox_menu_portrait_review{scale}x.png")
