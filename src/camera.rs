#[derive(Debug)]
pub struct Camera {
    pub winx: f32,
    pub winy: f32,
    pub x: f32,
    pub y: f32,
    pub scale: f32
}

impl Camera {
    pub fn new(winx: f32, winy: f32) -> Camera {
        Camera {
            winx  : winx as f32,
            winy  : winy as f32,
            x     : 0.0,
            y     : 0.0,
            scale : 1.0
        }
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

    pub fn get_real_pos(&self, px: i32, py: i32) -> (f32, f32) {
        ((px as f32)*self.scale + self.x, (py as f32)*self.scale + self.y)
    }

    pub fn get_px_pos(&self, x: f32, y: f32) -> (i32, i32) {
        (((x - self.x)/self.scale).round() as i32,
         ((y - self.y)/self.scale).round() as i32)
    }
}
