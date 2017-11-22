use std::f32;
// use std;
use std::collections::HashMap;

use ggez::{GameResult, Context};
use ggez::error::GameError;
use ggez::graphics;
use ggez::graphics::Image;
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

// fn collide_enities(e1: &Entity, e2: &Entity, min_distance: f32) -> (Entity, Entity)
// {
//     match (e1, e2) {
//         (Entity::Kinematic{pos: pos1, vel: vel1}, Entity::Kinematic{pos: pos2, vel: vel2}) => {
//             let one_to_two = pos2 - e1.pos;
//             let distance = one_to_two.norm();
//             let pos_delta = (min_distance - distance)/2.0 * one_to_two;
//             (
//                 Entity::Kinematic {
//                     id: e1.id,
//                     pos: e1.pos - pos_delta,
//                     vel: one_to_two/distance*e1.vel.norm()
//                 },
//                 Entity::Kinematic {
//                     id: e2.id,
//                     pos: pos2 + pos_delta,
//                     vel: one_to_two/distance*e2.vel.norm()
//                 },
//             )
//         }
//         (_, _) => (e1, e2)
//     }
// }

// type cm = i32;
type Position = Vector2;
type Velocity = Vector2;
type IdT = i32;

// const SQUARE_SIZE: f32 = 10.0;

// #[derive(PartialEq, Debug)]
// pub struct KinematicEntity {

// }

pub enum TerrainType
{
    Grass,
    Water,
    Desert
}

// struct GameObject
// {
//     id  : IdT,
//     entity : Entity
// }

pub enum Entity {
    Kinematic {
        pos : Position,
        vel : Velocity
    },
    Shard {
        pos: Vector2,
        size: f32,
        biomes: Vec<Biome>,
    }
}

pub struct World {
    entities: HashMap<IdT, Entity>,
    shard_images: HashMap<IdT, Image>,
    current_id: i32,
    pub camera: Camera,
    pub last_mouse_state: Option<(i32, i32)>,
    pub rng: rand::ThreadRng,
}

pub struct Biome {
    pos: Vector2,
    terrain: TerrainType
}

fn create_image(context: &mut Context, shard: &Entity, image_size: usize) -> GameResult<Image> {
    match shard {
        &Entity::Shard{size, ref biomes, ..} => {
            // let npixels = 4*image_size*image_size;
            // let mut buffer:[u8; npixels] = [0; npixels];
            let mut buffer = Vec::new();
            let middle = Vector2::new((image_size/2) as f32, (image_size/2) as f32);
            for i in 0..image_size {
                for j in 0..image_size {
                    let pixel_point = Vector2::new(j as f32, i as f32);
                    let dist = (pixel_point - middle).norm();
                    if dist <= size {
                        // let ix = i*image_size + j;
                        let closest_biome = biomes.iter().max_by_key(|b| ((b.pos - pixel_point).norm()*1000.0) as u32);
                        let color = match closest_biome {
                            Some(&Biome{pos: _, terrain:TerrainType::Grass }) => [0   as u8, 255 as u8, 0   as u8, 255 as u8],
                            Some(&Biome{pos: _, terrain:TerrainType::Water }) => [0   as u8, 0   as u8, 255 as u8, 255 as u8],
                            Some(&Biome{pos: _, terrain:TerrainType::Desert}) => [255 as u8, 0   as u8, 0   as u8, 255 as u8],
                            _                                                 => [255 as u8, 255 as u8, 255 as u8, 255 as u8]
                        };
                        buffer.extend(color.iter());
                    }
                    else {
                        buffer.extend([0 as u8, 0 as u8, 0 as u8, 0 as u8].iter());
                    }
                }
            }
            return Image::from_rgba8(context, image_size as u16, image_size as u16, &buffer);
        }
        _ => Err(GameError::from(String::from("Need shard to create image")))
    }
}

impl World {
    pub fn new(ctx: &mut Context, win_width: f32, win_height: f32) -> GameResult<World> {
        let entities = HashMap::new();
        let shard_images = HashMap::new();
        let camera = Camera::new(win_width, win_height);
        let mut w = World {
            entities: entities,
            shard_images: shard_images,
            current_id: 0,
            camera: camera,
            last_mouse_state: None,
            rng: rand::thread_rng(),
        };
        w.add_shard(ctx);
        Ok(w)
    }

