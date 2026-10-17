//! Writes art.swf: timeline sprites with `DefineScalingGrid`, placed on the main timeline.
//! Built against the `swf` crate.

use swf::*;

const FILL: CharacterId = 1;
const ROUND: CharacterId = 2;
const STROKE: CharacterId = 3;
const THICK: CharacterId = 4;
const GRADIENT: CharacterId = 5;
const CORNER_GRADIENT: CharacterId = 6;
const GRIDDED_FILL: CharacterId = 7;

fn px(v: f64) -> Twips {
    Twips::from_pixels(v)
}

fn rect(x0: f64, y0: f64, x1: f64, y1: f64) -> Rectangle<Twips> {
    Rectangle {
        x_min: px(x0),
        y_min: px(y0),
        x_max: px(x1),
        y_max: px(y1),
    }
}

fn move_to(x: f64, y: f64, fill: u32, line: u32) -> ShapeRecord {
    ShapeRecord::StyleChange(Box::new(StyleChangeData {
        move_to: Some(Point::new(px(x), px(y))),
        fill_style_0: Some(0),
        fill_style_1: Some(fill),
        line_style: Some(line),
        new_styles: None,
    }))
}

fn line(dx: f64, dy: f64) -> ShapeRecord {
    ShapeRecord::StraightEdge {
        delta: PointDelta::new(px(dx), px(dy)),
    }
}

fn curve(cx: f64, cy: f64, ax: f64, ay: f64) -> ShapeRecord {
    ShapeRecord::CurvedEdge {
        control_delta: PointDelta::new(px(cx), px(cy)),
        anchor_delta: PointDelta::new(px(ax), px(ay)),
    }
}

fn color(rgb: u32) -> Color {
    Color::from_rgb(rgb, 255)
}

fn square(records: &mut Vec<ShapeRecord>, x: f64, y: f64, size: f64, fill: u32) {
    records.push(move_to(x, y, fill, 0));
    records.extend([line(size, 0.0), line(0.0, size), line(-size, 0.0), line(0.0, -size)]);
}

fn gradient(x: f64, y: f64, size: f64) -> FillStyle {
    let scale = Fixed16::from_f64(size * 20.0 / 32768.0);
    FillStyle::LinearGradient(Gradient {
        matrix: Matrix {
            a: scale,
            d: scale,
            tx: px(x + size / 2.0),
            ty: px(y + size / 2.0),
            ..Matrix::IDENTITY
        },
        spread: GradientSpread::Pad,
        interpolation: GradientInterpolation::Rgb,
        records: vec![
            GradientRecord {
                ratio: 0,
                color: color(0xFF0000),
            },
            GradientRecord {
                ratio: 255,
                color: color(0x0000FF),
            },
        ],
    })
}

