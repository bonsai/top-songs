import numpy as np
from PIL import Image, ImageDraw, ImageFont
from moviepy.editor import ImageSequenceClip
import os

FPS = 24
DURATION = 60
VW, VH = 720, 1280
TOTAL = FPS * DURATION

DR = 7
DS = 18
PD = 18
COLS = 36
ROWS = 25
GAP = COLS
BW = (COLS - 1) * DS + 2 * PD + 2 * DR
BH = (ROWS - 1) * DS + 2 * PD + 2 * DR

ARTISTS = [
    "masuzoe3","火星人から来た人","SANPODANCERS","Manamin",
    "表現モシクハ","ningen","ともちん","時空狂5moyo",
    "ダンボール","西山亮","おしゃれどろぼう"
]
COLORS = [
    (255,0,65),(255,136,0),(255,204,0),(85,255,0),
    (0,255,204),(0,65,255),(170,0,255),(255,65,255),
    (255,105,180),(0,255,65),(255,102,0)
]
N = len(ARTISTS)
ART_SEC = DURATION / N
PAUSE = 0.8

FP = "C:/Windows/Fonts/msgothic.ttc"

def text_to_cols(text, height):
    fs = int(height * 0.85)
    try: font = ImageFont.truetype(FP, fs)
    except: font = ImageFont.load_default()
    tmp = Image.new('L', (1,1), 0)
    bb = ImageDraw.Draw(tmp).textbbox((0,0), text, font=font)
    tw = max(1, min(bb[2]-bb[0], 4000))
    img = Image.new('L', (tw+4, height), 0)
    ImageDraw.Draw(img).text((-bb[0], -bb[1]), text, fill=255, font=font)
    a = np.array(img)
    return [[bool(a[y,x]>128) for y in range(height)] for x in range(tw)]

# Pre-build base image (unlit dots)
base = Image.new('RGB', (BW, BH), (8,8,8))
bd = ImageDraw.Draw(base)
for ci in range(COLS):
    cx = PD + DR + ci * DS
    for ri in range(ROWS):
        cy = PD + DR + ri * DS
        bd.ellipse([cx-DR, cy-DR, cx+DR, cy+DR], fill=(30,30,30))

def render_frame(columns, sp, color):
    img = base.copy()
    d = ImageDraw.Draw(img)
    total = len(columns) + GAP if columns else 0
    sp = sp % total if total else 0
    base_idx = int(sp)
    # glow layer (RGBA overlay composited at end)
    glow_img = Image.new('RGBA', (BW, BH), (0,0,0,0))
    gd = ImageDraw.Draw(glow_img)
    for ci in range(COLS):
        cx = PD + DR + ci * DS
        idx = base_idx + ci
        if columns and idx < len(columns):
            col = columns[idx]
            for ri in range(ROWS):
                if ri < len(col) and col[ri]:
                    cy = PD + DR + ri * DS
                    # glow rings
                    for gr, ga in [(12,18),(8,35),(4,55)]:
                        gd.ellipse([cx-gr, cy-gr, cx+gr, cy+gr], fill=(*color, ga))
                    # bright dot
                    d.ellipse([cx-DR, cy-DR, cx+DR, cy+DR], fill=color)
                    # highlight
                    hr = DR // 2
                    d.ellipse([cx-hr, cy-hr, cx+hr, cy+hr], fill=(255,255,255))
    img = Image.alpha_composite(img.convert('RGBA'), glow_img).convert('RGB')
    return img

def to_vid(img):
    s = VW / BW
    nw, nh = int(BW*s), int(BH*s)
    b = img.resize((nw, nh), Image.LANCZOS)
    vf = Image.new('RGB', (VW, VH), (3,3,3))
    y0 = (VH - nh) // 2
    vf.paste(b, ((VW-nw)//2, y0))
    arr = np.array(vf, dtype=np.int16)
    for y in range(60):
        a = int(160 * (1 - y/60))
        arr[y] = np.maximum(arr[y] - a, 0)
        arr[VH-1-y] = np.maximum(arr[VH-1-y] - a, 0)
    return Image.fromarray(arr.astype(np.uint8))

print("Pre-rendering text...")
cols_list = []
for name in ARTISTS:
    c = text_to_cols(name, ROWS)
    cols_list.append(c)
    print(f"  {name}: {len(c)} cols")

print(f"\nRendering {TOTAL} frames...")
frames = []
for fi in range(TOTAL):
    t = fi / FPS
    ai = int(t / ART_SEC) % N
    ts = t - ai * ART_SEC
    coll = cols_list[ai] if ts >= PAUSE else []
    spd = 0.35
    sp = ((ts - PAUSE) * FPS * spd) % (len(coll) + GAP) if coll and ts >= PAUSE else 0
    board = render_frame(coll, sp, COLORS[ai])
    frames.append(np.array(to_vid(board)))
    if (fi+1) % 200 == 0:
        pct = int((fi+1)/TOTAL*100)
        print(f"  {fi+1}/{TOTAL} ({pct}%)")

print("\nWriting video...")
out = os.path.expanduser("~/Desktop/led-board-showcase.mp4")
ImageSequenceClip(frames, fps=FPS).write_videofile(
    out, codec="libx264", audio=False,
    ffmpeg_params=["-pix_fmt","yuv420p","-preset","medium","-crf","18"])
print(f"\nDone! {out}")
