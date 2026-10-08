from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
P = {
    'outline':'#30232b','deep':'#5c2b30','orange_shadow':'#a74727',
    'orange':'#df6e2f','orange_light':'#f68f3c','orange_top':'#ffad52',
    'ear_shadow':'#b66b46','ear_cream':'#f6d6a3','cream_shadow':'#cda77e',
    'cream':'#efcf9d','cream_light':'#fff0c5','cream_white':'#fff5d9',
    'eye':'#281e27','iris':'#6b342c','scarf_dark':'#492638',
    'scarf':'#772c42','scarf_light':'#a44956','steel_dark':'#46505d',
    'steel':'#8295a0','steel_light':'#bdc6bd',
}
im = Image.new('RGBA',(48,48),(0,0,0,0)); d = ImageDraw.Draw(im)
def poly(points,color): d.polygon(points,fill=P[color])
def px(x,y,color): d.point((x,y),fill=P[color])
def line(points,color,width=1): d.line(points,fill=P[color],width=width)

# Hand-authored native-grid clusters. The E concept is not sampled or scaled.
# Bust and asymmetrical shoulder armour.
poly([(9,38),(14,36),(35,36),(40,39),(44,45),(44,47),(3,47),(3,45)],'outline')
poly([(5,43),(9,40),(14,41),(15,47),(4,47)],'steel_dark')
poly([(5,44),(9,41),(13,42),(13,45),(7,45)],'steel')
poly([(7,42),(10,41),(12,42),(9,43)],'steel_light')
poly([(35,41),(40,40),(43,45),(43,47),(34,47)],'steel_dark')
poly([(37,41),(40,41),(42,44),(41,45),(36,44)],'steel')
line([(17,43),(18,47),(30,47),(31,43)],'steel_dark',2)

# Unequal high ears, their inner light and ear roots.
poly([(8,17),(7,9),(8,3),(10,1),(13,3),(17,8),(20,14),(17,19)],'outline')
poly([(9,15),(9,7),(10,4),(12,5),(16,10),(18,16)],'orange')
poly([(10,13),(10,7),(12,6),(15,11),(16,15)],'ear_shadow')
poly([(11,11),(11,8),(12,7),(14,10),(15,13)],'ear_cream')
poly([(30,14),(34,6),(38,2),(40,3),(42,7),(43,16),(39,20),(33,18)],'outline')
poly([(32,16),(35,8),(38,4),(40,6),(41,11),(41,16)],'orange')
poly([(35,14),(36,8),(38,6),(39,8),(40,13)],'ear_shadow')
poly([(36,12),(37,9),(38,7),(39,9),(39,12)],'ear_cream')

# Pear-shaped warm head with clustered fur and an asymmetric cheek silhouette.
poly([(17,12),(21,11),(25,12),(29,11),(34,13),(37,16),(40,18),
      (41,22),(42,24),(41,26),(44,29),(42,31),(42,34),(39,37),
      (34,39),(30,40),(18,40),(13,38),(9,36),(6,33),(5,31),
      (3,30),(5,27),(5,23),(7,19),(11,16),(14,16)],'outline')
poly([(17,13),(22,12),(25,13),(29,12),(34,14),(38,18),
      (40,22),(40,27),(42,30),(40,34),(35,37),(30,39),
      (18,39),(11,36),(7,32),(6,29),(7,23),(10,19),
      (14,17)],'orange_shadow')
poly([(15,16),(20,13),(27,13),(33,15),(37,18),(39,22),
      (39,29),(36,34),(31,37),(18,37),(11,34),(8,30),
      (8,23),(11,19)],'orange')
poly([(13,19),(17,16),(21,15),(29,15),(33,17),(36,20),
      (37,24),(35,28),(31,30),(13,27),(10,23)],'orange_light')
poly([(16,18),(20,15),(23,16),(26,15),(30,17),(28,18),
      (24,17),(21,19),(17,19)],'orange_top')
