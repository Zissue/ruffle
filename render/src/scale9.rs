use crate::matrix::Matrix;
use crate::shape_utils::{DistilledShape, DrawCommand, DrawPath};
use swf::{FillStyle, LineStyle, Point, Rectangle, Twips};

/// Where an object's scaling grid moves the points of its content at one scale of the object.
///
/// Content outside the grid keeps its size and content inside it stretches, so the points move
/// to coordinates that the object's matrix places with its scale divided out.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Scale9 {
    x: Axis,
    y: Axis,
}

#[derive(Clone, Copy, Debug, PartialEq)]
struct Axis {
    /// The content's edges and the grid's lines, in twips.
    from: [f32; 4],
    to: [f32; 4],
}

impl Axis {
    fn new(min: Twips, grid_min: Twips, grid_max: Twips, max: Twips, scale: f32) -> Option<Self> {
        if !(min < grid_min && grid_min < grid_max && grid_max < max && scale > 0.0) {
            return None;
        }
        let from = [min, grid_min, grid_max, max].map(|v| v.get() as f32);
        let (start, end) = (from[0] * scale, from[3] * scale);
        let (head, tail) = (from[1] - from[0], from[3] - from[2]);
        let edge_scale = ((end - start) / (head + tail)).min(1.0);
        Some(Self {
            from,
            to: [
                start,
                start + head * edge_scale,
                end - tail * edge_scale,
                end,
            ],
        })
    }

    fn map(&self, v: f32) -> f32 {
        let i = if v < self.from[1] {
            0
        } else if v < self.from[2] {
            1
        } else {
            2
        };
        let (from, to) = (
            (self.from[i], self.from[i + 1]),
            (self.to[i], self.to[i + 1]),
        );
        to.0 + (v - from.0) * (to.1 - to.0) / (from.1 - from.0)
    }

    /// The linear map taking `[min, max]` to where `map` takes its ends.
    fn span(&self, min: f32, max: f32) -> (f32, f32) {
        let (start, end) = (self.map(min), self.map(max));
        let factor = if max > min {
            (end - start) / (max - min)
        } else {
            (self.map(min + 1.0) - start).max(0.0)
        };
        (factor, start - min * factor)
    }
}

impl Scale9 {
    /// `bounds` is the extent of the content the grid applies to, and `grid` the grid, both in
    /// the gridded object's coordinates. `None` if the grid doesn't slice anything: it isn't
    /// strictly inside `bounds`, a scale isn't positive, or the object is at its own size.
    pub fn new(
        bounds: Rectangle<Twips>,
        grid: Rectangle<Twips>,
        scale_x: f32,
        scale_y: f32,
    ) -> Option<Self> {
        if !bounds.is_valid() || !grid.is_valid() || (scale_x == 1.0 && scale_y == 1.0) {
            return None;
        }
        Some(Self {
            x: Axis::new(bounds.x_min, grid.x_min, grid.x_max, bounds.x_max, scale_x)?,
            y: Axis::new(bounds.y_min, grid.y_min, grid.y_max, bounds.y_max, scale_y)?,
        })
    }

    fn scale(&self) -> (f32, f32) {
        let scale = |axis: &Axis| (axis.to[3] - axis.to[0]) / (axis.from[3] - axis.from[0]);
        (scale(&self.x), scale(&self.y))
    }

    fn map(&self, point: Point<Twips>) -> Point<Twips> {
        Point::new(
            Twips::new(self.x.map(point.x.get() as f32).round() as i32),
            Twips::new(self.y.map(point.y.get() as f32).round() as i32),
        )
    }

    /// What to append to the matrix a shape is drawn with, for the shape `slice` makes of it.
    /// `to_grid` takes the shape's coordinates to the gridded object's.
    pub fn unscale(&self, to_grid: Matrix) -> Option<Matrix> {
        let (scale_x, scale_y) = self.scale();
        Some(to_grid.inverse()? * Matrix::scale(1.0 / scale_x, 1.0 / scale_y) * to_grid)
    }