    pub fn add_kinematic_entity(&mut self, x: f32, y: f32, vx: f32, vy: f32) {
        self.entities.insert (
            self.current_id,
            Entity::Kinematic {
                pos: Vector2::new(x, y),
                vel: Vector2::new(vx, vy)
            }
        );
        self.current_id += 1;
        println!("{:?}",  self.entities.len());
    }

    pub fn add_shard(&mut self, ctx: &mut Context) {
        let shard = Entity::Shard {
            pos: Vector2::new(0.0, 0.0),
            size: 1000.0,
            biomes: vec![Biome{pos: Vector2::new( 0.0  ,  500.0), terrain: TerrainType::Grass },
                         Biome{pos: Vector2::new(-400.0, -300.0), terrain: TerrainType::Desert},
                         Biome{pos: Vector2::new( 400.0, -300.0), terrain: TerrainType::Water }]
        };
        if let Ok(image) = create_image(ctx, &shard, 128) {
            self.shard_images.insert(self.current_id, image);
            self.entities.insert(self.current_id, shard);
            self.current_id += 1;
        }
    }

    // fn collide(&mut self, dt: f32)
    // {
    //     let mut colliding_enities = Vec::new();
    //     let mut has_collided = HashSet::new();
    //     {
    //         let mut i = self.entities.values();
    //         // for ref entity in self.entities.values() {
    //         while let Some(entity) = i.next() {
    //             for other_entity in self.entities.values() {
    //                 if entity.id == other_entity.id {
    //                     continue;
    //                 }
    //                 if has_collided.contains(&entity.id) {
    //                     break;
    //                 }
    //                 if has_collided.contains(&other_entity.id) {
    //                     continue;
    //                 }
    //                 let distance = (entity.pos - other_entity.pos).norm();
    //                 if distance < SQUARE_SIZE {
    //                     let (e1, e2) = collide_enities(entity, other_entity, SQUARE_SIZE);
    //                     has_collided.insert(e1.id);
    //                     colliding_enities.push(e1);
    //                     has_collided.insert(e2.id);
    //                     colliding_enities.push(e2);
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    //     while let Some(e) = colliding_enities.pop() {
    //         self.entities.insert(e.id, e);
    //     }
    // }

    pub fn update_kinematic_entities(&mut self, dt: f32) {
        let mut updated_entities = Vec::new();
        {
            for (id, e) in self.entities.iter() {
                match e {
                    &Entity::Kinematic{pos, vel} => {
                        updated_entities.push((*id, Entity::Kinematic{pos: pos + vel * dt, vel: vel}))
                    },
                    _                                      => {}
                }
            }
        }
        for (id, e) in updated_entities {
            self.entities.insert(id, e);
        }
    }


    pub fn draw_entities(&self, ctx: &mut Context) -> GameResult<()> {
        let circle_image = graphics::Image::new(ctx, "/circle.png").unwrap();
        let mut spritebatch = graphics::spritebatch::SpriteBatch::new(circle_image);

        for (id, e) in self.entities.iter() {
            match e {
                &Entity::Kinematic{pos, ..} => {
                    let (px, py) = self.camera.get_px_pos(pos[0], pos[1]);

                    let p = graphics::DrawParam {
                        dest: graphics::Point2::new(px as f32, py as f32),
                        // scale: graphics::Point2::new(1.0, 1.0),
                        scale: graphics::Point2::new(1.0/self.camera.scale, 1.0/self.camera.scale),
                        ..Default::default()
                    };
                    spritebatch.add(p);
                },
                &Entity::Shard{pos, ..} => {
                    let (px, py) = self.camera.get_px_pos(pos[0], pos[1]);
                    if let Some(shard_image) = self.shard_images.get(id) {
                        if let Err(e) = graphics::draw(ctx, shard_image, graphics::Point2::new(px as f32, py as f32), 0.0) {
                            return Err(e);
                        }
                    }
                }
            }

        }
        let param = graphics::DrawParam {
            ..Default::default()
        };
        graphics::draw_ex(ctx, &spritebatch, param)?;
        spritebatch.clear();

        graphics::present(ctx);
        Ok(())
    }
}
