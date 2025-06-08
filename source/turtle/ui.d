/// Port of rxi microui v2.02: git@github.com:rxi/microui.git
module turtle.ui;

/*
    Copyright (c) 2024 rxi
    Copyright (c) 2025 Guillaume Piolat (D port)
    Permission is hereby granted, free of charge, to any person 
    obtaining a copy of this software and associated documentation 
    files (the "Software"), to deal in the Software without 
    restriction, including without limitation the rights to use, copy, 
    modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is 
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be 
    included in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
    DEALINGS IN THE SOFTWARE.
*/

// microui.h:

import core.stdc.string: memset, strlen, memcpy;
import core.stdc.stdlib: strtod, qsort;
import core.stdc.stdio: sprintf;

import colors;
import dplug.graphics.font;
import dplug.core.nogc;
import dplug.graphics.image;
import dplug.graphics.draw;
import dplug.math;
import dplug.canvas;


// TODO: expose mu_Container under pretty name and behaviour
// TODO: text_height Not sure what microUI wanted here: lineGap or 
//       size of cap?

// A list of all public API calls:
// - ui.setFont
// - ui.beginWindow
// - ui.endWindow
// - ui.beginPopup
// - ui.endPopup
// - ui.minSize
// - ui.currentContainerRect
// - ui.button
// - ui.slider
// - ui.label
// - ui.header
// - ui.drawRect
// - ui.drawBox
// - ui.drawText
// - ui.layoutRow
// - ui.layoutBeginColumn
// - ui.layoutEndColumn


public:

enum MU_VERSION = "2.02";
alias mu_Real = double;
alias mu_Font = Font;


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

enum : int
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


/** 
    Provides immediate UI functionality in `turtle`.
    This is the original microUI but modified a bit:
    - replaced free function by object
    - gets passed a buffer and Font
    - clean-up of API

    You can get the `MicroUI` object with the `Game.ui()` 
    call.
*/
class MicroUI
{
private:

    /** 
        Change font face used in the whole UI. Default font 
        is Lato regular.
    */
    public void setFont(const(void)[] fontBinary)
    {
        destroyFree(_uiFont);

        _uiFont = null;
        _uiFont = mallocNew!Font(cast(ubyte[]) fontBinary);

        _style = default_style(_uiFont);
        style = &_style;
    }

    /**
        Id for widget, this is typically auto-generated.
    */
    private alias mu_Id = uint;
   

    /// Returns: UI root font-size in px.
    float fontSizePx()
    {
        return _uiFontsizePx;
    }

    /// Set UI font-size in px.
    void fontSizePx(float fontSizePx)
    {
        _uiFontsizePx = fontSizePx;
    }

    

    //
    // basic widgets
    //

    /**
        Basic text display.
    */
    public void text(const(char)[] text) 
    {
        //const(char)* start, end, p = text;
        int width = -1;
        mu_Font font = style.font;
        Color color = style.colors[MU_COLOR_TEXT];
        layoutBeginColumn();
        layoutRow(1, &width, text_height(font));

        size_t start, end, p = 0;
        do 
        {
            box2i r = layoutNext();
            int w = 0;
            start = end = p;
            do 
            {
                size_t word = p;

                while (p < text.length && text[p] != ' ' && text[p] != '\n')
                { 
                    p++; 
                }
                w += text_width(font, text[word..p]);

                if (w > r.width && end != start) 
                    break;
                if (p+1 < text.length)
                    w += text_width(font, text[p..p+1]);
                end = p++;

            } while (end < text.length && text[end] != '\n');
            drawText(font, text[start..end], vec2i(r.min.x, r.min.y), color);
            p = end + 1;
        } while (end < text.length);
        layoutEndColumn();
    }

    /**
        A simple text label.
    */
    public void label(const(char)[] text) 
    {
        drawControlText(text, layoutNext(), MU_COLOR_TEXT, 0);
    }

    /**
        A simple clickable button with optional icon.
    */
    public int button(const(char)[] label, int icon = 0, int opt = MU_OPT_ALIGNCENTER) 
    {
        int res = 0;
        mu_Id id = label ? get_id(label.ptr, istrlen(label))
            : get_id(&icon, isizeof!icon);
        box2i r = layoutNext();
        update_control(id, r, opt);
        /* handle click */
        if (mouse_pressed == MU_MOUSE_LEFT && focus == id) {
            res |= MU_RES_SUBMIT;
        }
        /* draw */
        draw_control_frame(id, r, MU_COLOR_BUTTON, opt);
        if (label) { drawControlText(label, r, MU_COLOR_TEXT, opt); }
        if (icon) { draw_icon(icon, r, style.colors[MU_COLOR_TEXT]); }
        return res;
    }

