module fe;
/*
** Copyright (c) 2020 rxi
**
** This library is free software; you can redistribute it and/or modify it
** under the terms of the MIT license. See `fe.c` for details.
*/

// Note: objective is to be embedded, so removed things related to FILE*.
nothrow @nogc:

import core.stdc.string: memset, strlen, strchr, strcmp;
import core.stdc.stdlib: strtod;
import core.stdc.stdio: snprintf, putc, stdout;

public:




/**
    Create/destroys a fe interpreter context for use in a project.
    
    The function expects a block of memory (typically greater than 16kb), the 
    block is used by the context to store objects and context state and should 
    remain valid for the lifetime of the context. `fe_close()` should be called
    when you are finished with a context, this will assure any ptr objects are 
    properly garbage collected.

    Example:
        int size = 1024 * 1024;
        void* data = malloc(size);
        void* udata = null; // optional user data
        fe_Context* ctx = fe_open(data, size, udata);
        // ...
        fe_close(ctx);
        free(data);
*/
alias fe_open = fe_open_impl;
///ditto
alias fe_close = fe_close_impl;


// A foreign function.
alias fe_CFunc = fe_Object* function(fe_Context *ctx, fe_Object *args);

// Report error from interpreter.
alias fe_ErrorFn = void function(fe_Context *ctx, const(char)*err, fe_Object* cl);

// Write one char to stdout.
alias fe_PutChar = void function(char chr);

// write one char to user
alias fe_WriteFn = void function(fe_Context *ctx, void* udata, char chr);

// read one char to user
alias fe_ReadFn = char function(fe_Context *ctx, void* udata);

/// Collection of all callbacks to setup.
struct fe_Handlers
{
    fe_ErrorFn error; 
    fe_CFunc mark, gc; 
    fe_PutChar putChar;
}

/**
    Setup some necessary I/O callbacks.
 
    Example:
        fe_handlers(ctx).error = &myErrorFun;
        fe_handlers(ctx).putChar = &myPutChar;
*/
fe_Handlers* fe_handlers(fe_Context *ctx) 
{
    return &ctx.handlers;
}

void defaultPutChar(char ch)
{
    putc(ch, stdout);
}

/**
    To run a script it should first be read then evaluated; this should be done
    in a loop if there are several root-level expressions contained in the 
    script. `fe_read()` can be used with a custom `fe_ReadFn` callback function
    to read from the source.

    Example:

        int gc = fe_savegc(ctx);
        while(true)
        {
            fe_Object *obj = fe_read(ctx, &readFn, userData);

            // break if there's nothing left to read
            if (!obj) break;

            // evaluate read object
            fe_eval(ctx, obj);
        }
        // restore GC stack which would now contain 
        // both the read object and result from evaluation
        fe_restoregc(ctx, gc);
*/
alias fe_read = fe_read_impl;
///ditto
alias fe_eval = fe_eval_impl;
///ditto
alias fe_savegc = fe_savegc_impl;
///ditto
alias fe_restoregc = fe_restoregc_impl;


/**
    Calling a function.

    fe_Object* fe_bool(fe_Context *ctx, int b);
    fe_Object* fe_number(fe_Context *ctx, fe_Number n);
    fe_Object* fe_string(fe_Context *ctx, const char *str);
    fe_Object* fe_symbol(fe_Context *ctx, const char *name);
    fe_Number fe_tonumber(fe_Context *ctx, fe_Object *obj);

    A function can be called by creating a list and evaulating it; for example,
    we could add two numbers using the + function.

    Example:

        int gc = fe_savegc(ctx);

        fe_Object* objs[3];
        objs[0] = fe_symbol(ctx, "+");
        objs[1] = fe_number(ctx, 10);
        objs[2] = fe_number(ctx, 20);

        fe_Object* res = fe_eval(ctx, fe_list(ctx, objs, 3));
        printf("result: %g\n", fe_tonumber(ctx, res));

        // discard all temporary objects pushed to the GC stack
        fe_restoregc(ctx, gc);
*/
alias fe_bool = fe_bool_impl;
///ditto
alias fe_number = fe_number_impl;
///ditto
alias fe_string = fe_string_impl;
///ditto
alias fe_symbol = fe_symbol_impl;
///ditto
fe_Number fe_tonumber(fe_Context *ctx, fe_Object *obj) 
{
    return number(checktype(ctx, obj, FE_TNUMBER));
}
///ditto
alias fe_cfunc = fe_cfunc_impl;
///ditto
alias fe_list = fe_list_impl;


