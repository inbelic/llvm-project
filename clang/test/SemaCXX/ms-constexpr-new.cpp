// RUN: %clang_cc1 -fms-compatibility -fms-compatibility-version=19.33 -std=c++20 -verify=supported %s
// RUN: %clang_cc1 -fms-compatibility -fms-compatibility-version=19.32 -std=c++20 -verify=unsupported %s
// supported-no-diagnostics

[[nodiscard]]
[[msvc::constexpr]] // unsupported-warning {{unknown attribute 'msvc::constexpr' ignored}}
inline void* operator new(decltype(sizeof(void*)), void* p) noexcept { return p; }

namespace std {
  constexpr int* construct_at(int* p, int v) {
    [[msvc::constexpr]] return ::new (p) int(v); // unsupported-warning {{unknown attribute 'msvc::constexpr' ignored}}
  }
}

constexpr bool check_std_construct_at() { int x; return *std::construct_at(&x, 42) == 42; }
static_assert(check_std_construct_at());

constexpr int* construct_at(int* p, int v) { [[msvc::constexpr]] return ::new (p) int(v); } // unsupported-error {{constexpr function never produces a constant expression}} \
                                                                                            // unsupported-warning {{unknown attribute 'msvc::constexpr' ignored}} \
                                                                                            // unsupported-note 2{{this placement new expression is not supported in constant expressions before C++2c}}
constexpr bool check_construct_at() { int x; return *construct_at(&x, 42) == 42; }          // unsupported-note {{in call to 'construct_at(&x, 42)'}}
static_assert(check_construct_at());                                                        // unsupported-error {{static assertion expression is not an integral constant expression}}\
                                                                                            // unsupported-note {{in call to 'check_construct_at()'}}
