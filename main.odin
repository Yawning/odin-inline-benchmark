package main

import "core:simd"
import "core:encoding/hex"
import "core:fmt"
import "core:runtime"
import "core:time"

_ROUNDS :: 20

_SIGMA_0 : u32 : 0x61707865
_SIGMA_1 : u32 : 0x3320646e
_SIGMA_2 : u32 : 0x79622d32
_SIGMA_3 : u32 : 0x6b206574
_ROT_7L: simd.u32x4 : {7, 7, 7, 7}
_ROT_7R: simd.u32x4 : {25, 25, 25, 25}
_ROT_12L: simd.u32x4 : {12, 12, 12, 12}
_ROT_12R: simd.u32x4 : {20, 20, 20, 20}
_ROT_8L: simd.u32x4 : {8, 8, 8, 8}
_ROT_8R: simd.u32x4 : {24, 24, 24, 24}
_ROT_16: simd.u32x4 : {16, 16, 16, 16}

bench_setup :: proc(options: ^time.Benchmark_Options, allocator: runtime.Allocator) -> (err: time.Benchmark_Error) {
	options.output = make([]byte, 32)
	return nil
}

bench_manual_inlining :: proc(options: ^time.Benchmark_Options, allocator: runtime.Allocator) -> (err: time.Benchmark_Error) {
	key:   [32]byte
	nonce: [16]byte
	dst:   [32]byte

	for _ in 0..=options.rounds {
		hchacha20_inlined(dst[:], key[:], nonce[:])
	}
	options.count = options.rounds
	copy(options.output, dst[:])
	return nil
}

bench_compiler_inlining :: proc(options: ^time.Benchmark_Options, allocator: runtime.Allocator) -> (err: time.Benchmark_Error) {
	key:   [32]byte
	nonce: [16]byte
	dst:   [32]byte

	for _ in 0..=options.rounds {
		hchacha20(dst[:], key[:], nonce[:])
	}
	options.count = options.rounds
	copy(options.output, dst[:])
	return nil
}

main :: proc() {
	key:   [32]byte
	nonce: [16]byte
	dst:   [32]byte

	hchacha20(dst[:], key[:], nonce[:])
	x := string(hex.encode(dst[:]))
	fmt.printf("dst compiler inlining: %s\n", x)

	hchacha20_inlined(dst[:], key[:], nonce[:])
	x = string(hex.encode(dst[:]))
	fmt.printf("dst manual inlining: %s\n", x)

	options := &time.Benchmark_Options{
		rounds = 1000000,
		bytes = 64,
		setup = bench_setup,
		bench = bench_compiler_inlining,
		teardown = nil,
	}

	_ = time.benchmark(options, context.allocator)
	fmt.printf("compiler inlining:\t%v rounds, %v ns,\t%5.3f rounds/s\n", options.rounds, time.duration_nanoseconds(options.duration), options.rounds_per_second)

	options.bench = bench_manual_inlining
	_ = time.benchmark(options, context.allocator)
	fmt.printf("manual inlining:\t%v rounds, %v ns,\t%5.3f rounds/s\n", options.rounds, time.duration_nanoseconds(options.duration), options.rounds_per_second)
}