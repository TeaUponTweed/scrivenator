extern crate ggez;
// extern crate sdl2;

use std::path;
use std::time::Duration;

use ggez::conf;
use ggez::game::{Game, GameState};
use ggez::{GameResult, Context};
use ggez::graphics;
use ggez::timer;
use ggez::event::{MouseState};

// use sdl2::mouse;

// First we make a structure to contain the game's state
struct MainState {
    text: graphics::Text,
}

// Then we implement the `ggez::game::GameState` trait on it, which
// requires callbacks for creating the game state, updating it each
// frame, and drawing it.
//
// The `GameState` trait also contains callbacks for event handling
// that you can override if you wish, but the defaults are fine.
impl GameState for MainState {
    fn load(ctx: &mut Context, _conf: &conf::Conf) -> GameResult<MainState> {
        println!("Game resource path: {:?}", ctx.filesystem);

        let fontpath = path::Path::new("Roboto-Regular.ttf");
        let font = graphics::Font::new(ctx, fontpath, 48).unwrap();
        let text = graphics::Text::new(ctx, "Hello world!", &font).unwrap();

        let s = MainState { text: text };
        Ok(s)

    }

    fn update(&mut self, _ctx: &mut Context, _dt: Duration) -> GameResult<()> {
        Ok(())
    }

    fn draw(&mut self, ctx: &mut Context) -> GameResult<()> {
        ctx.renderer.clear();
        try!(graphics::draw(ctx, &mut self.text, None, None));
        ctx.renderer.present();
        timer::sleep_until_next_frame(ctx, 60);
        Ok(())
    }

    fn mouse_wheel_event(&mut self, _x: i32, _y: i32) {}

    fn mouse_motion_event(&mut self,
                          _state: MouseState,
                          _x: i32,
                          _y: i32,
                          _xrel: i32,
                          _yrel: i32) {
    }
}

// Now our main function, which does three things:
//
// * First, create a new `ggez::conf::Conf`
// object which contains configuration info on things such
// as screen resolution and window title,
// * Second, create a `ggez::game::Game` object which will
// do the work of creating our MainState and running our game,
// * then just call `game.run()` which runs the `Game` mainloop.
pub fn main() {
    let c = conf::Conf::new();
    let mut game: Game<MainState> = Game::new("helloworld", c).unwrap();
    if let Err(e) = game.run() {
        println!("Error encountered: {:?}", e);
    } else {
        println!("Game exited cleanly.");
    }
}
