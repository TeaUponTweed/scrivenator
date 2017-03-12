use std::f32;
// use std::cmp::{min, max};
use froggy;

use ggez::{GameResult, Context};
use ggez::graphics;
use ggez::graphics::{Rect};

use rand;

use camera::{Camera};
use quadtree::{Quadtree, HasExtent};

#[derive(Clone, Debug, PartialEq)]
pub struct Position {
    x: f32,
    y: f32,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Velocity {
    vx: f32,
    vy: f32,
}

#[derive(Clone, PartialEq)]
pub struct Entity {
    pos: froggy::Pointer<Position>,
    vel: froggy::Pointer<Velocity>,
}

struct Wakka {
    entity: Entity,
    extent: Rect,
}

impl HasExtent for Wakka {
    fn rect(&self) -> Rect {
        self.extent
    }
}

fn min<T: PartialOrd> (a: T, b: T) -> T {
    if a <= b {
        a
    } else {
        b
    }
    // match a.le(&b) {
    //     Some(true) => a,
    //     Some(false) => b,
    //     None => b,
    // }
}

fn max<T: PartialOrd> (a: T, b: T) -> T {
    if a <= b {
        b
    } else {
        a
    }
}

pub struct World {
    pos: froggy::Storage<Position>,
    vel: froggy::Storage<Velocity>,
    entities: Vec<Entity>,
    pub camera: Camera,
    pub last_mouse_state: Option<(i32, i32)>,
    pub rng: rand::ThreadRng,
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
            rng: rand::thread_rng(),
        }
    }

    pub fn add_entity(&mut self, x: f32, y: f32, vx: f32, vy: f32) {
        let mut positions = self.pos.write();
        let mut velocities = self.vel.write();
        self.entities.push(Entity {
            pos: positions.create(Position { x: x, y: y }),
            vel: velocities.create(Velocity { vx: vx, vy: vy }),
        });
        println!("{:?}",  self.entities.len());
    }

    fn build_quadree(&self) -> Quadtree<Wakka> {
        let positions = self.pos.read();
        // Find quadtree bounding rectangle
        let (mut minx, mut miny, mut maxx, mut maxy) = (f32::MAX, f32::MAX, f32::MIN, f32::MIN);
        for e in self.entities.iter() {
            let Position {x, y} = *positions.access(&e.pos);
            minx = min(x, minx);
            maxx = max(x, maxx);
            miny = min(y, miny);
            maxy = max(y, maxy);
        }

        let mut quadtree = Quadtree::new(Rect{x: minx, y:miny, w: maxx-minx, h:maxy-miny});

        for e in self.entities.iter() {
            let Position{x, y} = *positions.access(&e.pos);
            let w = Wakka{entity: (*e).clone(), extent: Rect {x: x, y: y, w: 10.0, h: 10.0} };
            quadtree.insert(w)
        }
        quadtree
    }

    pub fn update_kinematic_entities(&mut self, dt: f32) {
        let mut quadtree = self.build_quadree();
        let mut colliding_enities = Vec::new();
        {
            let positions = self.pos.read();
            let velocities = self.vel.read();
            for e in self.entities.iter() {
                let p = positions.access(&e.pos);
                let v = velocities.access(&e.vel);
                for &Wakka{entity: ref othere, ..} in quadtree.retrieve(&Rect{x: (*p).x, y: (*p).y, w: 10.0, h: 10.0}) {
                    let otherp = positions.access(&othere.pos);
                    let dx = p.x - otherp.x;
                    let dy = p.y - otherp.y;
                    let distance = (dx*dx + dy*dy).sqrt();
                    if distance < 10.0 {
                        let updated_dx = p.x - otherp.x - v.vx * dt;
                        let updated_dy = p.y - otherp.y - v.vy * dt;
                        let updated_distance = (updated_dx*updated_dx + updated_dy*updated_dy).sqrt();
                        colliding_enities.push((e,
                                                otherp.x + (10.0/updated_distance * dx),
                                                otherp.y + (10.0/updated_distance * dy),
                                                -v.vx,
                                                -v.vy));
                        break;
                    }
                }
            }
        }
        let mut positions = self.pos.write();
        let mut velocities = self.vel.write();
        for &(e, px, py, vx, vy) in colliding_enities.iter() {
            let mut p = positions.access(&e.pos);
            let mut v = velocities.access(&e.vel);
            p.x = px;
            p.y = py;
            v.vx = vx;
            v.vy = vy;
        }
        for e in self.entities.iter() {
            let mut p = positions.access(&e.pos);
            let v = velocities.access(&e.vel);
            p.x += v.vx*dt;
            p.y += v.vy*dt;
        }
    }

    pub fn draw_squares(&self, ctx: &mut Context) -> GameResult<()> {
        let win_width = (ctx.conf.window_width as f32) * self.camera.scale;
        let win_height = (ctx.conf.window_height as f32) * self.camera.scale;
        let mut quadtree = self.build_quadree();
        let positions = self.pos.read();
        // for e in self.entities.iter() {
        for &Wakka{entity: ref e, ..} in quadtree.retrieve(&Rect{x: self.camera.x, y: self.camera.y, w: win_width, h: win_height}) {
            let p = positions.access(&e.pos);
            let (px, py) = self.camera.get_px_pos(p.x, p.y);
            let pxsize = (10.0/self.camera.scale).round() as u32;
            let rect = graphics::Rect::new(px as f32, py as f32, pxsize as f32, pxsize as f32);
            graphics::rectangle(ctx, graphics::DrawMode::Fill, rect)?;
        }
        Ok(())
    }
}
