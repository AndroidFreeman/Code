from PIL import Image; img = Image.open('assets/images/logo.png'); w,h=img.size; pixels=img.load(); min_x=w; max_x=0; min_y=h; max_y=0; 
for y in range(h):
  for x in range(w):
    if pixels[x,y][1] > 0:
      min_x = min(min_x, x); max_x = max(max_x, x); min_y = min(min_y, y); max_y = max(max_y, y)
print(f'Bounding box of non-transparent pixels: ({min_x}, {min_y}) to ({max_x}, {max_y})')
