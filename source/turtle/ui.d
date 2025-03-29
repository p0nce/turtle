module turtle.ui;

// Port of rxi microui v2.02: git@github.com:rxi/microui.git

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

import core.stdc.string: memset, strlen, memcpy;
import core.stdc.stdlib: strtod, qsort;
import core.stdc.stdio: sprintf;
import colors;
import dplug.graphics.font;
import dplug.math;

// <public API>
public:

enum MU_VERSION = "2.02";
alias mu_Real = float;
alias mu_Font = void*;

// TODO: phase out in favor of vec2i
struct mu_Vec2
{ 
    int x = 0, 
        y = 0; 
}

// TODO: phase out in favor of box2i
struct mu_Rect
{ 
    int x = 0, 
        y = 0, 
        w = 0, 
        h = 0; 
}

/// provides interface to immediate UI functionality in turtle.
/// This is the original microUI but also get passed a buffer, font size, etc.
class MicroUI
{
public: // for users


    // Id for widget, this is typically auto-generated.
    alias mu_Id = uint;

    /**
        Create 2D Vector for use in UI.
        TODO: replace by vec2i
    */
    mu_Vec2 vec2(int x, int y)
    {
        return mu_Vec2(x, y);
    }

    /**
        Create 2D rectangle for use in UI.
        TODO: replace by box2i
    */
    mu_Rect rect(int x, int y, int w, int h)
    {
        return mu_Rect(x, y, w, h);
    }

    enum : int 
    {
        MU_CLIP_PART = 1,
        MU_CLIP_ALL
    }

    //
    // basic widgets
    //

    void text(const(char)* text) 
    {
        const(char)* start, end, p = text;
        int width = -1;
        mu_Font font = style.font;
        Color color = style.colors[MU_COLOR_TEXT];
        layout_begin_column();
        layout_row(1, &width, text_height(font));
        do {
            mu_Rect r = layout_next();
            int w = 0;
            start = end = p;
            do {
                const(char)* word = p;
                while (*p && *p != ' ' && *p != '\n') { p++; }
                w += text_width(font, word, cast(int)(p - word));
                if (w > r.w && end != start) { break; }
                w += text_width(font, p, 1);
                end = p++;
            } while (*end && *end != '\n');
            draw_text(font, start, cast(int)(end - start), vec2(r.x, r.y), color);
            p = end + 1;
        } while (*end);
        layout_end_column();
    }

    void label(const(char)* text) 
    {
        draw_control_text(text, layout_next(), MU_COLOR_TEXT, 0);
    }

