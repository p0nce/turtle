import fe;

import core.stdc.stdarg;
import core.stdc.stdlib: rand, malloc, free, calloc;
import core.stdc.math: roundf;
import core.stdc.string: memset, memcpy, strncmp;
import core.stdc.stdio: printf, vsnprintf;


// celce.h

enum int MEMORY_SIZE = 0x7fff;
enum int PALETTE_START = 0x4000;
enum int FONT_START = 0x4040;
enum int DISPLAY_START = 0x52a0; /* bank 1 */
enum int FE_CTX_DATA_SIZE = 65535;
enum int FONT_HEIGHT = 7;
enum int FONT_WIDTH = 7;
enum int FONT_FALLBACK_GLYPH = 0x7f;
enum SCRATCH_SIZE = MEMORY_SIZE;

alias ssize_t = ptrdiff_t;

enum 
{
    BK_Normal = 0,
    BK_Rom = 1,
    BK_COUNT = 2
}

struct rgba_t
{
	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a;
}
struct Config 
{
	char[512] title;
	int width;
	int height;
	int scale;
	bool debug_;
}

// The Cel7 VM
class Cel7
{
nothrow @nogc:
	this()
    {
        this.fe_ctx_data = malloc(FE_CTX_DATA_SIZE);
        this.ctx = fe_open(fe_ctx_data, FE_CTX_DATA_SIZE, cast(void*)this);
		fe_handlers(ctx).error = &my_fe_error;

		// TODO
        //fe_handlers(ctx).putChar = &myPutChar;

        // Add builtins

        ApiFunc[11] fe_apis = 
        [
            ApiFunc(        "//",    &fe_divide ),
            ApiFunc(         "%",   &fe_modulus ),
            ApiFunc(      "quit",      &fe_quit ),
            ApiFunc(      "rand",      &fe_rand ),
            ApiFunc(      "poke",      &fe_poke ),
            ApiFunc(      "peek",      &fe_peek ),
            ApiFunc(     "color",     &fe_color ),
            ApiFunc(       "put",       &fe_put ),
            ApiFunc(       "get",       &fe_get ),
            ApiFunc(      "fill",      &fe_fill ),
            ApiFunc(    "strlen",    &fe_strlen ),

            /*	ApiFunc(  "strstart",  &fe_strstart ),
            ApiFunc(     "strat",     &fe_strat ),
            ApiFunc( "char->num",    &fe_ch2num ),
            ApiFunc( "num->char",    &fe_num2ch ),
            ApiFunc(  "username",  &fe_username ),
            ApiFunc(     "delay",     &fe_delay ),
            ApiFunc(     "ticks",     &fe_ticks ),
            ApiFunc(    "swibnk",    &fe_swibnk ), */
        ];

        for (size_t i = 0; i < fe_apis.length; ++i) 
        {
            fe_set(ctx, fe_symbol(ctx, fe_apis[i].name.ptr), fe_cfunc(ctx, fe_apis[i].func));
        }

		load(cast(const(ubyte)[]) DEFAULT_CARTRIDGE_C7);
    }

	~this()
    {
		free(fe_ctx_data);
    }

	void load(const(ubyte)[] source)
    {
        struct UserContext
        {
            const(ubyte)[] remain;
        }

        static char readInBuf(fe_Context *ctx, void* udata)
        {
            UserContext* uc = cast(UserContext*)udata;
            if (uc.remain.length == 0)
                return '\0';
            else
            {
                char ch = cast(char) uc.remain[0];
                uc.remain = uc.remain[1..$];
                return ch;
            }
        }

		static immutable rgba_t[16] DEFAULT_PALETTE =
        [
			rgba_t(0, 0, 0, 255),
			rgba_t(247, 247, 230, 255),
			rgba_t(247,  20, 103, 255),
			rgba_t(253, 151,  31, 255),
			rgba_t(230, 212,  21, 255),
			rgba_t(160, 224,  31, 255),
			rgba_t( 70, 187, 255, 255),
			rgba_t(169, 138, 255, 255),
			rgba_t(249, 170, 175, 255),
			rgba_t(171,  51,  71, 255),
			rgba_t(55,  148, 110, 255),
			rgba_t( 42,  70, 105, 255),
			rgba_t(124, 141, 153, 255),
			rgba_t(194, 190, 174, 255),
			rgba_t(117, 113,  94, 255),
			rgba_t(62, 61, 50, 255),
        ];

		// Reset memory to default state
		palettePointer()[0..16] = DEFAULT_PALETTE[];

        int gc = fe_savegc(ctx);
        UserContext uc;
        uc.remain = source;
        while(true)
        {
            fe_Object *obj = fe_read(ctx, &readInBuf, &uc);
            if (!obj) break;
            fe_eval(ctx, obj);
        }
        fe_restoregc(ctx, gc);

		get_string_global("title", config.title.ptr, config.title.length);
        config.width = cast(int) get_number_global("width".ptr);
        config.height = cast(int) get_number_global("height".ptr);
        config.scale = 1;//cast(int) get_number_global("scale".ptr);
    }

