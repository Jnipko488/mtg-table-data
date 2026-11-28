import sys,subprocess,os,json
from PIL import Image, ImageOps
def ocr(path):
    im=Image.open(path).convert('RGB'); w,h=im.size
    bb=im.convert('RGBA').getbbox() if im.mode=='RGBA' else None
    box=im.crop((105,h-262,425,h-100)).resize((960,486),Image.LANCZOS)
    g=ImageOps.grayscale(box)
    if '_golden' in path: g=ImageOps.invert(g)
    g=g.point(lambda v: 255 if v>150 else 0) if '_golden' in path else g
    tmp='/tmp/ocr_'+os.path.basename(path)+'.png'; g.save(tmp)
    r=subprocess.run(['tesseract',tmp,'-','--psm','6'],capture_output=True,text=True).stdout
    return ' '.join(r.split())
if __name__=='__main__':
    for p in sys.argv[1:]: print(os.path.basename(p),'=>',ocr(p))
