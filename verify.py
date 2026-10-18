from pathlib import Path
import struct
root = Path(__file__).parent
files = list((root/'temas').glob('*/*'))
assert len(files) == 7*17, f'Esperados 119 cursores, encontrados {len(files)}'
for p in files:
    b=p.read_bytes()
    if p.suffix=='.cur':
        reserved,kind,n=struct.unpack_from('<HHH',b)
        assert (reserved,kind,n)==(0,2,4),p
        for i in range(n):
            w,h,_,_,x,y,size,offset=struct.unpack_from('<BBBBHHII',b,6+16*i)
            assert x<w and y<h and offset+size<=len(b),p
            assert struct.unpack_from('<I',b,offset)[0]==40,p
    else:
        assert b[:4]==b'RIFF' and b[8:12]==b'ACON',p
        assert struct.unpack_from('<I',b,4)[0]+8==len(b),p
        assert b.count(b'icon')==12,p
print('119 arquivos verificados: 105 CUR (4 resolucoes) e 14 ANI (12 quadros).')
