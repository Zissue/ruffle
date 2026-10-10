package {
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.external.ExternalInterface;
    import flash.net.URLRequest;
    import flash.utils.getQualifiedClassName;

    public class Test extends MovieClip {
        private var loader:Loader = new Loader();

        public function Test() {
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
            out("load(missing.swf)");
            loader.load(new URLRequest("missing.swf"));
        }

        private function onIOError(e:IOErrorEvent):void {
            out("ioError");
            try {
                loader.close();
                out("close() returned");
            } catch (e:Error) {
                out("close() threw " + getQualifiedClassName(e) + " " + e.errorID);
            }
            loader.unloadAndStop(true);
            out("unloadAndStop() returned");
            out("load(child_a.swf)");
            loader.load(new URLRequest("child_a.swf"));
        }

        private function onComplete(e:Event):void {
            out("complete: " + getQualifiedClassName(loader.content));
            out("done");
        }

        private function out(line:String):void {
            trace(line);
            if (ExternalInterface.available) {
                ExternalInterface.call("report", line);
            }
        }
    }
}
