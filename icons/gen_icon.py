#!/usr/bin/env python3
"""ACE Player Passport — Icon Generator v5"""
import math, os
from PIL import Image, ImageDraw, ImageFont

DIDOT   = '/System/Library/Fonts/Supplemental/Didot.ttc'
HELV    = '/System/Library/Fonts/Helvetica.ttc'
TIMES   = '/System/Library/Fonts/Times.ttc'
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

BG    = (10, 18, 38)
CREAM = (238, 228, 205)
GOLD  = (201, 168, 76)


def draw_tennis_ball(draw, cx, cy, r):
    for dy in range(-r, r+1):
        for dx in range(-r, r+1):
            d = math.sqrt(dx*dx + dy*dy)
            if d <= r:
                t = d / r
                g = int(190 - 20*t)
                draw.point((cx+dx, cy+dy), fill=(g, g+8, int(75-25*t)))
    sw = max(2, r//15)
    pts1, pts2 = [], []
    for a in range(-90, 91, 2):
        rad = math.radians(a)
        ox = r * 0.36 * math.cos(rad)
        y  = cy + r * math.sin(rad)
        pts1.append((cx + ox, y))
        pts2.append((cx - ox, y))
    draw.line(pts1, fill=(250, 255, 245), width=sw)
    draw.line(pts2, fill=(250, 255, 245), width=sw)
    # highlight
    hx, hy, hr = cx-r//3, cy-r//3, r//4
    for dy in range(-hr, hr+1):
        for dx in range(-hr, hr+1):
            if dx*dx+dy*dy <= hr*hr:
                t = math.sqrt(dx*dx+dy*dy)/hr
                draw.point((hx+dx, hy+dy), fill=(255, 255, int(200*(1-t)+180)))


def make_icon(size):
    S    = size * 2
    img  = Image.new('RGBA', (S, S), BG+(255,))
    draw = ImageDraw.Draw(img)

    # Rounded corners mask
    cr = S // 9
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S-1, S-1], radius=cr, fill=255)
    img.putalpha(mask)

    # ── "A" — sized so it fits comfortably with padding ──
    font_size_A = int(S * 0.46)
    try:
        fA = ImageFont.truetype(DIDOT, font_size_A, index=1)
    except:
        fA = ImageFont.truetype(DIDOT, font_size_A, index=0)

    bbox_A = draw.textbbox((0, 0), "A", font=fA)
    aw = bbox_A[2] - bbox_A[0]
    ah = bbox_A[3] - bbox_A[1]

    # Horizontal center; top of glyph at 8% from top
    ax = (S - aw)//2 - bbox_A[0]
    ay = int(S * 0.08) - bbox_A[1]

    draw.text((ax, ay), "A", font=fA, fill=CREAM)

    # Crossbar at ~50% of glyph height
    crossbar_y  = ay + bbox_A[1] + int(ah * 0.50)
    crossbar_cx = S // 2

    # ── Tennis ball ──
    ball_r  = int(S * 0.075)
    ball_cx = crossbar_cx
    ball_cy = crossbar_y
    draw_tennis_ball(draw, ball_cx, ball_cy, ball_r)

    # ── Gold swoosh ──
    swoosh_r  = int(ball_r * 2.0)
    sw_cx     = ball_cx - int(ball_r * 0.05)
    sw_cy     = ball_cy + int(ball_r * 0.10)
    start_ang, end_ang, n = 210, 370, 140
    pts = []
    for i in range(n+1):
        t   = i/n
        ang = math.radians(start_ang + (end_ang-start_ang)*t)
        pts.append((sw_cx + swoosh_r*math.cos(ang),
                    sw_cy + swoosh_r*math.sin(ang)))

    max_sw = max(5, int(S*0.019))
    min_sw = max(1, int(S*0.003))
    for i in range(len(pts)-1):
        t  = i/(len(pts)-1)
        tp = math.sin(math.pi*t)
        w  = max(1, int(min_sw + (max_sw-min_sw)*tp))
        draw.line([pts[i], pts[i+1]], fill=GOLD+(int(160+95*tp),), width=w)

    # ── Divider line ──
    A_bottom = ay + bbox_A[1] + ah
    line_y   = A_bottom + int(S * 0.012)
    line_w   = int(S * 0.46)
    lx0      = (S - line_w)//2
    lh       = max(1, S//280)
    draw.rectangle([lx0, line_y, lx0+line_w, line_y+lh], fill=GOLD)

    # ── "ACE" ──
    font_size_ace = int(S * 0.125)
    try:
        fAce = ImageFont.truetype(DIDOT, font_size_ace, index=1)
    except:
        fAce = ImageFont.truetype(DIDOT, font_size_ace, index=0)

    bbox_ace = draw.textbbox((0,0), "ACE", font=fAce)
    ace_w    = bbox_ace[2]-bbox_ace[0]
    ace_x    = (S-ace_w)//2 - bbox_ace[0]
    ace_y    = line_y + lh + int(S*0.012) - bbox_ace[1]
    draw.text((ace_x, ace_y), "ACE", font=fAce, fill=CREAM)

    # ── "PLAYER • PASSPORT" ──
    font_size_sub = int(S * 0.042)
    try:
        fSub = ImageFont.truetype(HELV, font_size_sub)
    except:
        try:
            fSub = ImageFont.truetype(TIMES, font_size_sub)
        except:
            fSub = ImageFont.load_default()

    sub_txt  = "PLAYER  •  PASSPORT"
    bbox_sub = draw.textbbox((0,0), sub_txt, font=fSub)
    sub_w    = bbox_sub[2]-bbox_sub[0]
    sub_x    = (S-sub_w)//2 - bbox_sub[0]
    ace_bot  = ace_y + bbox_ace[3]
    sub_y    = ace_bot + int(S*0.010) - bbox_sub[1]
    draw.text((sub_x, sub_y), sub_txt, font=fSub, fill=GOLD)

    return img.resize((size, size), Image.LANCZOS)


if __name__ == '__main__':
    for sz, name in [(512, 'icon-512.png'), (192, 'icon-192.png'), (180, 'apple-touch-icon.png')]:
        icon = make_icon(sz)
        path = os.path.join(OUT_DIR, name)
        icon.save(path, 'PNG', optimize=True)
        print(f"✓ {name} ({sz}×{sz})")
    print("Done!")