    public int checkbox(const(char)[] label, int *state) 
    {
        int res = 0;
        mu_Id id = get_id(&state, isizeof!state);
        box2i r = layoutNext();
        box2i box = r;
        update_control(id, r, 0);
        /* handle click */
        if (mouse_pressed == MU_MOUSE_LEFT && focus == id) 
        {
            res |= MU_RES_CHANGE;
            *state = !*state;
        }
        /* draw */
        draw_control_frame(id, box, MU_COLOR_BASE, 0);
        if (*state) 
        {
            draw_icon(MU_ICON_CHECK, box, style.colors[MU_COLOR_TEXT]);
        }
        r = box2i(r.min.x + box.width, r.min.y, r.width - box.width, r.height);
        drawControlText(label, r, MU_COLOR_TEXT, 0);
        return res;
    }

    public int textbox(char[] buf, int bufsz, int opt = 0) 
    {
        mu_Id id = get_id(buf.ptr, cast(int) buf.length);
        box2i r = layoutNext();
        return textbox_raw(buf.ptr, bufsz, id, r, opt);
    }


    public int slider(mu_Real *value, 
                      mu_Real low, mu_Real high,
                      mu_Real step = 0, 
                      const(char) *fmt = MU_SLIDER_FMT, 
                      int opt = MU_OPT_ALIGNCENTER)
    {
        char[MU_MAX_FMT + 1] buf;
        box2i thumb;
        int x, w, res = 0;
        mu_Real last = *value, v = last;
        mu_Id id = get_id(&value, cast(int) value.sizeof);
        box2i base = layoutNext();

        /* handle text input mode */
        if (number_textbox(&v, base, id)) { return res; }

        /* handle normal mode */
        update_control(id, base, opt);

        /* handle input */
        if (focus == id &&
            (mouse_down | mouse_pressed) == MU_MOUSE_LEFT)
        {
            v = low + (mouse_pos.x - base.min.x) * (high - low) / base.width;
            if (step) 
            { 
                v = (cast(long)((v + step / 2) / step)) * step; 
            }
        }
        /* clamp and store value, update res */
        *value = v = mu_clamp(v, low, high);
        if (last != v) { res |= MU_RES_CHANGE; }

        /* draw base */
        draw_control_frame(id, base, MU_COLOR_BASE, opt);
        /* draw thumb */
        w = style.thumb_size;
        x = cast(int) ( (v - low) * (base.width - w) / (high - low) );
        thumb = rectangle(base.min.x + x, base.min.y, w, base.height);
        draw_control_frame(id, thumb, MU_COLOR_BUTTON, opt);
        /* draw text  */
        sprintf(buf.ptr, fmt, v);
        drawControlText(buf[0..strlen(buf.ptr)], base, MU_COLOR_TEXT, opt);

        return res;
    }


    int number(mu_Real *value, mu_Real step,
               const(char)* fmt = MU_SLIDER_FMT, 
               int opt = MU_OPT_ALIGNCENTER)
    {
        char[MU_MAX_FMT + 1] buf;
        int res = 0;
        mu_Id id = get_id(&value, cast(int) value.sizeof);
        box2i base = layoutNext();
        mu_Real last = *value;

        /* handle text input mode */
        if (number_textbox(value, base, id)) { return res; }

        /* handle normal mode */
        update_control(id, base, opt);

        /* handle input */
        if (focus == id && mouse_down == MU_MOUSE_LEFT) {
            *value += mouse_delta.x * step;
        }
        /* set flag if value changed */
        if (*value != last) { res |= MU_RES_CHANGE; }

        /* draw base */
        draw_control_frame(id, base, MU_COLOR_BASE, opt);
        /* draw text  */
        sprintf(buf.ptr, fmt, *value);
        drawControlText(buf, base, MU_COLOR_TEXT, opt);
        return res;
    }

    /// TODO ddoc
    public int beginTreenode(const(char)[] label, int opt = 0) 
    {
        int res = header_internal(label, 1, opt);
        if (res & MU_RES_ACTIVE) {
            get_layout().indent += style.indent;
            id_stack.push(last_id);
        }
        return res;
    }

    /// TODO ddoc
    public void endTreenode() 
    {
        get_layout().indent -= style.indent;
        pop_id();
    }

    /**
        Display a title header, eg. for the top of a window.
    */
    public int header(const(char)[] label, int opt = 0) 
    {
        return header_internal(label, 0, opt);
    }


    //
    // windows
    //

