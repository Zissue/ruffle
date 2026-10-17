package {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

public class Test extends Sprite {
    private var clicked:int = 0;
    private var under:Sprite;
    private var row:Sprite;
    private var button:Sprite;

    public function Test() {
        under = box("under", 0x0000ff, 0, 0, 200, 200);
        addChild(under);
        row = box("row", 0x00ff00, 20, 20, 160, 60);
        addChild(row);
        button = box("button", 0xff0000, 10, 10, 40, 40);
        row.addChild(button);
        for each (var target:Sprite in [under, row, button]) {
            for each (var type:String in [MouseEvent.MOUSE_OVER, MouseEvent.MOUSE_OUT, MouseEvent.ROLL_OVER, MouseEvent.ROLL_OUT]) {
                target.addEventListener(type, report);
            }
        }
        button.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
            trace("click: removing row");
            removeChild(row);
            clicked = 1;
        });
        addEventListener(Event.ENTER_FRAME, function(e:Event):void {
            if (clicked > 0 && clicked <= 2) {
                trace("frame " + clicked + " after the click");
                clicked++;
            }
        });
        stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void {
            trace("mouseMove to " + e.stageX + " on " + (e.target == stage ? "stage" : e.target.name));
        });
    }

    private function report(e:MouseEvent):void {
        trace(e.type + " on " + e.currentTarget.name + " (target " + e.target.name + ", related " + (e.relatedObject ? e.relatedObject.name : null) + ")");
    }

    private function box(name:String, color:uint, x:Number, y:Number, w:Number, h:Number):Sprite {
        var s:Sprite = new Sprite();
        s.name = name;
        s.graphics.beginFill(color);
        s.graphics.drawRect(0, 0, w, h);
        s.x = x;
        s.y = y;
        return s;
    }
}
}
