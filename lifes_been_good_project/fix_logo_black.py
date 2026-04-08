from PIL import Image
img = Image.open('assets/images/logo.png').convert('RGBA')
w, h = img.size
pixels = img.load()
for y in range(h):
  for x in range(w):
    if pixels[x,y][3] > 0:
      pixels[x,y] = (0, 0, 0, pixels[x,y][3])
img.save('assets/images/logo.png')
print('Fixed logo to black')
