package {
import flash.display.*;
import flash.external.ExternalInterface;
import flash.geom.Rectangle;
import flash.text.TextField;

public class Test extends Sprite {
    public function Test() {
        var art:Sprite = new Sprite();
        art.graphics.beginFill(0);
        art.graphics.drawRect(0, 0, 60, 60);
        log("unset: " + art.scale9Grid);
        for each (var grid:Rectangle in [
            new Rectangle(15, 15, 30, 30),
            new Rectangle(15.33, 15.77, 29.5, 29.4),
            new Rectangle(10.96, 10.04, 20.98, 20.99),
            new Rectangle(0, 15, 60, 30),
            new Rectangle(-5, 15, 70, 30),
            new Rectangle(15, 15, 0, 30),
            new Rectangle(15, 15, -5, 30),
            new Rectangle(30, 30, 0.01, 0.01),
            new Rectangle(1, 1, 58, 58)
        ]) {
            set("art", art, grid);
        }
        art.scale9Grid = null;
        log("null: " + art.scale9Grid);

        var negative:Sprite = new Sprite();
        negative.graphics.beginFill(0);
        negative.graphics.drawRect(-100, -100, 300, 300);
        set("negative", negative, new Rectangle(-10.7, -10.2, 20.9, 20.1));

        set("empty", new Sprite(), new Rectangle(1, 1, 2, 2));

        var stroked:Sprite = new Sprite();
        stroked.graphics.lineStyle(10, 0);
        stroked.graphics.drawRect(0, 0, 60, 60);
        set("stroked", stroked, new Rectangle(-2, 15, 30, 30));

        var withShape:Sprite = new Sprite();
        withShape.addChild(drawn(new Shape()));
        set("withShape", withShape, new Rectangle(15, 15, 30, 30));

        var withInvisibleShape:Sprite = new Sprite();
        withInvisibleShape.addChild(drawn(new Shape())).visible = false;
        set("withInvisibleShape", withInvisibleShape, new Rectangle(15, 15, 30, 30));

        var withSprite:Sprite = new Sprite();
        withSprite.addChild(drawn(new Sprite()));
        set("withSprite", withSprite, new Rectangle(15, 15, 30, 30));

        var withNestedShape:Sprite = new Sprite();
        withNestedShape.addChild(new Sprite()).addChild(drawn(new Shape()));
        set("withNestedShape", withNestedShape, new Rectangle(15, 15, 30, 30));

        var withText:Sprite = new Sprite();
        var text:TextField = new TextField();
        text.width = text.height = 60;
        withText.addChild(text);
        set("withText", withText, new Rectangle(15, 15, 30, 30));

        var cleared:Sprite = drawn(new Sprite());
        cleared.scale9Grid = new Rectangle(15, 15, 30, 30);
        cleared.graphics.clear();
        log("after graphics.clear: " + cleared.scale9Grid);
        log("done");
    }

    private function set(name:String, target:DisplayObject, grid:Rectangle):void {
        try {
            target.scale9Grid = grid;
            log(name + " " + grid + ": " + target.scale9Grid);
        } catch (e:Error) {
            log(name + " " + grid + ": " + Object(e).constructor + " " + e.errorID);
        }
    }

    private function drawn(o:*):* {
        o.graphics.beginFill(0);
        o.graphics.drawRect(0, 0, 60, 60);
        return o;
    }

    private function log(line:String):void {
        trace(line);
        if (ExternalInterface.available) {
            ExternalInterface.call("report", line);
        }
    }
}
}
