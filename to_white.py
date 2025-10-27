from PIL import Image

def make_non_transparent_white(input_path, output_path):
    """
    Convert all non-transparent pixels in a PNG to white.
    
    Args:
        input_path: Path to input PNG file
        output_path: Path to save the output PNG file
    """
    # Open the image
    img = Image.open(input_path)
    
    # Convert to RGBA if it's not already
    img = img.convert('RGBA')
    
    # Get pixel data
    pixels = img.load()
    width, height = img.size
    
    # Iterate through all pixels
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            
            # If pixel is not transparent (alpha > 0)
            if a > 0:
                # Set to white, keep alpha channel
                pixels[x, y] = (255, 255, 255, a)
    
    # Save the result
    img.save(output_path, 'PNG')
    print(f"Image saved to {output_path}")

# Example usage
if __name__ == "__main__":
    input_file = "assets/utensils/test-glass_0000s_0005_Liquid.png"
    output_file = "output.png"
    
    make_non_transparent_white(input_file, output_file)