package main

import "core:intrinsics"
import "core:simd"

_rotw16 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.bit_xor(simd.shl(v, _ROT_16), simd.shr(v, _ROT_16))
}
_rotw12 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.bit_xor(simd.shl(v, _ROT_12L), simd.shr(v, _ROT_12R))
}
_rotw8 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.bit_xor(simd.shl(v, _ROT_8L), simd.shr(v, _ROT_8R))
}
_rotw7 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.bit_xor(simd.shl(v, _ROT_7L), simd.shr(v, _ROT_7R))
}
_rotv1 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.shuffle(v, v, 1, 2, 3, 0)
}
_rotv2 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.shuffle(v, v, 2, 3, 0, 1)
}
_rotv3 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
	return simd.shuffle(v, v, 3, 0, 1, 2)
}

_dqround :: #force_inline proc "contextless" (a, b, c, d: simd.u32x4) -> (simd.u32x4, simd.u32x4, simd.u32x4, simd.u32x4) {
	a, b, c, d := a, b, c, d

	// a += b; d ^= a; d = ROTW16(d);
	a = simd.add(a, b)
	d = simd.bit_xor(d, a)
	d = _rotw16(d)

	// c += d; b ^= c; b = ROTW12(b);
	c = simd.add(c, d)
	b = simd.bit_xor(b, c)
	b = _rotw12(b)

	// a += b; d ^= a; d = ROTW8(d);
	a = simd.add(a, b)
	d = simd.bit_xor(d, a)
	d = _rotw8(d)

	// c += d; b ^= c; b = ROTW7(b);
	c = simd.add(c, d)
	b = simd.bit_xor(b, c)
	b = _rotw7(b)

	// b = ROTV1(b); c = ROTV2(c);  d = ROTV3(d);
	b = _rotv1(b)
	c = _rotv2(c)
	d = _rotv3(d)

	// a += b; d ^= a; d = ROTW16(d);
	a = simd.add(a, b)
	d = simd.bit_xor(d, a)
	d = _rotw16(d)

	// c += d; b ^= c; b = ROTW12(b);
	c = simd.add(c, d)
	b = simd.bit_xor(b, c)
	b = _rotw12(b)

	// a += b; d ^= a; d = ROTW8(d);
	a = simd.add(a, b)
	d = simd.bit_xor(d, a)
	d = _rotw8(d)

	// c += d; b ^= c; b = ROTW7(b);
	c = simd.add(c, d)
	b = simd.bit_xor(b, c)
	b = _rotw7(b)

	// b = ROTV3(b); c = ROTV2(c); d = ROTV1(d);
	b = _rotv3(b)
	c = _rotv2(c)
	d = _rotv1(d)

	return a, b, c, d
}

hchacha20 :: proc "contextless" (dst, key, nonce: []byte) {
	v0 := simd.u32x4{_SIGMA_0, _SIGMA_1, _SIGMA_2, _SIGMA_3}
	v1 := intrinsics.unaligned_load(transmute(^simd.u32x4)&key[0])
	v2 := intrinsics.unaligned_load(transmute(^simd.u32x4)&key[16])
	v3 := intrinsics.unaligned_load(transmute(^simd.u32x4)&nonce[0])

	for i := _ROUNDS; i > 0; i = i - 2 {
		v0, v1, v2, v3 = _dqround(v0, v1, v2, v3)
	}

	dst_v := ([^]simd.u32x4)(raw_data(dst))
	intrinsics.unaligned_store((^simd.u32x4)(dst_v[0:]), v0)
	intrinsics.unaligned_store((^simd.u32x4)(dst_v[1:]), v3)
}