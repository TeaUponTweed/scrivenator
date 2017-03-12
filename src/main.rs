extern crate froggy;
extern crate ggez;
extern crate sdl2;

pub mod quadtree;
pub mod vector;
pub mod camera;
pub mod gamestate;

use std::time::Duration;

use ggez::conf;
use ggez::{GameResult, Context};
use ggez::graphics;
use ggez::event;
use ggez::event::{MouseState, EventHandler, Keycode, Mod, MouseButton};

use gamestate::{World};

fn dt_as_float(dt: Duration) -> f32 {
    (dt.as_secs() as f32) +  (dt.subsec_nanos() as f32)/(1000000000.0)
}


impl EventHandler for World {

    fn update(&mut self, _ctx: &mut Context, _dt: Duration) -> GameResult<()> {
        self.update_kinematic_entities(dt_as_float(_dt));
        Ok(())
    }

    fn draw(&mut self, ctx: &mut Context) -> GameResult<()> {
        graphics::clear(ctx);
        graphics::set_color(ctx, graphics::Color::new(1.0, 1.0, 1.0, 1.0))?;
        self.draw_squares(ctx)?;
        graphics::present(ctx);
        Ok(())
    }

    fn mouse_button_down_event(&mut self, _button: MouseButton, _x: i32, _y: i32) {
        println!("{:?}", "here");
        println!("{:?}", _x);
        println!("{:?}", _y);
        let (x, y) = self.camera.get_real_pos(_x, _y);
        println!("{:?}", x);
        println!("{:?}", y);
        self.add_entity(x, y, 2.0, 2.0);
    }

    fn mouse_wheel_event(&mut self, _x: i32, _y: i32) {
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

    fn mouse_motion_event(&mut self,
                          _state: MouseState,
                          _x: i32,
                          _y: i32,
                          _xrel: i32,
                          _yrel: i32) {
        self.last_mouse_state = Some((_x, _y));
    }

    fn key_up_event(&mut self, _keycode: Keycode, _keymod: Mod, _repeat: bool) {}

}

pub fn main() {
    let c = conf::Conf::new();
    let ctx = &mut Context::load_from_conf("helloworld", c).unwrap();
    let state = &mut World::new();
    if let Err(e) = event::run(ctx, state) {
        println!("Error encountered: {}", e);
    } else {
        println!("Game exited cleanly.");
    }
}
