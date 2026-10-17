package {
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;

public class Test extends Sprite {
    private var fields:Array = [];

    public function Test() {
        var outer:Sprite = new Sprite();
        outer.mouseEnabled = false;
        addChild(outer);
        var inner:Sprite = new Sprite();
        inner.mouseEnabled = false;
        outer.addChild(inner);
        inner.addChild(newField("input in two mouse-disabled sprites", TextFieldType.INPUT, 10));

        var parent:Sprite = new Sprite();
        parent.mouseEnabled = false;
        addChild(parent);
        parent.addChild(newField("dynamic in a mouse-disabled sprite", TextFieldType.DYNAMIC, 60));

        addChild(newField("input in the root", TextFieldType.INPUT, 110));

        stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void {
            for each (var field:TextField in fields) {
                trace(field.name + ": selection " + field.selectionBeginIndex + "-" + field.selectionEndIndex);
            }
        });
    }

    private function newField(name:String, type:String, y:int):TextField {
        var field:TextField = new TextField();
        field.name = name;
        field.type = type;
        field.border = true;
        field.embedFonts = true;
        field.defaultTextFormat = new TextFormat("Noto Sans", 20);
        field.text = "0123456789abcdefghij";
        field.x = 10;
        field.y = y;
        field.width = 300;
        field.height = 30;
        addChild(field);
        fields.push(field);
        return field;
    }
}
}
