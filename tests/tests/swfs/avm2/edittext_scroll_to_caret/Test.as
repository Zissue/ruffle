package {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;

public class Test extends Sprite {
    private var text:TextField;

    public function Test() {
        text = newField(TextFieldType.INPUT, 10);
        var dynamicText:TextField = newField(TextFieldType.DYNAMIC, 60);
        var unselectable:TextField = newField(TextFieldType.INPUT, 110);
        unselectable.selectable = false;

        text.text = "0123456789abcdefghijklmnopqrst";
        select(text, 30, 30);
        select(text, 0, 0);
        select(text, 8, 8);
        select(text, 9, 9);
        select(text, 12, 12);
        select(text, 5, 15);
        select(text, 15, 5);
        text.scrollH = 30;
        select(text, 29, 29);
        text.scrollH = 30;
        select(text, 1, 1);
        text.scrollH = 100;
        select(text, 8, 8);

        for each (var width:Number in [95, 96]) {
            var narrow:TextField = newField(TextFieldType.INPUT, 160);
            narrow.width = width;
            narrow.text = text.text;
            trace("width " + width);
            select(narrow, 8, 8);
            select(narrow, 13, 13);
            removeChild(narrow);
        }

        select(text, 30, 30);
        text.text = "0123456789abcdefghijklmno";
        describeScroll(text, "text shortened");
        text.text = "0123456789abcdefghijklmnopqrst";
        describeScroll(text, "text lengthened");

        dynamicText.text = text.text;
        select(dynamicText, 30, 30);
        unselectable.text = text.text;
        select(unselectable, 30, 30);

        text.multiline = true;
        text.scrollH = 0;
        select(text, 30, 30);
        text.multiline = false;

        text.text = "";
        describeScroll(text, "cleared");
        text.addEventListener(Event.CHANGE, function(e:Event):void {
            describe(text, "change");
        });
        text.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent):void {
            if (e.keyCode != 8 && e.charCode == 0) {
                describe(text, "keyUp " + e.keyCode);
            }
        });
    }

    private function newField(type:String, y:int):TextField {
        var field:TextField = new TextField();
        field.type = type;
        field.border = true;
        field.embedFonts = true;
        field.defaultTextFormat = new TextFormat("Noto Sans", 20);
        field.x = 10;
        field.y = y;
        field.width = 100;
        field.height = 30;
        addChild(field);
        return field;
    }

    private function select(field:TextField, begin:int, end:int):void {
        var before:int = field.scrollH;
        field.setSelection(begin, end);
        describe(field, "setSelection(" + begin + ", " + end + ") from scrollH " + before);
    }

    private function describeScroll(field:TextField, label:String):void {
        trace(label + ": scrollH=" + field.scrollH + " maxScrollH=" + field.maxScrollH);
    }

    private function describe(field:TextField, label:String):void {
        trace(label + ": caret=" + field.caretIndex + " scrollH=" + field.scrollH + " maxScrollH=" + field.maxScrollH);
    }
}
}
