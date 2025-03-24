module turtle.ui.microui;

// Port of rxi microui v2.0.1: git@github.com:rxi/microui.git

// Copyright (c) 2024 rxi
// Copyright (c) 2025 Guillaume Piolat (D port)
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// microui.h:

nothrow @nogc:

enum MU_VERSION = "2.02";

enum size_t MU_COMMANDLIST_SIZE     = (256 * 1024);
enum size_t MU_ROOTLIST_SIZE        = 32;
enum size_t MU_CONTAINERSTACK_SIZE  = 32;
enum size_t MU_CLIPSTACK_SIZE       = 32;
enum size_t MU_IDSTACK_SIZE         = 32;
enum size_t MU_LAYOUTSTACK_SIZE     = 16;
enum size_t MU_CONTAINERPOOL_SIZE   = 48;
enum size_t MU_TREENODEPOOL_SIZE    = 48;
enum size_t MU_MAX_WIDTHS           = 16;
alias MU_REAL = float;
enum string MU_REAL_FMT = "%.3g";
enum string MU_SLIDER_FMT = "%.2f";
enum size_t MU_MAX_FMT = 127;

struct mu_stack(T, size_t n)
{
    int idx;
    T[n] items;
}

T mu_min(T)(T a, T b) { return a < b ? a : b; }
T mu_max(T)(T a, T b) { return a > b ? a : b; }
T mu_clamp(T)(T x, T a, T b) { return mu_min(b, mu_max(a, x)); }

enum : int 
{
    MU_CLIP_PART = 1,
    MU_CLIP_ALL
}

enum : int 
{
    MU_COMMAND_JUMP = 1,
    MU_COMMAND_CLIP,
    MU_COMMAND_RECT,
    MU_COMMAND_TEXT,
    MU_COMMAND_ICON,
    MU_COMMAND_MAX
}

enum : int
{
    MU_COLOR_TEXT,
    MU_COLOR_BORDER,
    MU_COLOR_WINDOWBG,
    MU_COLOR_TITLEBG,
    MU_COLOR_TITLETEXT,
    MU_COLOR_PANELBG,
    MU_COLOR_BUTTON,
    MU_COLOR_BUTTONHOVER,
    MU_COLOR_BUTTONFOCUS,
    MU_COLOR_BASE,
    MU_COLOR_BASEHOVER,
    MU_COLOR_BASEFOCUS,
    MU_COLOR_SCROLLBASE,
    MU_COLOR_SCROLLTHUMB,
    MU_COLOR_MAX
}

enum : int
{
    MU_ICON_CLOSE = 1,
    MU_ICON_CHECK,
    MU_ICON_COLLAPSED,
    MU_ICON_EXPANDED,
    MU_ICON_MAX
}

enum : int
{
    MU_RES_ACTIVE       = (1 << 0),
    MU_RES_SUBMIT       = (1 << 1),
    MU_RES_CHANGE       = (1 << 2)
}

enum 
{
    MU_OPT_ALIGNCENTER  = (1 << 0),
    MU_OPT_ALIGNRIGHT   = (1 << 1),
    MU_OPT_NOINTERACT   = (1 << 2),
    MU_OPT_NOFRAME      = (1 << 3),
    MU_OPT_NORESIZE     = (1 << 4),
    MU_OPT_NOSCROLL     = (1 << 5),
    MU_OPT_NOCLOSE      = (1 << 6),
    MU_OPT_NOTITLE      = (1 << 7),
    MU_OPT_HOLDFOCUS    = (1 << 8),
    MU_OPT_AUTOSIZE     = (1 << 9),
    MU_OPT_POPUP        = (1 << 10),
    MU_OPT_CLOSED       = (1 << 11),
    MU_OPT_EXPANDED     = (1 << 12)
}

enum 
{
    MU_MOUSE_LEFT       = (1 << 0),
    MU_MOUSE_RIGHT      = (1 << 1),
    MU_MOUSE_MIDDLE     = (1 << 2)
}

enum 
{
    MU_KEY_SHIFT        = (1 << 0),
    MU_KEY_CTRL         = (1 << 1),
    MU_KEY_ALT          = (1 << 2),
    MU_KEY_BACKSPACE    = (1 << 3),
    MU_KEY_RETURN       = (1 << 4)
}

alias mu_Id = uint;
alias mu_Real = MU_REAL;
alias mu_Font = void*;

struct mu_Vec2
{ 
    int x, y; 
}

struct mu_Rect
{ 
    int x, y, w, h; 
}

struct mu_Color
{ 
    ubyte r, g, b, a; 
}

struct mu_PoolItem
{ 
    mu_Id id; 
    int last_update; 
}

struct mu_BaseCommand
{ 
    int type, size; 
}

struct mu_JumpCommand
{ 
    mu_BaseCommand base; 
    void *dst; 
}

