"""Arte original vetorial parametrica; Pillow apenas rasteriza em alta resolucao."""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path
import struct, math, json, argparse
ROOT=Path(__file__).parent
THEMES={'Azul pervinca':('#8197FF','#243B72'), 'Branco':('#F4F5F7','#41454D'), 'Laranja':('#FF983E','#783C1F'), 'Menta':('#67D7AA','#215A48'), 'Violeta':('#B57AF2','#513174'), 'Vermelho e preto':('#F51D36','#151518'), 'Preto e vermelho':('#29292F','#F51D36')}
ROLES=['Arrow','Help','AppStarting','Wait','Crosshair','IBeam','NWPen','No','SizeNS','SizeWE','SizeNWSE','SizeNESW','SizeAll','UpArrow','Hand','Pin','Person']
def rgb(h): return tuple(bytes.fromhex(h.lstrip('#')))
def chunk(tag,b): return tag+struct.pack('<I',len(b))+b+(b'\0' if len(b)%2 else b'')
def curve(start,segments):
    pts=[start]; a=start
    for b,c,d in segments:
        for i in range(1,21):
            t=i/20; u=1-t
            pts.append(tuple(u**3*a[k]+3*u*u*t*b[k]+3*u*t*t*c[k]+t**3*d[k] for k in (0,1)))
        a=d
    return pts
POINTER=curve((9,5),[
 ((7,4),(5,6),(6,10)),((9,23),(13,41),(17,51)),
 ((18,54),(21,54),(23,50)),((26,40),(30,33),(47,31)),
 ((52,31),(53,28),(49,25)),((39,19),(19,9),(9,5))])
def render(role,size,face,edge,frame=0):
    scale=4; n=size*scale; f=n/64
    mask=Image.new('L',(n,n)); d=ImageDraw.Draw(mask)
    def poly(p): d.polygon([(round(x*f),round(y*f)) for x,y in p],fill=255)
    def line(p,w=4):
        q=[(round(x*f),round(y*f)) for x,y in p]; width=max(1,round(w*f))
        d.line(q,fill=255,width=width,joint='curve')
        for x,y in q: d.ellipse((x-width/2,y-width/2,x+width/2,y+width/2),fill=255)
    def oval(box,fill=255): d.ellipse(tuple(round(x*f) for x in box),fill=fill)
    hotspot=(32,32)
    if role in ('Arrow','Help','AppStarting','Pin','Person'):
        if role=='Arrow': poly(POINTER)
        else: poly([(x*.76,y*.76) for x,y in POINTER])
        hotspot=(7,6)
    if role=='Help':
        line([(40,35),(40,33),(44,30),(49,32),(49,37),(44,41),(44,44)],3); oval((42,48,46,52))
    if role=='Pin':
        oval((39,33,55,49)); poly([(40,44),(47,57),(54,44)]); oval((44,38,50,44),0)
    if role=='Person':
        oval((41,32,51,42)); line([(39,53),(40,46),(52,46),(54,53)],4)
    if role in ('Wait','AppStarting'):
        cx,cy,r=(32,32,18) if role=='Wait' else (47,46,10)
        for j in range(12):
            a=2*math.pi*j/12-math.pi/2
            val=int(50+205*((j-frame)%12)/11)
            x=cx+r*math.cos(a); y=cy+r*math.sin(a); z=3 if role=='Wait' else 2
            d.ellipse(((x-z)*f,(y-z)*f,(x+z)*f,(y+z)*f),fill=val)
    if role=='IBeam':
        line([(32,10),(32,54)],4); line([(22,10),(42,10)],4); line([(22,54),(42,54)],4)
    if role=='Crosshair':
        line([(32,8),(32,56)],2); line([(8,32),(56,32)],2)
    if role=='No':
        oval((11,11,53,53)); oval((17,17,47,47),0); line([(18,18),(46,46)],5)
    if role.startswith('Size'):
        dirs={'SizeNS':[(0,-1),(0,1)],'SizeWE':[(-1,0),(1,0)],'SizeNWSE':[(-.707,-.707),(.707,.707)],'SizeNESW':[(.707,-.707),(-.707,.707)],'SizeAll':[(0,-1),(0,1),(-1,0),(1,0)]}[role]
        for ux,uy in dirs:
            vx,vy=-uy,ux
            p=lambda a,b:(32+ux*a+vx*b,32+uy*a+vy*b)
            if role!='SizeAll': line([p(0,0),p(16,0)],5)
            poly([p(23,0),p(12,-8),p(12,8)])
    if role=='UpArrow':
        poly([(32,8),(17,27),(26,27),(26,53),(38,53),(38,27),(47,27)]); hotspot=(32,9)
    if role=='NWPen':
        poly([(13,49),(17,36),(43,10),(52,19),(26,45)]); line([(19,36),(26,43)],2); hotspot=(14,48)
    if role=='Hand':
        p=curve((23,34),[
         ((23,24),(23,13),(23,10)),((23,4),(31,4),(31,10)),
         ((31,18),(31,23),(31,26)),((32,20),(39,20),(39,27)),
         ((40,22),(46,23),(46,30)),((48,26),(54,28),(54,34)),
         ((55,46),(49,56),(39,57)),((31,58),(27,54),(23,49)),
         ((18,43),(14,39),(13,36)),((10,30),(16,27),(20,31)),
         ((21,32),(22,33),(23,34))]); poly(p); hotspot=(26,7)
    # Shallow bevel and contrasting rim, preserved at small sizes through supersampling.
    rim=max(3,2*round(1.2*f)+1)
    expanded=mask.filter(ImageFilter.MaxFilter(rim))
    shadow=expanded.filter(ImageFilter.GaussianBlur(1.1*f))
    im=Image.new('RGBA',(n,n)); sh=Image.new('RGBA',(n,n),(0,0,0,0)); sh.paste((0,0,0,65),(0,0,n,n),shadow)
    im.alpha_composite(sh,(0,round(1.5*f)))
    im.paste((*rgb(edge),255),(0,0,n,n),expanded)
    base=rgb(face); grad=Image.new('RGBA',(n,n)); gd=ImageDraw.Draw(grad)
    for y in range(n):
        t=y/n; light=.32*(1-t)**3; dark=.19*t
        col=tuple(round((c+(255-c)*light)*(1-dark)) for c in base)
        gd.line((0,y,n,y),fill=(*col,255))
    im.paste(grad,(0,0),mask)
    # Narrow upper edge reflection.
    eroded=mask.filter(ImageFilter.MinFilter(max(3,2*round(.55*f)+1)))
    import PIL.ImageChops as C
    border=C.subtract(mask,eroded)
    fade=Image.new('L',(n,n)); fd=ImageDraw.Draw(fade)
    for y in range(n): fd.line((0,y,n,y),fill=int(160*(1-y/n)**2))
    im.paste((255,255,255,255),(0,0,n,n),C.multiply(border,fade))
    return im.resize((size,size),Image.Resampling.LANCZOS),tuple(round(v*size/64) for v in hotspot)