	void callInit()
    {
		int gc = fe_savegc(ctx);
        fe_Object*[1] objs;
        objs[0] = fe_symbol(ctx, "init");
        fe_Object *res = fe_eval(ctx, fe_list(ctx, objs.ptr, 1));
        fe_restoregc(ctx, gc);
    }

	void callStep()
    {
		int gc = fe_savegc(ctx);
        fe_Object*[1] objs;
        objs[0] = fe_symbol(ctx, "step");
        fe_Object *res = fe_eval(ctx, fe_list(ctx, objs.ptr, 1));
        fe_restoregc(ctx, gc);
    }

	// Render each char in a framebuffer.
	// Note: only render in the used part of rgbaPixels.
	// The buffer should be cleared before passed to this API.

    // PERF: compute hash of graphics memory + character memory?
    // PERF: have an internal buffer.
    //       if same char and colors as before, do not redraw
	void render(int width, int height, ubyte* rgbaPixels, size_t pitchBytes)
    {

        // First, compute size of console, so that character are always drawn in multiple of 7x7
        int scaleW = cast(int)(width / (config.width * 7));
        int scaleH = cast(int)(height / (config.height * 7));
        //if (scaleW < 1) scaleW = 1;
        //if (scaleH < 1) scaleH = 1;
        int scale = scaleW < scaleH ? scaleW : scaleH; // note: can be zero if too small

		// Width and height of a character in output buffer
		int scale7 = scale * 7;

        int consoleWidthPixels = scale7 * config.width;
        int consoleHeightPixels = scale7 * config.height;
        int marginX = (width - consoleWidthPixels)/2;
        int marginY = (height - consoleHeightPixels)/2;
		int W = config.width;
		int H = config.height;
		ubyte* displayMemory = &memory[BK_Normal][DISPLAY_START];
        for (int row = 0; row < H; ++row)
        {
            for (int col = 0; col < W; ++col)
            {
                size_t coord = row * W + col;
                int  ch    = displayMemory[coord * 2 + 0];
                ubyte fg_i = (displayMemory[coord * 2 + 1] >> 0) & 0xF;
                ubyte bg_i = (displayMemory[coord * 2 + 1] >> 4) & 0xF;

				//assert(fg_i == 0);
				//assert(bg_i == 0);
				// draw character
				ubyte r = cast(ubyte)(fg_i<<4);
                ubyte g = cast(ubyte)(bg_i<<4);

				if (ch < 32 || ch > 126)
                {
                    ch = FONT_FALLBACK_GLYPH;
                }
				else
                {
					int bbbb = 0;
                }

				assert(ch >= 32);

				// decode character in 7x7 buffer.
				rgba_t* palette = palettePointer();
				rgba_t fgColor = palette[fg_i];
				rgba_t bgColor = palette[bg_i];
				fgColor.a = 255;
				bgColor.a = 255;

				ubyte* charData = fontPointer();
				
				for (int y = 0; y < 7; ++y)
                {
					for (int x = 0; x < 7; ++x)
                    {
						assert(x >= 0 && x < 8);
						ubyte font_ch = fontPointer[(ch-32) * 49 + x + y * 7];
						rgba_t color = font_ch ? fgColor : bgColor;

						// Draw a number of 7x7 squares
						for (int yy = 0; yy < scale; ++yy)
                        {
							int xg =      x*scale + col*scale7 + marginX;
                            int yg = yy + y*scale + row*scale7 + marginY;
                            rgba_t* p = cast(rgba_t*)(rgbaPixels + (pitchBytes*yg) + xg*4);

                            for (int xx = 0; xx < scale; ++xx)
                            {
								p[xx] = color;
                            }
                        }
                    }
                }
            }
        }
    }

private:
	void* fe_ctx_data = null;
    fe_Context* ctx = null;
    bool quit = false;
	int bank = BK_Normal;
	ubyte color = 1;