    public int beginWindow(const(char)[] title, box2i rect, int opt = 0) 
    {
        assert(style !is null);
        box2i body;
        mu_Id id = get_id(title.ptr, istrlen(title));
        mu_Container *cnt = get_container_internal(id, opt);
        if (!cnt || !cnt.open) { return 0; }
        id_stack.push(id);

        if (cnt.rect.width == 0) { cnt.rect = rect; }
        begin_root_container(cnt);
        rect = body = cnt.rect;

        /* draw frame */
        if (~opt & MU_OPT_NOFRAME) {
            draw_frame(rect, MU_COLOR_WINDOWBG);
        }

        /* do title bar */
        if (~opt & MU_OPT_NOTITLE) {
            box2i tr = rect;
            tr.max.y = tr.min.y + style.title_height;
            draw_frame(tr, MU_COLOR_TITLEBG);

            /* do title text */
            if (~opt & MU_OPT_NOTITLE) 
            {
                mu_Id id2 = get_id("!title".ptr, 6);
                update_control(id2, tr, opt);
                drawControlText(title, tr, MU_COLOR_TITLETEXT, opt);
                if (id == focus && mouse_down == MU_MOUSE_LEFT) {
                    cnt.rect.min.x += mouse_delta.x;
                    cnt.rect.min.y += mouse_delta.y;
                    cnt.rect.max.x += mouse_delta.x;
                    cnt.rect.max.y += mouse_delta.y;
                }
                body.min.y += tr.height;
                //body.h -= tr.h;
            }

            /* do `close` button */
            if (~opt & MU_OPT_NOCLOSE) 
            {
                mu_Id id2 = get_id("!close".ptr, 6);
                box2i r = rectangle(tr.min.x + tr.width - tr.height, tr.min.y, tr.height, tr.height);
                tr.max.y -= r.width;
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
            box2i r = rectangle(rect.max.x - sz, 
                                rect.max.y - sz, sz, sz);
            update_control(id2, r, opt);
            if (id2 == focus && mouse_down == MU_MOUSE_LEFT) 
            {
                int w = mu_max(96, cnt.rect.width  + mouse_delta.x);
                int h = mu_max(64, cnt.rect.height + mouse_delta.y);
                cnt.rect.max.x = cnt.rect.min.x + w;
                cnt.rect.max.y = cnt.rect.min.y + h;
            }
        }

        /* resize to content size */
        if (opt & MU_OPT_AUTOSIZE) {
            box2i r = get_layout().body;

            int w = cnt.content_size.x + (cnt.rect.width - r.width);
            int h = cnt.content_size.y + (cnt.rect.height - r.height);

            cnt.rect.max.x = cnt.rect.min.x + w;
            cnt.rect.max.y = cnt.rect.min.y + h;
        }

        /* close if this is a popup window and elsewhere was clicked */
        if (opt & MU_OPT_POPUP && mouse_pressed && hover_root != cnt) {
            cnt.open = 0;
        }

        push_clip_rect(cnt.body);
        return MU_RES_ACTIVE;
    }


    public void endWindow() 
    {
        pop_clip_rect();
        end_root_container();
    }

    void begin_panel(const(char)[] name, int opt = 0) 
    {
        mu_Container *cnt;
        push_id(name.ptr, istrlen(name));
        cnt = get_container_internal(last_id, opt);
        cnt.rect = layoutNext();
        if (~opt & MU_OPT_NOFRAME) 
        {
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
    public void openPopup(const(char)[] name) 
    {
        mu_Container *cnt = get_container(name);
        /* set as hover root so popup isn't closed in beginWindow()  */
        hover_root = next_hover_root = cnt;
        /* position at mouse cursor, open and bring-to-front */
        cnt.rect = rectangle(mouse_pos.x, mouse_pos.y, 1, 1);
        cnt.open = 1;
        bring_to_front(cnt);
    }

    public int beginPopup(const(char)[] name) 
    {
        int opt = MU_OPT_POPUP 
                | MU_OPT_AUTOSIZE
                | MU_OPT_NORESIZE
                | MU_OPT_NOSCROLL
                | MU_OPT_NOTITLE
                | MU_OPT_CLOSED;

        return beginWindow(name, rectangle(0, 0, 0, 0), opt);
    }

    public void endPopup() 
    {
        endWindow();
    }


    //
    // draw
    //

    /**
        Draw a filled rectangle in the UI.
    */
    public void drawRect(box2i rect, Color color) 
    {
        mu_Command *cmd;
        rect = intersect_rects(rect, get_clip_rect());
        if (rect.width > 0 && rect.height > 0) 
        {
            cmd = push_command( MU_COMMAND_RECT, cast(int)mu_RectCommand.sizeof);
            cmd.rect.rect = rect;
            cmd.rect.color = color;
        }
    }

    /**
        Draw a box in the UI, 1 pixel wide.
    */
    public void drawBox(box2i r, Color color) 
    {
        drawRect(rectangle(r.min.x + 1, r.min.y, r.width - 2, 1), color);
        drawRect(rectangle(r.min.x + 1, r.min.y + r.height - 1, r.width - 2, 1), color);
        drawRect(rectangle(r.min.x, r.min.y, 1, r.height), color);
        drawRect(rectangle(r.min.x + r.width - 1, r.min.y, 1, r.height), color);
    }

    /**
        Draw text on the UI.
    */
    public void drawText(mu_Font font, 
                         const(char)[] str, 
                         vec2i pos, Color color)
    {
        mu_Command *cmd;
        box2i rect = rectangle(pos.x, pos.y, text_width(font, str), text_height(font));
        int clipped = check_clip(rect);
        if (clipped == MU_CLIP_ALL ) 
            return;
        if (clipped == MU_CLIP_PART) 
        { 
            set_clip(get_clip_rect()); 
        }

        int len = cast(int) str.length;

        cmd = push_command(MU_COMMAND_TEXT, cast(int)(mu_TextCommand.sizeof) + len);
        memcpy(cmd.text.str.ptr, str.ptr, len);
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

    // TODO: is probably meant to be public?
    private void draw_icon(int id, box2i rect, Color color) 
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

    private mu_Id get_id(const(void)* data, int size) 
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

    private void push_id(const(void)* data, int size) 
    {
        id_stack.push(get_id(data, size));
    }

    private void pop_id() 
    {
        id_stack.pop();
    }

    private void set_focus(mu_Id id)
    {
        focus = id;
        updated_focus = 1;
    }

    private void bring_to_front(mu_Container *cnt) 
    {
        cnt.zindex = ++last_zindex;
    }


    //
    // clipping
    //
    private void push_clip_rect(box2i rect)
    {
        box2i last = get_clip_rect();
        clip_stack.push(intersect_rects(rect, last));
    }

    private void pop_clip_rect()
    {
        clip_stack.pop();
    }

    private box2i get_clip_rect()
    {
        assert(clip_stack.idx > 0);
        return clip_stack.items[clip_stack.idx - 1];
    }

    private enum : int 
    {
        MU_CLIP_PART = 1,
        MU_CLIP_ALL
    }

    private int check_clip(box2i r)
    {
        box2i cr = get_clip_rect();
        if (r.min.x > cr.min.x + cr.width  || r.min.x + r.width  < cr.min.x ||
            r.min.y > cr.min.y + cr.height || r.min.y + r.height < cr.min.y   ) 
        { 
            return MU_CLIP_ALL; 
        }
        if (r.min.x >= cr.min.x && r.min.x + r.width  <= cr.min.x + cr.width &&
            r.min.y >= cr.min.y && r.min.y + r.height <= cr.min.y + cr.height ) 
        { 
            return 0; 
        }
        return MU_CLIP_PART;
    }

    private void set_clip(box2i rect) 
    {
        mu_Command *cmd;
        cmd = push_command(MU_COMMAND_CLIP, cast(int)mu_ClipCommand.sizeof);
        cmd.clip.rect = rect;
    }

    //
    // containers
    //

    /**
        This gets the current container.
        microui's example modifies its rectangle as a user API, which seems
        eminently unsafe.
    */
    private mu_Container* get_current_container() 
    {
        assert(container_stack.idx > 0);
        return container_stack.items[container_stack.idx - 1];
    }

    private mu_Container* get_container(const(char)[] name) 
    {
        mu_Id id = get_id(name.ptr, istrlen(name));
        return get_container_internal(id, 0);
    }

    /**
        Sets the minimum size in pixels of the current container.
    */
    public void minSize(int w, int h)
    {
        assert(container_stack.idx > 0);
        mu_Container* ct = container_stack.items[container_stack.idx - 1];
        w = mu_max(ct.rect.width, w);
        h = mu_max(ct.rect.height, h);
        ct.rect.max.x = ct.rect.min.x + w;
        ct.rect.max.y = ct.rect.min.y + h;
    }

    /**
        Return: current container bounds.
    */
    public box2i currentContainerRect()
    {
        return get_current_container.rect;
    }

    
    //
    // layout
    //


    ///TODO docs
    public void layoutRow(int items, const(int)* widths, int height) 
    {
        mu_Layout *layout = get_layout();
        if (widths) 
        {
            assert(items <= MU_MAX_WIDTHS);
            memcpy(layout.widths.ptr, widths, items * (widths[0]).sizeof);
        }
        layout.items = items;
        layout.position = vec2i(layout.indent, layout.next_row);
        layout.size.y = height;
        layout.item_index = 0;
    }


    ///TODO docs
    public void layout_width(int width) 
    {
        get_layout().size.x = width;
    }

    ///TODO docs
    public void layout_height(int height) 
    {
        get_layout().size.y = height;
    }

    ///TODO docs
    public void layoutBeginColumn() 
    {
        push_layout(layoutNext(), vec2i(0, 0));
    }

    ///TODO docs
    public void layoutEndColumn() 
    {
        mu_Layout* a, b;
        b = get_layout();
        layout_stack.pop();
        /* inherit position/next_row/max from child layout if they are greater */
        a = get_layout();
        a.position.x = mu_max(a.position.x, b.position.x + b.body.min.x - a.body.min.x);
        a.next_row = mu_max(a.next_row, b.next_row + b.body.min.y - a.body.min.y);
        a.max.x = mu_max(a.max.x, b.max.x);
        a.max.y = mu_max(a.max.y, b.max.y);
    }

    void layout_set_next(box2i r, int relative) 
    {
        mu_Layout *layout = get_layout();
        layout.next = r;
        layout.next_type = relative ? RELATIVE : ABSOLUTE;
    }

    /**
    TODO DDoc
    */
    public box2i layoutNext() 
    {
        mu_Layout *layout = get_layout();
        mu_Style *style = style;
        box2i res;

        if (layout.next_type) 
        {
            /* handle rect set by `mu_layout_set_next` */
            int type = layout.next_type;
            layout.next_type = 0;
            res = layout.next;
            if (type == ABSOLUTE) 
            { 
                return (last_rect = res); 
            }
        } 
        else 
        {
            /* handle next row */
            if (layout.item_index == layout.items) 
            {
                layoutRow(layout.items, null, layout.size.y);
            }

            /* position */
            res.min.x = layout.position.x;
            res.min.y = layout.position.y;

            /* size */
            res.max.x = res.min.x + (layout.items > 0 ? layout.widths[layout.item_index] : layout.size.x);
            res.max.y = res.min.y + layout.size.y;
            if (res.width == 0) { res.max.x = res.min.x + style.size.x + style.padding * 2; }
            if (res.height == 0) { res.max.y = res.min.y + style.size.y + style.padding * 2; }
            if (res.width <  0) { res.max.x += layout.body.width - res.min.x + 1; }
            if (res.height <  0) { res.max.y += layout.body.height - res.min.y + 1; }

            layout.item_index++;
        }

        /* update position */
        layout.position.x += res.width + style.spacing;
        layout.next_row = mu_max(layout.next_row, res.min.y + res.height + style.spacing);

        /* apply body offset */
        res.min.x += layout.body.min.x;
        res.min.y += layout.body.min.y;
        res.max.x += layout.body.min.x;
        res.max.y += layout.body.min.y;

        /* update max position */
        layout.max.x = mu_max(layout.max.x, res.max.x);
        layout.max.y = mu_max(layout.max.y, res.max.y);

        return (last_rect = res);
    }

    /**
    TODO DDoc
    */
    public void drawControlText(const(char)[] str, 
                                  box2i rect,
                                  int colorid, 
                                  int opt)
    {
        vec2i pos;
        mu_Font font = style.font;
        int tw = text_width(font, str);
        push_clip_rect(rect);
        pos.y = rect.min.y + (rect.height - text_height(font)) / 2;
        if (opt & MU_OPT_ALIGNCENTER) {
            pos.x = rect.min.x + (rect.width - tw) / 2;
        } else if (opt & MU_OPT_ALIGNRIGHT) {
            pos.x = rect.min.x + rect.width - tw - style.padding;
        } else {
            pos.x = rect.min.x + style.padding;
        }
        drawText(font, str, pos, style.colors[colorid]);
        pop_clip_rect();
    }

package: // for game.d

    enum DEFAULT_UI_FONT_SIZE_PX = 30;

    Font _uiFont = null;
    float _uiFontsizePx = DEFAULT_UI_FONT_SIZE_PX;

    /**
        Called by game.d, create the immediate UI system.
    */
    this() 
    {
    }

    ~this()
    {
        destroyFree(_uiFont);
    }

    // render function, called by game.d
    void renderOnFramebuf(ImageRef!RGBA framebuffer)
    {
        bool dirtyIconCanvas;
        ImageRef!RGBA framebufferClipped;

        void updateClippedFb(box2i r)
        {
            dirtyIconCanvas = true;
            // must only crop INSIDE the image rect
            r = r.intersection(box2i.rectangle(0, 0, framebuffer.w, framebuffer.h));
            framebufferClipped = framebuffer.cropImageRef(r);
        }

        // start with clip rect being full rectangle
        updateClippedFb(box2i.rectangle(0, 0, framebuffer.w, framebuffer.h));

        mu_Command *cmd = null;
        while (next_command(&cmd)) 
        {
            if (cmd.type == MU_COMMAND_TEXT) 
            {
                RGBA8 c = cmd.rect.color.toRGBA8();
                RGBA c2 = RGBA(c.r, c.g, c.b, c.a);

                int len = cast(int) strlen(cmd.text.str.ptr);
                const(char)[] s = cmd.text.str.ptr[0..len];
                framebufferClipped.fillText(_uiFont, s, _uiFontsizePx, 0, c2, cmd.text.pos.x, cmd.text.pos.y,
                                             HorizontalAlignment.left, VerticalAlignment.hanging);
            }
            else if (cmd.type == MU_COMMAND_RECT) 
            {
                box2i r2 = cmd.rect.rect;
                RGBA8 c = cmd.rect.color.toRGBA8();
                RGBA c2 = RGBA(c.r, c.g, c.b, c.a);
                framebufferClipped.fillRectFloat(r2.min.x, r2.min.y, r2.max.x, r2.max.y, c2, c.a / 255.0f);
            }
            else if (cmd.type == MU_COMMAND_ICON) 
            {
                // lazy init icon canvas
                if (dirtyIconCanvas)
                {
                    dirtyIconCanvas = false;
                    _canvasIcon.initialize(framebufferClipped);
                }

                box2i r = cmd.icon.rect;
                switch(cmd.icon.id)
                {
                    case MU_ICON_CLOSE:

                        // Draw a cross
                        //   A   C
                        //  / \ / \
                        // L   B  D
                        //  \     /
                        //   K   E
                        //  /     \
                        // J   H   F
                        //  \ / \ /
                        //   I   G
                        float e00 = 0.28;
                        float e25 = 0.39;
                        float e50 = 0.5;
                        float e75 = 0.61;
                        float e100 = 0.72;
                        float x0 = r.min.x * e100 + r.max.x *  e00;
                        float x1 = r.min.x *  e75 + r.max.x *  e25;
                        float x2 = r.min.x *  e50 + r.max.x *  e50;
                        float x3 = r.min.x *  e25 + r.max.x *  e75;
                        float x4 = r.min.x *  e00 + r.max.x * e100;
                        float y0 = r.min.y * e100 + r.max.y *  e00;
                        float y1 = r.min.y *  e75 + r.max.y *  e25;
                        float y2 = r.min.y *  e50 + r.max.y *  e50;
                        float y3 = r.min.y *  e25 + r.max.y *  e75;
                        float y4 = r.min.y *  e00 + r.max.y * e100;

                        with(_canvasIcon)
                        {
                            fillStyle = cmd.icon.color;
                            beginPath();
                            moveTo(x1, y0);
                            lineTo(x2, y1);
                            lineTo(x3, y0);
                            lineTo(x4, y1);
                            lineTo(x3, y2);
                            lineTo(x4, y3);
                            lineTo(x3, y4);
                            lineTo(x2, y3);
                            lineTo(x1, y4);
                            lineTo(x0, y3);
                            lineTo(x1, y2);
                            lineTo(x0, y1);
                            closePath();
                            fill();
                        }
                        break;

                        // checkbox icon
                    case MU_ICON_CHECK:
                        // TODO
                        break;

                        // collapsed >
                    case MU_ICON_COLLAPSED:
                        // TODO
                        break;

                        // collapsed v
                    case MU_ICON_EXPANDED:
                        // TODO
                        break;

                    default:
                        assert(false);
                }
            }
            if (cmd.type == MU_COMMAND_CLIP) 
            {
                box2i r = cmd.clip.rect;
                updateClippedFb(r);
            }
        }
    }


    /**
        Called by game.d, start defining UI.
    */
    void begin() 
    {
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
                bring_to_front(next_hover_root);
        }

        /* reset input state */
        key_pressed = 0;
        input_text_buf[0] = '\0';
        mouse_pressed = 0;
        scroll_delta = vec2i(0, 0);
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
        mouse_pos = vec2i(x, y);
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

    void input_text(const(char)[] text) 
    {
        int len = cast(int) strlen(input_text_buf.ptr);
        int size = istrlen(text) + 1;
        assert(len + size <= isizeof!(input_text_buf));
        memcpy(input_text_buf.ptr + len, text.ptr, size);
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

    // and their only implementation
    int text_width(mu_Font font, const(char)[] str)
    {
        Font dplugFont = cast(Font)font;
        assert(dplugFont);
        int len = cast(int) str.length;
        box2i b = dplugFont.measureText(str[0..len], _uiFontsizePx, 0);
        return b.width;
    }

    int text_height(mu_Font font)
    {
        Font dplugFont = cast(Font)font;
        assert(dplugFont);
        box2i b = dplugFont.measureText("A", _uiFontsizePx, 0);
        return b.height;
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

    enum unclipped_rect = rectangle(0, 0, 0x1000000, 0x1000000);

    static box2i expand_rect(box2i rect, int n) 
    {
        return rectangle(rect.min.x - n, rect.min.y - n, rect.width + n * 2, rect.height + n * 2);
    }

    static box2i intersect_rects(box2i r1, box2i r2) 
    {
        int x1 = mu_max(r1.min.x, r2.min.x);
        int y1 = mu_max(r1.min.y, r2.min.y);
        int x2 = mu_min(r1.min.x + r1.width,  r2.min.x + r2.width);
        int y2 = mu_min(r1.min.y + r1.height, r2.min.y + r2.height);
        if (x2 < x1) { x2 = x1; }
        if (y2 < y1) { y2 = y1; }
        return rectangle(x1, y1, x2 - x1, y2 - y1);
    }

    static int rect_overlaps_vec2(box2i r, vec2i p) 
    {
        return p.x >= r.min.x && p.x < r.max.x 
            && p.y >= r.min.y && p.y < r.max.y;
    }


    enum 
    { 
        RELATIVE = 1, 
        ABSOLUTE = 2 
    }

    /* core state */
    mu_Style _style;
    mu_Style *style = null;
    mu_Id hover = 0;
    mu_Id focus = 0;
    mu_Id last_id = 0;
    box2i last_rect;
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
    mu_stack!(box2i, MU_CLIPSTACK_SIZE) clip_stack;
    mu_stack!(mu_Id, MU_IDSTACK_SIZE) id_stack;
    mu_stack!(mu_Layout, MU_LAYOUTSTACK_SIZE) layout_stack;
    /* retained state pools */
    mu_PoolItem[MU_CONTAINERPOOL_SIZE] container_pool;
    mu_Container[MU_CONTAINERPOOL_SIZE] containers;
    mu_PoolItem[MU_TREENODEPOOL_SIZE] treenode_pool;
    /* input state */
    vec2i mouse_pos;
    vec2i last_mouse_pos;
    vec2i mouse_delta;
    vec2i scroll_delta;
    int mouse_down;
    int mouse_pressed;
    int key_down;
    int key_pressed;
    char[32] input_text_buf;

    Canvas _canvasIcon;

    static struct mu_Layout
    {
        box2i body;
        box2i next;
        vec2i position;
        vec2i size;
        vec2i max;
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
        box2i rect; 
    }

    static struct mu_RectCommand
    { 
        mu_BaseCommand base; 
        box2i rect; 
        Color color; 
    }

    static struct mu_TextCommand
    { 
        mu_BaseCommand base; 
        mu_Font font; 
        vec2i pos; 
        Color color; 
        char[1] str; 
    }

    static struct mu_IconCommand
    { 
        mu_BaseCommand base; 
        box2i rect; 
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
        box2i rect;
        box2i body;
        vec2i content_size;
        vec2i scroll;
        int zindex;
        int open;
    }

    static struct mu_Style
    {
        mu_Font font = null;
        vec2i size = vec2i(0, 0);
        int padding = 0;
        int spacing = 0;
        int indent = 0;
        int title_height = 0;
        int scrollbar_size = 0;
        int thumb_size = 0;
        Color[MU_COLOR_MAX] colors;
    }

    private void draw_frame(box2i rect, int colorid) 
    {
        drawRect(rect, style.colors[colorid]);
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
            drawBox(expand_rect(rect, 1), borderCol);
        }
    }

    //
    // pool (private)
    //

    private int pool_init(mu_PoolItem *items, int len, mu_Id id) 
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

    private int pool_get(mu_PoolItem *items, int len, mu_Id id) 
    {
        int i;
        for (i = 0; i < len; i++) 
        {
            if (items[i].id == id) 
                return i;
        }
        return -1;
    }

    private void pool_update(mu_PoolItem *items, int idx) 
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
             font, vec2i(68, 10), 5*2, 4*2, 24*2,
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

    private void push_layout(box2i body, vec2i scroll) 
    {
        mu_Layout layout;
        int width = 0;
        memset(&layout, 0, layout.sizeof); // PERF: is useless 
        layout.body = rectangle(body.min.x - scroll.x, body.min.y - scroll.y, body.width, body.height);
        layout.max = vec2i(-0x1000000, -0x1000000);
        layout_stack.push(layout);
        layoutRow(1, &width, 0);
    }

    private mu_Layout* get_layout() 
    {
        return &layout_stack.items[layout_stack.idx - 1];
    }

    //
    // containers (private)
    //
    private mu_Container* get_container_internal(mu_Id id, int opt) 
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
        cnt.content_size.x = layout.max.x - layout.body.min.x;
        cnt.content_size.y = layout.max.y - layout.body.min.y;
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

    void draw_control_frame(mu_Id id, box2i rect,
                               int colorid, int opt)
    {
        if (opt & MU_OPT_NOFRAME) { return; }
        colorid += (focus == id) ? 2 : (hover == id) ? 1 : 0;
        draw_frame(rect, colorid);
    }
   
    int mouse_over( box2i rect) 
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

    void update_control( mu_Id id, box2i rect, int opt) 
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


    int textbox_raw(char *buf, int bufsz, mu_Id id, box2i r,
                    int opt = 0)
    {
        int res = 0;
        update_control(id, r, opt | MU_OPT_HOLDFOCUS);

        if (focus == id) {
            /* handle text input */
            int len = cast(int) strlen(buf);
            int n = mu_min(bufsz - len - 1, cast(int) strlen(input_text_buf.ptr));
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
            if (key_pressed & MU_KEY_RETURN) 
            {
                set_focus(0);
                res |= MU_RES_SUBMIT;
            }
        }

        /* draw */
        draw_control_frame(id, r, MU_COLOR_BASE, opt);
        if (focus == id) {
            Color color = style.colors[MU_COLOR_TEXT];
            mu_Font font = style.font;
            int textw = text_width(font, buf[0..strlen(buf)]);
            int texth = text_height(font);
            int ofx = r.width - style.padding - textw - 1;
            int textx = r.min.x + mu_min(ofx, style.padding);
            int texty = r.min.y + (r.height - texth) / 2;
            push_clip_rect(r);
            drawText(font, buf[0..strlen(buf)], vec2i(textx, texty), color);
            drawRect(rectangle(textx + textw, texty, 1, texth), color);
            pop_clip_rect();
        } 
        else 
        {
            drawControlText(buf[0..strlen(buf)], r, MU_COLOR_TEXT, opt);
        }

        return res;
    }

    int number_textbox(mu_Real *value, box2i r, mu_Id id) 
    {
        if (mouse_pressed == MU_MOUSE_LEFT && key_down & MU_KEY_SHIFT &&
            hover == id
            ) {
                number_edit = id;
                sprintf(number_edit_buf.ptr, MU_REAL_FMT.ptr, *value);
            }
        if (number_edit == id) 
        {
            int res = textbox_raw(number_edit_buf.ptr, isizeof!(number_edit_buf), id, r, 0);
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

    private void scrollbar(bool VERT)(mu_Container* cnt, 
                              box2i* b, 
                              vec2i cs)
    {
        /* only add scrollbar if content size is larger than body */

        static if (VERT)
        {
            enum DIM = "y";
            int maxscroll = cs.y - b.height;
            bool needScroll = b.height > 0;
        }
        else
        {
            enum DIM = "x";
            int maxscroll = cs.x - b.width;
            bool needScroll = b.width > 0;
        }

        if (maxscroll > 0 && needScroll) 
        {
            box2i base, thumb;
            enum string idBuf = "!scrollbar" ~ DIM;
            mu_Id id = get_id(idBuf.ptr, 11);

            /* get sizing / positioning */
            base = *b;
            static if (VERT)
            {
                base.min.x = b.min.x + b.width;
                base.max.x = base.min.x + style.scrollbar_size;
            }
            else
            {
                base.min.y = b.min.y + b.height;
                base.max.y = base.min.y + style.scrollbar_size;
            }

            /* handle input */
            update_control(id, base, 0);
            if (focus == id && mouse_down == MU_MOUSE_LEFT) 
            {
                static if (VERT)
                {
                    cnt.scroll.y += mouse_delta.y * cs.y / base.height;
                }
                else
                {
                    cnt.scroll.x += mouse_delta.x * cs.x / base.width;
                }
            }

            /* clamp scroll to limits */
            static if (VERT)
                cnt.scroll.y = mu_clamp(cnt.scroll.y, 0, maxscroll);
            else
                cnt.scroll.x = mu_clamp(cnt.scroll.x, 0, maxscroll);

            /* draw base and thumb */
            draw_frame(base, MU_COLOR_SCROLLBASE);
            thumb = base;
            static if (VERT)
            {
                int h = mu_max(style.thumb_size, base.height * b.height / cs.y);
                thumb.min.y += cnt.scroll.y * (base.height - h) / maxscroll;
                thumb.max.y = thumb.min.y + h;
            }
            else
            {
                int w = mu_max(style.thumb_size, base.width * b.width / cs.x);
                
                thumb.min.x += cnt.scroll.x * (base.width - w) / maxscroll;
                thumb.max.x = thumb.min.x + w;
            }
            draw_frame(thumb, MU_COLOR_SCROLLTHUMB);

            /* set this as the scroll_target (will get scrolled on mousewheel) */
            /* if the mouse is over it */
            if (mouse_over(*b)) { scroll_target = cnt; }
        } 
        else 
        {
            static if (VERT)
                cnt.scroll.y = 0;
            else
                cnt.scroll.x = 0;
        }
    }

    private void scrollbars(mu_Container *cnt, box2i *body) 
    {
        int sz = style.scrollbar_size;
        vec2i cs = cnt.content_size;
        cs.x += style.padding * 2;
        cs.y += style.padding * 2;
        push_clip_rect(*body);
        /* resize body to make room for scrollbars */
        if (cs.y > cnt.body.height) { body.max.x -= sz; }
        if (cs.x > cnt.body.width) { body.max.y -= sz; }
        /* to create a horizontal or vertical scrollbar almost-identical code is
        ** used; only the references to `x|y` `w|h` need to be switched */
        scrollbar!true(cnt, body, cs);
        scrollbar!false(cnt, body, cs);
        pop_clip_rect();
    }

    private void push_container_body(mu_Container *cnt, box2i body, int opt) 
    {
        if (~opt & MU_OPT_NOSCROLL) { scrollbars(cnt, &body); }
        push_layout(expand_rect(body, -style.padding), cnt.scroll);
        cnt.body = body;
    }

    private int header_internal(const(char)[] label, int istreenode, int opt) 
    {
        box2i r;
        int active, expanded;
        mu_Id id = get_id(label.ptr, istrlen(label));
        int idx = pool_get(treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
        int width = -1;
        layoutRow(1, &width, 0);

        active = (idx >= 0);
        expanded = (opt & MU_OPT_EXPANDED) ? !active : active;
        r = layoutNext();
        update_control(id, r, 0);

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
            if (hover == id) { draw_frame(r, MU_COLOR_BUTTONHOVER); }
        } else {
            draw_control_frame(id, r, MU_COLOR_BUTTON, 0);
        }
        draw_icon(expanded ? MU_ICON_EXPANDED : MU_ICON_COLLAPSED,
                  r, style.colors[MU_COLOR_TEXT]);
        int rh = r.height;
        r.min.x += rh - style.padding;
        r.max.x += rh - style.padding;
        r.max.x -= rh - style.padding;
        drawControlText(label, r, MU_COLOR_TEXT, 0);

        return expanded ? MU_RES_ACTIVE : 0;
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
int istrlen(const(char)[] s)
{
    return cast(int) s.length;
}

// replaces cast(int) blah.sizeof
enum isizeof(alias T) = T.sizeof;

T mu_min(T)(T a, T b) { return a < b ? a : b; }
T mu_max(T)(T a, T b) { return a > b ? a : b; }
T mu_clamp(T)(T x, T a, T b) { return mu_min(b, mu_max(a, x)); }


enum size_t MU_MAX_WIDTHS           = 16;

extern(C)
{
    int compare_zindex(const(void)* a, const(void)* b) 
    {
        return (*cast(MicroUI.mu_Container**) a).zindex - (*cast(MicroUI.mu_Container**) b).zindex;
    }
}





