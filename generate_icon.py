#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

def create_gradient(width, height, color1, color2, color3):
    """Create a 3-color diagonal gradient"""
    img = Image.new('RGBA', (width, height))
    
    for y in range(height):
        for x in range(width):
            # Calculate position along diagonal (0 to 1)
            t = (x + y) / (width + height)
            
            if t < 0.5:
                # Blend color1 to color2
                t2 = t * 2
                r = int(color1[0] * (1 - t2) + color2[0] * t2)
                g = int(color1[1] * (1 - t2) + color2[1] * t2)
                b = int(color1[2] * (1 - t2) + color2[2] * t2)
            else:
                # Blend color2 to color3
                t2 = (t - 0.5) * 2
                r = int(color2[0] * (1 - t2) + color3[0] * t2)
                g = int(color2[1] * (1 - t2) + color3[1] * t2)
                b = int(color2[2] * (1 - t2) + color3[2] * t2)
            
            img.putpixel((x, y), (r, g, b, 255))
    
    return img

def add_rounded_corners(img, radius):
    """Add rounded corners to image"""
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)
    
    result = Image.new('RGBA', img.size, (0, 0, 0, 0))
    result.paste(img, mask=mask)
    return result

def create_icon(size=1024):
    # Colors: Purple blue -> Purple -> Pink
    color1 = (139, 124, 247)  # #8B7CF7
    color2 = (107, 92, 231)   # #6B5CE7
    color3 = (233, 102, 160)  # #E966A0
    
    # Create gradient background
    img = create_gradient(size, size, color1, color2, color3)
    
    # Add rounded corners (22% of size)
    radius = int(size * 0.22)
    img = add_rounded_corners(img, radius)
    
    # Add text
    draw = ImageDraw.Draw(img)
    
    # Try to use a bold font, fallback to default
    font_size = int(size * 0.35)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/SFNSDisplay.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    text = "TOY"
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - int(size * 0.05)
    
    # Draw shadow
    shadow_offset = int(size * 0.01)
    draw.text((x + shadow_offset, y + shadow_offset), text, font=font, fill=(0, 0, 0, 80))
    
    # Draw text
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))
    
    return img

def main():
    # Create assets/icon directory
    os.makedirs('assets/icon', exist_ok=True)
    
    # Generate main icon (1024x1024)
    print("Generating app_icon.png...")
    icon = create_icon(1024)
    icon.save('assets/icon/app_icon.png', 'PNG')
    
    # Generate foreground for Android adaptive icon (with padding)
    print("Generating app_icon_foreground.png...")
    fg_size = 1024
    fg = Image.new('RGBA', (fg_size, fg_size), (0, 0, 0, 0))
    
    # Create smaller icon for foreground (with safe zone padding)
    inner_size = int(fg_size * 0.6)
    inner_icon = create_icon(inner_size)
    
    # Center it
    offset = (fg_size - inner_size) // 2
    fg.paste(inner_icon, (offset, offset), inner_icon)
    fg.save('assets/icon/app_icon_foreground.png', 'PNG')
    
    print("Done! Icons saved to assets/icon/")
    print("\nNow run:")
    print("  flutter pub get")
    print("  dart run flutter_launcher_icons")

if __name__ == '__main__':
    main()
