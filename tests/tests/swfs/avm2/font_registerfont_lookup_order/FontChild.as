package {
import flash.display.Sprite;
import flash.text.Font;

public class FontChild extends Sprite {
    public function FontChild() {
        Font.registerFont(G2);
        Font.registerFont(G3);
        Font.registerFont(G4);
    }
}
}