/// Types in fe language
enum 
{
    FE_TPAIR,  ///
    FE_TFREE,  ///
    FE_TNIL,   ///
    FE_TNUMBER,///
    FE_TSYMBOL,///
    FE_TSTRING,///
    FE_TFUNC,  ///
    FE_TMACRO, ///
    FE_TPRIM,  ///
    FE_TCFUNC, ///
    FE_TPTR    ///
}

/// Get type of a fe value.
int fe_type(fe_Context *ctx, fe_Object *obj) 
{
    return type(obj);
}

// To document:
alias fe_nextarg = fe_nextarg_impl;
alias fe_error = fe_error_impl;
alias fe_tostring = fe_tostring_impl;
alias fe_car = fe_car_impl;
alias fe_cdr = fe_cdr_impl;


/// Get user data pointer.
void* fe_userdata(fe_Context* ctx)
{
    return ctx.udata;
}

/// Set value in environment.
void fe_set(fe_Context *ctx, fe_Object *sym, fe_Object *v) 
{
    cdr(getbound(sym, &nil)) = v;
}


// Not technically in public API, but we need to expose them as pointers.

struct fe_Object 
{ 
    Value car, cdr; 
}

struct fe_Context
{
    fe_Handlers handlers;
    fe_Object*[GCSTACKSIZE] gcstack;
    int gcstack_idx;
    fe_Object* objects;
    int object_count;
    fe_Object* calllist;
    fe_Object* freelist;
    fe_Object* symlist;
    fe_Object* t;
    int nextchr;

    // Addition: user data pointer, if you need to hold a larger interpreter object.
    void* udata;
}

private:

enum FE_VERSION = "1.0";

alias fe_Number = float;


static immutable string[] typenames = 
[
    "pair", "free", "nil", "number", "symbol", "string",
    "func", "macro", "prim", "cfunc", "ptr"
];


enum GCSTACKSIZE = 256;
enum int GCMARKBIT = 2;
enum int STRBUFSIZE = cast(int)((fe_Object*).sizeof - 1);

bool isnil(fe_Object* obj)
{
    return obj == &nil;
}

int type(fe_Object* obj)
{
    return (tag(obj) & 0x1) ? (tag(obj) >> 2) : FE_TPAIR;
}

ref char tag(fe_Object* obj)
{
    return obj.car.c;
}

ref fe_Object* car(fe_Object* obj)
{
    return obj.car.o;
}

ref fe_Object* cdr(fe_Object* obj)
{
    return obj.cdr.o;
}

ref float number(fe_Object* obj)
{
    return obj.cdr.n;
}

ref fe_CFunc cfunc(fe_Object* obj)
{
    return obj.cdr.f;
}

char* strbuf(fe_Object* x)
{
    return &x.car.c + 1;
}

ref char prim(fe_Object* x)
{
    return x.cdr.c;
}

void settype(fe_Object* obj, int t)
{
    tag(obj) = cast(char)(t << 2 | 1);
}


enum 
{
    P_LET, P_SET, P_IF, P_FN, P_MAC, P_WHILE, P_QUOTE, P_AND, P_OR, P_DO, P_CONS,
    P_CAR, P_CDR, P_SETCAR, P_SETCDR, P_LIST, P_NOT, P_IS, P_ATOM, P_PRINT, P_LT,
    P_LTE, P_ADD, P_SUB, P_MUL, P_DIV, P_MAX
}

static immutable string[] primnames = 
[
    "let", "=", "if", "fn", "mac", "while", "quote", "and", "or", "do", "cons",
    "car", "cdr", "setcar", "setcdr", "list", "not", "is", "atom", "print", "<",
    "<=", "+", "-", "*", "/"
];



union Value
{ 
    fe_Object *o; 
    fe_CFunc f; 
    fe_Number n; 
    char c; 
}

static assert(Value.sizeof == (void*).sizeof);


__gshared fe_Object nil = makeNil();

fe_Object makeNil()
{
    fe_Object nil;
    nil.car.o = cast(fe_Object *) cast(void*)(FE_TNIL << 2 | 1);
    nil.cdr.o = null;
    return nil;
}

