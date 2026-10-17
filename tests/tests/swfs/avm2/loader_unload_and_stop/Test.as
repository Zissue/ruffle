package {
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.net.URLRequest;
import flash.utils.Dictionary;
import flash.utils.Timer;
import flash.utils.setInterval;

public class Test extends Sprite {
    private var modes:Array = ["unload", "unloadAndStop"];
    private var loaders:Array = [new Loader(), new Loader()];
    private var children:Array = [];
    private var counts:Array = [{}, {}];
    private var timers:Array = [];
    private var before:Array;
    private var frame:int = 0;

    public function Test() {
        for each (var loader:Loader in loaders) {
            addChild(loader);
            loader.load(new URLRequest("child.swf"));
        }
        addEventListener(Event.ENTER_FRAME, tick);
    }

    private function tick(e:Event):void {
        frame++;
        var i:int;
        if (children.length == 0) {
            for each (var loader:Loader in loaders) {
                if (loader.content == null || loader.content["nestedLoaded"] != 2) {
                    return;
                }
            }
            for (i = 0; i < 2; i++) {
                setUp(i, loaders[i].content);
            }
            frame = 0;
            return;
        }
        for (i = 0; i < 2; i++) {
            countAdvance(i, "clip advances", children[i].clip);
            countAdvance(i, "off-list clip advances", children[i].offListClip);
            var position:Number = children[i].channel.position;
            if (lastPositions[i] != position) {
                counts[i]["sound position changes"]++;
            }
            lastPositions[i] = position;
        }
        if (frame == 6) {
            loaders[0].unload();
            loaders[1].unloadAndStop();
            for (i = 0; i < 2; i++) {
                var child:Object = children[i];
                trace(modes[i] + ": hasEventListener(enterFrame) root " + child.hasEventListener(Event.ENTER_FRAME)
                    + ", on-list " + child.onList.hasEventListener(Event.ENTER_FRAME)
                    + ", off-list " + child.offList.hasEventListener(Event.ENTER_FRAME));
            }
        }
        if (frame == 8) {
            before = [snapshot(0), snapshot(1)];
            for (i = 0; i < 2; i++) {
                loaders[i].dispatchEvent(new Event("custom"));
            }
            dispatchEvent(new Event("custom"));
            stage.dispatchEvent(new Event("custom"));
        }
        if (frame == 20) {
            for (i = 0; i < 2; i++) {
                report(i);
            }
            for (i = 0; i < 2; i++) {
                before[i] = snapshot(i);
                children[i].timer.start();
            }
        }
        if (frame == 32) {
            for (i = 0; i < 2; i++) {
                var timerTicks:int = snapshot(i)["Timer"] - before[i]["Timer"];
                trace(modes[i] + ": child's Timer restarted by the loading root " + (timerTicks > 0 ? "runs" : "stays stopped") + ", running " + children[i].timer.running);
                children[i].timer.stop();
            }
            for each (var timer:Timer in timers) {
                timer.stop();
            }
            removeEventListener(Event.ENTER_FRAME, tick);
        }
    }

    private function setUp(i:int, child:Object):void {
        children[i] = child;
        child.startTimeout();
        counts[i]["clip advances"] = 0;
        counts[i]["off-list clip advances"] = 0;
        counts[i]["sound position changes"] = 0;
        child.addEventListener(Event.ENTER_FRAME, counter(i, "loading root's enterFrame listener on child root"));
        stage.addEventListener("custom", child.counter("loading root's stage listener, child's closure"));
        child.addStageListener(counter(i, "child's stage listener, loading root's closure"));
        stage.addEventListener("custom", counter(i, "loading root's own stage listener"));

        var timer:Timer = new Timer(200);
        child.listenTo(timer);
        timer.start();
        timers.push(timer);

        timer = child.newTimer();
        timer.addEventListener(TimerEvent.TIMER, counter(i, "child's Timer, started by the loading root"));
        timer.start();
        timers.push(timer);

        timer = new Timer(200);
        timer.addEventListener(TimerEvent.TIMER, counter(i, "loading root's Timer, started by the child"));
        child.start(timer);
        timers.push(timer);

        setInterval(child.counter("loading root's setInterval, child's closure"), 200);
        child.setIntervalWith(counter(i, "child's setInterval, loading root's closure"));
    }

    private function report(i:int):void {
        var after:Object = snapshot(i);
        var names:Array = [];
        for (var name:String in after) {
            names.push(name);
        }
        names.sort();
        for each (name in names) {
            if (i == 0 && name == "clip advances") {
                continue;
            }
            trace(modes[i] + ": " + name + ": " + (after[name] > before[i][name] ? "runs" : "stopped"));
        }
        trace(modes[i] + ": child's Timer running " + children[i].timer.running);
    }

    private function snapshot(i:int):Object {
        var child:Object = children[i];
        var result:Object = {};
        var name:String;
        for (name in child.counts) {
            result[name] = child.counts[name];
        }
        for (var j:int = 0; j < 2; j++) {
            var nested:Object = child.nestedLoaders[j].content;
            for (name in nested.counts) {
                result[(j == 0 ? "on-list" : "off-list") + " Loader's " + name] = nested.counts[name];
            }
        }
        for (name in counts[i]) {
            result[name] = counts[i][name];
        }
        return result;
    }

    private var lastFrames:Dictionary = new Dictionary();
    private var lastPositions:Array = [-1, -1];

    private function countAdvance(i:int, name:String, clip:Object):void {
        if (lastFrames[clip] != undefined && lastFrames[clip] != clip.currentFrame) {
            counts[i][name]++;
        }
        lastFrames[clip] = clip.currentFrame;
    }

    private function counter(i:int, name:String):Function {
        counts[i][name] = 0;
        return function(...args):void {
            counts[i][name]++;
        };
    }
}
}