	Config config = Config("Hello world!", 16, 16, 1, false);
	ubyte[MEMORY_SIZE][BK_COUNT] memory;
	ubyte[SCRATCH_SIZE] scratch; // a scratch buffer

	rgba_t* palettePointer()
    {
		return cast(rgba_t*) &memory[BK_Normal][PALETTE_START];
    }

	ubyte* fontPointer()
    {
		return &memory[BK_Normal][FONT_START];
    }

	void get_string_global(const(char)* name, char *buf, size_t sz)
    {
        int gc = fe_savegc(ctx);
        fe_Object *var = fe_eval(ctx, fe_symbol(ctx, name));
        if (fe_type(ctx, var) == FE_TSTRING) 
        {
            fe_tostring(ctx, var, buf, cast(int) sz);
        } 
        else 
        {
            fe_errorf(ctx, "Global '%s' must be a string", name);
        }
        fe_restoregc(ctx, gc);
    }

	double get_number_global(const(char)* name)
    {
		int gc = fe_savegc(ctx);
		scope(exit) fe_restoregc(ctx, gc);

		fe_Object* var = fe_eval(ctx, fe_symbol(ctx, name));
		if (fe_type(ctx, var) == FE_TNUMBER) 
        {
			return fe_tonumber(ctx, var);
		} 
        else 
        {
			fe_errorf(ctx, "Global '%s' must be a number", name);
			return 0;
		}
    }	

	void on_error(const(char)* s) nothrow @nogc
    {
		printf("error: %s\n", s); // TODO: write on screen
    }
}

void my_fe_error(fe_Context *ctx, const(char)*err, fe_Object* cl) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);
	vm.on_error(err);
}

struct ApiFunc 
{
nothrow @nogc:
	string name;
	fe_Object* function(fe_Context *, fe_Object *)  func;
}


// utils.c

alias fe_errorf = raise_errorf;
void raise_errorf(fe_Context *ctx, const char *fmt, ...) nothrow @nogc
{
	char[512] buf = void;
	memset(buf.ptr, 0x0, buf.sizeof);

	va_list ap;
	va_start(ap, fmt);
	ssize_t len = vsnprintf(buf.ptr, buf.sizeof, fmt, ap);
	va_end(ap);
	assert(cast(size_t) len < buf.sizeof);
    fe_error(ctx, buf.ptr);
}


// fe_api.c

fe_Object* fe_divide(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	float accm = 0;
	float b;

	accm = fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	do {
		b = fe_tonumber(ctx, fe_nextarg(ctx, &arg));
		accm /= b;
	} while (fe_type(ctx, arg) == FE_TPAIR);

	return fe_number(ctx, roundf(accm));
}

