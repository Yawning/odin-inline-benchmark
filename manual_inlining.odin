package main

import "core:intrinsics"
import "core:simd"

hchacha20_inlined :: #force_no_inline proc "contextless" (dst, key, nonce: []byte) {
	v0 := simd.u32x4{_SIGMA_0, _SIGMA_1, _SIGMA_2, _SIGMA_3}
	v1 := intrinsics.unaligned_load(transmute(^simd.u32x4)&key[0])
	v2 := intrinsics.unaligned_load(transmute(^simd.u32x4)&key[16])
	v3 := intrinsics.unaligned_load(transmute(^simd.u32x4)&nonce[0])

	for i := _ROUNDS; i > 0; i = i - 2 {
		// a += b; d ^= a; d = ROTW16(d);
		v0 = simd.add(v0, v1)
		v3 = simd.bit_xor(v3, v0)
		v3 = simd.bit_xor(simd.shl(v3, _ROT_16), simd.shr(v3, _ROT_16))

		// c += d; b ^= c; b = ROTW12(b);
		v2 = simd.add(v2, v3)
		v1 = simd.bit_xor(v1, v2)
		v1 = simd.bit_xor(simd.shl(v1, _ROT_12L), simd.shr(v1, _ROT_12R))

		// a += b; d ^= a; d = ROTW8(d);
		v0 = simd.add(v0, v1)
		v3 = simd.bit_xor(v3, v0)
		v3 = simd.bit_xor(simd.shl(v3, _ROT_8L), simd.shr(v3, _ROT_8R))

		// c += d; b ^= c; b = ROTW7(b);
		v2 = simd.add(v2, v3)
		v1 = simd.bit_xor(v1, v2)
		v1 = simd.bit_xor(simd.shl(v1, _ROT_7L), simd.shr(v1, _ROT_7R))

		// b = ROTV1(b); c = ROTV2(c);  d = ROTV3(d);
		v1 = simd.shuffle(v1, v1, 1, 2, 3, 0)
		v2 = simd.shuffle(v2, v2, 2, 3, 0, 1)
		v3 = simd.shuffle(v3, v3, 3, 0, 1, 2)

		// a += b; d ^= a; d = ROTW16(d);
		v0 = simd.add(v0, v1)
		v3 = simd.bit_xor(v3, v0)
		v3 = simd.bit_xor(simd.shl(v3, _ROT_16), simd.shr(v3, _ROT_16))

		// c += d; b ^= c; b = ROTW12(b);
		v2 = simd.add(v2, v3)
		v1 = simd.bit_xor(v1, v2)
		v1 = simd.bit_xor(simd.shl(v1, _ROT_12L), simd.shr(v1, _ROT_12R))

		// a += b; d ^= a; d = ROTW8(d);
		v0 = simd.add(v0, v1)
		v3 = simd.bit_xor(v3, v0)
		v3 = simd.bit_xor(simd.shl(v3, _ROT_8L), simd.shr(v3, _ROT_8R))

		// c += d; b ^= c; b = ROTW7(b);
		v2 = simd.add(v2, v3)
		v1 = simd.bit_xor(v1, v2)
		v1 = simd.bit_xor(simd.shl(v1, _ROT_7L), simd.shr(v1, _ROT_7R))

		// b = ROTV3(b); c = ROTV2(c); d = ROTV1(d);
		v1 = simd.shuffle(v1, v1, 3, 0, 1, 2)
		v2 = simd.shuffle(v2, v2, 2, 3, 0, 1)
		v3 = simd.shuffle(v3, v3, 1, 2, 3, 0)
	}

	dst_v := ([^]simd.u32x4)(raw_data(dst))
	intrinsics.unaligned_store((^simd.u32x4)(dst_v[0:]), v0)
	intrinsics.unaligned_store((^simd.u32x4)(dst_v[1:]), v3)
}