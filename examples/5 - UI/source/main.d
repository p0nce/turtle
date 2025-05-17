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
        /* do window */
        if (ui.begin_window("Demo Window", ui.rect(40, 40, 300, 450))) 
        {
            ui.current_container_min_size(240, 300);

            /* window info */
            if (ui.header("Window Info")) 
            {
                mu_Rect wi = ui.current_container_rect();

                char[64] buf;
                ui.layout_row(2, [ 54, -1 ].ptr, 0);
                ui.label("Position:");
                sprintf(buf.ptr, "%d, %d", wi.x, wi.y); 
                ui.label(buf.ptr);
                ui.label("Size:");
                sprintf(buf.ptr, "%d, %d", wi.w, wi.h); 
                ui.label(buf.ptr);
            }

            /* labels + buttons */
            if (ui.header("Test Buttons", MU_OPT_EXPANDED)) 
            {
                ui.layout_row(3, [ 86, -110, -1 ].ptr, 0);
                ui.label("Test buttons 1:");
                if (ui.button("Button 1")) { writeln("Pressed button 1"); }
                if (ui.button("Button 2")) { writeln("Pressed button 2"); }
                ui.label("Test buttons 2:");
                if (ui.button("Button 3")) { writeln("Pressed button 3"); }
                if (ui.button("Popup")) { ui.open_popup("Test Popup"); }
                if (ui.begin_popup("Test Popup")) 
                {
                    ui.button("Hello");
                    ui.button("World");
                    ui.end_popup();
                }
            }

            /* tree */
            if (ui.header("Tree and Text", MU_OPT_EXPANDED)) 
            {
                ui.layout_row(2, [ 140, -1 ].ptr, 0);
                ui.layout_begin_column();
                if (ui.begin_treenode("Test 1")) 
                {
                    if (ui.begin_treenode("Test 1a")) 
                    {
                        ui.label("Hello");
                        ui.label("world");
                        ui.end_treenode();
                    }
                    if (ui.begin_treenode("Test 1b")) 
                    {
                        if (ui.button("Button 1")) { writeln("Pressed button 1"); }
                        if (ui.button("Button 2")) { writeln("Pressed button 2"); }
                        ui.end_treenode();
                    }
                    ui.end_treenode();
                }
                if (ui.begin_treenode("Test 2")) 
                {
                    ui.layout_row(2, [ 54, 54 ].ptr, 0);
                    if (ui.button("Button 3")) { writeln("Pressed button 3"); }
                    if (ui.button("Button 4")) { writeln("Pressed button 4"); }
                    if (ui.button("Button 5")) { writeln("Pressed button 5"); }
                    if (ui.button("Button 6")) { writeln("Pressed button 6"); }
                    ui.end_treenode();
                }
                if (ui.begin_treenode("Test 3")) 
                {
                    static int[3] checks = [ 1, 0, 1 ];
                    ui.checkbox("Checkbox 1", &checks[0]);
                    ui.checkbox("Checkbox 2", &checks[1]);
                    ui.checkbox("Checkbox 3", &checks[2]);
                    ui.end_treenode();
                }
                ui.layout_end_column();

                ui.layout_begin_column();
                ui.layout_row( 1, [ -1 ].ptr, 0);
                ui.text("Lorem ipsum dolor sit amet, consectetur adipiscing "~
                        "elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus "~
                        "ipsum, eu varius magna felis a nulla.");
                ui.layout_end_column();
            }

            /* background color sliders */
            if (ui.header("Background Color", MU_OPT_EXPANDED)) 
            {
                ui.layout_row(2, [ -78, -1 ].ptr, 74);
                /* sliders */
                ui.layout_begin_column();
                ui.layout_row(2, [ 46, -1 ].ptr, 0);
                    
                ui.label("Red:");   
                ui.slider(&bg[0], 0, 255);
                ui.label("Green:"); 
                ui.slider(&bg[1], 0, 255);
                ui.label("Blue:");  
                ui.slider(&bg[2], 0, 255);
                ui.layout_end_column();
                /* color preview */
                mu_Rect r = ui.layout_next();
                ui.draw_rect(r, rgb(bg[0], bg[1], bg[2], 1.0));
                char[32] buf;
                sprintf(buf.ptr, "#%02X%02X%02X", cast(int) bg[0], cast(int) bg[1], cast(int) bg[2]);
                ui.draw_control_text(buf.ptr, r, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);
            }

            ui.end_window();
        }
    }

    override void draw()
    {
    }
}

float[3] bg;