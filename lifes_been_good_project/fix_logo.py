from PIL import Image
img = Image.open('assets/images/logo.png').convert('RGBA')
w, h = img.size
new_img = Image.new('RGBA', (int(w * 1.6), int(h * 1.6)), (0, 0, 0, 0))
pixels = img.load()
for y in range(h):
  for x in range(w):
    if pixels[x,y][3] > 0:
      pixels[x,y] = (255, 255, 255, pixels[x,y][3])
new_img.paste(img, (int(w * 0.3), int(h * 0.3)))
new_img.save('assets/images/logo.png')
print('Fixed logo')
