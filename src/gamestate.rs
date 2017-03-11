use froggy;
use camera::{Camera};

#[derive(Copy, Clone, Debug, PartialEq)]
struct Position {
    x: f32,
    y: f32,
}

#[derive(Copy, Clone, Debug, PartialEq)]
struct Velocity {
    dx: f32,
    dy: f32,
}

struct Entity {
    pos: froggy::Pointer<Position>,
    vel: froggy::Pointer<Velocity>,
}

struct World {
    pos: froggy::Storage<Position>,
    vel: froggy::Storage<Velocity>,
    entities: Vec<Entity>,
    camera: Camera
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
        }
    }
    pub fn addEntity(&mut self, x: f32, y: f32, dx: f32, dy: f32) {
        let mut positions = self.pos.write();
        let mut velocities = self.vel.write();
        self.entities.push(Entity {
            pos: positions.create(Position { x: x, y: y }),
            vel: velocities.create(Velocity { dx: dx, dy: dy }),
        });
    }
}