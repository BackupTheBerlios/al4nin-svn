/*
 * Copyright (c) 2005 Gabor Greif
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
 
namespace aL4nin
{


// RawObj2Meta is intended to return a pointer for an object
// living in the world, that describes its allocation and collection
// behaviour.
// PAGE: number of bits needed to address a byte in a VM-page
// CLUSTER: how many bits are needed to address a page in a VM cluster of pages
// SCALE: how many bytes together have the same metadata info (2^SCALE bytes)
//   ##!! not true: SCALE simply tells us how much "denser" metaobjects are
//        compared to objects. I.e. 32*8byte (cons cells) together share the same
//        metaobject, and the metaobject is 8bytes then SCALE is 5 because
//        2^5==32.
// GRAN: 2^g is the metaobject size
//
// Theory of operation:
//   Find the lowest address in the cluster and scale down the displacement
//   of the object to the appropriate metaobject, masking away the bits so that
//   we always point to the start of the metaobject.
//
template <unsigned long PAGE_CLUSTER, unsigned long SCALE, unsigned long GRAN>
inline const void* RawObj2Meta(const void* obj)
{
    typedef unsigned long sptr_t;
    register sptr_t o(reinterpret_cast<sptr_t>(obj));
    enum 
        {
            pat = (1 << PAGE_CLUSTER) - 1,
            mask = ~((1 << GRAN) - 1)
        };
    
    register sptr_t b(o & ~static_cast<sptr_t>(pat)); // base
    register sptr_t d(o & static_cast<sptr_t>(pat));  // displacement
    return reinterpret_cast<const void*>(b + ((d >> SCALE) & mask));
}


// RawObj2Index is intended to return the index of the object
// into the object's meta's group.
// PAGE_CLUSTER: how many bits are needed to address a byte in a cluster
// OBJBYTES: size of an object, in bytes
// SCALE: see RawObj2Meta
// GRAN: see RawObj2Meta.
//
// Theory of operation:
//   Find the base-displacement to the metaobject,
//   then scale this up to get the start of this
//   object's group. Finally divide to obtain the index.
//
template <unsigned long PAGE_CLUSTER, unsigned long OBJBYTES, unsigned long SCALE, unsigned long GRAN>
inline unsigned RawObj2Index(const void* obj)
{
    typedef unsigned long sptr_t;
    register sptr_t o(reinterpret_cast<sptr_t>(obj));
    enum 
        {
            pat = (1 << PAGE_CLUSTER) - 1,
            mid = (1 << PAGE_CLUSTER) - (1 << SCALE),
            mask = ~((1 << GRAN) - 1)
        };
    
    // original:                                         // DO NOT DELETE!
    // register sptr_t d(o & static_cast<sptr_t>(pat));  // displacement
    // register sptr_t md((d >> SCALE) & mask);          // meta displacement
    // register sptr_t gd(d - (md << SCALE));            // displacement into meta's group of objs
    //
    // streamlined:
    register sptr_t gd = (o & pat) - (o & pat & (mask << SCALE) & mid);
    
    return gd / OBJBYTES;
}


// RawMeta2Obj is intended to return the object of the object's meta's group
// given an index of the object in the group and the address of the metaobject
// PAGE_CLUSTER: see RawObj2Index
// OBJBYTES: see RawObj2Index
// SCALE: see RawObj2Index
//
// Theory of operation:
//   Find the base-displacement of the metaobject,
//   then scale this up to get the start of this
//   object's group. Finally advance to the indexed object.
//
template <unsigned long PAGE_CLUSTER, unsigned long OBJBYTES, unsigned long SCALE>
inline void* RawMeta2Obj(void* meta, unsigned index)
{
    typedef unsigned long sptr_t;
    register sptr_t m(reinterpret_cast<sptr_t>(meta));
    enum 
        {
            pat = (1 << PAGE_CLUSTER) - 1,
        };
    
    register sptr_t b(m & ~pat);                        // base
    register sptr_t md(m & pat);                        // meta displacement
    register sptr_t gb(b + (md << SCALE));              // base of meta's group of objs
    return reinterpret_cast<void*>(gb + OBJBYTES * index);
}


// RawMeta2Cluster is intended to return the start of the metaobject's cluster
// given the address of the metaobject
// PAGE_CLUSTER: see RawObj2Index
//
// Theory of operation:
//   Find the base-displacement of the metaobject,
//   by masking away the LSB PAGE_CLUSTER bits.
//
template <unsigned long PAGE_CLUSTER>
inline void* RawMeta2Cluster(void* meta)
{
    typedef unsigned long sptr_t;
    register sptr_t m(reinterpret_cast<sptr_t>(meta));
    enum 
        {
            pat = (1 << PAGE_CLUSTER) - 1,
        };
    
    return reinterpret_cast<void*>(m & ~pat);
}


} // aL4nin