void fe_error_impl(fe_Context *ctx, const char *msg) 
{
    fe_Object *cl = ctx.calllist;
    /* reset context state */
    ctx.calllist = &nil;
    
    /* do error handler */    
    ctx.handlers.error(ctx, msg, cl);
}


fe_Object* fe_nextarg_impl(fe_Context *ctx, fe_Object **arg) 
{
    fe_Object *a = *arg;
    if (type(a) != FE_TPAIR) 
    {
        if (isnil(a)) { fe_error(ctx, "too few arguments"); }
        fe_error(ctx, "dotted pair in argument list");
    }
    *arg = cdr(a);
    return car(a);
}


fe_Object* checktype(fe_Context *ctx, fe_Object *obj, int supposedtype) 
{
    char[64] buf;
    if (type(obj) != supposedtype) 
    {
        snprintf(buf.ptr, 64, "expected %s, got %s", typenames[supposedtype].ptr, typenames[type(obj)].ptr);
        fe_error(ctx, buf.ptr);
    }
    return obj;
}

int fe_isnil(fe_Context *ctx, fe_Object *obj) {
  return isnil(obj);
}


void fe_pushgc(fe_Context *ctx, fe_Object *obj) 
{
    if (ctx.gcstack_idx == GCSTACKSIZE) 
    {
        fe_error(ctx, "gc stack overflow");
    }
    ctx.gcstack[ctx.gcstack_idx++] = obj;
}

void fe_restoregc_impl(fe_Context *ctx, int idx) 
{
    ctx.gcstack_idx = idx;
}

int fe_savegc_impl(fe_Context *ctx) 
{
    return ctx.gcstack_idx;
}

void fe_mark(fe_Context *ctx, fe_Object *obj) 
{
    fe_Object *pcar;
begin:
    if (tag(obj) & GCMARKBIT) 
    { 
        return; 
    }
    pcar = car(obj); /* store car before modifying it with GCMARKBIT */
    tag(obj) |= GCMARKBIT;

    switch (type(obj)) 
    {
    case FE_TPAIR:
        fe_mark(ctx, pcar);
        goto case FE_TFUNC;

    case FE_TFUNC: 
    case FE_TMACRO: 
    case FE_TSYMBOL: 
    case FE_TSTRING:
        obj = cdr(obj);
        goto begin;

    case FE_TPTR:
        if (ctx.handlers.mark) 
        { 
            ctx.handlers.mark(ctx, obj); 
        }
        break;
    default:
        break;
  }
}


static void collectgarbage(fe_Context *ctx) 
{
    int i;
    /* mark */
    for (i = 0; i < ctx.gcstack_idx; i++) 
    {
        fe_mark(ctx, ctx.gcstack[i]);
    }
    fe_mark(ctx, ctx.symlist);
    /* sweep and unmark */
    for (i = 0; i < ctx.object_count; i++) 
    {
        fe_Object *obj = &ctx.objects[i];
        if (type(obj) == FE_TFREE) 
            continue;

        if (~cast(int)(tag(obj)) & GCMARKBIT) 
        {
            if (type(obj) == FE_TPTR && ctx.handlers.gc) 
            {
                ctx.handlers.gc(ctx, obj);
            }
            settype(obj, FE_TFREE);
            cdr(obj) = ctx.freelist;
            ctx.freelist = obj;
        } 
        else 
        {
            tag(obj) &= ~GCMARKBIT;
        }
    }
}

int equal(fe_Object *a, fe_Object *b) 
{
  if (a == b) { return 1; }
  if (type(a) != type(b)) { return 0; }
  if (type(a) == FE_TNUMBER) 
  { 
    return number(a) == number(b); 
  }
  if (type(a) == FE_TSTRING) {
    for (; !isnil(a); a = cdr(a), b = cdr(b)) {
      if (car(a) != car(b)) { return 0; }
    }
    return a == b;
  }
  return 0;
}


static int streq(fe_Object *obj, const(char)* str) 
{
    while (!isnil(obj)) 
    {
        int i;
        for (i = 0; i < STRBUFSIZE; i++) 
        {
            if (strbuf(obj)[i] != *str) 
            { 
                return 0; 
            }
            if (*str) { str++; }
        }
        obj = cdr(obj);
    }
    return *str == '\0';
}


