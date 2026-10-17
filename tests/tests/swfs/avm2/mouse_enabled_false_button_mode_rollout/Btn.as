package {
import flash.display.MovieClip;
public class Btn extends MovieClip {
    public function Btn() {
        stop();
        buttonMode = true;
        graphics.beginFill(0xff0000);
        graphics.drawRect(0, 0, 100, 100);
    }
}
}