/// 60x60 art with 15px corners, for a (15, 15, 45, 45) grid.
fn art(id: CharacterId) -> Shape {
    let mut fill_styles = vec![];
    let mut line_styles = vec![];
    let mut records = vec![];
    let mut shape_bounds = rect(0.0, 0.0, 60.0, 60.0);
    match id {
        FILL | GRIDDED_FILL => {
            fill_styles = [0x808080, 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00]
                .map(|rgb| FillStyle::Color(color(rgb)))
                .to_vec();
            records.push(move_to(15.0, 0.0, 1, 0));
            records.extend([
                line(30.0, 0.0),
                line(0.0, 15.0),
                line(15.0, 0.0),
                line(0.0, 30.0),
                line(-15.0, 0.0),
                line(0.0, 15.0),
                line(-30.0, 0.0),
                line(0.0, -15.0),
                line(-15.0, 0.0),
                line(0.0, -30.0),
                line(15.0, 0.0),
                line(0.0, -15.0),
            ]);
            square(&mut records, 0.0, 0.0, 15.0, 2);
            square(&mut records, 45.0, 0.0, 15.0, 3);
            square(&mut records, 0.0, 45.0, 15.0, 4);
            square(&mut records, 45.0, 45.0, 15.0, 5);
        }
        ROUND => {
            fill_styles = vec![FillStyle::Color(color(0xFF8000))];
            records.push(move_to(15.0, 0.0, 1, 0));
            records.extend([
                line(30.0, 0.0),
                curve(15.0, 0.0, 0.0, 15.0),
                line(0.0, 30.0),
                curve(0.0, 15.0, -15.0, 0.0),
                line(-30.0, 0.0),
                curve(-15.0, 0.0, 0.0, -15.0),
                line(0.0, -30.0),
                curve(0.0, -15.0, 15.0, 0.0),
            ]);
        }
        STROKE => {
            line_styles = vec![LineStyle::new().with_width(px(4.0)).with_color(color(0))];
            records.push(move_to(0.0, 0.0, 0, 1));
            records.extend([line(60.0, 0.0), line(0.0, 60.0), line(-60.0, 0.0), line(0.0, -60.0)]);
            records.extend([move_to(30.0, 0.0, 0, 1), line(0.0, 60.0)]);
            records.extend([move_to(0.0, 30.0, 0, 1), line(60.0, 0.0)]);
            shape_bounds = rect(-2.0, -2.0, 62.0, 62.0);
        }
        THICK => {
            fill_styles = vec![FillStyle::Color(color(0x00C0C0))];
            line_styles = vec![LineStyle::new().with_width(px(10.0)).with_color(color(0))];
            records.push(move_to(0.0, 0.0, 1, 1));
            records.extend([line(60.0, 0.0), line(0.0, 60.0), line(-60.0, 0.0), line(0.0, -60.0)]);
            shape_bounds = rect(-5.0, -5.0, 65.0, 65.0);
        }
        GRADIENT => {
            fill_styles = vec![gradient(0.0, 0.0, 60.0)];
            square(&mut records, 0.0, 0.0, 60.0, 1);
        }
        CORNER_GRADIENT => {
            fill_styles = vec![FillStyle::Color(color(0x808080)), gradient(0.0, 0.0, 15.0)];
            records.push(move_to(15.0, 0.0, 1, 0));
            records.extend([
                line(45.0, 0.0),
                line(0.0, 60.0),
                line(-60.0, 0.0),
                line(0.0, -45.0),
                line(15.0, 0.0),
                line(0.0, -15.0),
            ]);
            square(&mut records, 0.0, 0.0, 15.0, 2);
        }
        _ => unreachable!(),
    }
    Shape {
        version: 4,
        id,
        shape_bounds,
        edge_bounds: rect(0.0, 0.0, 60.0, 60.0),
        flags: ShapeFlag::empty(),
        styles: ShapeStyles {
            fill_styles,
            line_styles,
        },
        shape: records,
    }
}

fn place(depth: Depth, id: CharacterId, m: [f64; 6], name: Option<&'static str>) -> Tag<'static> {
    Tag::PlaceObject(Box::new(PlaceObject {
        version: 2,
        action: PlaceObjectAction::Place(id),
        depth,
        matrix: Some(Matrix {
            a: Fixed16::from_f64(m[0]),
            b: Fixed16::from_f64(m[1]),
            c: Fixed16::from_f64(m[2]),
            d: Fixed16::from_f64(m[3]),
            tx: px(m[4]),
            ty: px(m[5]),
        }),
        color_transform: None,
        ratio: None,
        name: name.map(SwfStr::from_utf8_str),
        clip_depth: None,
        class_name: None,
        filters: None,
        background_color: None,
        blend_mode: None,
        clip_actions: None,
        has_image: false,
        is_bitmap_cached: None,
        is_visible: None,
        amf_data: None,
    }))
}

fn scale(x: f64, y: f64) -> [f64; 6] {
    [x, 0.0, 0.0, y, 0.0, 0.0]
}

fn sprite(
    id: CharacterId,
    grid: Option<Rectangle<Twips>>,
    children: &[(CharacterId, [f64; 6])],
) -> Vec<Tag<'static>> {
    let mut tags: Vec<Tag> = children
        .iter()
        .enumerate()
        .map(|(i, (child, m))| place(i as Depth + 1, *child, *m, None))
        .collect();
    tags.push(Tag::ShowFrame);
    let mut out = vec![Tag::DefineSprite(Sprite {
        id,
        num_frames: 1,
        tags,
    })];
    if let Some(splitter_rect) = grid {
        out.push(Tag::DefineScalingGrid { id, splitter_rect });
    }
    out
}

