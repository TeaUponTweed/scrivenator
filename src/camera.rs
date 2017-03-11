#[derive(Debug)]
pub struct Camera {
    x: f32,
    y: f32,
    scale: f32
}

impl Camera {
    pub fn new() -> Camera {
        Camera {x: 0.0, y: 0.0, scale: 1.0}
    }
    pub fn scale_around(&mut self, alpha: f32, x: f32, y: f32) {
        let dx = x*self.scale*(1.0 - alpha);
        let dy = y*self.scale*(1.0 - alpha);
        self.x = self.x + dx;
        self.y = self.y + dy;
        self.scale = self.scale*alpha;
    }

    pub fn move_pixels(&mut self, pdx: f32, pdy: f32) {
        let dx = self.scale*pdx;
        let dy = self.scale*pdy;
        self.x = self.x + dx;
        self.y = self.y + dy;
    }

    pub fn abs_pos(&self, px: f32, py: f32) -> (f32, f32) {
        (px*self.scale + self.x, py*self.scale + self.y)
    }
}