static fe_Object* object_(fe_Context *ctx) {
  fe_Object *obj;
  /* do gc if freelist has no more objects */
  if (isnil(ctx.freelist)) {
    collectgarbage(ctx);
    if (isnil(ctx.freelist)) { fe_error(ctx, "out of memory"); }
  }
  /* get object from freelist and push to the gcstack */
  obj = ctx.freelist;
  ctx.freelist = cdr(obj);
  fe_pushgc(ctx, obj);
  return obj;
}


fe_Object* fe_cons(fe_Context *ctx, fe_Object *pcar, fe_Object *pcdr) 
{
  fe_Object *obj = object_(ctx);
  car(obj) = pcar;
  cdr(obj) = pcdr;
  return obj;
}


fe_Object* fe_bool_impl(fe_Context *ctx, int b) {
  return b ? ctx.t : &nil;
}


fe_Object* fe_number_impl(fe_Context *ctx, fe_Number n) {
  fe_Object *obj = object_(ctx);
  settype(obj, FE_TNUMBER);
  number(obj) = n;
  return obj;
}

// Add one character to a string chain
fe_Object* buildstring(fe_Context *ctx, fe_Object *tail, int chr) 
{
    if (!tail || strbuf(tail)[STRBUFSIZE - 1] != '\0') 
    {
        fe_Object *obj = fe_cons(ctx, null, &nil);
        settype(obj, FE_TSTRING);
        if (tail) {
            cdr(tail) = obj;
            ctx.gcstack_idx--;
        }
        tail = obj;
    }
    strbuf(tail)[strlen(strbuf(tail))] = cast(char)chr;
    return tail;
}


fe_Object* fe_string_impl(fe_Context *ctx, const(char)*str) 
{
    fe_Object *obj = buildstring(ctx, null, '\0');
    fe_Object *tail = obj;
    while (*str) {
        tail = buildstring(ctx, tail, *str++);
    }
    return obj;
}

fe_Object* fe_symbol_impl(fe_Context *ctx, const(char)* name) 
{
  fe_Object *obj;
  /* try to find in symlist */
  for (obj = ctx.symlist; !isnil(obj); obj = cdr(obj)) {
    if (streq(car(cdr(car(obj))), name)) {
      return car(obj);
    }
  }
  /* create new object, push to symlist and return */
  obj = object_(ctx);
  settype(obj, FE_TSYMBOL);
  cdr(obj) = fe_cons(ctx, fe_string_impl(ctx, name), &nil);
  ctx.symlist = fe_cons(ctx, obj, ctx.symlist);
  return obj;
}


fe_Object* fe_cfunc_impl(fe_Context *ctx, fe_CFunc fn) 
{
  fe_Object *obj = object_(ctx);
  settype(obj, FE_TCFUNC);
  cfunc(obj) = fn;
  return obj;
}


fe_Object* fe_ptr(fe_Context *ctx, void *ptr) {
  fe_Object *obj = object_(ctx);
  settype(obj, FE_TPTR);
  cdr(obj) = cast(fe_Object*) ptr;
  return obj;
}


fe_Object* fe_list_impl(fe_Context *ctx, fe_Object **objs, int n) {
  fe_Object *res = &nil;
  while (n--) {
    res = fe_cons(ctx, objs[n], res);
  }
  return res;
}


fe_Object* fe_car_impl(fe_Context *ctx, fe_Object *obj) 
{
    if (isnil(obj)) { return obj; }
    return car(checktype(ctx, obj, FE_TPAIR));
}


fe_Object* fe_cdr_impl(fe_Context *ctx, fe_Object *obj) 
{
    if (isnil(obj)) { return obj; }
    return cdr(checktype(ctx, obj, FE_TPAIR));
}


void writestr(fe_Context *ctx, fe_WriteFn fn, void *udata, const(char)* s) 
{
    while (*s) 
    { 
        fn(ctx, udata, *s++); 
    }
}

