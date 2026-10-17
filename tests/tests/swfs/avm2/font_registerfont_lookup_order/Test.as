package {
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.net.URLRequest;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;

public class Test extends Sprite {
    public function Test() {
        measureAll("before registering fonts");
        Font.registerFont(RegFont);
        measureAll("after registering its own regular TestFont");
        var loader:Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.INIT, function(e:Event):void {
            measureAll("after the child registers fonts");
        });
        loader.load(new URLRequest("fontchild.swf"));
    }

    private function measureAll(label:String):void {
        measure(label, "TestFont", true, false);
        measure(label, "Case2", true, false);
        measure(label, "Case3", true, false);
        measure(label, "Case3", false, false);
        measure(label, "Case4", true, false);
    }

    private function measure(label:String, font:String, bold:Boolean, italic:Boolean):void {
        var field:TextField = new TextField();
        field.embedFonts = true;
        field.defaultTextFormat = new TextFormat(font, 20, null, bold, italic);
        field.text = "iiiii";
        trace(label + ": " + font + " bold=" + bold + " italic=" + italic + ": textWidth " + field.textWidth);
    }
}
}
