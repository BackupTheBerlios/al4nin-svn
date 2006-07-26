/*
module: terra-incognita
synopsis: ICFP 2006 contest postmission
author: heisenbug
copyright: © 2006 terraincognita team
*/

#include <algorithm>
#include <iostream>

// Alternative (PseudoJIT) Universal Machine

typedef void (*Fun)(void);


void Halt(Fun* array0, unsigned (&regs)[10])
{
    std::cerr << "Halting." << std::endl;
}

typedef typeof(Halt) *Instruct;

#define genC(NAME, A, B) NAME<A, B, 0>, NAME<A, B, 1>, NAME<A, B, 2>, NAME<A, B, 3>, NAME<A, B, 4>, NAME<A, B, 5>, NAME<A, B, 6>, NAME<A, B, 7>
#define genB(NAME, A) genC(NAME, A, 0), genC(NAME, A, 1), genC(NAME, A, 2), genC(NAME, A, 3), genC(NAME, A, 4), genC(NAME, A, 5), genC(NAME, A, 6), genC(NAME, A, 7)
#define genA(NAME) genB(NAME, 0), genB(NAME, 1), genB(NAME, 2), genB(NAME, 3), genB(NAME, 4), genB(NAME, 5), genB(NAME, 6), genB(NAME, 7)

inline static unsigned getOrig(Fun* array0, unsigned (&regs)[10])
{
    unsigned* v(reinterpret_cast<unsigned*>(regs[8]));
    ptrdiff_t offset = array0 - reinterpret_cast<Fun*>(regs[9]);
    return v[offset];
}