void fe_write(fe_Context *ctx, fe_Object *obj, fe_WriteFn fn, void *udata, int qt) 
{
  char[32] buf;

  switch (type(obj)) 
  {
    case FE_TNIL:
      writestr(ctx, fn, udata, "nil");
      break;

    case FE_TNUMBER:
      snprintf(buf.ptr, 32, "%.7g", number(obj));
      // TOOD: remove ',' if any
      writestr(ctx, fn, udata, buf.ptr);
      break;

    case FE_TPAIR:
      fn(ctx, udata, '(');
      for (;;) {
        fe_write(ctx, car(obj), fn, udata, 1);
        obj = cdr(obj);
        if (type(obj) != FE_TPAIR) { break; }
        fn(ctx, udata, ' ');
      }
      if (!isnil(obj)) {
        writestr(ctx, fn, udata, " . ");
        fe_write(ctx, obj, fn, udata, 1);
      }
      fn(ctx, udata, ')');
      break;

    case FE_TSYMBOL:
      fe_write(ctx, car(cdr(obj)), fn, udata, 0);
      break;

    case FE_TSTRING:
      if (qt) 
      { 
        fn(ctx, udata, '"'); 
      }
      while (!isnil(obj)) 
      {
        int i;
        for (i = 0; i < STRBUFSIZE && strbuf(obj)[i]; i++) {
          if (qt && strbuf(obj)[i] == '"') { fn(ctx, udata, '\\'); }
          fn(ctx, udata, strbuf(obj)[i]);
        }
        obj = cdr(obj);
      }
      if (qt) { fn(ctx, udata, '"'); }
      break;

    default:
      snprintf(buf.ptr, 32, "[%s %p]", typenames[type(obj)].ptr, cast(void*) obj);
      writestr(ctx, fn, udata, buf.ptr);
      break;
  }
}

void writechar(fe_Context *ctx, void* udata, char chr) 
{
    ctx.handlers.putChar(chr);
}

struct CharPtrInt
{ 
    char *p; 
    int n; 
}

void writebuf(fe_Context *ctx, void *udata, char chr) 
{
    CharPtrInt *x = cast(CharPtrInt*) udata;
    if (x.n) { *x.p++ = chr; x.n--; }
}

int fe_tostring_impl(fe_Context *ctx, fe_Object *obj, char *dst, int size) 
{
    CharPtrInt x;
    x.p = dst;
    x.n = size - 1;
    fe_write(ctx, obj, &writebuf, &x, 0);
    *x.p = '\0';
    return size - x.n - 1;
}

void* fe_toptr(fe_Context *ctx, fe_Object *obj) {
  return cdr(checktype(ctx, obj, FE_TPTR));
}


static fe_Object* getbound(fe_Object *sym, fe_Object *env) {
  /* try to find in environment */
  for (; !isnil(env); env = cdr(env)) {
    fe_Object *x = car(env);
    if (car(x) == sym) { return x; }
  }
  /* return global */
  return cdr(sym);
}


static fe_Object rparen;

static fe_Object* read_(fe_Context *ctx, fe_ReadFn fn, void *udata) 
{
  const char *delimiter = " \n\t\r();";
  fe_Object *v;
  fe_Object *res;
  fe_Object **tail;
  fe_Number n;
  int chr, gc;
  char[64] buf;
  char* p;

  /* get next character */
  chr = ctx.nextchr ? ctx.nextchr : fn(ctx, udata);
  ctx.nextchr = '\0';

  /* skip whitespace */
  while (chr && strchr(" \n\t\r", chr)) {
    chr = fn(ctx, udata);
  }

  switch (chr) {
    case '\0':
      return null;

    case ';':
      while (chr && chr != '\n') { chr = fn(ctx, udata); }
      return read_(ctx, fn, udata);

    case ')':
      return &rparen;

    case '(':
      res = &nil;
      tail = &res;
      gc = fe_savegc_impl(ctx);
      fe_pushgc(ctx, res); /* to cause error on too-deep nesting */
      while ( (v = read_(ctx, fn, udata)) != &rparen ) {
        if (v == null) { fe_error(ctx, "unclosed list"); }
        if (type(v) == FE_TSYMBOL && streq(car(cdr(v)), ".")) {
          /* dotted pair */
          *tail = fe_read_impl(ctx, fn, udata);
        } else {
          /* proper pair */
          *tail = fe_cons(ctx, v, &nil);
          tail = &cdr(*tail);
        }
        fe_restoregc_impl(ctx, gc);
        fe_pushgc(ctx, res);
      }
      return res;

    case '\'':
      v = fe_read_impl(ctx, fn, udata);
      if (!v) { fe_error(ctx, "stray '''"); }
      return fe_cons(ctx, fe_symbol_impl(ctx, "quote"), fe_cons(ctx, v, &nil));

    case '"':
      res = buildstring(ctx, null, '\0');
      v = res;
      chr = fn(ctx, udata);
      while (chr != '"') {
        if (chr == '\0') { fe_error(ctx, "unclosed string"); }
        if (chr == '\\') {
          chr = fn(ctx, udata);
          if (strchr("nrt", chr)) { chr = strchr("n\nr\rt\t", chr)[1]; }
        }
        v = buildstring(ctx, v, chr);
        chr = fn(ctx, udata);
      }
      return res;

    default:
      p = buf.ptr;
      do {
        if (p == buf.ptr + (buf.sizeof) - 1) 
        { 
            fe_error(ctx, "symbol too long"); 
            // TODO should exit nicely
        }
        *p++ = cast(char)chr;
        chr = fn(ctx, udata);
      } while (chr && !strchr(delimiter, chr));
      *p = '\0';
      ctx.nextchr = chr;
      n = strtod(buf.ptr, &p);  /* try to read as number */
      if (p != buf.ptr && strchr(delimiter, *p)) { return fe_number_impl(ctx, n); }
      if (!strcmp(buf.ptr, "nil")) { return &nil; }
      return fe_symbol_impl(ctx, buf.ptr);
  }
}