def cur(role,face,edge,frame=0):
    blobs=[]; entries=[]; offset=6+16*4
    for size in (32,48,64,96):
        im,hot=render(role,size,face,edge,frame)
        # Windows DIB: BGRA bottom-up, followed by 1-bit transparency mask.
        pixels=im.transpose(Image.Transpose.FLIP_TOP_BOTTOM).tobytes('raw','BGRA')
        stride=((size+31)//32)*4; bits=bytearray(stride*size)
        alpha=im.getchannel('A')
        for y in range(size):
            for x in range(size):
                if alpha.getpixel((x,size-1-y))==0: bits[y*stride+x//8]|=128>>(x%8)
        blob=struct.pack('<IiiHHIIiiII',40,size,size*2,1,32,0,len(pixels),0,0,0,0)+pixels+bits
        entries.append(struct.pack('<BBBBHHII',size,size,0,0,*hot,len(blob),offset)); blobs.append(blob); offset+=len(blob)
    return struct.pack('<HHH',0,2,4)+b''.join(entries)+b''.join(blobs)
def ani(role,face,edge):
    frames=[chunk(b'icon',cur(role,face,edge,i)) for i in range(12)]
    header=struct.pack('<9I',36,12,12,0,0,32,1,5,1)
    body=b'ACON'+chunk(b'anih',header)+chunk(b'LIST',b'fram'+b''.join(frames))
    return b'RIFF'+struct.pack('<I',len(body))+body
def generate(themes):
    for name,(face,edge) in themes.items():
        dest=ROOT/'temas'/name; dest.mkdir(parents=True,exist_ok=True)
        for role in ROLES:
            animated=role in ('Wait','AppStarting')
            (dest/(role+('.ani' if animated else '.cur'))).write_bytes(ani(role,face,edge) if animated else cur(role,face,edge))
        print(name,flush=True)
    (ROOT/'cores.json').write_text(json.dumps(THEMES,indent=2,ensure_ascii=False),encoding='utf-8')
def preview():
    w=1480; im=Image.new('RGB',(w,790),'#17191F'); d=ImageDraw.Draw(im)
    fontpath='C:/Windows/Fonts/segoeui.ttf'
    title=ImageFont.truetype(fontpath,36); text=ImageFont.truetype(fontpath,19)
    d.text((35,20),'Ponta suave — os 7 temas do pacote',font=title,fill='white')
    d.text((35,75),'Prévia dos arquivos reais • ponta sem haste • relevo suave',font=text,fill='#BFC5D3')
    for row,(name,(face,edge)) in enumerate(THEMES.items()):
        y=120+row*90
        d.text((35,y+20),name,font=text,fill='white')
        for j,role in enumerate(ROLES):
            x=265+j*69
            color='#F2F3F5' if row%2==0 else '#292D36'
            d.rounded_rectangle((x,y,x+63,y+69),8,fill=color)
            icon,_=render(role,48,face,edge)
            im.paste(icon,(x+7,y+9),icon)
    im.save(ROOT/'Previa-7-temas.png')
if __name__=='__main__':
    ap=argparse.ArgumentParser(); ap.add_argument('--cor'); ap.add_argument('--borda',default='#24242B'); ap.add_argument('--nome',default='Personalizado'); a=ap.parse_args()
    if a.cor: generate({a.nome:(a.cor,a.borda)})
    else: generate(THEMES); preview()