    int button(const(char)* label, int icon = 0, int opt = MU_OPT_ALIGNCENTER) 
    {
        int res = 0;
        mu_Id id = label ? get_id(ctx, label, istrlen(label))
            : get_id(ctx, &icon, isizeof!icon);
        mu_Rect r = mu_layout_next(ctx);
        update_control(ctx, id, r, opt);
        /* handle click */
        if (mouse_pressed == MU_MOUSE_LEFT && focus == id) {
            res |= MU_RES_SUBMIT;
        }
        /* draw */
        draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, opt);
        if (label) { draw_control_text(ctx, label, r, MU_COLOR_TEXT, opt); }
        if (icon) { draw_icon(ctx, icon, r, style.colors[MU_COLOR_TEXT]); }
        return res;
    }

    int checkbox(const(char)* label, int *state) 
    {
        int res = 0;
        mu_Id id = get_id(ctx, &state, isizeof!state);
        mu_Rect r = layout_next(ctx);
        mu_Rect box = rect(r.x, r.y, r.h, r.h);
        update_control(ctx, id, r, 0);
        /* handle click */
        if (mouse_pressed == MU_MOUSE_LEFT && focus == id) 
        {
            res |= MU_RES_CHANGE;
            *state = !*state;
        }
        /* draw */
        draw_control_frame(ctx, id, box, MU_COLOR_BASE, 0);
        if (*state) {
            draw_icon(ctx, MU_ICON_CHECK, box, style.colors[MU_COLOR_TEXT]);
        }
        r = rect(r.x + box.w, r.y, r.w - box.w, r.h);
        draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);
        return res;
    }

    int textbox(char *buf, int bufsz, int opt = 0) 
    {
        mu_Id id = get_id(ctx, &buf, cast(int) buf.sizeof);
        mu_Rect r = layout_next(ctx);
        return textbox_raw(ctx, buf, bufsz, id, r, opt);
    }


    int slider(mu_Real *value, mu_Real low, mu_Real high,
                  mu_Real step = 0, const(char) *fmt = MU_SLIDER_FMT, int opt = MU_OPT_ALIGNCENTER)
    {
        char[MU_MAX_FMT + 1] buf;
        mu_Rect thumb;
        int x, w, res = 0;
        mu_Real last = *value, v = last;
        mu_Id id = get_id(ctx, &value, cast(int) value.sizeof);
        mu_Rect base = mu_layout_next(ctx);

        /* handle text input mode */
        if (number_textbox(ctx, &v, base, id)) { return res; }

        /* handle normal mode */
        mu_update_control(ctx, id, base, opt);

        /* handle input */
        if (focus == id &&
            (mouse_down | mouse_pressed) == MU_MOUSE_LEFT)
        {
            v = low + (mouse_pos.x - base.x) * (high - low) / base.w;
            if (step) 
            { 
                v = (cast(long)((v + step / 2) / step)) * step; 
            }
        }
        /* clamp and store value, update res */
        *value = v = mu_clamp(v, low, high);
        if (last != v) { res |= MU_RES_CHANGE; }

        /* draw base */
        draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
        /* draw thumb */
        w = style.thumb_size;
        x = cast(int) ( (v - low) * (base.w - w) / (high - low) );
        thumb = mu_rect(base.x + x, base.y, w, base.h);
        draw_control_frame(ctx, id, thumb, MU_COLOR_BUTTON, opt);
        /* draw text  */
        sprintf(buf.ptr, fmt, v);
        draw_control_text(ctx, buf.ptr, base, MU_COLOR_TEXT, opt);

        return res;
    }



    int number(mu_Real *value, mu_Real step,
               const(char)* fmt = MU_SLIDER_FMT, 
               int opt = MU_OPT_ALIGNCENTER)
    {
        char[MU_MAX_FMT + 1] buf;
        int res = 0;
        mu_Id id = get_id(ctx, &value, cast(int) value.sizeof);
        mu_Rect base = layout_next(ctx);
        mu_Real last = *value;

        /* handle text input mode */
        if (number_textbox(ctx, value, base, id)) { return res; }

        /* handle normal mode */
        update_control(ctx, id, base, opt);

        /* handle input */
        if (focus == id && mouse_down == MU_MOUSE_LEFT) {
            *value += mouse_delta.x * step;
        }
        /* set flag if value changed */
        if (*value != last) { res |= MU_RES_CHANGE; }

        /* draw base */
        draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
        /* draw text  */
        sprintf(buf.ptr, fmt, *value);
        draw_control_text(ctx, buf.ptr, base, MU_COLOR_TEXT, opt);
        return res;
    }

    int begin_treenode(const(char)* label, int opt = 0) 
    {
        int res = header_internal(ctx, label, 1, opt);
        if (res & MU_RES_ACTIVE) {
            get_layout(ctx).indent += style.indent;
            id_stack.push(last_id);
        }
        return res;
    }


    void end_treenode() 
    {
        get_layout(ctx).indent -= style.indent;
        pop_id(ctx);
    }


    //
    // windows
    //

    int begin_window(const(char)* title, mu_Rect rect, int opt = 0) 
    {
        mu_Rect body;
        mu_Id id = get_id(title, istrlen(title));
        mu_Container *cnt = get_container_internal(id, opt);
        if (!cnt || !cnt.open) { return 0; }
        id_stack.push(id);

        if (cnt.rect.w == 0) { cnt.rect = rect; }
        begin_root_container(cnt);
        rect = body = cnt.rect;

        /* draw frame */
        if (~opt & MU_OPT_NOFRAME) {
            draw_frame(rect, MU_COLOR_WINDOWBG);
        }

        /* do title bar */
        if (~opt & MU_OPT_NOTITLE) {
            mu_Rect tr = rect;
            tr.h = style.title_height;
            draw_frame(tr, MU_COLOR_TITLEBG);

            /* do title text */
            if (~opt & MU_OPT_NOTITLE) 
            {
                mu_Id id2 = get_id("!title".ptr, 6);
                update_control(id2, tr, opt);
                draw_control_text(title, tr, MU_COLOR_TITLETEXT, opt);
                if (id == focus && mouse_down == MU_MOUSE_LEFT) {
                    cnt.rect.x += mouse_delta.x;
                    cnt.rect.y += mouse_delta.y;
                }
                body.y += tr.h;
                body.h -= tr.h;
            }

            /* do `close` button */
            if (~opt & MU_OPT_NOCLOSE) 
            {
                mu_Id id2 = get_id("!close".ptr, 6);
                mu_Rect r = mu_rect(tr.x + tr.w - tr.h, tr.y, tr.h, tr.h);
                tr.w -= r.w;
                draw_icon(MU_ICON_CLOSE, r, style.colors[MU_COLOR_TITLETEXT]);
                update_control(id, r, opt);
                if (mouse_pressed == MU_MOUSE_LEFT && id2 == focus) {
                    cnt.open = 0;
                }
            }
        }

        push_container_body(cnt, body, opt);

        /* do `resize` handle */
        if (~opt & MU_OPT_NORESIZE) 
        {
            int sz = style.title_height;
            mu_Id id2 = get_id("!resize".ptr, 7);
            mu_Rect r = rect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz);
            update_control(id2, r, opt);
            if (id2 == focus && mouse_down == MU_MOUSE_LEFT) 
            {
                cnt.rect.w = mu_max(96, cnt.rect.w + mouse_delta.x);
                cnt.rect.h = mu_max(64, cnt.rect.h + mouse_delta.y);
            }
        }

        /* resize to content size */
        if (opt & MU_OPT_AUTOSIZE) {
            mu_Rect r = get_layout().body;
            cnt.rect.w = cnt.content_size.x + (cnt.rect.w - r.w);
            cnt.rect.h = cnt.content_size.y + (cnt.rect.h - r.h);
        }

        /* close if this is a popup window and elsewhere was clicked */
        if (opt & MU_OPT_POPUP && mouse_pressed && hover_root != cnt) {
            cnt.open = 0;
        }

        push_clip_rect(cnt.body);
        return MU_RES_ACTIVE;
    }


    void end_window() 
    {
        pop_clip_rect();
        end_root_container();
    }

    void begin_panel(const(char)* name, int opt = 0) 
    {
        mu_Container *cnt;
        push_id(name, istrlen(name));
        cnt = get_container_internal(last_id, opt);
        cnt.rect = layout_next();
        if (~opt & MU_OPT_NOFRAME) {
            draw_frame(cnt.rect, MU_COLOR_PANELBG);
        }
        container_stack.push(cnt);
        push_container_body(cnt, cnt.rect, opt);
        push_clip_rect(cnt.body);
    }

    void end_panel() 
    {
        pop_clip_rect();
        pop_container();
    }

    //
    // popups
    //
    void open_popup(const(char)* name) 
    {
        mu_Container *cnt = get_container(name);
        /* set as hover root so popup isn't closed in begin_window()  */
        hover_root = next_hover_root = cnt;
        /* position at mouse cursor, open and bring-to-front */
        cnt.rect = mu_rect(mouse_pos.x, mouse_pos.y, 1, 1);
        cnt.open = 1;
        bring_to_front(cnt);
    }

    int mu_begin_popup(const(char)* name) 
    {
        int opt = MU_OPT_POPUP | MU_OPT_AUTOSIZE | MU_OPT_NORESIZE |
            MU_OPT_NOSCROLL | MU_OPT_NOTITLE | MU_OPT_CLOSED;
        return begin_window(name, mu_rect(0, 0, 0, 0), opt);
    }

    void end_popup() 
    {
        end_window();
    }





    //
    // draw
    //


    void draw_rect(mu_Rect rect, Color color) 
    {
        mu_Command *cmd;
        rect = intersect_rects(rect, get_clip_rect());
        if (rect.w > 0 && rect.h > 0) {
            cmd = push_command( MU_COMMAND_RECT, cast(int)mu_RectCommand.sizeof);
            cmd.rect.rect = rect;
            cmd.rect.color = color;
        }
    }

    void mu_draw_box(mu_Rect rect, Color color) 
    {
        draw_rect(rect(rect.x + 1, rect.y, rect.w - 2, 1), color);
        draw_rect(rect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
        draw_rect(rect(rect.x, rect.y, 1, rect.h), color);
        draw_rect(rect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
    }

    void draw_text(mu_Font font, 
                   const(char)* str, int len,
                   mu_Vec2 pos, Color color)
    {
        mu_Command *cmd;
        mu_Rect rect = rect(pos.x, pos.y, text_width(font, str, len), text_height(font));
        int clipped = check_clip(rect);
        if (clipped == MU_CLIP_ALL ) 
            return;
        if (clipped == MU_CLIP_PART) 
        { 
            set_clip(get_clip_rect()); 
        }

        /* add command */
        if (len < 0) 
        { 
            len = istrlen(str); // ugly
        }

        cmd = push_command(MU_COMMAND_TEXT, cast(int)(mu_TextCommand.sizeof) + len);
        memcpy(cmd.text.str.ptr, str, len);
        cmd.text.str.ptr[len] = '\0'; // do not perform bounds here, since it's out of struct
        cmd.text.pos = pos;
        cmd.text.color = color;
        cmd.text.font = font;
        /* reset clipping if it was set */
        if (clipped) 
        { 
            set_clip(unclipped_rect); 
        }
    }

    void draw_icon(int id, mu_Rect rect, Color color) 
    {
        mu_Command *cmd;
        /* do clip command if the rect isn't fully contained within the cliprect */
        int clipped = check_clip( rect);
        if (clipped == MU_CLIP_ALL )
            return;
        if (clipped == MU_CLIP_PART) 
        { 
            set_clip(get_clip_rect()); 
        }

        /* do icon command */
        cmd = push_command(MU_COMMAND_ICON, cast(int) mu_IconCommand.sizeof);
        cmd.icon.id = id;
        cmd.icon.rect = rect;
        cmd.icon.color = color;
        /* reset clipping if it was set */
        if (clipped) 
            set_clip(unclipped_rect);
    }



    //
    // ids
    //

    mu_Id get_id(const(void)* data, int size) 
    {
        static void compute_hash(mu_Id *hash, const(void) *data, int size) 
        {
            const(ubyte)*p = cast(const(ubyte)*) data;
            while (size--) 
            {
                *hash = (*hash ^ *p++) * 16777619;
            }
        }

        /* 32bit fnv-1a hash */
        enum mu_Id HASH_INITIAL = 2166136261;
        int idx = id_stack.idx;
        mu_Id res = (idx > 0) ? id_stack.items[idx - 1] : HASH_INITIAL;
        compute_hash(&res, data, size);
        last_id = res;
        return res;
    }

    void push_id(const(void)* data, int size) 
    {
        id_stack.push(get_id(data, size));
    }

    void pop_id() 
    {
        id_stack.pop();
    }

    void set_focus(mu_Id id)
    {
        focus = id;
        updated_focus = 1;
    }

    void mu_bring_to_front(mu_Container *cnt) 
    {
        cnt.zindex = ++last_zindex;
    }


    //
    // clipping
    //
    void push_clip_rect(mu_Rect rect)
    {
        mu_Rect last = get_clip_rect();
        clip_stack.push(intersect_rects(rect, last));
    }

    void pop_clip_rect()
    {
        clip_stack.pop();
    }

    mu_Rect get_clip_rect()
    {
        assert(clip_stack.idx > 0);
        return clip_stack.items[clip_stack.idx - 1];
    }

    int check_clip(mu_Rect r)
    {
        mu_Rect cr = get_clip_rect();
        if (r.x > cr.x + cr.w || r.x + r.w < cr.x ||
            r.y > cr.y + cr.h || r.y + r.h < cr.y   ) 
        { 
            return MU_CLIP_ALL; 
        }
        if (r.x >= cr.x && r.x + r.w <= cr.x + cr.w &&
            r.y >= cr.y && r.y + r.h <= cr.y + cr.h ) 
        { 
            return 0; 
        }
        return MU_CLIP_PART;        
    }

    void set_clip(mu_Rect rect) 
    {
        mu_Command *cmd;
        cmd = push_command(MU_COMMAND_CLIP, cast(int)mu_ClipCommand.sizeof);
        cmd.clip.rect = rect;
    }

    //
    // containers
    //
    mu_Container* get_current_container() 
    {
        assert(container_stack.idx > 0);
        return container_stack.items[container_stack.idx - 1];
    }

    mu_Container* get_container(const(char)* name) 
    {
        mu_Id id = get_id(name, istrlen(name));
        return get_container_internal(id, 0);
    }

    
    //
    // layout
    //
    void layout_row(int items, const(int)* widths, int height) 
    {
        mu_Layout *layout = get_layout();
        if (widths) 
        {
            assert(items <= MU_MAX_WIDTHS);
            memcpy(layout.widths.ptr, widths, items * (widths[0]).sizeof);
        }
        layout.items = items;
        layout.position = mu_vec2(layout.indent, layout.next_row);
        layout.size.y = height;
        layout.item_index = 0;
    }

    void layout_width(int width) 
    {
        get_layout().size.x = width;
    }

    void layout_height(int height) 
    {
        get_layout().size.y = height;
    }

    void layout_begin_column() 
    {
        push_layout(layout_next(), vec2(0, 0));
    }

    void layout_end_column() 
    {
        mu_Layout* a, b;
        b = get_layout();
        layout_stack.pop();
        /* inherit position/next_row/max from child layout if they are greater */
        a = get_layout();
        a.position.x = mu_max(a.position.x, b.position.x + b.body.x - a.body.x);
        a.next_row = mu_max(a.next_row, b.next_row + b.body.y - a.body.y);
        a.max.x = mu_max(a.max.x, b.max.x);
        a.max.y = mu_max(a.max.y, b.max.y);
    }

    void layout_set_next(mu_Rect r, int relative) 
    {
        mu_Layout *layout = get_layout();
        layout.next = r;
        layout.next_type = relative ? RELATIVE : ABSOLUTE;
    }

    mu_Rect layout_next() 
    {
        mu_Layout *layout = get_layout();
        mu_Style *style = style;
        mu_Rect res;

        if (layout.next_type) {
            /* handle rect set by `mu_layout_set_next` */
            int type = layout.next_type;
            layout.next_type = 0;
            res = layout.next;
            if (type == ABSOLUTE) { return (last_rect = res); }

        } else {
            /* handle next row */
            if (layout.item_index == layout.items) {
                mu_layout_row(layout.items, null, layout.size.y);
            }

            /* position */
            res.x = layout.position.x;
            res.y = layout.position.y;

            /* size */
            res.w = layout.items > 0 ? layout.widths[layout.item_index] : layout.size.x;
            res.h = layout.size.y;
            if (res.w == 0) { res.w = style.size.x + style.padding * 2; }
            if (res.h == 0) { res.h = style.size.y + style.padding * 2; }
            if (res.w <  0) { res.w += layout.body.w - res.x + 1; }
            if (res.h <  0) { res.h += layout.body.h - res.y + 1; }

            layout.item_index++;
        }

        /* update position */
        layout.position.x += res.w + style.spacing;
        layout.next_row = mu_max(layout.next_row, res.y + res.h + style.spacing);

        /* apply body offset */
        res.x += layout.body.x;
        res.y += layout.body.y;

        /* update max position */
        layout.max.x = mu_max(layout.max.x, res.x + res.w);
        layout.max.y = mu_max(layout.max.y, res.y + res.h);

        return (last_rect = res);
    }

package: // for game.d

    /**
        Called by game.d, create the immediate UI system.
    */
    this(Font font) 
    {
        // TODO init all .fields to 0        
        _style = default_style(font);
        style = &_style;
    }

    /**
        Called by game.d, start defining UI.
    */
    void begin() 
    {
        assert(text_width && text_height);
        command_list.idx = 0;
        root_list.idx = 0;
        scroll_target = null;
        hover_root = next_hover_root;
        next_hover_root = null;
        mouse_delta.x = mouse_pos.x - last_mouse_pos.x;
        mouse_delta.y = mouse_pos.y - last_mouse_pos.y;
        frame++;
    }

    /**
        Called by game.d, end defining UI.
    */
    void end() 
    {
        int i, n;
        /* check stacks */
        assert(container_stack.idx == 0);
        assert(clip_stack.idx      == 0);
        assert(id_stack.idx        == 0);
        assert(layout_stack.idx    == 0);

        /* handle scroll input */
        if (scroll_target) 
        {
            scroll_target.scroll.x += scroll_delta.x;
            scroll_target.scroll.y += scroll_delta.y;
        }

        /* unset focus if focus id was not touched this frame */
        if (!updated_focus) 
        { 
            focus = 0; 
        }

        updated_focus = 0;

        /* bring hover root to front if mouse was pressed */
        if (mouse_pressed && next_hover_root &&
            next_hover_root.zindex < last_zindex &&
            next_hover_root.zindex >= 0
            ) 
        {
                mu_bring_to_front(next_hover_root);
        }

        /* reset input state */
        key_pressed = 0;
        input_text_buf[0] = '\0';
        mouse_pressed = 0;
        scroll_delta = mu_vec2(0, 0);
        last_mouse_pos = mouse_pos;

        /* sort root containers by zindex */
        n = root_list.idx;
        qsort(root_list.items.ptr, n, (mu_Container*).sizeof, &compare_zindex);

        /* set root container jump commands */
        for (i = 0; i < n; i++) 
        {
            mu_Container *cnt = root_list.items[i];
            /* if this is the first container then make the first command jump to it.
            ** otherwise set the previous container's tail to jump to this one */
            if (i == 0) 
            {
                mu_Command *cmd = cast(mu_Command*) command_list.items;
                cmd.jump.dst = cast(char*) cnt.head + mu_JumpCommand.sizeof;
            } 
            else 
            {
                mu_Container *prev = root_list.items[i - 1];
                prev.tail.jump.dst = cast(char*) cnt.head + mu_JumpCommand.sizeof;
            }

            /* make the last container's tail jump to the end of command list */
            if (i == n - 1) 
            {
                cnt.tail.jump.dst = command_list.items.ptr + command_list.idx;
            }
        }
    }


    // 
    // input handlers, called by game.d
    //

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

    void input_mousemove(int x, int y) 
    {
        mouse_pos = mu_vec2(x, y);
    }

    void input_mousedown(int x, int y, int btn) 
    {
        input_mousemove(x, y);
        mouse_down |= btn;
        mouse_pressed |= btn;
    }


    void input_mouseup(int x, int y, int btn) 
    {
        input_mousemove(x, y);
        mouse_down &= ~btn;
    }

    void input_scroll(int x, int y) 
    {
        scroll_delta.x += x;
        scroll_delta.y += y;
    }

    void input_keydown(int key) 
    {
        key_pressed |= key;
        key_down |= key;
    }

    void input_keyup(int key) 
    {
        key_down &= ~key;
    }

    void input_text(const(char)*text) 
    {
        int len = istrlen(input_text_buf.ptr);
        int size = istrlen(text) + 1;
        assert(len + size <= isizeof!(mu_Context.input_text_buf));
        memcpy(input_text_buf.ptr + len, text, size);
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

    /* package callbacks */
    @nogc nothrow
    {
        int function(mu_Font font, const(char)*str, int len) text_width;
        int function(mu_Font font) text_height;
    }


    //
    // commandlist
    //

    mu_Command* push_command(int type, int size) 
    {
        mu_Command *cmd = cast(mu_Command*) (command_list.items.ptr + command_list.idx);
        assert(command_list.idx + size < MU_COMMANDLIST_SIZE);
        cmd.base.type = type;
        cmd.base.size = size;
        command_list.idx += size;
        return cmd;
    }


    int next_command(mu_Command **cmd) 
    {
        if (*cmd) {
            *cmd = cast(mu_Command*) ((cast(char*) *cmd) + (*cmd).base.size);
        } else {
            *cmd = cast(mu_Command*) command_list.items;
        }
        while (cast(char*) *cmd != command_list.items.ptr + command_list.idx) 
        {
            if ((*cmd).type != MU_COMMAND_JUMP) { return 1; }
            *cmd = cast(mu_Command*)( (*cmd).jump.dst );
        }
        return 0;
    }

    mu_Command* push_jump(mu_Command *dst) 
    {
        mu_Command *cmd;
        cmd = push_command(MU_COMMAND_JUMP, cast(int)mu_JumpCommand.sizeof);
        cmd.jump.dst = dst;
        return cmd;
    }


private:
    enum size_t MU_COMMANDLIST_SIZE     = (256 * 1024);
    enum size_t MU_ROOTLIST_SIZE        = 32;
    enum size_t MU_CONTAINERSTACK_SIZE  = 32;
    enum size_t MU_CLIPSTACK_SIZE       = 32;
    enum size_t MU_IDSTACK_SIZE         = 32;
    enum size_t MU_LAYOUTSTACK_SIZE     = 16;
    enum size_t MU_CONTAINERPOOL_SIZE   = 48;
    enum size_t MU_TREENODEPOOL_SIZE    = 48;
    alias MU_REAL = float;
    enum string MU_REAL_FMT = "%.3g";
    enum string MU_SLIDER_FMT = "%.2f";
    enum size_t MU_MAX_FMT = 127;

    enum unclipped_rect = mu_Rect(0, 0, 0x1000000, 0x1000000);

    enum 
    { 
        RELATIVE = 1, 
        ABSOLUTE = 2 
    }

    /* core state */
    mu_Style _style;
    mu_Style *style = nullptr;
    mu_Id hover = 0;
    mu_Id focus = 0;
    mu_Id last_id = 0;
    mu_Rect last_rect;
    int last_zindex = 0;
    int updated_focus = 0;
    int frame = 0;
    mu_Container *hover_root = null;
    mu_Container *next_hover_root = null;
    mu_Container *scroll_target = null;
    char[MU_MAX_FMT] number_edit_buf;
    mu_Id number_edit = 0;
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
    char[32] input_text_buf;


    static struct mu_Layout
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

    static struct mu_PoolItem
    { 
        mu_Id id; 
        int last_update; 
    }

    static struct mu_BaseCommand
    { 
        int type, size; 
    }

    static struct mu_JumpCommand
    { 
        mu_BaseCommand base; 
        void *dst; 
    }

    static struct mu_ClipCommand
    { 
        mu_BaseCommand base; 
        mu_Rect rect; 
    }

    static struct mu_RectCommand
    { 
        mu_BaseCommand base; 
        mu_Rect rect; 
        Color color; 
    }

    static struct mu_TextCommand
    { 
        mu_BaseCommand base; 
        mu_Font font; 
        mu_Vec2 pos; 
        Color color; 
        char[1] str; 
    }

    static struct mu_IconCommand
    { 
        mu_BaseCommand base; 
        mu_Rect rect; 
        int id; 
        Color color; 
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



    static struct mu_Container
    {
        mu_Command *head, tail;
        mu_Rect rect;
        mu_Rect body;
        mu_Vec2 content_size;
        mu_Vec2 scroll;
        int zindex;
        int open;
    }

    static struct mu_Style
    {
        mu_Font font = null;
        mu_Vec2 size = mu_Vec2(0, 0);
        int padding = 0;
        int spacing = 0;
        int indent = 0;
        int title_height = 0;
        int scrollbar_size = 0;
        int thumb_size = 0;
        Color[MU_COLOR_MAX] colors;
    }

    void draw_frame(mu_Rect rect, int colorid) 
    {
        mu_draw_rect(rect, style.colors[colorid]);
        if (colorid == MU_COLOR_SCROLLBASE  ||
            colorid == MU_COLOR_SCROLLTHUMB ||
            colorid == MU_COLOR_TITLEBG) 
        { 
            return; 
        }

        /* draw border */
        Color borderCol = style.colors[MU_COLOR_BORDER];
        if (borderCol.toRGBA8.a) // FUTURE: isFullyTransparent
        {
            mu_draw_box(expand_rect(rect, 1), borderCol);
        }
    }

    //
    // pool (private)
    //

    int pool_init(mu_PoolItem *items, int len, mu_Id id) 
    {
        int i, n = -1, f = frame;
        for (i = 0; i < len; i++) {
            if (items[i].last_update < f) {
                f = items[i].last_update;
                n = i;
            }
        }
        assert(n > -1);
        items[n].id = id;
        pool_update(items, n);
        return n;
    }

    int pool_get(mu_PoolItem *items, int len, mu_Id id) 
    {
        int i;
        for (i = 0; i < len; i++) 
        {
            if (items[i].id == id) 
                return i;
        }
        return -1;
    }

    void pool_update(mu_PoolItem *items, int idx) 
    {
        items[idx].last_update = frame;
    }


    //
    // styles
    // 

    // Default style on construction
    mu_Style default_style(Font font)
    {
        return mu_Style
            (
             /* font | size | padding | spacing | indent */
             cast(void*)font, mu_Vec2(68, 10), 5*2, 4*2, 24*2,
             /* title_height | scrollbar_size | thumb_size */
             24*2, 12*2, 8*2,
             [
                Color(RGBA8(230, 230, 230, 255 )), /* MU_COLOR_TEXT */
                Color(RGBA8(25,  25,  25,  255 )), /* MU_COLOR_BORDER */
                Color(RGBA8(50,  50,  50,  255 )), /* MU_COLOR_WINDOWBG */
                Color(RGBA8(25,  25,  25,  255 )), /* MU_COLOR_TITLEBG */
                Color(RGBA8(240, 240, 240, 255 )), /* MU_COLOR_TITLETEXT */
                Color(RGBA8(0,   0,   0,   0   )), /* MU_COLOR_PANELBG */
                Color(RGBA8(75,  75,  75,  255 )), /* MU_COLOR_BUTTON */
                Color(RGBA8(95,  95,  95,  255 )), /* MU_COLOR_BUTTONHOVER */
                Color(RGBA8(115, 115, 115, 255 )), /* MU_COLOR_BUTTONFOCUS */
                Color(RGBA8(30,  30,  30,  255 )), /* MU_COLOR_BASE */
                Color(RGBA8(35,  35,  35,  255 )), /* MU_COLOR_BASEHOVER */
                Color(RGBA8(40,  40,  40,  255 )), /* MU_COLOR_BASEFOCUS */
                Color(RGBA8(43,  43,  43,  255 )), /* MU_COLOR_SCROLLBASE */
                Color(RGBA8(30,  30,  30,  255 ))  /* MU_COLOR_SCROLLTHUMB */
             ]
             );
    }

    //
    // layouts (private)
    //

    void push_layout(mu_Rect body, mu_Vec2 scroll) 
    {
        mu_Layout layout;
        int width = 0;
        memset(&layout, 0, layout.sizeof); // PERF: is useless 
        layout.body = mu_rect(body.x - scroll.x, body.y - scroll.y, body.w, body.h);
        layout.max = mu_vec2(-0x1000000, -0x1000000);
        layout_stack.push(layout);
        mu_layout_row(1, &width, 0);
    }

    mu_Layout* get_layout() 
    {
        return &layout_stack.items[layout_stack.idx - 1];
    }

    //
    // containers (private)
    //
    mu_Container* get_container_internal(mu_Id id, int opt) 
    {
        mu_Container *cnt;
        /* try to get existing container from pool */
        int idx = pool_get(container_pool.ptr, MU_CONTAINERPOOL_SIZE, id);
        if (idx >= 0) 
        {
            if (containers[idx].open || ~opt & MU_OPT_CLOSED) 
            {
                pool_update(container_pool.ptr, idx);
            }
            return &containers[idx];
        }
        if (opt & MU_OPT_CLOSED) { return null; }
        /* container not found in pool: init new container */
        idx = pool_init(container_pool.ptr, MU_CONTAINERPOOL_SIZE, id);
        cnt = &containers[idx];
        memset(cnt, 0, (*cnt).sizeof);
        cnt.open = 1;
        bring_to_front(cnt);
        return cnt;
    }

    void pop_container() 
    {
        mu_Container *cnt = get_current_container();
        mu_Layout *layout = get_layout();
        cnt.content_size.x = layout.max.x - layout.body.x;
        cnt.content_size.y = layout.max.y - layout.body.y;
        /* pop container, layout and id */
        container_stack.pop();
        layout_stack.pop();
        pop_id();
    }

    void begin_root_container(mu_Container *cnt) 
    {
        container_stack.push(cnt);
        /* push container to roots list and push head command */
        root_list.push(cnt);
        cnt.head = push_jump(null);
        /* set as hover root if the mouse is overlapping this container and it has a
        ** higher zindex than the current hover root */
        if (rect_overlaps_vec2(cnt.rect, mouse_pos) &&
            (!next_hover_root || cnt.zindex > next_hover_root.zindex)
            ) {
                next_hover_root = cnt;
            }
        /* clipping is reset here in case a root-container is made within
        ** another root-containers's begin/end block; this prevents the inner
        ** root-container being clipped to the outer */
        clip_stack.push(unclipped_rect);
    }


    void end_root_container() 
    {
        /* push tail 'goto' jump command and set head 'skip' command. the final steps
        ** on initing these are done in mu_end() */
        mu_Container *cnt = get_current_container();
        cnt.tail = push_jump(null);
        cnt.head.jump.dst = command_list.items.ptr + command_list.idx;
        /* pop base clip rect and container */
        pop_clip_rect();
        pop_container();
    }

    //
    // control internals
    //

    void draw_control_frame(mu_Id id, mu_Rect rect,
                               int colorid, int opt)
    {
        if (opt & MU_OPT_NOFRAME) { return; }
        colorid += (focus == id) ? 2 : (hover == id) ? 1 : 0;
        draw_frame(rect, colorid);
    }

    void draw_control_text(const(char)* str, mu_Rect rect,
                              int colorid, int opt)
    {
        mu_Vec2 pos;
        mu_Font font = style.font;
        int tw = text_width(font, str, -1);
        mu_push_clip_rect(rect);
        pos.y = rect.y + (rect.h - text_height(font)) / 2;
        if (opt & MU_OPT_ALIGNCENTER) {
            pos.x = rect.x + (rect.w - tw) / 2;
        } else if (opt & MU_OPT_ALIGNRIGHT) {
            pos.x = rect.x + rect.w - tw - style.padding;
        } else {
            pos.x = rect.x + style.padding;
        }
        draw_text(font, str, -1, pos, style.colors[colorid]);
        mu_pop_clip_rect();
    }



    int mouse_over( mu_Rect rect) 
    {
        return rect_overlaps_vec2(rect, mouse_pos) &&
            rect_overlaps_vec2(get_clip_rect(), mouse_pos) &&
            in_hover_root();
    }

    int in_hover_root() 
    {
        int i = container_stack.idx;
        while (i--) {
            if (container_stack.items[i] == hover_root) { return 1; }
            /* only root containers have their `head` field set; stop searching if we've
            ** reached the current root container */
            if (container_stack.items[i].head) { break; }
        }
        return 0;
    }

    void update_control( mu_Id id, mu_Rect rect, int opt) 
    {
        int mouseover = mouse_over(rect);

        if (focus == id) { updated_focus = 1; }
        if (opt & MU_OPT_NOINTERACT) { return; }
        if (mouseover && !mouse_down) { hover = id; }

        if (focus == id) {
            if (mouse_pressed && !mouseover) { set_focus(0); }
            if (!mouse_down && ~opt & MU_OPT_HOLDFOCUS) { set_focus(0); }
        }

        if (hover == id) {
            if (mouse_pressed) {
                set_focus(id);
            } else if (!mouseover) {
                hover = 0;
            }
        }
    }


    int textbox_raw(char *buf, int bufsz, mu_Id id, mu_Rect r,
                    int opt = 0)
    {
        int res = 0;
        update_control(id, r, opt | MU_OPT_HOLDFOCUS);

        if (focus == id) {
            /* handle text input */
            int len = istrlen(buf);
            int n = mu_min(bufsz - len - 1, istrlen(input_text_buf.ptr));
            if (n > 0) {
                memcpy(buf + len, input_text_buf.ptr, n);
                len += n;
                buf[len] = '\0';
                res |= MU_RES_CHANGE;
            }
            /* handle backspace */
            if (key_pressed & MU_KEY_BACKSPACE && len > 0) 
            {
                /* skip utf-8 continuation bytes */
                while ((buf[--len] & 0xc0) == 0x80 && len > 0){}
                buf[len] = '\0';
                res |= MU_RES_CHANGE;
            }
            /* handle return */
            if (key_pressed & MU_KEY_RETURN) {
            set_focus(0);
                res |= MU_RES_SUBMIT;
            }
        }

        /* draw */
        draw_control_frame(id, r, MU_COLOR_BASE, opt);
        if (focus == id) {
            Color color = style.colors[MU_COLOR_TEXT];
            mu_Font font = style.font;
            int textw = text_width(font, buf, -1);
            int texth = text_height(font);
            int ofx = r.w - style.padding - textw - 1;
            int textx = r.x + mu_min(ofx, style.padding);
            int texty = r.y + (r.h - texth) / 2;
            push_clip_rect(r);
            draw_text(font, buf, -1, vec2(textx, texty), color);
            draw_rect(rect(textx + textw, texty, 1, texth), color);
            pop_clip_rect();
        } else {
            draw_control_text(buf, r, MU_COLOR_TEXT, opt);
        }

        return res;
    }

    int number_textbox(mu_Real *value, mu_Rect r, mu_Id id) 
    {
        if (mouse_pressed == MU_MOUSE_LEFT && key_down & MU_KEY_SHIFT &&
            hover == id
            ) {
                number_edit = id;
                sprintf(number_edit_buf.ptr, MU_REAL_FMT.ptr, *value);
            }
        if (number_edit == id) 
        {
            int res = textbox_raw(number_edit_buf.ptr, isizeof!(mu_Context.number_edit_buf), id, r, 0);
            if (res & MU_RES_SUBMIT || focus != id) 
            {
                *value = strtod(number_edit_buf.ptr, null);
                number_edit = 0;
            } else {
                return 1;
            }
        }
        return 0;
    }




    void scrollbar(bool VERT)(mu_Context* ctx, 
                              mu_Container* cnt, 
                              mu_Rect* b, 
                              mu_Vec2 cs)
    {
        /* only add scrollbar if content size is larger than body */

        static if (VERT)
        {
            enum DIM = "y";
            int maxscroll = cs.y - b.h;
            bool needScroll = b.h > 0;
        }
        else
        {
            enum DIM = "x";
            int maxscroll = cs.x - b.w;
            bool needScroll = b.w > 0;
        }

        if (maxscroll > 0 && needScroll) 
        {
            mu_Rect base, thumb;
            enum string idBuf = "!scrollbar" ~ DIM;
            mu_Id id = get_id(ctx, idBuf.ptr, 11);

            /* get sizing / positioning */
            base = *b;
            static if (VERT)
            {
                base.x = b.x + b.w;
                base.w = style.scrollbar_size;
            }
            else
            {
                base.y = b.y + b.h;
                base.h = style.scrollbar_size;
            }

            /* handle input */
            mu_update_control(ctx, id, base, 0);
            if (focus == id && mouse_down == MU_MOUSE_LEFT) 
            {
                static if (VERT)
                {
                    cnt.scroll.y += mouse_delta.y * cs.y / base.h;
                }
                else
                {
                    cnt.scroll.x += mouse_delta.x * cs.x / base.w;
                }
            }

            /* clamp scroll to limits */
            static if (VERT)
                cnt.scroll.y = mu_clamp(cnt.scroll.y, 0, maxscroll);
            else
                cnt.scroll.x = mu_clamp(cnt.scroll.x, 0, maxscroll);

            /* draw base and thumb */
            draw_frame(ctx, base, MU_COLOR_SCROLLBASE);
            thumb = base;
            static if (VERT)
            {
                thumb.h = mu_max(style.thumb_size, base.h * b.h / cs.y);
                thumb.y += cnt.scroll.y * (base.h - thumb.h) / maxscroll;
            }
            else
            {
                thumb.w = mu_max(style.thumb_size, base.w * b.w / cs.x);
                thumb.x += cnt.scroll.x * (base.w - thumb.w) / maxscroll;
            }
            draw_frame(ctx, thumb, MU_COLOR_SCROLLTHUMB);

            /* set this as the scroll_target (will get scrolled on mousewheel) */
            /* if the mouse is over it */
            if (mu_mouse_over(ctx, *b)) { scroll_target = cnt; }
        } 
        else 
        {
            static if (VERT)
                cnt.scroll.y = 0;
            else
                cnt.scroll.x = 0;
        }
    }

    void scrollbars(mu_Container *cnt, mu_Rect *body) 
    {
        int sz = style.scrollbar_size;
        mu_Vec2 cs = cnt.content_size;
        cs.x += style.padding * 2;
        cs.y += style.padding * 2;
        mu_push_clip_rect(ctx, *body);
        /* resize body to make room for scrollbars */
        if (cs.y > cnt.body.h) { body.w -= sz; }
        if (cs.x > cnt.body.w) { body.h -= sz; }
        /* to create a horizontal or vertical scrollbar almost-identical code is
        ** used; only the references to `x|y` `w|h` need to be switched */
        scrollbar!true(ctx, cnt, body, cs);
        scrollbar!false(ctx, cnt, body, cs);
        mu_pop_clip_rect(ctx);
    }

    void push_container_body(mu_Container *cnt, mu_Rect body, int opt) 
    {
        if (~opt & MU_OPT_NOSCROLL) { scrollbars(ctx, cnt, &body); }
        push_layout(ctx, expand_rect(body, -style.padding), cnt.scroll);
        cnt.body = body;
    }
}

// </public API>

private:
private:
private:    

struct mu_stack(T, size_t N)
{
    int idx;
    T[N] items;

    void push(T val)
    {
        items[idx++] = val;
    }

    void pop()
    {
        assert(idx > 0);
        idx--;
    }
}

// microui rightly uses int as size_t
int istrlen(const(char)* s)
{
    size_t len = strlen(s);
    assert(len <= int.max);
    return cast(int) strlen(s);
}

// replaces cast(int) blah.sizeof
enum isizeof(alias T) = T.sizeof;

T mu_min(T)(T a, T b) { return a < b ? a : b; }
T mu_max(T)(T a, T b) { return a > b ? a : b; }
T mu_clamp(T)(T x, T a, T b) { return mu_min(b, mu_max(a, x)); }


enum size_t MU_MAX_WIDTHS           = 16;

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




mu_Rect expand_rect(mu_Rect rect, int n) 
{
    return mu_rect(rect.x - n, rect.y - n, rect.w + n * 2, rect.h + n * 2);
}

mu_Rect intersect_rects(mu_Rect r1, mu_Rect r2) 
{
    int x1 = mu_max(r1.x, r2.x);
    int y1 = mu_max(r1.y, r2.y);
    int x2 = mu_min(r1.x + r1.w, r2.x + r2.w);
    int y2 = mu_min(r1.y + r1.h, r2.y + r2.h);
    if (x2 < x1) { x2 = x1; }
    if (y2 < y1) { y2 = y1; }
    return mu_rect(x1, y1, x2 - x1, y2 - y1);
}

int rect_overlaps_vec2(mu_Rect r, mu_Vec2 p) 
{
    return p.x >= r.x && p.x < r.x + r.w && p.y >= r.y && p.y < r.y + r.h;
}







extern(C)
{
    int compare_zindex(const(void)* a, const(void)* b) 
    {
        return (*cast(mu_Container**) a).zindex - (*cast(mu_Container**) b).zindex;
    }
}



int header_internal(const(char)* label, int istreenode, int opt) 
{
    mu_Rect r;
    int active, expanded;
    mu_Id id = get_id(ctx, label, istrlen(label));
    int idx = pool_get(ctx, treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
    int width = -1;
    mu_layout_row(ctx, 1, &width, 0);

    active = (idx >= 0);
    expanded = (opt & MU_OPT_EXPANDED) ? !active : active;
    r = mu_layout_next(ctx);
    mu_update_control(ctx, id, r, 0);

    /* handle click */
    active ^= (mouse_pressed == MU_MOUSE_LEFT && focus == id);

    /* update pool ref */
    if (idx >= 0) 
    {
        if (active) 
        { 
            pool_update(treenode_pool.ptr, idx); 
        }
        else 
        { 
            memset(&treenode_pool[idx], 0, mu_PoolItem.sizeof); 
        }
    } 
    else if (active) 
    {
        pool_init(treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
    }

    /* draw */
    if (istreenode) {
        if (hover == id) { draw_frame(ctx, r, MU_COLOR_BUTTONHOVER); }
    } else {
        draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, 0);
    }
    mu_draw_icon(
                 ctx, expanded ? MU_ICON_EXPANDED : MU_ICON_COLLAPSED,
                 mu_rect(r.x, r.y, r.h, r.h), style.colors[MU_COLOR_TEXT]);
    r.x += r.h - style.padding;
    r.w -= r.h - style.padding;
    draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);

    return expanded ? MU_RES_ACTIVE : 0;
}


int mu_header(const(char)* label, int opt = 0) 
{
    return header_internal(ctx, label, 0, opt);
}