struct mu_ClipCommand
{ 
    mu_BaseCommand base; 
    mu_Rect rect; 
}

struct mu_RectCommand
{ 
    mu_BaseCommand base; 
    mu_Rect rect; 
    mu_Color color; 
}

struct mu_TextCommand
{ 
    mu_BaseCommand base; 
    mu_Font font; 
    mu_Vec2 pos; 
    mu_Color color; 
    char[1] str; 
}

struct mu_IconCommand
{ 
    mu_BaseCommand base; 
    mu_Rect rect; 
    int id; mu_Color color; 
} 

union mu_Command
{
  int type;
  mu_BaseCommand base;
  mu_JumpCommand jump;
  mu_ClipCommand clip;
  mu_RectCommand rect;
  mu_TextCommand text;
  mu_IconCommand icon;
}

struct mu_Layout
{
  mu_Rect body;
  mu_Rect next;
  mu_Vec2 position;
  mu_Vec2 size;
  mu_Vec2 max;
  int[MU_MAX_WIDTHS] widths;
  int items;
  int item_index;
  int next_row;
  int next_type;
  int indent;
}

struct mu_Container
{
    mu_Command *head, tail;
    mu_Rect rect;
    mu_Rect body;
    mu_Vec2 content_size;
    mu_Vec2 scroll;
    int zindex;
    int open;
}

struct mu_Style
{
    mu_Font font;
    mu_Vec2 size;
    int padding;
    int spacing;
    int indent;
    int title_height;
    int scrollbar_size;
    int thumb_size;
    mu_Color[MU_COLOR_MAX] colors;
}

struct mu_Context 
{
    /* callbacks */
    int function(mu_Font font, const(char)*str, int len) text_width;
    int function(mu_Font font) text_height;
    void function(mu_Context *ctx, mu_Rect rect, int colorid) draw_frame;

    /* core state */
    mu_Style _style;
    mu_Style *style;
    mu_Id hover;
    mu_Id focus;
    mu_Id last_id;
    mu_Rect last_rect;
    int last_zindex;
    int updated_focus;
    int frame;
    mu_Container *hover_root;
    mu_Container *next_hover_root;
    mu_Container *scroll_target;
    char[MU_MAX_FMT] number_edit_buf;
    mu_Id number_edit;
    /* stacks */
    mu_stack!(char, MU_COMMANDLIST_SIZE) command_list;
    mu_stack!(mu_Container*, MU_ROOTLIST_SIZE) root_list;
    mu_stack!(mu_Container*, MU_CONTAINERSTACK_SIZE) container_stack;
    mu_stack!(mu_Rect, MU_CLIPSTACK_SIZE) clip_stack;
    mu_stack!(mu_Id, MU_IDSTACK_SIZE) id_stack;
    mu_stack!(mu_Layout, MU_LAYOUTSTACK_SIZE) layout_stack;
    /* retained state pools */
    mu_PoolItem[MU_CONTAINERPOOL_SIZE] container_pool;
    mu_Container[MU_CONTAINERPOOL_SIZE] containers;
    mu_PoolItem[MU_TREENODEPOOL_SIZE] treenode_pool;
    /* input state */
    mu_Vec2 mouse_pos;
    mu_Vec2 last_mouse_pos;
    mu_Vec2 mouse_delta;
    mu_Vec2 scroll_delta;
    int mouse_down;
    int mouse_pressed;
    int key_down;
    int key_pressed;
    char[32] input_text;
}

