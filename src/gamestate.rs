use froggy;

use ggez::{GameResult, Context};
use ggez::graphics;

use camera::{Camera};


#[derive(Clone, Debug, PartialEq)]
pub struct Position {
    x: f32,
    y: f32,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Velocity {
    dx: f32,
    dy: f32,
}

pub struct Entity {
    pos: froggy::Pointer<Position>,
    vel: froggy::Pointer<Velocity>,
}

pub struct World {
    pos: froggy::Storage<Position>,
    vel: froggy::Storage<Velocity>,
    entities: Vec<Entity>,
    pub camera: Camera,
    pub last_mouse_state: Option<(i32, i32)>,
}

impl World {
    pub fn new() -> World {
        let pstorage = froggy::Storage::new();
        let vstorage = froggy::Storage::new();
        let entities = Vec::new();
        let camera = Camera::new();
        World {
            pos: pstorage,
            vel: vstorage,
            entities: entities,
            camera: camera,
            last_mouse_state: None,
        }
    }

    pub fn add_entity(&mut self, x: f32, y: f32, dx: f32, dy: f32) {
        let mut positions = self.pos.write();
        let mut velocities = self.vel.write();
        self.entities.push(Entity {
            pos: positions.create(Position { x: x, y: y }),
            vel: velocities.create(Velocity { dx: dx, dy: dy }),
        });
        println!("{:?}",  self.entities.len());
    }

    pub fn update_kinematic_entities(&mut self, dt: f32) {
        let mut positions = self.pos.write();
        let velocities = self.vel.read();
        for e in self.entities.iter() {
            let mut p = positions.access(&e.pos);
            let v = velocities.access(&e.vel);
            p.x += v.dx*dt;
            p.y += v.dy*dt;
        }
    }

    pub fn draw_squares(&self, ctx: &mut Context) -> GameResult<()> {
        let positions = self.pos.read();
        for e in self.entities.iter() {
            let p = positions.access(&e.pos);
            let (px, py) = self.camera.get_px_pos(p.x, p.y);
            let pxsize = (10.0/self.camera.scale).round() as u32;
            let rect = graphics::Rect::new(px as f32, py as f32, pxsize as f32, pxsize as f32);
            graphics::rectangle(ctx, graphics::DrawMode::Fill, rect)?;
        }
        Ok(())
    }
}
