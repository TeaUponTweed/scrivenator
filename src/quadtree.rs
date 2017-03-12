use ggez::graphics::Rect;

const MAX_OBJECTS: usize = 15;
const MAX_LEVELS: i32 = 20;

pub trait HasExtent {
    fn rect(&self) -> Rect;
}

/// A quadtree for minimizing collision checks between actors
pub struct Quadtree<Type>  where Type: HasExtent {
    /// The level of the current tree, (0 is root)
    level: i32,
    /// The actors that the current tree holds
    objects: Vec<Type>,
    /// An array of 4 subtrees to split into when parent is full
    nodes: [Option<Box<Quadtree<Type>>>; 4],
    /// The bounds of the current tree
    bounds: Rect,
}

impl<Type> Quadtree<Type> where Type: HasExtent {
    pub fn new(rect: Rect) -> Quadtree<Type> {
        Quadtree {
            level: 0,
            objects: Vec::with_capacity(MAX_OBJECTS),
            bounds: rect,
            nodes: [None, None, None, None],
        }
    }

    /// Splits the node into four subnodes
    fn split(&mut self) {
        let width = ((self.bounds.w as f64) / 2.0) as f32;
        let height = ((self.bounds.h as f64) / 2.0) as f32;
        let (x, y) = (self.bounds.x, self.bounds.y);

        if width as u32 > 0u32 && height as u32 > 0u32 {
            self.nodes[0] = Some(Box::new(Quadtree {
                level: self.level + 1,
                objects: Vec::with_capacity(MAX_OBJECTS),
                bounds: Rect::new(x + width, y, width as f32, height as f32),
                nodes: [None, None, None, None],
            }));
            self.nodes[1] = Some(Box::new(Quadtree {
                level: self.level + 1,
                objects: Vec::with_capacity(MAX_OBJECTS),
                bounds: Rect::new(x, y, width as f32, height as f32),
                nodes: [None, None, None, None],
            }));
            self.nodes[2] = Some(Box::new(Quadtree {
                level: self.level + 1,
                objects: Vec::with_capacity(MAX_OBJECTS),
                bounds: Rect::new(x, y + height, width as f32, height as f32),
                nodes: [None, None, None, None],
            }));
            self.nodes[3] = Some(Box::new(Quadtree {
                level: self.level + 1,
                objects: Vec::with_capacity(MAX_OBJECTS),
                bounds: Rect::new(x + width, y + height, width as f32, height as f32),
                nodes: [None, None, None, None],
            }));
        }
    }

    /// Determine which node index the object belongs to
    fn index(&self, rect: &Rect) -> Option<i32> {
        let vert_mid = (self.bounds.x as f64) + (self.bounds.w as f64) / 2.;
        let horiz_mid = (self.bounds.y as f64) + (self.bounds.h as f64) / 2.;

        let top_quad = (rect.y as f64) < horiz_mid &&
                       (rect.y as f64) + (rect.h as f64) < horiz_mid;
        let bot_quad = (rect.y as f64) > horiz_mid;

        if (rect.x as f64) < vert_mid &&
           (rect.x as f64) + (rect.w as f64) < vert_mid {
            if top_quad {
                return Some(1);
            } else if bot_quad {
                return Some(2);
            }
        } else if (rect.x as f64) > vert_mid {
            if top_quad {
                return Some(0);
            } else if bot_quad {
                return Some(3);
            }
        }

        None
    }

    /// Inserts an actor into the quadtree
    pub fn insert(&mut self, actor: Type) where Type : HasExtent {
        if self.nodes[0].is_some() {
            if let Some(index) = self.index(&actor.rect()) {
                if let Some(ref mut node) = self.nodes[index as usize] {
                    node.insert(actor);
                }
                return;
            }
        }

        if self.objects.len() == MAX_OBJECTS && self.level < MAX_LEVELS {
            if self.nodes[0].is_none() {
                self.split();
            }

            let mut leftover_parent = Vec::with_capacity(MAX_OBJECTS);
            while !self.objects.is_empty() {
                let object = self.objects.pop().unwrap();
                if let Some(index) = self.index(&object.rect()) {
                    if let Some(ref mut node) = self.nodes[index as usize] {
                        node.insert(object);
                    }
                } else {
                    leftover_parent.push(object);
                }
            }

            // Handle the overflowing actor also
            if let Some(index) = self.index(&actor.rect()) {
                if let Some(ref mut node) = self.nodes[index as usize] {
                    node.insert(actor);
                }
            } else {
                leftover_parent.push(actor);
            }

            self.objects = leftover_parent;
        } else {
            self.objects.push(actor);
        }
    }

    /// Return all objects that could collide
    pub fn retrieve(&mut self, rect: &Rect) -> Vec<&Type> where Type: HasExtent {
        let mut retrieved_values = Vec::new();
        if let Some(index) = self.index(rect) {
            if let Some(ref mut node) = self.nodes[index as usize] {
                retrieved_values.extend(node.retrieve(rect).into_iter());
            }
        } else {
            // if current object is not in a quadrant add all of the children
            // since it could potentially collide with other objects in a quadrant
            for node in &mut self.nodes[..] {
                if let Some(ref mut node) = *node {
                    retrieved_values.extend(node.retrieve(rect).into_iter());
                }
            }
        }

        for object in &self.objects {
            if object.rect() != *rect {
                retrieved_values.push(object);
            }
        }

        retrieved_values
    }

    /// Returns the total number of elements in the quadtree
    pub fn len(&self) -> usize {
        let mut l = self.objects.len();

        for i in 0..4 {
            if let Some(ref node) = self.nodes[i] {
                l += node.len();
            }
        }

        l
    }
}