fe_Object* fe_modulus(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	ssize_t a = cast(ssize_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	ssize_t b = cast(ssize_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	if (b == 0) 
    {
		fe_errorf(ctx, "Tried to divide %d by zero", a);
	}

	return fe_number(ctx, cast(float)(a % b));
}

fe_Object* fe_quit(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 cel7 = cast(Cel7) fe_userdata(ctx);
	cel7.quit = true;
	return fe_bool(ctx, 0);
}

fe_Object* fe_rand(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	ssize_t n = cast(ssize_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	if (n == 0) {
		fe_errorf(ctx, "Expected non-zero argument.");
	}

	return fe_number(ctx, cast(float)(rand() % n));
}

fe_Object* fe_poke(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);

	size_t addr = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	fe_Object *payload = fe_nextarg(ctx, &arg);

	ubyte* buf = vm.scratch.ptr;	
	size_t sz = 0;

	if (fe_type(ctx, payload) == FE_TSTRING) 
    {
		sz = fe_tostring(ctx, payload, cast(char*) buf, SCRATCH_SIZE);
	} 
    else 
    {
		buf[0] = cast(ubyte) fe_tonumber(ctx, payload);
		sz = 1;
	}

	check_user_address(ctx, addr, sz, true);
	memcpy(&vm.memory[vm.bank][addr], buf, sz);

	return fe_bool(ctx, 0);
}

// Check a user-provided address and ensure that
//     1. The bank is writeable, if the user wants to write to it, and
//     2. The address...sz range is within memory bounds.
void check_user_address(fe_Context *ctx, size_t addr, size_t sz, bool write) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);

	if ((write && vm.bank == BK_Rom) || (addr + sz) >= MEMORY_SIZE) 
    {
		const(char)* action = write ? "writeable".ptr : "readable".ptr;

		if (sz == 1) 
        {
			raise_errorf(ctx, "Address [%d]0x%04X not %s.".ptr, vm.bank, addr, action);
		} 
        else 
        {
			raise_errorf(ctx, "Address [%d]0x%04X...%04X not %s.".ptr,
                         vm.bank, addr, addr + (sz - 1), action);
		}
	}
}

fe_Object * fe_peek(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);
	size_t addr = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	size_t size = 1;

	if (fe_type(ctx, arg) == FE_TPAIR) 
    {
		size = cast(size_t)fe_tonumber(ctx, fe_car(ctx, arg));

		check_user_address(ctx, addr, size, false);

		char *buf = cast(char*) calloc(size, char.sizeof); // PERF: wat
		memcpy(buf, cast(void *)&vm.memory[vm.bank][addr], size);

		fe_Object *retval = fe_string(ctx, cast(const char *)&buf);
		free(buf);
		return retval;
	} 
    else 
    {
		check_user_address(ctx, addr, 1, false);
		return fe_number(ctx, cast(float)vm.memory[vm.bank][addr]);
	}
}

fe_Object* fe_color(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);
	vm.color = cast(ubyte) fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	return fe_bool(ctx, 0);
}

fe_Object* fe_put(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);

	ubyte* buf = vm.scratch.ptr;

	if (vm.bank == BK_Rom) 
    {
		fe_errorf(ctx, "Cannot write to bank.".ptr);
	}

	size_t sx = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	size_t sy = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	fe_Object *str = null;
	size_t x = sx;

	int width = vm.config.width;

	do {
		str = fe_nextarg(ctx, &arg);
		size_t sz = fe_tostring(ctx, str, cast(char *)buf, buf.sizeof);

		for (size_t i = 0; i < sz && x < width; ++i, ++x) 
        {
			size_t coord = sy * width + x;
			size_t addr = DISPLAY_START + (coord * 2);
			vm.memory[BK_Normal][addr + 0] = buf[i];
			vm.memory[BK_Normal][addr + 1] = vm.color;
		}

	} while (fe_type(ctx, arg) == FE_TPAIR);

	return fe_bool(ctx, 0);
}

fe_Object * fe_get(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);
	size_t x = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	size_t y = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	ubyte res = vm.memory[BK_Normal][y * vm.config.width + x + 0];
	return fe_number(ctx, res);
}

fe_Object * fe_fill(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	Cel7 vm = cast(Cel7) fe_userdata(ctx);
	if (vm.bank == BK_Rom) 
    {
		fe_errorf(ctx, "Cannot write to bank.");
	}

	size_t x = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	size_t y = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	size_t w = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	size_t h = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	char[2] buf = [0, 0];
	size_t sz = fe_tostring(ctx, fe_nextarg(ctx, &arg), cast(char *)&buf, buf.sizeof);
	if (sz < 1 || sz > 1) 
    {
		fe_error(ctx, "Expected a string with one character");
	}
	ubyte c = buf[0];

	for (size_t dy = y; dy < (y + h); ++dy) 
    {
		for (size_t dx = x; dx < (x + w); ++dx) 
        {
			size_t coord = dy * vm.config.width + dx;
			size_t addr = DISPLAY_START + (coord * 2);
			vm.memory[BK_Normal][addr + 0] = c;
			vm.memory[BK_Normal][addr + 1] = vm.color;
		}
	}

	return fe_bool(ctx, 0);
}

