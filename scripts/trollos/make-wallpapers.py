#!/usr/bin/env python3
"""TrollOS wallpapers: python3 scripts/trollos/make-wallpapers.py dark|light|pixel
Writes trollos-<variant>.png (3840×2160) and a small prev_trollos-<variant>.png into the current folder.
The splat shape is read from docs/trollos/splat-source.png."""
from pathlib import Path
import numpy as np, sys
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage
W,H = 3840,2160
src = np.asarray(Image.open(Path(__file__).resolve().parents[2] / 'docs/trollos/splat-source.png').convert('RGB')).astype(np.float32)/255
mask = (src[...,0]-np.maximum(src[...,1],src[...,2]))>0.25
mask = ndimage.binary_fill_holes(ndimage.binary_opening(mask,iterations=2))
sdf = ndimage.distance_transform_edt(~mask)-ndimage.distance_transform_edt(mask)
sdf = ndimage.gaussian_filter(sdf,1.5)
ys,xs = np.nonzero(mask); cy,cx=(ys.min()+ys.max())/2,(xs.min()+xs.max())/2
r_max = np.sqrt((ys-cy)**2+(xs-cx)**2).max()

def splat(size_px, ox, oy):
    """SDF in output pixels; splat circle diameter = size_px, centred at (ox,oy)."""
    scale = r_max/(size_px/2)
    yy,xx = np.mgrid[0:H,0:W].astype(np.float32)
    d = ndimage.map_coordinates(sdf,[cy+(yy-oy)*scale, cx+(xx-ox)*scale],order=1,mode='nearest')
    return d/scale
def cov(d,soft=1.0): return np.clip(0.5-d/soft,0,1)
def radial(c0,c1,c2,cxr=0.5,cyr=0.47,rr=0.75):
    yy,xx = np.mgrid[0:H,0:W].astype(np.float32)
    t = np.sqrt(((xx/W-cxr)*W/H)**2+(yy/H-cyr)**2)/rr
    t = np.clip(t,0,1)[...,None]
    c0,c1,c2=[np.array(c,np.float32)/255 for c in (c0,c1,c2)]
    return np.where(t<0.55, c0+(c1-c0)*(t/0.55), c1+(c2-c1)*((t-0.55)/0.45))
def hexc(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
def blur(a,s): return ndimage.gaussian_filter(a,s)
def noise(img,amt=0.012,seed=1):
    rng=np.random.default_rng(seed); return np.clip(img+rng.normal(0,amt,img.shape[:2])[...,None],0,1)
def save(img,name):
    Image.fromarray((np.clip(img,0,1)*255+0.5).astype(np.uint8)).save(name+'.png',optimize=True)
    Image.fromarray((np.clip(img,0,1)*255+0.5).astype(np.uint8)).resize((960,540),Image.LANCZOS).save('prev_'+name+'.png')

def body_grad(top,mid,bot,y0,y1):
    yy = np.mgrid[0:H,0:W][0].astype(np.float32)
    t = np.clip((yy-y0)/(y1-y0),0,1)[...,None]
    top,mid,bot=[np.array(hexc(c),np.float32)/255 for c in (top,mid,bot)]
    return np.where(t<0.55, top+(mid-top)*(t/0.55), mid+(bot-mid)*((t-0.55)/0.45))

which = sys.argv[1]
S = 980; ox,oy = W/2, H/2
if which in ('dark','light'):
    d = splat(S,ox,oy); a = cov(d,1.2)[...,None]
    body = body_grad('#FF4A50','#EC2730','#C9111B',oy-S/2,oy+S/2)
    if which=='dark':
        bg = radial(hexc('#1D1316'),hexc('#110E11'),hexc('#09080A'))
        glow = blur(cov(d,1.0),90)[...,None]*0.55 + blur(cov(d,1.0),24)[...,None]*0.35
        img = bg + glow*np.array([0.85,0.08,0.10])
        sh = blur(cov(splat(S,ox,oy+14),1),18)[...,None]*0.45
        img = img*(1-sh)
    else:
        bg = radial(hexc('#F7F1EE'),hexc('#EFE6E2'),hexc('#E2D6D2'))
        sh = blur(cov(splat(S,ox+10,oy+26),1),34)[...,None]*0.22
        img = bg*(1-sh*np.array([0.55,0.75,0.75]))
    # inner rim highlight / bevel
    rim = np.clip(1-np.abs(d+6)/6,0,1)*(blur(d,3)<0)
    gy = np.gradient(blur(d,6),axis=0)
    hi = (rim*np.clip(gy,0,1))[...,None]*0.35
    lo = (rim*np.clip(-gy,0,1))[...,None]*0.25
    b = np.clip(body + hi - lo*body,0,1)
    img = img*(1-a)+b*a
    img = noise(img, 0.010 if which=='dark' else 0.006)
    save(img,'trollos-'+which)
elif which=='pixel':
    # big pixel-art splat: sample the mask on a coarse grid
    P = 24                               # one art pixel in screen px
    n = 44                               # art grid size
    bg = radial(hexc('#1A1215'),hexc('#100D10'),hexc('#08070A'))
    img = bg.copy()
    # faint pixel grid over the whole screen
    yy,xx = np.mgrid[0:H,0:W]
    grid = ((xx%P==0)|(yy%P==0))[...,None]
    img = img*(1-grid*0.18)+grid*0.18*np.array([0.11,0.08,0.09])
    gx0 = int((W/2 - n*P/2)//P*P); gy0 = int((H/2 - n*P/2)//P*P)
    d = splat(n*P*0.94, gx0+n*P/2, gy0+n*P/2)
    cells = d[gy0+P//2:gy0+n*P:P, gx0+P//2:gx0+n*P:P] < 0
    big = np.kron(cells, np.ones((P,P))).astype(np.float32)
    full = np.zeros((H,W),np.float32); full[gy0:gy0+n*P, gx0:gx0+n*P]=big
    glow = blur(full,70)[...,None]*0.5
    img = img + glow*np.array([0.8,0.07,0.1])
    # shade cells: lighter on top-left edges, darker bottom-right
    up = np.roll(cells,1,0); lf = np.roll(cells,1,1); dn=np.roll(cells,-1,0); rt=np.roll(cells,-1,1)
    col = np.zeros(cells.shape+(3,),np.float32)
    base=np.array(hexc('#E8262F'))/255; hl=np.array(hexc('#FF5A60'))/255; sd=np.array(hexc('#A80E18'))/255
    col[cells]=base
    col[cells & (~up | ~lf)] = hl
    col[cells & (~dn | ~rt)] = sd
    colbig = np.kron(col, np.ones((P,P,1)))
    fullc = np.zeros((H,W,3),np.float32); fullc[gy0:gy0+n*P, gx0:gx0+n*P]=colbig
    # drop shadow one art pixel down-right
    shadow = np.zeros((H,W),np.float32); shadow[gy0+P:gy0+n*P+P, gx0+P:gx0+n*P+P]=big
    img = img*(1-shadow[...,None]*0.6)
    img = img*(1-full[...,None])+fullc*full[...,None]
    # scanlines
    img = img*(1-((yy%4)<2)[...,None]*0.06)
    save(img,'trollos-pixel')
