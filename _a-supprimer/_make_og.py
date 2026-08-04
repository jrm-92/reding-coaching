#!/usr/bin/env python3
# Génère la carte Open Graph (1200x630) : "COACH RUNNING / TOUS NIVEAUX"
import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
ORANGE = (255, 107, 53)
WHITE = (255, 255, 255)
FONT_DIR = "/usr/share/fonts/truetype/lato/"
f_title = lambda s: ImageFont.truetype(FONT_DIR + "Lato-BlackItalic.ttf", s)
f_bold  = lambda s: ImageFont.truetype(FONT_DIR + "Lato-Bold.ttf", s)

# --- Fond : dégradé vertical navy (près du noir en haut -> navy en bas) ---
top = np.array([7, 11, 18], float)
bot = np.array([11, 24, 42], float)
grad = (top[None, :] + (bot - top)[None, :] * (np.linspace(0, 1, H)[:, None]))
bg = np.repeat(grad[:, None, :], W, axis=1).astype(np.uint8)
img = Image.fromarray(bg, "RGB")

# --- Photo à droite, fondu diagonal vers le navy ---
photo = Image.open("photo_10k_jo.webp").convert("RGB")
pw = 640
scale = pw / photo.width
photo = photo.resize((pw, int(photo.height * scale)), Image.LANCZOS)
photo = photo.crop((0, 0, pw, H))
photo = Image.fromarray((np.asarray(photo, float) * 0.8).astype(np.uint8), "RGB")  # assombrie
px0 = W - pw  # 560
# masque alpha diagonal (le navy occupe une large bande à gauche)
xs = np.arange(W)[None, :]
ys = np.arange(H)[:, None]
edge = 612 + 120 * (ys / H)     # bord du fondu (plus à droite en bas)
fade = 150.0
alpha = np.clip((xs - edge) / fade, 0, 1)
mask = Image.fromarray((alpha * 255).astype(np.uint8), "L")
photo_full = Image.new("RGB", (W, H), (0, 0, 0))
photo_full.paste(photo, (px0, 0))
img = Image.composite(photo_full, img, mask)

draw = ImageDraw.Draw(img)

# --- Logo REDING RUNNING (haut gauche) ---
logo = Image.open("logo_running_orange.png").convert("RGBA")
lw = 250
logo = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
img.paste(logo, (60, 46), logo)

# --- Titre : COACH RUNNING (blanc) / TOUS NIVEAUX (orange) ---
def text_tracked(x, y, s, font, fill, track=2):
    for ch in s:
        draw.text((x, y), ch, font=font, fill=fill)
        x += draw.textlength(ch, font=font) + track

tf = f_title(74)
text_tracked(64, 238, "COACH RUNNING", tf, WHITE, 2)
text_tracked(64, 324, "TOUS NIVEAUX", tf, ORANGE, 2)

# --- Filet accent orange ---
draw.rectangle([68, 430, 68 + 92, 430 + 6], fill=ORANGE)

# --- Sous-titre + URL ---
draw.text((68, 470), "Suivi à distance  ·  Coaching terrain", font=f_bold(30), fill=WHITE)
draw.text((68, 552), "reding-running.fr", font=f_bold(28), fill=ORANGE)

img.save("og_preview.jpg", quality=90)
print("OK -> og_preview.jpg", img.size)
