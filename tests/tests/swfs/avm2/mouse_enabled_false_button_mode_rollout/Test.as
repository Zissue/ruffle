package {
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.MouseEvent;

public class Test extends Sprite {
    public function Test() {
        var btn:MovieClip = new Btn();
        btn.x = 50;
        btn.y = 50;
        addChild(btn);
        btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
            btn.mouseEnabled = false;
            trace("click: frame " + btn.currentFrame);
        });
        btn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
            trace("rollOut: frame " + btn.currentFrame);
        });
        stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void {
            if (e.stageX == 300) {
                trace("moved away: frame " + btn.currentFrame);
            }
        });
    }
}
}
