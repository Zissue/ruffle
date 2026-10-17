package {
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.URLRequest;
import flash.utils.Timer;
import flash.utils.setInterval;
import flash.utils.setTimeout;

public class Child extends MovieClip {
    public var counts:Object = {};
    public var onList:Sprite = new Sprite();
    public var offList:Sprite = new Sprite();
    public var clip:MovieClip = new Clip();
    public var offListClip:MovieClip = new Clip();
    public var timer:Timer = new Timer(200);
    public var nestedLoaders:Array = [new Loader(), new Loader()];
    public var nestedLoaded:int = 0;
    public var channel:SoundChannel = new Snd().play(0, 1000, new SoundTransform(0));

    public function Child() {
        addChild(onList);
        addChild(clip);
        addChild(nestedLoaders[0]);
        for each (var loader:Loader in nestedLoaders) {
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
                nestedLoaded++;
            });
            loader.load(new URLRequest("grandchild.swf"));
        }

        setInterval(counter("setInterval"), 200);
        timer.addEventListener(TimerEvent.TIMER, counter("Timer"));
        timer.start();

        channel.addEventListener(Event.SOUND_COMPLETE, counter("soundComplete"));
        addEventListener(Event.ENTER_FRAME, counter("root enterFrame"));
        addEventListener(Event.FRAME_CONSTRUCTED, counter("root frameConstructed"));
        addEventListener(Event.EXIT_FRAME, counter("root exitFrame"));
        onList.addEventListener(Event.ENTER_FRAME, counter("on-list enterFrame"));
        offList.addEventListener(Event.ENTER_FRAME, counter("off-list enterFrame"));
        addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
            stage.addEventListener("custom", counter("stage listener"));
            parent.addEventListener("custom", counter("listener on its Loader"));
            parent.parent.addEventListener("custom", counter("listener on the loading root"));
        });
    }

    public function startTimeout():void {
        setTimeout(counter("setTimeout"), 500);
    }

    public function listenTo(timer:Timer):void {
        timer.addEventListener(TimerEvent.TIMER, counter("loading root's Timer, child's listener"));
    }

    public function newTimer():Timer {
        return new Timer(200);
    }

    public function start(timer:Timer):void {
        timer.start();
    }

    public function setIntervalWith(closure:Function):void {
        setInterval(closure, 200);
    }

    public function addStageListener(listener:Function):void {
        stage.addEventListener("custom", listener);
    }

    public function counter(name:String):Function {
        counts[name] = 0;
        return function(...args):void {
            counts[name]++;
        };
    }
}
}
