package {
import flash.display.*;
import flash.events.Event;
import flash.external.ExternalInterface;
import flash.net.URLRequest;

// art.swf (generate.rs) places sprites gridded with DefineScalingGrid.
[SWF(width="950", height="330", backgroundColor="#FFFFFF")]
public class Test extends Sprite {
    private var loader:Loader = new Loader();

    public function Test() {
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
        loader.load(new URLRequest("art.swf"));
    }

    private function onComplete(event:Event):void {
        addChild(loader);
        var art:DisplayObjectContainer = DisplayObjectContainer(loader.content);
        for (var i:int = 0; i < art.numChildren; i++) {
            var child:DisplayObject = art.getChildAt(i);
            log(child.name + " " + child.scale9Grid);
        }
    }

    private function log(line:String):void {
        trace(line);
        if (ExternalInterface.available) {
            ExternalInterface.call("report", line);
        }
    }
}
}
