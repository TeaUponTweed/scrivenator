use std::f32;
// use std;
use std::collections::HashSet;
use std::collections::HashMap;

use ggez::{GameResult, Context};
use ggez::graphics;
use ggez::graphics::Vector2;
// use ggez::nalgebra as na;

use rand;

use camera::{Camera};

// fn vec_from_angle(angle: f32) -> Vector2 {
//     let vx = angle.sin();
//     let vy = angle.cos();
//     Vector2::new(vx, vy)
// }

// fn random_vec(max_magnitude: f32) -> Vector2 {
//     let angle = rand::random::<f32>() * 2.0 * std::f32::consts::PI;
//     let mag = rand::random::<f32>() * max_magnitude;
//     vec_from_angle(angle) * (mag)
// }

fn collide_enities(e1: &Entity, e2: &Entity, min_distance: f32) -> (Entity, Entity)
{
    let one_to_two = e2.pos - e1.pos;
    let distance = one_to_two.norm();
    let pos_delta = (min_distance - distance)/2.0 * one_to_two;
    (
        Entity {
            id: e1.id,
            pos: e1.pos - pos_delta,
            vel: one_to_two/distance*e1.vel.norm()
        },
        Entity {
            id: e2.id,
            pos: e2.pos + pos_delta,
            vel: one_to_two/distance*e2.vel.norm()
        },
    )
}

// type cm = i32;
type Position = Vector2;
type Velocity = Vector2;
type IdT = i32;

const SQUARE_SIZE: f32 = 10.0;

#[derive(PartialEq, Debug)]
pub struct Entity {
    pub id  : IdT,
    pub pos : Position,
    pub vel : Velocity
}


pub struct World {
    entities: HashMap<IdT, Entity>,
    current_id: i32,
    pub camera: Camera,
    pub last_mouse_state: Option<(i32, i32)>,
    pub rng: rand::ThreadRng,
}

impl World {
    pub fn new(ctx: &mut Context) -> GameResult<World> {
        ctx.print_resource_stats();

        let entities = HashMap::new();
        let camera = Camera::new();
        let w = World {
            entities: entities,
            current_id: 0,
            camera: camera,
            last_mouse_state: None,
            rng: rand::thread_rng(),
        };
        Ok(w)
    }

    pub fn add_entity(&mut self, x: f32, y: f32, vx: f32, vy: f32) {
        self.entities.insert (
            self.current_id,
            Entity {
                id: self.current_id,
                pos: Vector2::new(x, y),
                vel: Vector2::new(vx, vy)
            }
        );
        self.current_id += 1;
        println!("{:?}",  self.entities.len());
    }

    pub fn update_kinematic_entities(&mut self, dt: f32) {
        let mut colliding_enities = Vec::new();
        let mut has_collided = HashSet::new();
        {
            let mut i = self.entities.values();
            // for ref entity in self.entities.values() {
            while let Some(entity) = i.next() {
                for other_entity in self.entities.values() {
                    if entity.id == other_entity.id {
                        continue;
                    }
                    if has_collided.contains(&entity.id) {
                        break;
                    }
                    if has_collided.contains(&other_entity.id) {
                        continue;
                    }
                    let distance = (entity.pos - other_entity.pos).norm();
                    if distance < SQUARE_SIZE {
                        let (e1, e2) = collide_enities(entity, other_entity, SQUARE_SIZE);
                        has_collided.insert(e1.id);
                        colliding_enities.push(e1);
                        has_collided.insert(e2.id);
                        colliding_enities.push(e2);
                        break;
                    }
                }
            }
        }
        while let Some(e) = colliding_enities.pop() {
            self.entities.insert(e.id, e);
        }
        // self.entities = {}
        // let thing = self.entities.values.collect().par_iter().map(|e| store.compute_price(&list))
        let updated_entities = self.entities.values().map(|e|
            (e.id, Entity {pos: e.pos + e.vel *dt, .. *e})
        ).collect();

        self.entities = updated_entities;
        //     e.pos += e.vel * dt;
        // }
    }

    pub fn update_entity(&mut self, e: Entity) {
        self.entities.insert(e.id, e);
        // match self.entities.get(&e.id) {
        //     Some(_) => self.entities.insert(e.id, *e),
        //     _ => println!("Dont have entity {:?}, can't update", e.id),
        // };
    }

    pub fn draw_squares(&self, ctx: &mut Context) -> GameResult<()> {
        // let win_width = (ctx.conf.window_width as f32) * self.camera.scale;
        // let win_height = (ctx.conf.window_height as f32) * self.camera.scale;
        for e in self.entities.values() {
            let (px, py) = self.camera.get_px_pos(e.pos[0], e.pos[1]);
            let pxsize = (10.0/self.camera.scale).round() as u32;
            let rect = graphics::Rect::new(px as f32, py as f32, pxsize as f32, pxsize as f32);
            graphics::rectangle(ctx, graphics::DrawMode::Fill, rect)?;
        }
        Ok(())
    }
}