fn main() {
    let grid = Some(rect(15.0, 15.0, 45.0, 45.0));
    let mut tags = vec![Tag::FileAttributes(FileAttributes::IS_ACTION_SCRIPT_3)];
    for id in [FILL, ROUND, STROKE, THICK, GRADIENT, CORNER_GRADIENT, GRIDDED_FILL] {
        tags.push(Tag::DefineShape(Box::new(art(id))));
    }
    tags.push(Tag::DefineScalingGrid {
        id: GRIDDED_FILL,
        splitter_rect: rect(15.0, 15.0, 45.0, 45.0),
    });
    let one = scale(1.0, 1.0);
    let sprites: Vec<(CharacterId, Option<Rectangle<Twips>>, Vec<(CharacterId, [f64; 6])>)> = vec![
        (101, grid, vec![(FILL, one)]),
        (102, grid, vec![(ROUND, one)]),
        (103, grid, vec![(STROKE, one)]),
        (104, grid, vec![(THICK, one)]),
        (105, grid, vec![(GRADIENT, one)]),
        (106, grid, vec![(CORNER_GRADIENT, one)]),
        // A child shape's matrix: scaled, flipped, rotated.
        (107, Some(rect(7.5, 7.5, 22.5, 22.5)), vec![(FILL, scale(0.5, 0.5))]),
        (108, Some(rect(7.5, 7.5, 22.5, 22.5)), vec![(STROKE, scale(0.5, 0.5))]),
        (109, grid, vec![(FILL, [-1.0, 0.0, 0.0, 1.0, 60.0, 0.0])]),
        (110, grid, vec![(FILL, [0.0, 1.0, -1.0, 0.0, 60.0, 0.0])]),
        // A nested sprite isn't sliced, but slices with its own grid.
        (111, None, vec![(FILL, one)]),
        (112, grid, vec![(111, one)]),
        (113, Some(rect(30.0, 30.0, 90.0, 60.0)), vec![(101, scale(2.0, 1.5))]),
        // Two shapes share one grid.
        (114, grid, vec![(FILL, scale(0.5, 1.0)), (FILL, [0.5, 0.0, 0.0, 1.0, 30.0, 0.0])]),
        // A nested sprite's shapes don't widen what the grid applies to.
        (115, None, vec![(ROUND, [1.5, 0.0, 0.0, 0.333, -15.0, 60.0])]),
        (116, grid, vec![(FILL, one), (115, one)]),
        // Grids that don't slice: wider than the art, empty, flush with its edges, inverted.
        (117, Some(rect(-10.0, 15.0, 70.0, 45.0)), vec![(FILL, one)]),
        (118, Some(rect(30.0, 30.0, 30.0, 30.0)), vec![(FILL, one)]),
        (119, Some(rect(30.0, 15.0, 30.0, 45.0)), vec![(FILL, one)]),
        (120, Some(rect(0.0, 15.0, 60.0, 45.0)), vec![(FILL, one)]),
        (121, Some(rect(45.0, 45.0, 15.0, 15.0)), vec![(FILL, one)]),
        // Grids with fractional and negative coordinates, for the getter.
        (122, Some(rect(95.25, 73.75, 285.75, 221.25)), vec![(FILL, one)]),
        (123, Some(rect(-134.95, -126.0, 136.0, 118.0)), vec![(FILL, one)]),
    ];
    for (id, grid, children) in &sprites {
        tags.extend(sprite(*id, *grid, children));
    }

    let cells: [(CharacterId, f64, f64, &'static str); 24] = [
        (101, 1.0, 1.0, "basic_unscaled"),
        (101, 1.8, 1.4, "basic"),
        (102, 1.8, 1.4, "round"),
        (103, 1.8, 1.4, "stroke"),
        (104, 1.4, 1.2, "thick_stroke"),
        (105, 1.8, 1.4, "gradient"),
        (106, 1.8, 1.4, "corner_gradient"),
        (107, 3.6, 2.8, "scaled_child"),
        (108, 3.6, 2.8, "scaled_child_stroke"),
        (109, 1.8, 1.4, "flipped_child"),
        (110, 1.8, 1.4, "rotated_child"),
        (112, 1.8, 1.4, "nested"),
        (113, 0.9, 0.93, "nested_grid"),
        (GRIDDED_FILL, 1.8, 1.4, "gridded_shape"),
        (114, 1.8, 1.4, "two_shapes"),
        (116, 1.2, 1.4, "nested_bounds"),
        (117, 1.8, 1.4, "wide"),
        (118, 1.8, 1.4, "empty"),
        (119, 1.8, 1.4, "zero_width"),
        (120, 1.8, 1.4, "flush"),
        (121, 1.8, 1.4, "inverted"),
        (122, 1.0, 1.0, "fractional"),
        (123, 1.0, 1.0, "negative"),
        (101, 0.4, 0.6, "smaller_than_corners"),
    ];
    for (i, (id, sx, sy, name)) in cells.iter().enumerate() {
        let x = 6.0 + (i % 8) as f64 * 118.0;
        let y = 6.0 + (i / 8) as f64 * 108.0;
        tags.push(place(i as Depth + 1, *id, [*sx, 0.0, 0.0, *sy, x, y], Some(name)));
    }
    tags.push(Tag::ShowFrame);

    let header = Header {
        compression: Compression::None,
        version: 43,
        stage_size: rect(0.0, 0.0, 950.0, 330.0),
        frame_rate: Fixed8::from_f32(24.0),
        num_frames: 1,
    };
    let file = std::fs::File::create("art.swf").expect("create art.swf");
    swf::write_swf(&header, &tags, file).expect("write art.swf");
}
