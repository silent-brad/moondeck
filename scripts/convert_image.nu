#!/usr/bin/env nu

# Convert an image (PNG/JPG) to raw RGB565 format for the Moondeck display.
# Requires ImageMagick (convert/magick).
#
# Usage:
#   nu scripts/convert_image.nu input.jpg --width 400 --height 300
#   nu scripts/convert_image.nu input.png -o output.rgb565
#   nu scripts/convert_image.nu input.jpg --width 200 --height 200 -o /data/images/photo.rgb565

def main [
    input: string      # Input image file (PNG, JPG, etc.)
    --width (-w): int   # Target width (optional, keeps aspect if only one given)
    --height (-h): int  # Target height (optional, keeps aspect if only one given)
    --output (-o): string # Output file path (default: input with .rgb565 extension)
] {
    let out = if ($output | is-empty) {
        $input | path parse | update extension "rgb565" | path join
    } else {
        $output
    }

    mut resize_args = []
    if ($width != null) and ($height != null) {
        $resize_args = ["-resize" $"($width)x($height)!"]
    } else if ($width != null) {
        $resize_args = ["-resize" $"($width)x"]
    } else if ($height != null) {
        $resize_args = ["-resize" $"x($height)"]
    }

    # Convert to raw RGB565 using ImageMagick:
    # 1. Resize to target dimensions
    # 2. Convert to 16-bit RGB (5-6-5) raw pixel data
    (magick $input
        ...$resize_args
        -depth 8
        -colorspace sRGB
        RGB:- |
    each {|row|
        # ImageMagick RGB:- outputs raw R,G,B bytes
        # We need to convert to RGB565 (2 bytes per pixel, little-endian)
    })

    # Use a simpler approach: output raw RGB then convert with a pipeline
    let tmp = $"/tmp/moondeck_convert_(random chars -l 8).rgb"

    magick $input ...$resize_args -depth 8 $"RGB:($tmp)"

    # Read dimensions after resize
    let info = (magick identify -format "%wx%h" $input ...$resize_args | str trim)

    # Convert raw RGB to RGB565 using pure nu
    let rgb_bytes = (open $tmp --raw)
    let pixel_count = ($rgb_bytes | bytes length) / 3

    mut rgb565_buf = (0x[] | into binary)
    for i in 0..<$pixel_count {
        let offset = $i * 3
        let r = ($rgb_bytes | bytes at $offset..($offset + 1) | into int)
        let g = ($rgb_bytes | bytes at ($offset + 1)..($offset + 2) | into int)
        let b = ($rgb_bytes | bytes at ($offset + 2)..($offset + 3) | into int)

        # RGB565: RRRR RGGG GGGB BBBB
        let rgb565 = (($r bit-shr 3) bit-shl 11) bit-or (($g bit-shr 2) bit-shl 5) bit-or ($b bit-shr 3)

        # Little-endian u16
        let lo = ($rgb565 bit-and 0xFF)
        let hi = (($rgb565 bit-shr 8) bit-and 0xFF)
        $rgb565_buf = ($rgb565_buf | bytes add ([($lo) ($hi)] | into binary))
    }

    $rgb565_buf | save -f $out
    rm -f $tmp

    print $"Converted ($input) -> ($out) \(($pixel_count) pixels, ($pixel_count * 2) bytes\)"
}
