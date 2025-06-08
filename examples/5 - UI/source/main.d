import turtle;
import std;

int main(string[] args)
{
    runGame(new UIExample);
    return 0;
}

import core.stdc.stdio: sprintf;

class UIExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("#2d2d30") );
        setTitle("UI example");
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape"))
            exitGame;
    }

    /// `ui` calls are possible in the `gui()` callback.
    override void gui()
    {
        with(ui)
        {
            if (beginWindow("Demo Window", rectangle(40, 40, 300, 450))) 
            {
                minSize(240, 300);

                /* window info */
                if (header("Window Info")) 
                {
                    box2i wi = currentContainerRect();

                    layoutRow(2, [ 54, -1 ].ptr, 0);
                    label("Position:");
                    label( format("%d, %d", wi.min.x, wi.min.y) );
                    label("Size:");
                    label( format("%d, %d", wi.width, wi.height) );
                }

                /* labels + buttons */
                if (header("Test Buttons", MU_OPT_EXPANDED)) 
                {
                    layoutRow(3, [ 86, -110, -1 ].ptr, 0);
                    label("Test buttons 1:");
                    if (button("Button 1")) { writeln("Pressed button 1"); }
                    if (button("Button 2")) { writeln("Pressed button 2"); }
                    label("Test buttons 2:");
                    if (button("Button 3")) { writeln("Pressed button 3"); }
                    if (button("Popup")) { openPopup("Test Popup"); }
                    if (beginPopup("Test Popup")) 
                    {
                        button("Hello");
                        button("World");
                        endPopup();
                    }
                }

                /* tree */
                if (header("Tree and Text", MU_OPT_EXPANDED)) 
                {
                    layoutRow(2, [ 140, -1 ].ptr, 0);
                    layoutBeginColumn();
                    if (beginTreenode("Test 1")) 
                    {
                        if (beginTreenode("Test 1a")) 
                        {
                            label("Hello");
                            label("world");
                            endTreenode();
                        }
                        if (beginTreenode("Test 1b")) 
                        {
                            if (button("Button 1")) { writeln("Pressed button 1"); }
                            if (button("Button 2")) { writeln("Pressed button 2"); }
                            endTreenode();
                        }
                        endTreenode();
                    }
                    if (beginTreenode("Test 2")) 
                    {
                        layoutRow(2, [ 54, 54 ].ptr, 0);
                        if (button("Button 3")) { writeln("Pressed button 3"); }
                        if (button("Button 4")) { writeln("Pressed button 4"); }
                        if (button("Button 5")) { writeln("Pressed button 5"); }
                        if (button("Button 6")) { writeln("Pressed button 6"); }
                        endTreenode();
                    }
                    if (beginTreenode("Test 3")) 
                    {
                        static int[3] checks = [ 1, 0, 1 ];
                        checkbox("Checkbox 1", &checks[0]);
                        checkbox("Checkbox 2", &checks[1]);
                        checkbox("Checkbox 3", &checks[2]);
                        endTreenode();
                    }
                    layoutEndColumn();

                    layoutBeginColumn();
                    layoutRow( 1, [ -1 ].ptr, 0);
                    text("Lorem ipsum dolor sit amet, consectetur adipiscing "~
                         "elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus "~
                         "ipsum, eu varius magna felis a nulla.");
                    layoutEndColumn();
                }

                /* background color sliders */
                if (header("Background Color", MU_OPT_EXPANDED)) 
                {
                    layoutRow(2, [ -78, -1 ].ptr, 74);
                    /* sliders */
                    layoutBeginColumn();
                    layoutRow(2, [ 46, -1 ].ptr, 0);
                    
                    label("Red:");   
                    slider(&bg[0], 0, 255);
                    label("Green:"); 
                    slider(&bg[1], 0, 255);
                    label("Blue:");  
                    slider(&bg[2], 0, 255);
                    layoutEndColumn();

                    /* color preview */
                    box2i r = layoutNext();
                    drawRect(r, rgb(bg[0], bg[1], bg[2], 1.0));
                    string buf = format("#%02X%02X%02X", cast(int) bg[0], cast(int) bg[1], cast(int) bg[2]);
                    drawControlText(buf, r, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);
                }

                endWindow();
            }
        }
    }

    override void draw()
    {
    }
}

double[3] bg = [255, 128, 128];