package {
import flash.display.*;
import flash.external.ExternalInterface;
import flash.filters.GlowFilter;
import flash.geom.*;

// Each cell is a 60x60 piece of art with 15px corners and a (15, 15, 30, 30) scaling grid,
// mostly at a scale of (1.8, 1.4). Sliced, the corners stay 15px squares.
[SWF(width="950", height="440", backgroundColor="#FFFFFF")]
public class Test extends Sprite {
    private var cells:Array = [];

    public function Test() {
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        var s:Sprite, p:Sprite, sh:Shape;

        // The sprite's own drawing, a child shape, a bitmap fill, a bitmap child.
        put(0, scaled(gridded(art(new Sprite()))));
        s = new Sprite(); s.addChild(art(new Shape())); put(1, scaled(gridded(s)));
        s = new Sprite(); s.graphics.beginBitmapFill(artBitmap()); s.graphics.drawRect(0, 0, 60, 60); put(2, scaled(gridded(s)));
        s = new Sprite(); s.addChild(new Bitmap(artBitmap())); put(3, scaled(gridded(s)));
        // Gradients across the whole art and in a corner, round corners, and a curve whose control point is in another region.
        s = new Sprite(); gradient(s.graphics, 0, 0, 60, 60); put(4, scaled(gridded(s)));
        s = new Sprite(); s.graphics.beginFill(0x808080); s.graphics.drawRect(0, 0, 60, 60); gradient(s.graphics, 0, 0, 15, 15); put(5, scaled(gridded(s)));
        s = new Sprite(); s.graphics.beginFill(0xFF8000); s.graphics.drawRoundRect(0, 0, 60, 60, 30, 30); put(6, scaled(gridded(s)));
        s = new Sprite(); s.graphics.beginFill(0x00FF00); s.graphics.moveTo(0, 60); s.graphics.curveTo(10, 0, 60, 60); s.graphics.lineTo(0, 60);
        s.scale9Grid = new Rectangle(20, 35, 20, 20); s.scaleX = 1.8; s.scaleY = 2.6; put(7, s, 0, -78);

        // Rotation, skew and flips in the gridded object's own matrix, and in its parent's.
        s = gridded(art(new Sprite())); s.rotation = 10; s.scaleX = 1.6; s.scaleY = 1.2; put(8, s, 12, 0);
        s = gridded(art(new Sprite())); s.transform.matrix = new Matrix(1.8, 1 / 4096, 0, 1.4); put(9, s);
        s = gridded(art(new Sprite())); s.transform.matrix = new Matrix(1.8, 1 / 2048, 0, 1.4); put(10, s);
        p = new Sprite(); s = gridded(art(new Sprite())); s.scaleX = 1.6; s.scaleY = 1.2; p.addChild(s); p.rotation = 10; put(11, p, 12, 0);
        p = new Sprite(); s = gridded(art(new Sprite())); s.scaleX = 0.9; s.scaleY = 0.7; p.addChild(s); p.scaleX = p.scaleY = 2; put(12, p);
        s = gridded(art(new Sprite())); s.scaleX = -1.8; s.scaleY = 1.4; put(13, s, 108, 0);
        s = gridded(art(new Sprite())); s.scaleX = 1.8; s.scaleY = -1.4; put(14, s, 0, 84);
        // Smaller than the corners.
        s = gridded(art(new Sprite())); s.scaleX = 0.4; s.scaleY = 0.6; put(15, s);

        // Strokes keep their width.
        s = new Sprite(); strokes(s.graphics, "normal"); put(16, scaled(gridded(s)), 3, 3);
        s = new Sprite(); strokes(s.graphics, "none"); put(17, scaled(gridded(s)), 3, 3);
        // A cached gridded sprite slices; a cached child, a nested sprite's drawing and a mask don't.
        s = scaled(gridded(art(new Sprite()))); s.cacheAsBitmap = true; put(18, s);
        s = new Sprite(); sh = art(new Shape()); sh.cacheAsBitmap = true; s.addChild(sh); put(19, scaled(gridded(s)));
        s = new Sprite(); s.addChild(art(new Sprite())); put(20, scaled(gridded(s)));
        p = new Sprite(); p.graphics.beginFill(0x0000FF); p.graphics.drawRect(0, 0, 108, 84);
        s = new Sprite(); s.graphics.beginFill(0); s.graphics.drawRoundRect(0, 0, 60, 60, 30, 30); p.addChild(scaled(gridded(s))); p.mask = s; put(21, p);
        s = scaled(gridded(art(new Sprite()))); s.filters = [new GlowFilter(0xFF00FF, 1, 4, 4, 2, 1)]; put(22, s);
        // Child shapes with their own rotation, and scale and position.
        s = new Sprite(); sh = art(new Shape()); sh.rotation = 90; sh.x = 60; s.addChild(sh); put(23, scaled(gridded(s)));

        s = new Sprite(); sh = art(new Shape()); sh.scaleX = sh.scaleY = 0.5; sh.x = sh.y = 10; s.addChild(sh);
        s.scale9Grid = new Rectangle(15, 15, 10, 10); s.scaleX = 2.7; s.scaleY = 2.1; put(24, s, -27, -21);
        // A nested sprite's drawing and a bitmap child widen what the grid applies to; a button doesn't.
        s = art(new Sprite()); p = new Sprite(); p.graphics.beginFill(0xFF8000); p.graphics.drawRect(-15, 60, 90, 10); s.addChild(p);
        s.scale9Grid = new Rectangle(15, 15, 30, 30); s.scaleX = s.scaleY = 1.2; put(25, s, 18, 0);
        s = art(new Sprite()); var bar:Bitmap = new Bitmap(new BitmapData(90, 10, false, 0xFF8000)); bar.x = -15; bar.y = 60; s.addChild(bar);
        s.scale9Grid = new Rectangle(15, 15, 30, 30); s.scaleX = s.scaleY = 1.2; put(26, s, 18, 0);
        s = art(new Sprite()); sh = new Shape(); sh.graphics.beginFill(0xFF8000); sh.graphics.drawRect(-15, 60, 90, 10); s.addChild(new SimpleButton(sh, sh, sh, sh));
        s.scale9Grid = new Rectangle(15, 15, 30, 30); s.scaleX = s.scaleY = 1.2; put(27, s, 18, 0);
        // BitmapData.draw leaves out the drawn object's own grid with its matrix, but not its children's.
        var bd:BitmapData = new BitmapData(108, 84, false, 0xFFFFFF); bd.draw(scaled(gridded(art(new Sprite()))), new Matrix(1.8, 0, 0, 1.4)); put(28, new Bitmap(bd));
        p = new Sprite(); p.addChild(scaled(gridded(art(new Sprite()))));
        bd = new BitmapData(108, 84, false, 0xFFFFFF); bd.draw(p); put(29, new Bitmap(bd));

        var round:DisplayObject = cells[6];
        var hits:String = "hitTestPoint uses the unsliced shape:";
        for each (var point:Array in [[6, 6], [10, 4], [54, 1], [1, 42]]) {
            hits += " (" + point[0] + "," + point[1] + ")=" + round.hitTestPoint(round.x + point[0], round.y + point[1], true);
        }
        log(hits);
        log("getBounds of a sprite smaller than its corners: " + cells[15].getBounds(this));
    }

    private function log(line:String):void {
        trace(line);
        if (ExternalInterface.available) {
            ExternalInterface.call("report", line);
        }
    }

    private function put(i:int, o:DisplayObject, dx:Number = 0, dy:Number = 0):void {
        o.x = 6 + (i % 8) * 118 + dx;
        o.y = 6 + int(i / 8) * 108 + dy;
        cells[i] = o;
        addChild(o);
    }

    private function gridded(s:Sprite):Sprite {
        s.scale9Grid = new Rectangle(15, 15, 30, 30);
        return s;
    }

    private function scaled(s:Sprite):Sprite {
        s.scaleX = 1.8;
        s.scaleY = 1.4;
        return s;
    }

    private function art(o:*):* {
        var g:Graphics = o.graphics;
        g.beginFill(0x808080);
        g.moveTo(15, 0); g.lineTo(45, 0); g.lineTo(45, 15); g.lineTo(60, 15); g.lineTo(60, 45); g.lineTo(45, 45);
        g.lineTo(45, 60); g.lineTo(15, 60); g.lineTo(15, 45); g.lineTo(0, 45); g.lineTo(0, 15); g.lineTo(15, 15);
        g.lineTo(15, 0);
        var colors:Array = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00];
        var corners:Array = [[0, 0], [45, 0], [0, 45], [45, 45]];
        for (var i:int = 0; i < 4; i++) {
            g.beginFill(colors[i]);
            g.drawRect(corners[i][0], corners[i][1], 15, 15);
        }
        g.endFill();
        return o;
    }

    private function artBitmap():BitmapData {
        var bd:BitmapData = new BitmapData(60, 60, false, 0x808080);
        bd.fillRect(new Rectangle(0, 0, 15, 15), 0xFF0000);
        bd.fillRect(new Rectangle(45, 0, 15, 15), 0x00FF00);
        bd.fillRect(new Rectangle(0, 45, 15, 15), 0x0000FF);
        bd.fillRect(new Rectangle(45, 45, 15, 15), 0xFFFF00);
        return bd;
    }

    private function gradient(g:Graphics, x:Number, y:Number, width:Number, height:Number):void {
        var m:Matrix = new Matrix();
        m.createGradientBox(width, height, 0, x, y);
        g.beginGradientFill(GradientType.LINEAR, [0xFF0000, 0x0000FF], [1, 1], [0, 255], m);
        g.drawRect(x, y, width, height);
        g.endFill();
    }

    private function strokes(g:Graphics, scaleMode:String):void {
        g.lineStyle(4, 0x000000, 1, false, scaleMode);
        g.drawRect(0, 0, 60, 60);
        g.moveTo(30, 0); g.lineTo(30, 60);
        g.moveTo(0, 30); g.lineTo(60, 30);
    }
}
}