template <int, int B, int C>
void Alloc(Fun* array0, unsigned (&regs)[10])
{
    const size_t need(regs[C]);
    std::cerr << "Allocating. " << need << " [" << B << "] "  << " = alloc[" << C << "] " << std::endl;
    regs[B] = reinterpret_cast<unsigned>(new unsigned[need]);

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int, int B, int C>
void Load(Fun* array0, unsigned (&regs)[10])
{
    if (regs[B])
    {
        // set c-o-w ###
        regs[9] = regs[B];
    }
    array0 = reinterpret_cast<Fun*>(regs[9]);
    array0 += regs[C];
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int, int, int C>
void Abandon(Fun* array0, unsigned (&regs)[10])
{
    std::cerr << "Abandoning. " << " [" << C << "] " << std::endl;
    delete reinterpret_cast<unsigned*>(regs[C]);

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int, int, int C>
void Output(Fun* array0, unsigned (&regs)[10])
{
    char ch(regs[C]);
    std::cout << ch << std::flush;

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int, int, int C>
void Input(Fun* array0, unsigned (&regs)[10])
{
    char ch;
    std::cin >> ch;
    regs[C] = std::cin.eof() ? ~0 : static_cast<unsigned char>(ch);

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Cond(Fun* array0, unsigned (&regs)[10])
{
    if (regs[C])
		regs[A] = regs[B];

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int, int, int A>
void Ortho(Fun* array0, unsigned (&regs)[10])
{
    enum { mask = (1 << 25) - 1 };
    regs[A] = mask & getOrig(array0, regs);

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Index(Fun* array0, unsigned (&regs)[10])
{
    const unsigned* arr(reinterpret_cast<unsigned*>(regs[B]));
  
    regs[A] = arr ? arr[regs[C]] : reinterpret_cast<const unsigned*>(regs[8])[regs[C]];

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Amend(Fun* array0, unsigned (&regs)[10])
{
    unsigned* arr(reinterpret_cast<unsigned*>(regs[A]));

    if (arr)
        arr[regs[B]] = regs[C];
    else
        reinterpret_cast<unsigned*>(regs[8])[regs[B]] = regs[C];

    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Add(Fun* array0, unsigned (&regs)[10])
{
    regs[A] = regs[B] + regs[C];
    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Mul(Fun* array0, unsigned (&regs)[10])
{
    regs[A] = regs[B] * regs[C];
    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Div(Fun* array0, unsigned (&regs)[10])
{
    regs[A] = regs[B] / regs[C];
    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

template <int A, int B, int C>
void Nand(Fun* array0, unsigned (&regs)[10])
{
    regs[A] = ~(regs[B] & regs[C]);
    ++array0;
    (*reinterpret_cast<Instruct*>(array0))(array0, regs);
}

void Compiler(Fun* array0, unsigned (&regs)[10])
{
    const unsigned platter(getOrig(array0, regs));
//    unsigned* v(reinterpret_cast<unsigned*>(regs[8]));
//    ptrdiff_t offset = array0 - reinterpret_cast<Fun*>(regs[9]);
//    unsigned platter = v[offset];
    std::cerr << std::hex <<"platter: " << platter << std::dec << std::endl;

	Instruct compiled;
    
    switch (platter >> 28)
    {
        case 0:
        {
            static Instruct const movers[8 * 8 * 8] = { genA(Cond) };
            compiled = movers[platter & 0x1FF];
            break;
        };
        case 1:
        {
            static Instruct const indexers[8 * 8 * 8] = { genA(Index) };
            compiled = indexers[platter & 0x1FF];
            break;
        };
        case 2:
        {
            static Instruct const amenders[8 * 8 * 8] = { genA(Amend) };
            compiled = amenders[platter & 0x1FF];
            break;
        };
        case 3:
        {
            static Instruct const adders[8 * 8 * 8] = { genA(Add) };
            compiled = adders[platter & 0x1FF];
            break;
        };
        case 4:
        {
            static Instruct const multipliers[8 * 8 * 8] = { genA(Mul) };
            compiled = multipliers[platter & 0x1FF];
            break;
        };
        case 5:
        {
            static Instruct const dividers[8 * 8 * 8] = { genA(Div) };
            compiled = dividers[platter & 0x1FF];
            break;
        };
        case 6:
        {
            static Instruct const nanders[8 * 8 * 8] = { genA(Nand) };
            compiled = nanders[platter & 0x1FF];
            break;
        };
        case 7:
            compiled = Halt;
            break;
        case 8:
        {
            static Instruct const allocers[8 * 8] = { genB(Alloc, 0) };
            compiled = allocers[platter & 0x3F];
            break;
        }
        case 9:
        {
            static Instruct const abandoners[8] = { genC(Abandon, 0, 0) };
            compiled = abandoners[platter & 0x7];
            break;
        }
        case 10:
        {
            static Instruct const outputters[8] = { genC(Output, 0, 0) };
            compiled = outputters[platter & 0x7];
            break;
        }
        case 11:
        {
            static Instruct const inputters[8] = { genC(Input, 0, 0) };
            compiled = inputters[platter & 0x7];
            break;
        }
        case 12:
        {
            static Instruct const loaders[8 * 8] = { genB(Load, 0) };
            compiled = loaders[platter & 0x3F];
            break;
        }
        case 13:
        {
            static Instruct const orthographers[8] = { genC(Ortho, 0, 0) };
            compiled = orthographers[(platter >> 25) & 0x7];
            break;
        }
    };

	array0[0] = reinterpret_cast<Fun>(compiled);
    compiled(array0, regs);
}

struct d2cObject
{
    const d2cObject& d2cClass;
    
    private: d2cObject(void); // no impl.
};

struct d2cCell : d2cObject
{
    unsigned data;
};

struct DylanVector : d2cObject
{
    size_t size;
    d2cCell arr[];
};


Fun fillWithCompiler(const d2cCell&)
{
    return reinterpret_cast<Fun>(Compiler);
}


unsigned justCopy(const d2cCell& c)
{
    return c.data;
}


extern "C" void* enterUM(void* dylancookie, const struct DylanVector& v)
{
    unsigned* copy = new unsigned[v.size];
    std::transform(v.arr, v.arr + v.size, copy, justCopy);
    Fun* jitted = new Fun[v.size];
    std::transform(v.arr, v.arr + v.size, jitted, fillWithCompiler);
    unsigned regs[10] = { 0, 0, 0, 0, 0, 0, 0, 0, unsigned(copy), unsigned(jitted)};
    reinterpret_cast<Instruct>(*jitted)(jitted, regs);
    return dylancookie;
}

/*
int main(void)
{
    std::cerr << "main." << std::endl;
    DylanVector& v(*(DylanVector*)new char[100]);
    v.size = 4;
    v.arr[0].data = (13 << 28) | (1 << 25) | 42; // Ortho: A = 1, val 41
    v.arr[1].data = (3 << 28) | (5 << 6) | (3 << 3) | 1; // Add: A = 5, B = 3, C = 1
    v.arr[2].data = (8 << 28) | (7 << 3) | 1; // Alloc: B = 7, C = 1
    v.arr[3].data = 7 << 28;       // Halt
    
    enterUM(NULL, v);
}
*/
