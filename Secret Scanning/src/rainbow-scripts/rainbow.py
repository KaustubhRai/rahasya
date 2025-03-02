# code for the rainbow library goes here

#!/usr/bin/env python3
import sys
import math
import random

def rainbow_text(text):
    # Random starting points but very subtle changes
    random.seed()  # Different colors each time

    # Use much slower color transitions
    start_r = random.uniform(0.4, 0.9)
    start_g = random.uniform(0.4, 0.9)
    start_b = random.uniform(0.4, 0.9)

    # Very small frequency for super smooth transitions
    freq_r = 0.1
    freq_g = 0.1
    freq_b = 0.1

    # Different phase for each color component
    phase_r = random.uniform(0, 2)
    phase_g = random.uniform(0, 2)
    phase_b = random.uniform(0, 2)

    # Split into lines but maintain color continuity across them
    lines = text.split("\n")
    position = 0  # Global position tracker

    for line in lines:
        if not line:
            print()
            continue

        # For this line, calculate a single color
        r = 0.5 * math.sin(freq_r * position / 5 + phase_r) + start_r
        g = 0.5 * math.sin(freq_g * position / 5 + phase_g) + start_g
        b = 0.5 * math.sin(freq_b * position / 5 + phase_b) + start_b

        # Clamp RGB values between 0 and 1
        r = max(0, min(1, r))
        g = max(0, min(1, g))
        b = max(0, min(1, b))

        # Convert to 0-255 range
        r_255 = int(r * 255)
        g_255 = int(g * 255)
        b_255 = int(b * 255)

        # Print the whole line in this single color
        print(f"\033[38;2;{r_255};{g_255};{b_255}m{line}\033[0m")

        # Move position forward for next line
        position += 1

if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r") as f:
            text = f.read().rstrip()
    else:
        text = sys.stdin.read().rstrip()

    rainbow_text(text)
    # Reset color at the end
    print("\033[0m", end="")
