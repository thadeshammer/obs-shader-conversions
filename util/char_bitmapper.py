# python 3.10

import csv

from PIL import Image, ImageDraw, ImageFont


def char_to_bitmap(target_char):
    # Create a 5x5 image
    img = Image.new("1", (5, 5), 0)
    draw = ImageDraw.Draw(img)

    # Use a monospaced font (adjust path as needed)
    # use fonts better for smaller sizes for accuracy; use other fonts for fun results
    font = ImageFont.truetype("DejaVuSansMono-Bold.ttf", 8)
    draw.text((0, -1), target_char, font=font, fill=1)

    # Convert image to binary grid
    grid = []
    for y in range(5):
        row = []
        for x in range(5):
            row.append(1 if img.getpixel((x, y)) else 0)
        grid.append(row)

    # Convert grid to integer
    bitmap_result = 0
    for y in range(5):
        for x in range(5):
            if grid[y][x] == 1:
                bitmap_result |= 1 << (y * 5 + x)

    return bitmap_result


# Characters to convert
# chars = [".", ":", "*", "o", "&", "8", "@", "#"]  # thades-mode - simple

# thades mode - extra
chars = [
    ".",
    ":",
    "*",
    "o",
    "&",
    "8",
    "@",
    "#",
    "1",
    "~",
    "\\",
    "☺",
    "§",
    "¤",
    "¶",
    "¢",
    "¥",
    "Ω",
    "µ",
    "æ",
    "¿",
]


# Generate bitmaps and sort by intensity
char_bitmaps = []
for char in chars:
    bitmap = char_to_bitmap(char)
    char_bitmaps.append((char, bitmap))

# Sort by bitmap intensity
char_bitmaps.sort(key=lambda x: bin(x[1]).count("1"))

# Write to CSV
with open("bitmaps.csv", "w", newline="", encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["char", "bitmap"])
    for char, bitmap in char_bitmaps:
        writer.writerow([char, bitmap])

# Generate shader code
luminance_step = 1.0 / len(char_bitmaps)
shader_code = []
for i, (char, bitmap) in enumerate(char_bitmaps):
    gray_value = round(luminance_step * i, 2)
    if_statement: str = f"if (gray > {gray_value})  n = {bitmap};     // {char}"
    shader_code.append(if_statement)

with open("shader_code.txt", "w", encoding="utf-8") as shader_file:
    shader_file.write("\n".join(shader_code))

print("Bitmap generation and shader code creation complete!")