fe_Object* fe_read_impl(fe_Context *ctx, fe_ReadFn fn, void *udata) 
{
    fe_Object* obj = read_(ctx, fn, udata);
    if (obj == &rparen) 
    { 
        fe_error(ctx, "stray ')'"); 
        //TODO: should exit nicely
    }
    return obj;
}

fe_Object* evallist(fe_Context *ctx, fe_Object *lst, fe_Object *env) 
{
    fe_Object *res = &nil;
    fe_Object **tail = &res;
    while (!isnil(lst)) 
    {
        *tail = fe_cons(ctx, eval(ctx, fe_nextarg(ctx, &lst), env, null), &nil);
        tail = &cdr(*tail);
    }
    return res;
}


static fe_Object* dolist(fe_Context *ctx, fe_Object *lst, fe_Object *env) {
  fe_Object *res = &nil;
  int save = fe_savegc_impl(ctx);
  while (!isnil(lst)) {
    fe_restoregc_impl(ctx, save);
    fe_pushgc(ctx, lst);
    fe_pushgc(ctx, env);
    res = eval(ctx, fe_nextarg(ctx, &lst), env, &env);
  }
  return res;
}


static fe_Object* argstoenv(fe_Context *ctx, fe_Object *prm, fe_Object *arg, fe_Object *env) {
  while (!isnil(prm)) {
    if (type(prm) != FE_TPAIR) {
      env = fe_cons(ctx, fe_cons(ctx, prm, arg), env);
      break;
    }
    env = fe_cons(ctx, fe_cons(ctx, car(prm), fe_car(ctx, arg)), env);
    prm = cdr(prm);
    arg = fe_cdr(ctx, arg);
  }
  return env;
}

fe_Object* evalarg(fe_Context *ctx, ref fe_Object *arg, fe_Object *env)
{
    return eval(ctx, fe_nextarg(ctx, &arg), env, null);
}

