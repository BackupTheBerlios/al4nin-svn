/*
module: terra-incognita
synopsis: ICFP 2006 contest postmission
author: heisenbug
copyright: © 2006 terraincognita team
*/

#include <algorithm>
#include <cstdio>
//#include <iostream>

// Alternative (PseudoJIT) Universal Machine

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


void Halt(void** array0, unsigned (&regs)[10]/*, DylanVector&*/)
{
    std::printf("Halting.\n");
}

typedef typeof(Halt) *Instruct;

template <int A, int B, int C>
void Add(void** array0, unsigned (&regs)[10]/*, DylanVector&*/)
{
    std::printf("Adding.[%d] = [%d] + [%d]\n", A, B, C);
//    std::stderr << "Adding. [" << A << "] = [" << B << "] + [" << C << "]" << std::endl;
    regs[A] = regs[B] + regs[C];
    ++array0;
    (*reinterpret_cast<typeof(&Halt)*>(array0))(array0, regs);
}

void Compiler(void** array0, unsigned (&regs)[10]/*, DylanVector&*/)
{
    DylanVector& v(*reinterpret_cast<DylanVector*>(regs[8]));
    ptrdiff_t offset = array0 - reinterpret_cast<void**>(regs[9]);
    unsigned platter = v.arr[offset].data;
    std::printf("platter: %x\n", platter);
///    std::stderr.format("platter: %x\n", platter);
    
    switch (platter >> 28)
    {
        case 0:;
        case 3:
        {
            typeof(&Compiler) adders[8 * 8 * 8] = { Add<0, 0, 0>, Add<0, 0, 1> };
            array0[0] = adders[platter & 0x1F];
            break;
        };
        case 7:
            array0[0] = Halt;
            break;
    };
    
    (*reinterpret_cast<typeof(&Halt)*>(array0))(array0, regs);
};


Instruct fillWithCompiler(const d2cCell&)
{
//    std::stderr << "fillWithCompiler." << std::endl;
    std::printf("fillWithCompiler.\n");
    return Compiler;
};


extern "C" void* enterUM(void* dylancookie, const struct DylanVector& v)
{
    Instruct* jitted = new Instruct[v.size];
    std::transform(v.arr, v.arr + v.size, jitted, fillWithCompiler);
    unsigned regs[10] = { 0, 0, 0, 0, 0, 0, 0, 0, unsigned(&v), unsigned(jitted)};
    (*jitted)(jitted, regs);
    return dylancookie;
}


int main(void)
{
    std::printf("main.\n");
//    std::stderr << "main." << std::endl;
    DylanVector& v(*(DylanVector*)new char[100]);
    v.size = 2;
    v.arr[0].data = (3 << 28) + 1; // Add: A = 0, B = 0, C = 1
    v.arr[1].data = 7 << 28;       // Halt
    
    enterUM(NULL, v);
};