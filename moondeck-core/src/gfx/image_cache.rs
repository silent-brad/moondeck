use std::collections::HashMap;

use anyhow::{Context, Result};

pub struct ImageData {
    pub pixels: Vec<u16>,
    pub width: u32,
    pub height: u32,
}

pub struct ImageCache {
    cache: HashMap<String, ImageData>,
    max_entries: usize,
}

impl ImageCache {
    pub fn new(max_entries: usize) -> Self {
        Self {
            cache: HashMap::new(),
            max_entries,
        }
    }

    pub fn get(&self, path: &str) -> Option<&ImageData> {
        self.cache.get(path)
    }

    pub fn insert(&mut self, path: String, data: ImageData) {
        if self.cache.len() >= self.max_entries && !self.cache.contains_key(&path) {
            if let Some(oldest) = self.cache.keys().next().cloned() {
                self.cache.remove(&oldest);
            }
        }
        self.cache.insert(path, data);
    }

    pub fn contains(&self, path: &str) -> bool {
        self.cache.contains_key(path)
    }

    pub fn clear(&mut self) {
        self.cache.clear();
    }

    pub fn load_rgb565(&mut self, path: &str, bytes: &[u8], width: u32, height: u32) -> Result<()> {
        let expected = (width * height * 2) as usize;
        if bytes.len() != expected {
            anyhow::bail!(
                "RGB565 size mismatch for {}: got {} bytes, expected {} ({}x{})",
                path,
                bytes.len(),
                expected,
                width,
                height
            );
        }

        let pixels: Vec<u16> = bytes
            .chunks_exact(2)
            .map(|chunk| u16::from_le(u16::from_ne_bytes([chunk[0], chunk[1]])))
            .collect();

        self.insert(
            path.to_string(),
            ImageData {
                pixels,
                width,
                height,
            },
        );
        Ok(())
    }

    pub fn decode_jpeg_to_rgb565(&mut self, path: &str, jpeg_data: &[u8]) -> Result<()> {
        use zune_core::bytestream::ZCursor;
        use zune_core::colorspace::ColorSpace;
        use zune_core::options::DecoderOptions;

        let options = DecoderOptions::default().jpeg_set_out_colorspace(ColorSpace::RGB);
        let mut decoder = zune_jpeg::JpegDecoder::new_with_options(ZCursor::new(jpeg_data), options);
        let pixel_data = decoder.decode().context("Failed to decode JPEG")?;
        let info = decoder.info().context("Missing JPEG metadata")?;

        let width = info.width as u32;
        let height = info.height as u32;

        let pixels: Vec<u16> = pixel_data
            .chunks_exact(3)
            .map(|rgb| {
                let r = (rgb[0] as u16 >> 3) & 0x1F;
                let g = (rgb[1] as u16 >> 2) & 0x3F;
                let b = (rgb[2] as u16 >> 3) & 0x1F;
                (r << 11) | (g << 5) | b
            })
            .collect();

        self.insert(
            path.to_string(),
            ImageData {
                pixels,
                width,
                height,
            },
        );
        Ok(())
    }
}