poly([(32,18),(36,20),(38,24),(38,27),(36,28),(35,23)],'orange_shadow')

# Two separate fluffy cheek lobes curl around the compact centre muzzle.
poly([(5,28),(8,27),(11,28),(13,27),(16,29),(18,31),
      (21,32),(21,36),(17,38),(11,36),(8,34),(6,32),
      (4,31),(7,30)],'cream_shadow')
poly([(6,29),(10,28),(14,29),(17,32),(20,33),(19,36),
      (15,37),(10,34),(7,31)],'cream')
poly([(7,29),(11,29),(15,31),(17,34),(14,35),(10,33)],'cream_light')
poly([(28,32),(31,30),(35,28),(39,27),(42,29),(44,30),
      (41,32),(42,34),(38,37),(32,39),(28,37)],'cream_shadow')
poly([(29,33),(32,30),(38,29),(41,30),(39,34),(35,37),
      (30,37)],'cream')
poly([(31,32),(35,30),(40,30),(38,33),(34,36),(31,35)],'cream_light')
poly([(18,33),(21,31),(26,30),(30,32),(32,36),
      (29,38),(23,39),(18,37)],'cream')
poly([(20,32),(23,31),(27,31),(30,33),(29,36),
      (24,37),(20,36)],'cream_light')
poly([(21,33),(24,32),(28,33),(28,35),(21,35)],'cream_white')
# Two orange fur points interrupt the lower cream field. They keep the cheek
# lobes attached to the muzzle without turning the face into a white band.
poly([(18,29),(20,30),(21,33),(19,32)],'orange')
poly([(31,29),(33,28),(32,31),(30,33),(29,31)],'orange')
px(20,31,'orange_light'); px(31,30,'orange_light')

# Compact alert eyes with upper lids, warm irises and single highlights.
line([(13,25),(15,23),(18,23),(20,25)],'orange_shadow')
poly([(15,25),(16,24),(18,24),(19,25),(19,28),(17,29),(15,28)],'outline')
poly([(16,25),(18,25),(18,27),(17,28),(16,27)],'iris')
px(16,25,'cream_white')
line([(30,25),(32,23),(35,24),(37,26)],'orange_shadow')
poly([(31,25),(33,24),(35,25),(36,27),(35,29),(32,29),(31,27)],'outline')
poly([(32,25),(34,25),(35,27),(34,28),(32,27)],'iris')
px(33,25,'cream_white')
line([(14,22),(17,21),(19,22)],'orange_shadow')
line([(31,22),(34,21),(36,23)],'orange_shadow')

# Short slightly offset muzzle, not a centred geometric triangle.
poly([(25,32),(27,32),(28,33),(27,34),(25,34),(24,33)],'eye')
px(25,32,'steel_dark')
line([(26,34),(26,35),(24,36),(22,36)],'deep')
px(21,35,'orange_shadow'); px(29,35,'orange_shadow')

# Burgundy scarf folds around neck and falls over left shoulder.
poly([(12,38),(17,39),(23,40),(31,39),(37,37),(40,40),
      (37,44),(31,46),(20,47),(13,44),(10,41)],'scarf_dark')
poly([(12,39),(19,41),(27,42),(35,40),(38,39),(37,42),
      (32,44),(23,45),(15,43)],'scarf')
line([(14,40),(21,42),(29,42),(35,40)],'scarf_light')
poly([(10,42),(13,44),(18,46),(16,47),(7,47),(8,45)],'scarf_dark')
line([(12,44),(15,46),(12,47)],'scarf_light')

assert set(im.tobytes()[3::4]) <= {0,255}
im.save(OUT/'fox_E_portrait_native_48.png')
for scale in (2,4):
    im.resize((48*scale,48*scale),Image.Resampling.NEAREST).save(
        OUT/f'fox_E_portrait_review_{scale}x.png')