    /// Moves `shape`'s points as the grid does and passes the result to `consume`.
    ///
    /// A gradient or bitmap fill stretches as its path's bounds do. Stroke widths don't change.
    pub fn slice<R>(
        &self,
        mut shape: DistilledShape<'_>,
        to_grid: Matrix,
        consume: impl FnOnce(DistilledShape<'_>) -> R,
    ) -> Option<R> {
        let from_grid = to_grid.inverse()?;
        let mut fills: Vec<(usize, FillStyle)> = Vec::new();
        let mut lines: Vec<(usize, LineStyle)> = Vec::new();
        for (index, path) in shape.paths.iter().enumerate() {
            match path {
                DrawPath::Fill {
                    style, commands, ..
                } if !matches!(style, FillStyle::Color(_)) => {
                    fills.push((
                        index,
                        self.stretch_fill(style, commands, to_grid, from_grid),
                    ));
                }
                DrawPath::Stroke {
                    style, commands, ..
                } if !matches!(style.fill_style(), FillStyle::Color(_)) => {
                    let fill = self.stretch_fill(style.fill_style(), commands, to_grid, from_grid);
                    lines.push((index, (*style).clone().with_fill_style(fill)));
                }
                _ => {}
            }
        }

        let move_point = |point: &mut Point<Twips>| {
            *point = from_grid * self.map(to_grid * *point);
        };
        for path in &mut shape.paths {
            let (DrawPath::Fill { commands, .. } | DrawPath::Stroke { commands, .. }) = path;
            for command in commands {
                match command {
                    DrawCommand::MoveTo(anchor) | DrawCommand::LineTo(anchor) => move_point(anchor),
                    DrawCommand::QuadraticCurveTo { control, anchor } => {
                        move_point(control);
                        move_point(anchor);
                    }
                    DrawCommand::CubicCurveTo {
                        control_a,
                        control_b,
                        anchor,
                    } => {
                        move_point(control_a);
                        move_point(control_b);
                        move_point(anchor);
                    }
                }
            }
        }

        let (mut fills, mut lines) = (fills.iter().peekable(), lines.iter().peekable());
        let paths = shape
            .paths
            .into_iter()
            .enumerate()
            .map(|(index, path)| match path {
                DrawPath::Fill {
                    style,
                    commands,
                    winding_rule,
                } => DrawPath::Fill {
                    style: fills
                        .next_if(|(i, _)| *i == index)
                        .map_or(style, |(_, fill)| fill),
                    commands,
                    winding_rule,
                },
                DrawPath::Stroke {
                    style,
                    is_closed,
                    commands,
                } => DrawPath::Stroke {
                    style: lines
                        .next_if(|(i, _)| *i == index)
                        .map_or(style, |(_, line)| line),
                    is_closed,
                    commands,
                },
            })
            .collect();

        let bounds = |rect: Rectangle<Twips>| {
            if !rect.is_valid() {
                return rect;
            }
            let rect = to_grid * rect;
            let corners = [
                self.map(Point::new(rect.x_min, rect.y_min)),
                self.map(Point::new(rect.x_max, rect.y_max)),
            ];
            from_grid
                * Rectangle {
                    x_min: corners[0].x,
                    y_min: corners[0].y,
                    x_max: corners[1].x,
                    y_max: corners[1].y,
                }
        };
        Some(consume(DistilledShape {
            paths,
            shape_bounds: bounds(shape.shape_bounds),
            edge_bounds: bounds(shape.edge_bounds),
            id: shape.id,
            flat: shape.flat,
        }))
    }

    fn stretch_fill(
        &self,
        fill: &FillStyle,
        commands: &[DrawCommand],
        to_grid: Matrix,
        from_grid: Matrix,
    ) -> FillStyle {
        let mut min = (f32::INFINITY, f32::INFINITY);
        let mut max = (f32::NEG_INFINITY, f32::NEG_INFINITY);
        let mut include = |point: Point<Twips>| {
            let point = to_grid * point;
            let (x, y) = (point.x.get() as f32, point.y.get() as f32);
            min = (min.0.min(x), min.1.min(y));
            max = (max.0.max(x), max.1.max(y));
        };
        for command in commands {
            match *command {
                DrawCommand::MoveTo(anchor) | DrawCommand::LineTo(anchor) => include(anchor),
                DrawCommand::QuadraticCurveTo { control, anchor } => {
                    include(control);
                    include(anchor);
                }
                DrawCommand::CubicCurveTo {
                    control_a,
                    control_b,
                    anchor,
                } => {
                    include(control_a);
                    include(control_b);
                    include(anchor);
                }
            }
        }
        if min.0 > max.0 {
            return fill.clone();
        }
        let (a, tx) = self.x.span(min.0, max.0);
        let (d, ty) = self.y.span(min.1, max.1);
        let stretch = from_grid
            * Matrix {
                a,
                d,
                tx: Twips::new(tx.round() as i32),
                ty: Twips::new(ty.round() as i32),
                ..Matrix::IDENTITY
            }
            * to_grid;
        let mut fill = fill.clone();
        match &mut fill {
            FillStyle::Color(_) => {}
            FillStyle::LinearGradient(gradient)
            | FillStyle::RadialGradient(gradient)
            | FillStyle::FocalGradient { gradient, .. } => {
                gradient.matrix = (stretch * Matrix::from(gradient.matrix)).into();
            }
            FillStyle::Bitmap { matrix, .. } => {
                *matrix = (stretch * Matrix::from(*matrix)).into();
            }
        }
        fill
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rect(x_min: i32, y_min: i32, x_max: i32, y_max: i32) -> Rectangle<Twips> {
        Rectangle {
            x_min: Twips::from_pixels_i32(x_min),
            y_min: Twips::from_pixels_i32(y_min),
            x_max: Twips::from_pixels_i32(x_max),
            y_max: Twips::from_pixels_i32(y_max),
        }
    }

    fn mapped(scale9: &Scale9, x: i32, y: i32) -> (f64, f64) {
        let point = scale9.map(Point::new(
            Twips::from_pixels_i32(x),
            Twips::from_pixels_i32(y),
        ));
        (point.x.to_pixels(), point.y.to_pixels())
    }

    #[test]
    fn edges_keep_their_size() {
        let scale9 = Scale9::new(rect(0, 0, 60, 60), rect(15, 15, 45, 45), 1.8, 1.4)
            .expect("grid inside bounds");
        assert_eq!(mapped(&scale9, 0, 0), (0.0, 0.0));
        assert_eq!(mapped(&scale9, 15, 15), (15.0, 15.0));
        assert_eq!(mapped(&scale9, 45, 45), (93.0, 69.0));
        assert_eq!(mapped(&scale9, 60, 60), (108.0, 84.0));
        assert_eq!(mapped(&scale9, 30, 30), (54.0, 42.0));
    }

    #[test]
    fn edges_are_placed_from_the_scaled_bounds() {
        let scale9 = Scale9::new(rect(-15, 0, 75, 70), rect(15, 15, 45, 45), 1.2, 1.2)
            .expect("grid inside bounds");
        assert_eq!(mapped(&scale9, 0, 0), (-3.0, 0.0));
        assert_eq!(mapped(&scale9, 60, 60), (75.0, 74.0));
    }

    #[test]
    fn edges_shrink_together_when_they_do_not_fit() {
        let scale9 = Scale9::new(rect(0, 0, 60, 60), rect(15, 15, 45, 45), 0.4, 0.6)
            .expect("grid inside bounds");
        assert_eq!(mapped(&scale9, 15, 15), (12.0, 15.0));
        assert_eq!(mapped(&scale9, 45, 45), (12.0, 21.0));
        assert_eq!(mapped(&scale9, 60, 60), (24.0, 36.0));
    }

    #[test]
    fn grids_not_strictly_inside_do_not_slice() {
        let bounds = rect(0, 0, 60, 60);
        assert!(Scale9::new(bounds, rect(0, 15, 60, 45), 2.0, 2.0).is_none());
        assert!(Scale9::new(bounds, rect(-10, 15, 70, 45), 2.0, 2.0).is_none());
        assert!(Scale9::new(bounds, rect(30, 15, 30, 45), 2.0, 2.0).is_none());
        assert!(Scale9::new(bounds, rect(45, 45, 15, 15), 2.0, 2.0).is_none());
        assert!(Scale9::new(bounds, rect(15, 15, 45, 45), -2.0, 2.0).is_none());
        assert!(Scale9::new(bounds, rect(15, 15, 45, 45), 1.0, 1.0).is_none());
    }
}
