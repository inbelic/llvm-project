// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.0-library -finclude-default-header -verify %s

RWBuffer<uint> In : register(u0);
RWStructuredBuffer<uint> Out0 : register(u1);
RWStructuredBuffer<uint> Out1 : register(u2);
RWStructuredBuffer<uint> OutArr[];

cbuffer c {
    bool cond;
};

void conditional_initialization(uint idx) {
    // expected-warning@+1 {{assignment of 'cond ? Out0 : Out1' to local resource 'Out' is not to the same unique global resource}}
    RWStructuredBuffer<uint> Out = cond ? Out0 : Out1;
    Out[idx] = In[idx];
}

void branched_assignment(uint idx) {
    RWStructuredBuffer<uint> Out = Out0; // expected-note {{variable 'Out' is declared here}}
    if (cond) {
        // expected-warning@+1 {{assignment of 'Out1' to local resource 'Out' is not to the same unique global resource}}
        Out = Out1;
    }
    Out[idx] = In[idx];
}

void branched_assignment_with_array(uint idx) {
    RWStructuredBuffer<uint> Out = Out0; // expected-note {{variable 'Out' is declared here}}
    if (cond) {
        // expected-warning@+1 {{assignment of 'OutArr[0]' to local resource 'Out' is not to the same unique global resource}}
        Out = OutArr[0];
    }
    Out[idx] = In[idx];
}

void conditional_assignment(uint idx) {
    RWStructuredBuffer<uint> Out;
    // expected-warning@+1 {{assignment of 'cond ? Out0 : Out1' to local resource 'Out' is not to the same unique global resource}}
    Out = cond ? Out0 : Out1;
    Out[idx] = In[idx];
}

static RWStructuredBuffer<uint> StaticOut;

void static_conditional_assignment(uint idx) {
    // expected-warning@+1 {{assignment of 'cond ? Out0 : Out1' to local resource 'StaticOut' is not to the same unique global resource}}
    StaticOut = cond ? Out0 : Out1;
    StaticOut[idx] = In[idx];
}

void transitive_assignment(uint idx) {
    RWStructuredBuffer<uint> A = Out0; // expected-note {{variable 'A' is declared here}}
    RWStructuredBuffer<uint> B = Out1;
    // expected-warning@+1 {{assignment of 'B' to local resource 'A' is not to the same unique global resource}}
    A = B;
    A[idx] = In[idx];
}

void pingpong_swap(uint idx, uint n) {
    RWStructuredBuffer<uint> src = Out0; // expected-note {{variable 'src' is declared here}}
    RWStructuredBuffer<uint> dst = Out1; // expected-note {{variable 'dst' is declared here}}
    for (uint i = 0; i < n; ++i) {
        dst[idx] = src[idx];
        RWStructuredBuffer<uint> tmp = src;
        // expected-warning@+1 {{assignment of 'dst' to local resource 'src' is not to the same unique global resource}}
        src = dst;
        // expected-warning@+1 {{assignment of 'tmp' to local resource 'dst' is not to the same unique global resource}}
        dst = tmp;
    }
}
