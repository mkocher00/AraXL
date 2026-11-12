0000000080000648 <fmatmul_vec_16x16>:
80000648: 7139         	addi	sp, sp, -0x40
8000064a: fc22         	sd	s0, 0x38(sp)
8000064c: f826         	sd	s1, 0x30(sp)
8000064e: f44a         	sd	s2, 0x28(sp)
80000650: f04e         	sd	s3, 0x20(sp)
80000652: ec52         	sd	s4, 0x18(sp)
80000654: e856         	sd	s5, 0x10(sp)
80000656: e45a         	sd	s6, 0x8(sp)
80000658: e05e         	sd	s7, 0x0(sp)
8000065a: 00369293     	slli	t0, a3, 0x3
8000065e: 005584b3     	add	s1, a1, t0
80000662: 005487b3     	add	a5, s1, t0
80000666: 00578433     	add	s0, a5, t0
8000066a: 0005b887     	fld	fa7, 0x0(a1)
8000066e: 0004b807     	fld	fa6, 0x0(s1)
80000672: 0007b387     	fld	ft7, 0x0(a5)
80000676: 00043287     	fld	ft5, 0x0(s0)
8000067a: 9416         	add	s0, s0, t0
8000067c: 005407b3     	add	a5, s0, t0
80000680: 005784b3     	add	s1, a5, t0
80000684: 00043307     	fld	ft6, 0x0(s0)
80000688: 0007b207     	fld	ft4, 0x0(a5)
8000068c: 0004b187     	fld	ft3, 0x0(s1)
80000690: 9496         	add	s1, s1, t0
80000692: 0004b107     	fld	ft2, 0x0(s1)
80000696: 9496         	add	s1, s1, t0
80000698: 0004b087     	fld	ft1, 0x0(s1)
8000069c: 9496         	add	s1, s1, t0
8000069e: 0004b007     	fld	ft0, 0x0(s1)
800006a2: 9496         	add	s1, s1, t0
800006a4: 2088         	fld	fa0, 0x0(s1)
800006a6: 9496         	add	s1, s1, t0
800006a8: 208c         	fld	fa1, 0x0(s1)
800006aa: 9496         	add	s1, s1, t0
800006ac: 2090         	fld	fa2, 0x0(s1)
800006ae: 9496         	add	s1, s1, t0
800006b0: 2094         	fld	fa3, 0x0(s1)
800006b2: 9496         	add	s1, s1, t0
800006b4: 2098         	fld	fa4, 0x0(s1)
800006b6: 9496         	add	s1, s1, t0
800006b8: 209c         	fld	fa5, 0x0(s1)
800006ba: 02067807     	vle64.v	v16, (a2)
800006be: 00371813     	slli	a6, a4, 0x3
800006c2: 16068663     	beqz	a3, 0x8000082e <fmatmul_vec_16x16+0x1e6>
800006c6: ffe68893     	addi	a7, a3, -0x2
800006ca: 01058e93     	addi	t4, a1, 0x10
800006ce: 01060e33     	add	t3, a2, a6
800006d2: 00471313     	slli	t1, a4, 0x4
800006d6: 006603b3     	add	t2, a2, t1
800006da: ff8e8793     	addi	a5, t4, -0x8
800006de: b308d057     	vfmacc.vf	v0, fa7, v16
800006e2: ff8eb887     	fld	fa7, -0x8(t4)
800006e6: 020e7887     	vle64.v	v17, (t3)
800006ea: b30850d7     	vfmacc.vf	v1, fa6, v16
800006ee: 9796         	add	a5, a5, t0
800006f0: 0007b807     	fld	fa6, 0x0(a5)
800006f4: b303d157     	vfmacc.vf	v2, ft7, v16
800006f8: 00578733     	add	a4, a5, t0
800006fc: 00073387     	fld	ft7, 0x0(a4)
80000700: b302d1d7     	vfmacc.vf	v3, ft5, v16
80000704: 00570633     	add	a2, a4, t0
80000708: 00063287     	fld	ft5, 0x0(a2)
8000070c: b3035257     	vfmacc.vf	v4, ft6, v16
80000710: 005606b3     	add	a3, a2, t0
80000714: 0006b307     	fld	ft6, 0x0(a3)
80000718: b30252d7     	vfmacc.vf	v5, ft4, v16
8000071c: 005685b3     	add	a1, a3, t0
80000720: 0005b207     	fld	ft4, 0x0(a1)
80000724: b301d357     	vfmacc.vf	v6, ft3, v16
80000728: 00558f33     	add	t5, a1, t0
8000072c: 000f3187     	fld	ft3, 0x0(t5)
80000730: b30153d7     	vfmacc.vf	v7, ft2, v16
80000734: 005f0fb3     	add	t6, t5, t0
80000738: 000fb107     	fld	ft2, 0x0(t6)
8000073c: b300d457     	vfmacc.vf	v8, ft1, v16
80000740: 005f8433     	add	s0, t6, t0
80000744: 00043087     	fld	ft1, 0x0(s0)
80000748: b30054d7     	vfmacc.vf	v9, ft0, v16
8000074c: 005404b3     	add	s1, s0, t0
80000750: 0004b007     	fld	ft0, 0x0(s1)
80000754: b3055557     	vfmacc.vf	v10, fa0, v16
80000758: 00548933     	add	s2, s1, t0
8000075c: 00093507     	fld	fa0, 0x0(s2)
80000760: b305d5d7     	vfmacc.vf	v11, fa1, v16
80000764: 005909b3     	add	s3, s2, t0
80000768: 0009b587     	fld	fa1, 0x0(s3)
8000076c: b3065657     	vfmacc.vf	v12, fa2, v16
80000770: 00598a33     	add	s4, s3, t0
80000774: 000a3607     	fld	fa2, 0x0(s4)
80000778: b306d6d7     	vfmacc.vf	v13, fa3, v16
8000077c: 005a0ab3     	add	s5, s4, t0
80000780: 000ab687     	fld	fa3, 0x0(s5)
80000784: b3075757     	vfmacc.vf	v14, fa4, v16
80000788: 005a8b33     	add	s6, s5, t0
8000078c: 000b3707     	fld	fa4, 0x0(s6)
80000790: b307d7d7     	vfmacc.vf	v15, fa5, v16
80000794: 005b0bb3     	add	s7, s6, t0
80000798: 000bb787     	fld	fa5, 0x0(s7)
8000079c: 08088963     	beqz	a7, 0x8000082e <fmatmul_vec_16x16+0x1e6>
800007a0: b318d057     	vfmacc.vf	v0, fa7, v17
800007a4: 000eb887     	fld	fa7, 0x0(t4)
800007a8: 0203f807     	vle64.v	v16, (t2)
800007ac: b31850d7     	vfmacc.vf	v1, fa6, v17
800007b0: 0087b807     	fld	fa6, 0x8(a5)
800007b4: b313d157     	vfmacc.vf	v2, ft7, v17
800007b8: 00873387     	fld	ft7, 0x8(a4)
800007bc: b312d1d7     	vfmacc.vf	v3, ft5, v17
800007c0: 00863287     	fld	ft5, 0x8(a2)
800007c4: b3135257     	vfmacc.vf	v4, ft6, v17
800007c8: 0086b307     	fld	ft6, 0x8(a3)
800007cc: b31252d7     	vfmacc.vf	v5, ft4, v17
800007d0: 0085b207     	fld	ft4, 0x8(a1)
800007d4: b311d357     	vfmacc.vf	v6, ft3, v17
800007d8: 008f3187     	fld	ft3, 0x8(t5)
800007dc: b31153d7     	vfmacc.vf	v7, ft2, v17
800007e0: 008fb107     	fld	ft2, 0x8(t6)
800007e4: b310d457     	vfmacc.vf	v8, ft1, v17
800007e8: 00843087     	fld	ft1, 0x8(s0)
800007ec: b31054d7     	vfmacc.vf	v9, ft0, v17
800007f0: 0084b007     	fld	ft0, 0x8(s1)
800007f4: b3155557     	vfmacc.vf	v10, fa0, v17
800007f8: 00893507     	fld	fa0, 0x8(s2)
800007fc: b315d5d7     	vfmacc.vf	v11, fa1, v17
80000800: 0089b587     	fld	fa1, 0x8(s3)
80000804: b3165657     	vfmacc.vf	v12, fa2, v17
80000808: 008a3607     	fld	fa2, 0x8(s4)
8000080c: b316d6d7     	vfmacc.vf	v13, fa3, v17
80000810: 008ab687     	fld	fa3, 0x8(s5)
80000814: b3175757     	vfmacc.vf	v14, fa4, v17
80000818: 008b3707     	fld	fa4, 0x8(s6)
8000081c: b317d7d7     	vfmacc.vf	v15, fa5, v17
80000820: 008bb787     	fld	fa5, 0x8(s7)
80000824: 18f9         	addi	a7, a7, -0x2
80000826: 0ec1         	addi	t4, t4, 0x10
80000828: 9e1a         	add	t3, t3, t1
8000082a: 939a         	add	t2, t2, t1
8000082c: b57d         	j	0x800006da <fmatmul_vec_16x16+0x92>
8000082e: b318d057     	vfmacc.vf	v0, fa7, v17
80000832: 02057027     	vse64.v	v0, (a0)
80000836: 9542         	add	a0, a0, a6
80000838: b31850d7     	vfmacc.vf	v1, fa6, v17
8000083c: 020570a7     	vse64.v	v1, (a0)
80000840: 9542         	add	a0, a0, a6
80000842: b313d157     	vfmacc.vf	v2, ft7, v17
80000846: 02057127     	vse64.v	v2, (a0)
8000084a: 9542         	add	a0, a0, a6
8000084c: b312d1d7     	vfmacc.vf	v3, ft5, v17
80000850: 020571a7     	vse64.v	v3, (a0)
80000854: 9542         	add	a0, a0, a6
80000856: b3135257     	vfmacc.vf	v4, ft6, v17
8000085a: 02057227     	vse64.v	v4, (a0)
8000085e: 9542         	add	a0, a0, a6
80000860: b31252d7     	vfmacc.vf	v5, ft4, v17
80000864: 020572a7     	vse64.v	v5, (a0)
80000868: 9542         	add	a0, a0, a6
8000086a: b311d357     	vfmacc.vf	v6, ft3, v17
8000086e: 02057327     	vse64.v	v6, (a0)
80000872: 9542         	add	a0, a0, a6
80000874: b31153d7     	vfmacc.vf	v7, ft2, v17
80000878: 020573a7     	vse64.v	v7, (a0)
8000087c: 9542         	add	a0, a0, a6
8000087e: b310d457     	vfmacc.vf	v8, ft1, v17
80000882: 02057427     	vse64.v	v8, (a0)
80000886: 9542         	add	a0, a0, a6
80000888: b31054d7     	vfmacc.vf	v9, ft0, v17
8000088c: 020574a7     	vse64.v	v9, (a0)
80000890: 9542         	add	a0, a0, a6
80000892: b3155557     	vfmacc.vf	v10, fa0, v17
80000896: 02057527     	vse64.v	v10, (a0)
8000089a: 9542         	add	a0, a0, a6
8000089c: b315d5d7     	vfmacc.vf	v11, fa1, v17
800008a0: 020575a7     	vse64.v	v11, (a0)
800008a4: 9542         	add	a0, a0, a6
800008a6: b3165657     	vfmacc.vf	v12, fa2, v17
800008aa: 02057627     	vse64.v	v12, (a0)
800008ae: 9542         	add	a0, a0, a6
800008b0: b316d6d7     	vfmacc.vf	v13, fa3, v17
800008b4: 020576a7     	vse64.v	v13, (a0)
800008b8: 9542         	add	a0, a0, a6
800008ba: b3175757     	vfmacc.vf	v14, fa4, v17
800008be: 02057727     	vse64.v	v14, (a0)
800008c2: 9542         	add	a0, a0, a6
800008c4: b317d7d7     	vfmacc.vf	v15, fa5, v17
800008c8: 020577a7     	vse64.v	v15, (a0)
800008cc: 7462         	ld	s0, 0x38(sp)
800008ce: 74c2         	ld	s1, 0x30(sp)
800008d0: 7922         	ld	s2, 0x28(sp)
800008d2: 7982         	ld	s3, 0x20(sp)
800008d4: 6a62         	ld	s4, 0x18(sp)
800008d6: 6ac2         	ld	s5, 0x10(sp)
800008d8: 6b22         	ld	s6, 0x8(sp)
800008da: 6b82         	ld	s7, 0x0(sp)
800008dc: 6121         	addi	sp, sp, 0x40
800008de: 8082         	ret