// entire API
mu_Vec2 mu_vec2(int x, int y);
mu_Rect mu_rect(int x, int y, int w, int h);
mu_Color mu_color(int r, int g, int b, int a);
void mu_init(mu_Context *ctx);
void mu_begin(mu_Context *ctx);
void mu_end(mu_Context *ctx);
void mu_set_focus(mu_Context *ctx, mu_Id id);
mu_Id mu_get_id(mu_Context *ctx, const void *data, int size);
void mu_push_id(mu_Context *ctx, const void *data, int size);
void mu_pop_id(mu_Context *ctx);
void mu_push_clip_rect(mu_Context *ctx, mu_Rect rect);
void mu_pop_clip_rect(mu_Context *ctx);
mu_Rect mu_get_clip_rect(mu_Context *ctx);
int mu_check_clip(mu_Context *ctx, mu_Rect r);
mu_Container* mu_get_current_container(mu_Context *ctx);
mu_Container* mu_get_container(mu_Context *ctx, const char *name);
void mu_bring_to_front(mu_Context *ctx, mu_Container *cnt);
int mu_pool_init(mu_Context *ctx, mu_PoolItem *items, int len, mu_Id id);
int mu_pool_get(mu_Context *ctx, mu_PoolItem *items, int len, mu_Id id);
void mu_pool_update(mu_Context *ctx, mu_PoolItem *items, int idx);
void mu_input_mousemove(mu_Context *ctx, int x, int y);
void mu_input_mousedown(mu_Context *ctx, int x, int y, int btn);
void mu_input_mouseup(mu_Context *ctx, int x, int y, int btn);
void mu_input_scroll(mu_Context *ctx, int x, int y);
void mu_input_keydown(mu_Context *ctx, int key);
void mu_input_keyup(mu_Context *ctx, int key);
void mu_input_text(mu_Context *ctx, const char *text);
mu_Command* mu_push_command(mu_Context *ctx, int type, int size);
int mu_next_command(mu_Context *ctx, mu_Command **cmd);
void mu_set_clip(mu_Context *ctx, mu_Rect rect);
void mu_draw_rect(mu_Context *ctx, mu_Rect rect, mu_Color color);
void mu_draw_box(mu_Context *ctx, mu_Rect rect, mu_Color color);
void mu_draw_text(mu_Context *ctx, mu_Font font, const char *str, int len, mu_Vec2 pos, mu_Color color);
void mu_draw_icon(mu_Context *ctx, int id, mu_Rect rect, mu_Color color);
void mu_layout_row(mu_Context *ctx, int items, const int *widths, int height);
void mu_layout_width(mu_Context *ctx, int width);
void mu_layout_height(mu_Context *ctx, int height);
void mu_layout_begin_column(mu_Context *ctx);
void mu_layout_end_column(mu_Context *ctx);
void mu_layout_set_next(mu_Context *ctx, mu_Rect r, int relative);
mu_Rect mu_layout_next(mu_Context *ctx);
void mu_draw_control_frame(mu_Context *ctx, mu_Id id, mu_Rect rect, int colorid, int opt);
void mu_draw_control_text(mu_Context *ctx, const char *str, mu_Rect rect, int colorid, int opt);
int mu_mouse_over(mu_Context *ctx, mu_Rect rect);
void mu_update_control(mu_Context *ctx, mu_Id id, mu_Rect rect, int opt);

int mu_button(mu_Context *ctx, const char *label)
{
    return mu_button_ex(ctx, label, 0, MU_OPT_ALIGNCENTER);
}

int mu_textbox(mu_Context *ctx, char *buf, int bufsz)
{
    return mu_textbox_ex(ctx, buf, bufsz, 0);
}

int mu_slider(mu_Context *ctx, mu_Real *value, mu_Real lo, mu_Real hi)
{
    return mu_slider_ex(ctx, value, lo, hi, 0, MU_SLIDER_FMT, MU_OPT_ALIGNCENTER);
}

int mu_number(mu_Context *ctx, mu_Real *value, mu_Real step)
{
    return mu_number_ex(ctx, value, step, MU_SLIDER_FMT, MU_OPT_ALIGNCENTER);
}

int mu_header(mu_Context *ctx, const char *label)
{
    return mu_header_ex(ctx, label, 0);
}
   
int mu_begin_treenode(mu_Context *ctx, const char *label, int opt)
{
    return mu_begin_treenode_ex(ctx, label, 0);
}
int mu_begin_window(mu_Context *ctx, const char *title, mu_Rect rect)
{
    return mu_begin_window_ex(ctx, title, rect, 0);
}
void mu_begin_panel(mu_Context *ctx, const char *name)
{
    return mu_begin_panel_ex(ctx, name, 0);
}

void mu_text(mu_Context *ctx, const char *text);
void mu_label(mu_Context *ctx, const char *text);
int mu_button_ex(mu_Context *ctx, const char *label, int icon, int opt);
int mu_checkbox(mu_Context *ctx, const char *label, int *state);
int mu_textbox_raw(mu_Context *ctx, char *buf, int bufsz, mu_Id id, mu_Rect r, int opt);
int mu_textbox_ex(mu_Context *ctx, char *buf, int bufsz, int opt);
int mu_slider_ex(mu_Context *ctx, mu_Real *value, mu_Real low, mu_Real high, mu_Real step, const char *fmt, int opt);
int mu_number_ex(mu_Context *ctx, mu_Real *value, mu_Real step, const char *fmt, int opt);
int mu_header_ex(mu_Context *ctx, const char *label, int opt);
int mu_begin_treenode_ex(mu_Context *ctx, const char *label, int opt);
void mu_end_treenode(mu_Context *ctx);
int mu_begin_window_ex(mu_Context *ctx, const char *title, mu_Rect rect, int opt);
void mu_end_window(mu_Context *ctx);
void mu_open_popup(mu_Context *ctx, const char *name);
int mu_begin_popup(mu_Context *ctx, const char *name);
void mu_end_popup(mu_Context *ctx);
void mu_begin_panel_ex(mu_Context *ctx, const char *name, int opt);
void mu_end_panel(mu_Context *ctx);
