#![cfg_attr(feature="clippy", feature(plugin))]
#![cfg_attr(feature="clippy", plugin(clippy))]

extern crate froggy;
extern crate ggez;
extern crate sdl2;
extern crate rand;

pub mod quadtree;
pub mod camera;
pub mod gamestate;

use std::time::Duration;
use std::f32;
use std::f32::consts::{PI};
use std::env;
use std::path;
use rand::distributions::{Range, IndependentSample};

use ggez::conf;
use ggez::{GameResult, Context};
use ggez::graphics;
// use ggez::event;
// use ggez::event::{MouseState, EventHandler, Keycode, Mod, MouseButton};
use ggez::timer;
use ggez::event::*;

use gamestate::{World};


// fn dt_as_float(dt: Duration) -> f32 {
//     (dt.as_secs() as f32) +  (dt.subsec_nanos() as f32)/(1000000000.0)
// }


impl EventHandler for World {

    fn update(&mut self, ctx: &mut Context) -> GameResult<()> {
        const DESIRED_FPS: u32 = 20;
        while timer::check_update_time(ctx, DESIRED_FPS) {
            let dt = 1.0 / (DESIRED_FPS as f32);
            self.update_kinematic_entities(dt);
        }
        Ok(())
    }

    fn draw(&mut self, ctx: &mut Context) -> GameResult<()> {
        graphics::clear(ctx);
        graphics::set_color(ctx, graphics::Color::new(1.0, 1.0, 1.0, 1.0))?;
        self.draw_squares(ctx)?;
        graphics::present(ctx);
        Ok(())
    }

    fn mouse_button_down_event(&mut self, _: &mut Context, _button: MouseButton, mx: i32, my: i32) {
        let (x, y) = self.camera.get_real_pos(mx, my);
        let pos_range = Range::new(-100.0, 100.0);
        let speed_range = Range::new(50.0, 200.0);
        let dir_range = Range::new(0.0, 2.0*PI);
        for _ in 0..20 {
            let dir = dir_range.ind_sample(&mut self.rng);
            let speed = speed_range.ind_sample(&mut self.rng);
            let posx = x + pos_range.ind_sample(&mut self.rng);
            let posy = y + pos_range.ind_sample(&mut self.rng);
            let velx = speed*dir.cos();
            let vely = speed*dir.sin();
            self.add_entity(posx, posy, velx, vely);
        }

    }

    fn mouse_wheel_event(&mut self, _: &mut Context, _x: i32, _y: i32) {
        match self.last_mouse_state {
            Some((mx, my)) => {
                if _y > 0 {
                    self.camera.scale_around(17.0/16.0, mx as f32, my as f32)
                } else if _y < 0 {
                    self.camera.scale_around(15.0/16.0, mx as f32, my as f32)
                }
            }
            None => {},
        }
    }

    fn mouse_motion_event(&mut self, _: &mut Context,
                          _state: MouseState,
                          _x: i32,
                          _y: i32,
                          _xrel: i32,
                          _yrel: i32) {
        self.last_mouse_state = Some((_x, _y));
    }

    fn key_up_event(&mut self, _: &mut Context, _keycode: Keycode, _keymod: Mod, _repeat: bool) {}

}

pub fn main() {
    let mut c = conf::Conf::new();
    c.window_title = "Astroblasto!".to_string();
    c.window_width = 640;
    c.window_height = 480;

    let ctx = &mut Context::load_from_conf("astroblasto", "ggez", c).unwrap();
    // We add the CARGO_MANIFEST_DIR/resources do the filesystems paths so
    // we we look in the cargo project for files.
    if let Ok(manifest_dir) = env::var("CARGO_MANIFEST_DIR") {
        let mut path = path::PathBuf::from(manifest_dir);
        path.push("resources");
        ctx.filesystem.mount(&path, true);
        println!("Adding path {:?}", path);
    } else {
        println!("aie?");
    }

    match World::new(ctx) {
        Err(e) => {
            println!("Could not load game!");
            println!("Error: {}", e);
        }
        Ok(ref mut game) => {
            let result = run(ctx, game);
            if let Err(e) = result {
                println!("Error encountered running game: {}", e);
            } else {
                println!("Game exited cleanly.");
            }
        }
    }
}
