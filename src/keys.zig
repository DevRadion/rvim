const key_map = blk: {
    var keys: [127]Key = undefined;

    // Lowercase a-z
    keys['a'] = Key.a;
    keys['b'] = Key.b;
    keys['c'] = Key.c;
    keys['d'] = Key.d;
    keys['e'] = Key.e;
    keys['f'] = Key.f;
    keys['g'] = Key.g;
    keys['h'] = Key.h;
    keys['i'] = Key.i;
    keys['j'] = Key.j;
    keys['k'] = Key.k;
    keys['l'] = Key.l;
    keys['m'] = Key.m;
    keys['n'] = Key.n;
    keys['o'] = Key.o;
    keys['p'] = Key.p;
    keys['q'] = Key.q;
    keys['r'] = Key.r;
    keys['s'] = Key.s;
    keys['t'] = Key.t;
    keys['u'] = Key.u;
    keys['v'] = Key.v;
    keys['w'] = Key.w;
    keys['x'] = Key.x;
    keys['y'] = Key.y;
    keys['z'] = Key.z;

    // Uppercase A-Z
    keys['A'] = Key.A;
    keys['B'] = Key.B;
    keys['C'] = Key.C;
    keys['D'] = Key.D;
    keys['E'] = Key.E;
    keys['F'] = Key.F;
    keys['G'] = Key.G;
    keys['H'] = Key.H;
    keys['I'] = Key.I;
    keys['J'] = Key.J;
    keys['K'] = Key.K;
    keys['L'] = Key.L;
    keys['M'] = Key.M;
    keys['N'] = Key.N;
    keys['O'] = Key.O;
    keys['P'] = Key.P;
    keys['Q'] = Key.Q;
    keys['R'] = Key.R;
    keys['S'] = Key.S;
    keys['T'] = Key.T;
    keys['U'] = Key.U;
    keys['V'] = Key.V;
    keys['W'] = Key.W;
    keys['X'] = Key.X;
    keys['Y'] = Key.Y;
    keys['Z'] = Key.Z;

    // Symbols
    keys['['] = Key.OpenSquareBracket;
    keys[']'] = Key.CloseSquareBracket;
    keys['{'] = Key.OpenCurlyBrace;
    keys['}'] = Key.CloseCurlyBrace;

    break :blk keys;
};

pub const Key = enum {
    Backspace,
    Delete,
    Escape,
    Tab,
    CapsLock,
    Enter,
    Ins,

    PgUp,
    PgDown,

    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,

    // Lowercase a-z
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,

    // Uppercase A-Z
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,

    // Symbols
    OpenSquareBracket,
    CloseSquareBracket,
    OpenCurlyBrace,
    CloseCurlyBrace,

    // Modifier
    Shift,
    Ctrl,
    Alt,

    pub fn isModifier(key: Key) bool {
        return switch (key) {
            Key.Shift, Key.Ctrl, Key.Alt => true,
            else => false,
        };
    }

    pub fn fromChar(char: u8) ?Key {
        if (char > key_map.len) return null;
        return key_map[char];
    }

    pub fn toChar(key: Key) ?u8 {
        if (key.isModifier()) return null;
        for (0..key_map.len) |idx| {
            if (key_map[idx] == key) return @intCast(idx);
        }
        return null;
    }
};
