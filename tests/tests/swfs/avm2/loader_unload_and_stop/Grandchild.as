package {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;
import flash.utils.setInterval;

public class Grandchild extends Sprite {
    public var counts:Object = {};

    public function Grandchild() {
        setInterval(counter("setInterval"), 200);
        var timer:Timer = new Timer(200);
        timer.addEventListener(TimerEvent.TIMER, counter("Timer"));
        timer.start();
        addEventListener(Event.ENTER_FRAME, counter("enterFrame"));
    }

    private function counter(name:String):Function {
        counts[name] = 0;
        return function(...args):void {
            counts[name]++;
        };
    }
}
}