fe_Object* eval(fe_Context *ctx, 
                fe_Object *obj, 
                fe_Object *env, 
                fe_Object **newenv) 
{
  fe_Object *fn, arg, res;
  fe_Object cl;
  fe_Object* va, vb;
  int n, gc;

  if (type(obj) == FE_TSYMBOL) { return cdr(getbound(obj, env)); }
  if (type(obj) != FE_TPAIR) { return obj; }

  car(&cl) = obj, cdr(&cl) = ctx.calllist;
  ctx.calllist = &cl;

  gc = fe_savegc_impl(ctx);
  fn = eval(ctx, car(obj), env, null);
  arg = cdr(obj);
  res = &nil;

  switch (type(fn)) {
    case FE_TPRIM:
      switch (prim(fn)) 
      {
        case P_LET:
          va = checktype(ctx, fe_nextarg(ctx, &arg), FE_TSYMBOL);
          if (newenv) 
          {
            *newenv = fe_cons(ctx, fe_cons(ctx, va, evalarg(ctx, arg, env)), env);
          }
          break;

        case P_SET:
          va = checktype(ctx, fe_nextarg(ctx, &arg), FE_TSYMBOL);
          cdr(getbound(va, env)) = evalarg(ctx, arg, env);
          break;

        case P_IF:
          while (!isnil(arg)) {
            va = evalarg(ctx, arg, env);
            if (!isnil(va)) {
              res = isnil(arg) ? va : evalarg(ctx, arg, env);
              break;
            }
            if (isnil(arg)) { break; }
            arg = cdr(arg);
          }
          break;

        case P_FN: case P_MAC:
          va = fe_cons(ctx, env, arg);
          fe_nextarg(ctx, &arg);
          res = object_(ctx);
          settype(res, prim(fn) == P_FN ? FE_TFUNC : FE_TMACRO);
          cdr(res) = va;
          break;

        case P_WHILE:
          va = fe_nextarg(ctx, &arg);
          n = fe_savegc_impl(ctx);
          while (!isnil(eval(ctx, va, env, null))) 
          {
            dolist(ctx, arg, env);
            fe_restoregc_impl(ctx, n);
          }
          break;

        case P_QUOTE:
          res = fe_nextarg(ctx, &arg);
          break;

        case P_AND:
          while (!isnil(arg) && !isnil(res = evalarg(ctx, arg, env))) 
          {
          }
          break;

        case P_OR:
          while (!isnil(arg) && isnil(res = evalarg(ctx, arg, env))) 
          {
          }
          break;

        case P_DO:
          res = dolist(ctx, arg, env);
          break;

        case P_CONS:
          va = evalarg(ctx, arg, env);
          res = fe_cons(ctx, va, evalarg(ctx, arg, env));
          break;

        case P_CAR:
          res = fe_car(ctx, evalarg(ctx, arg, env));
          break;

        case P_CDR:
          res = fe_cdr(ctx, evalarg(ctx, arg, env));
          break;

        case P_SETCAR:
          va = checktype(ctx, evalarg(ctx, arg, env), FE_TPAIR);
          car(va) = evalarg(ctx, arg, env);
          break;

        case P_SETCDR:
          va = checktype(ctx, evalarg(ctx, arg, env), FE_TPAIR);
          cdr(va) = evalarg(ctx, arg, env);
          break;

        case P_LIST:
          res = evallist(ctx, arg, env);
          break;

        case P_NOT:
          res = fe_bool(ctx, isnil(evalarg(ctx, arg, env)));
          break;

        case P_IS:
          va = evalarg(ctx, arg, env);
          res = fe_bool(ctx, equal(va, evalarg(ctx, arg, env)));
          break;

        case P_ATOM:
          res = fe_bool(ctx, fe_type(ctx, evalarg(ctx, arg, env)) != FE_TPAIR);
          break;

        case P_PRINT:

            while (!isnil(arg)) 
            {
                fe_write(ctx, evalarg(ctx, arg, env), &writechar, null, 0);
              if (!isnil(arg)) { writechar(ctx, null, ' '); }
            }
            writechar(ctx, null, '\n');
            break;

        case P_LT:
            va = checktype(ctx, evalarg(ctx, arg, env), FE_TNUMBER);
            vb = checktype(ctx, evalarg(ctx, arg, env), FE_TNUMBER);
            res = fe_bool(ctx, number(va) < number(vb));
            break;

        case P_LTE:
            va = checktype(ctx, evalarg(ctx, arg, env), FE_TNUMBER);
            vb = checktype(ctx, evalarg(ctx, arg, env), FE_TNUMBER);
            res = fe_bool(ctx, number(va) <= number(vb));
            break;

        case P_ADD:
            fe_Number x = fe_tonumber(ctx, evalarg(ctx, arg, env));
            while (!isnil(arg)) 
            {
                x = x + fe_tonumber(ctx, evalarg(ctx, arg, env));
            }
            res = fe_number_impl(ctx, x);
            break;

        case P_SUB:
            fe_Number x = fe_tonumber(ctx, evalarg(ctx, arg, env));
            while (!isnil(arg)) 
            {
                x = x - fe_tonumber(ctx, evalarg(ctx, arg, env));
            }
            res = fe_number_impl(ctx, x);
            break;

        case P_MUL:
            fe_Number x = fe_tonumber(ctx, evalarg(ctx, arg, env));
            while (!isnil(arg)) 
            {
                x = x * fe_tonumber(ctx, evalarg(ctx, arg, env));
            }
            res = fe_number_impl(ctx, x);
            break;

        case P_DIV:
            fe_Number x = fe_tonumber(ctx, evalarg(ctx, arg, env));
            while (!isnil(arg)) 
            {
                x = x / fe_tonumber(ctx, evalarg(ctx, arg, env));
            }
            res = fe_number_impl(ctx, x);
            break;

        default:
            assert(false);
      }
      break;

    case FE_TCFUNC:
      res = cfunc(fn)(ctx, evallist(ctx, arg, env));
      break;

    case FE_TFUNC:
      arg = evallist(ctx, arg, env);
      va = cdr(fn); /* (env params ...) */
      vb = cdr(va); /* (params ...) */
      res = dolist(ctx, cdr(vb), argstoenv(ctx, car(vb), arg, car(va)));
      break;

    case FE_TMACRO:
      va = cdr(fn); /* (env params ...) */
      vb = cdr(va); /* (params ...) */
      /* replace caller object with code generated by macro and re-eval */
      *obj = *dolist(ctx, cdr(vb), argstoenv(ctx, car(vb), arg, car(va)));
      fe_restoregc_impl(ctx, gc);
      ctx.calllist = cdr(&cl);
      return eval(ctx, obj, env, null);

    default:
      fe_error(ctx, "tried to call non-callable value");
  }

  fe_restoregc_impl(ctx, gc);
  fe_pushgc(ctx, res);
  ctx.calllist = cdr(&cl);
  return res;
}

