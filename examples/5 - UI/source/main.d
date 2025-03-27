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
    float posx = 0;
    float posy = 0;

    override void load()
    {
        setBackgroundColor( color("#2d2d30") );
        setTitle("UI example");
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape"))
        {
            exitGame;
        }
    }

    override void resized(float width, float height)
    {
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
    }

    override void mouseWheel(float wheelX, float wheelY)
    {
    }

    override void mouseReleased(float x, float y, MouseButton butto)
    {
    }

    override void gui()
    {
        static void test_window(mu_Context *ctx) 
        {
            /* do window */
            if (mu_begin_window(ctx, "Demo Window", mu_rect(40, 40, 300, 450))) 
            {
                mu_Container *win = mu_get_current_container(ctx);
                win.rect.w = mu_max(win.rect.w, 240);
                win.rect.h = mu_max(win.rect.h, 300);

                /* window info */
                if (mu_header(ctx, "Window Info")) 
                {
                    mu_Container *wi = mu_get_current_container(ctx);
                    char[64] buf;
                    mu_layout_row(ctx, 2, [ 54, -1 ].ptr, 0);
                    mu_label(ctx,"Position:");
                    sprintf(buf.ptr, "%d, %d", wi.rect.x, wi.rect.y); mu_label(ctx, buf.ptr);
                    mu_label(ctx, "Size:");
                    sprintf(buf.ptr, "%d, %d", wi.rect.w, wi.rect.h); mu_label(ctx, buf.ptr);
                }

                /* labels + buttons */
                if (mu_header(ctx, "Test Buttons", MU_OPT_EXPANDED)) 
                {
                    mu_layout_row(ctx, 3, [ 86, -110, -1 ].ptr, 0);
                    mu_label(ctx, "Test buttons 1:");
                    if (mu_button(ctx, "Button 1")) { writeln("Pressed button 1"); }
                    if (mu_button(ctx, "Button 2")) { writeln("Pressed button 2"); }
                    mu_label(ctx, "Test buttons 2:");
                    if (mu_button(ctx, "Button 3")) { writeln("Pressed button 3"); }
                    if (mu_button(ctx, "Popup")) { mu_open_popup(ctx, "Test Popup"); }
                    if (mu_begin_popup(ctx, "Test Popup")) {
                        mu_button(ctx, "Hello");
                        mu_button(ctx, "World");
                        mu_end_popup(ctx);
                    }
                }

                /* tree */
                if (mu_header(ctx, "Tree and Text", MU_OPT_EXPANDED)) 
                {
                    mu_layout_row(ctx, 2, [ 140, -1 ].ptr, 0);
                    mu_layout_begin_column(ctx);
                    if (mu_begin_treenode(ctx, "Test 1")) 
                    {
                        if (mu_begin_treenode(ctx, "Test 1a")) 
                        {
                            mu_label(ctx, "Hello");
                            mu_label(ctx, "world");
                            mu_end_treenode(ctx);
                        }
                        if (mu_begin_treenode(ctx, "Test 1b")) 
                        {
                            if (mu_button(ctx, "Button 1")) { writeln("Pressed button 1"); }
                            if (mu_button(ctx, "Button 2")) { writeln("Pressed button 2"); }
                            mu_end_treenode(ctx);
                        }
                        mu_end_treenode(ctx);
                    }
                    if (mu_begin_treenode(ctx, "Test 2")) 
                    {
                        mu_layout_row(ctx, 2, [ 54, 54 ].ptr, 0);
                        if (mu_button(ctx, "Button 3")) { writeln("Pressed button 3"); }
                        if (mu_button(ctx, "Button 4")) { writeln("Pressed button 4"); }
                        if (mu_button(ctx, "Button 5")) { writeln("Pressed button 5"); }
                        if (mu_button(ctx, "Button 6")) { writeln("Pressed button 6"); }
                        mu_end_treenode(ctx);
                    }
                    if (mu_begin_treenode(ctx, "Test 3")) 
                    {
                        static int[3] checks = [ 1, 0, 1 ];
                        mu_checkbox(ctx, "Checkbox 1", &checks[0]);
                        mu_checkbox(ctx, "Checkbox 2", &checks[1]);
                        mu_checkbox(ctx, "Checkbox 3", &checks[2]);
                        mu_end_treenode(ctx);
                    }
                    mu_layout_end_column(ctx);

                    mu_layout_begin_column(ctx);
                    mu_layout_row(ctx, 1, [ -1 ].ptr, 0);
                    mu_text(ctx, "Lorem ipsum dolor sit amet, consectetur adipiscing "~
                            "elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus "~
                            "ipsum, eu varius magna felis a nulla.");
                    mu_layout_end_column(ctx);
                }

                /* background color sliders */
                if (mu_header(ctx, "Background Color", MU_OPT_EXPANDED)) 
                {
                    mu_layout_row(ctx, 2, [ -78, -1 ].ptr, 74);
                    /* sliders */
                    mu_layout_begin_column(ctx);
                    mu_layout_row(ctx, 2, [ 46, -1 ].ptr, 0);
                    
                    mu_label(ctx, "Red:");   mu_slider(ctx, &bg[0], 0, 255);
                    mu_label(ctx, "Green:"); mu_slider(ctx, &bg[1], 0, 255);
                    mu_label(ctx, "Blue:");  mu_slider(ctx, &bg[2], 0, 255);
                    mu_layout_end_column(ctx);
                    /* color preview */
                    mu_Rect r = mu_layout_next(ctx);
                    mu_draw_rect(ctx, r, rgb(bg[0], bg[1], bg[2], 1.0));
                    char[32] buf;
                    sprintf(buf.ptr, "#%02X%02X%02X", cast(int) bg[0], cast(int) bg[1], cast(int) bg[2]);
                    mu_draw_control_text(ctx, buf.ptr, r, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);
                }

                mu_end_window(ctx);
            }
        }
        test_window(ui);
    }

    override void draw()
    {
    }
}

float[3] bg;