fe_Object * fe_strlen(fe_Context *ctx, fe_Object *arg) nothrow @nogc
{
	char[4096] buf;
	size_t sz = fe_tostring(ctx, fe_nextarg(ctx, &arg), cast(char *)&buf, buf.sizeof);
	return fe_number(ctx, cast(float)sz);
}

fe_Object* fe_strstart(fe_Context *ctx, fe_Object *arg)
{
	ubyte[4096] buf1;
	fe_tostring(ctx, fe_nextarg(ctx, &arg), cast(char *)buf1.ptr, buf1.sizeof);
	ubyte[4096] buf2;
	size_t sz = fe_tostring(ctx, fe_nextarg(ctx, &arg), cast(char *)buf2.ptr, buf2.sizeof);
	return fe_bool(ctx, !strncmp(cast(const char *)&buf1, cast(const char *)&buf2, sz));
}

fe_Object* fe_strat(fe_Context *ctx, fe_Object *arg)
{
	ubyte[4096] buf;
	fe_tostring(ctx, fe_nextarg(ctx, &arg), cast(char *)&buf, buf.sizeof);
	size_t ind = cast(size_t)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	buf[ind + 1] = '\0';
	return fe_string(ctx, cast(const char *)&buf[ind]);
}

fe_Object* fe_ch2num(fe_Context *ctx, fe_Object *arg)
{
	char[2] buf = [0, 0];
	fe_tostring(ctx, fe_nextarg(ctx, &arg), cast(char *)&buf, 2);
	return fe_number(ctx, cast(float)buf[0]);
}

fe_Object* fe_num2ch(fe_Context *ctx, fe_Object *arg)
{
	ubyte num = cast(ubyte)fe_tonumber(ctx, fe_nextarg(ctx, &arg));
	char[2] buf = [num, 0];
	return fe_string(ctx, buf.ptr);
}

/*
static fe_Object *
fe_username(fe_Context *ctx, fe_Object *arg)
{
	return fe_string(ctx, get_username());
}

fe_Object* fe_delay(fe_Context *ctx, fe_Object *arg)
{
	float delay = fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	if (delay < 0 || !isnormal(delay)) {
		fe_errorf("Delay %f invalid.", delay);
	}

	delay_val.tv_sec  = cast(time_t)roundf(delay);
	delay_val.tv_usec = cast(suseconds_t)((delay - roundf(delay)) * 1000000);
	gettimeofday(&delay_set, NULL);

	return fe_bool(ctx, 0);
}

fe_Object* fe_ticks(fe_Context *ctx, fe_Object *arg)
{
	return fe_number(ctx, cast(float)mode.steps[mode.cur]);
}*/

/*
fe_Object* fe_swibnk(fe_Context *ctx, fe_Object *arg)
{
	float bank_arg = fe_tonumber(ctx, fe_nextarg(ctx, &arg));

	if (bank_arg < 0 || bank_arg > BK_COUNT) {
		fe_errorf("Cannot switch to bank %.f.", bank_arg);
	}

	bank = cast(size_t)bank_arg;

	return fe_bool(ctx, 0);
}*/

static immutable string DEFAULT_CARTRIDGE_C7 = 
`(= title "cel7ce")
(= width  16)
(= height 16)

(= msg " no cartridge ")
(= pad "              ")

(= init (fn ()
    # Put random characters everywhere, excluding lowercase
    (let y 0)
    (while (< y height)
    (let x 0)
        (while (< x width)
        (color (+ 1 (rand 14)))
            (put x y (num->char (+ 32 (rand 56))))
            (= x (+ x 1))
            )
    (= y (+ y 1))
)

(color 1)
(do
(let x (- (// width 2) (// (strlen msg) 2)))
    (let y (// height 2))
            (put x (- y 1) pad)
            (put x (- y 0) msg)
            (put x (+ y 1) pad)
            )
    ))

(= step (fn ()
        (delay 1)
        (let sparsity (* (+ (// (ticks) 7) 1) 7))
        (let i (+ 0x4040 (* 1 49)))
        (while (< i (+ 0x4040 (* 56 49)))
            (poke i (if (is (rand sparsity) 0) 1 0))
            (= i (+ i 1))
            )
        ))`;