fe_Object* fe_eval_impl(fe_Context *ctx, fe_Object *obj) 
{
    return eval(ctx, obj, &nil, null);
}

fe_Context* fe_open_impl(void *ptr, int size, void* udata = null) 
{
    int i, save;
    fe_Context *ctx;

    /* init context struct */
    ctx = cast(fe_Context*) ptr;
    memset(ctx, 0, fe_Context.sizeof);
    ptr = cast(char*) ptr + fe_Context.sizeof;
    size -= fe_Context.sizeof;

    /* init objects memory region */
    ctx.objects = cast(fe_Object*) ptr;
    ctx.object_count = cast(int)(size / fe_Object.sizeof);

    /* init lists */
    ctx.calllist = &nil;
    ctx.freelist = &nil;
    ctx.symlist = &nil;

    /* init user data */
    ctx.udata = udata;

    /* populate freelist */
    for (i = 0; i < ctx.object_count; i++) 
    {
        fe_Object *obj = &ctx.objects[i];
        settype(obj, FE_TFREE);
        cdr(obj) = ctx.freelist;
        ctx.freelist = obj;
    }

    /* init objects */
    ctx.t = fe_symbol_impl(ctx, "t");
    fe_set(ctx, ctx.t, ctx.t);

    /* register built in primitives */
    save = fe_savegc_impl(ctx);
    for (i = 0; i < P_MAX; i++) 
    {
        fe_Object *v = object_(ctx);
        settype(v, FE_TPRIM);
        prim(v) = cast(char) i;
        fe_set(ctx, fe_symbol_impl(ctx, primnames[i].ptr), v);
        fe_restoregc_impl(ctx, save);
    }

    ctx.handlers.putChar = &defaultPutChar;

    return ctx;
}

void fe_close_impl(fe_Context *ctx) 
{
    /* clear gcstack and symlist; makes all objects unreachable */
    ctx.gcstack_idx = 0;
    ctx.symlist = &nil;
    collectgarbage(ctx);
}

unittest // create/destroy interpreter
{   
    import core.stdc.stdlib;
    int size = 1024 * 1024;
    void* data = malloc(size);
    fe_Context* ctx = fe_open(data, size);
    fe_close(ctx);
    free(data);
}

unittest // call a function manually
{
    import core.stdc.stdlib;
    import core.stdc.stdio;
    int size = 1024 * 1024;
    void* data = malloc(size);
    fe_Context* ctx = fe_open(data, size);

    int gc = fe_savegc(ctx);

    fe_Object*[3] objs;
    objs[0] = fe_symbol(ctx, "+");
    objs[1] = fe_number(ctx, 10);
    objs[2] = fe_number(ctx, 20);

    fe_Object* res = fe_eval(ctx, fe_list(ctx, objs.ptr, 3));
    assert( fe_tonumber(ctx, res) == 30.0f );

    // discard all temporary objects pushed to the GC stack
    fe_restoregc(ctx, gc);

    fe_close(ctx);
    free(data);
}