0000000080000110 <fmatmul>:
80000110: 7119         	addi	sp, sp, -0x80
80000112: fc86         	sd	ra, 0x78(sp)
80000114: f8a2         	sd	s0, 0x70(sp)
80000116: f4a6         	sd	s1, 0x68(sp)
80000118: f0ca         	sd	s2, 0x60(sp)
8000011a: ecce         	sd	s3, 0x58(sp)
8000011c: e8d2         	sd	s4, 0x50(sp)
8000011e: e4d6         	sd	s5, 0x48(sp)
80000120: e0da         	sd	s6, 0x40(sp)
80000122: fc5e         	sd	s7, 0x38(sp)
80000124: f862         	sd	s8, 0x30(sp)
80000126: f466         	sd	s9, 0x28(sp)
80000128: f06a         	sd	s10, 0x20(sp)
8000012a: ec6e         	sd	s11, 0x18(sp)
8000012c: 89be         	mv	s3, a5
8000012e: 8a3a         	mv	s4, a4
80000130: 8bb6         	mv	s7, a3
80000132: e832         	sd	a2, 0x10(sp)
80000134: e42e         	sd	a1, 0x8(sp)
80000136: 10000593     	li	a1, 0x100
8000013a: 8aaa         	mv	s5, a0
8000013c: 0af5e263     	bltu	a1, a5, 0x800001e0 <fmatmul+0xd0>
80000140: 0d89fcd7     	vsetvli	s9, s3, e64, m1, ta, ma
80000144: 10098f63     	beqz	s3, 0x80000262 <fmatmul+0x152>
80000148: 160b8463     	beqz	s7, 0x800002b0 <fmatmul+0x1a0>
8000014c: 4d01         	li	s10, 0x0
8000014e: 003c9513     	slli	a0, s9, 0x3
80000152: e02a         	sd	a0, 0x0(sp)
80000154: 00799913     	slli	s2, s3, 0x7
80000158: 007a1b13     	slli	s6, s4, 0x7
8000015c: 41a98533     	sub	a0, s3, s10
80000160: 01956363     	bltu	a0, s9, 0x80000166 <fmatmul+0x56>
80000164: 8566         	mv	a0, s9
80000166: 4d81         	li	s11, 0x0
80000168: 003d1c13     	slli	s8, s10, 0x3
8000016c: 65c2         	ld	a1, 0x10(sp)
8000016e: 9c2e         	add	s8, s8, a1
80000170: 0d857057     	vsetvli	zero, a0, e64, m1, ta, ma
80000174: 6422         	ld	s0, 0x8(sp)
80000176: 84d6         	mv	s1, s5
80000178: 5e003057     	vmv.v.i	v0, 0x0
8000017c: 5e0030d7     	vmv.v.i	v1, 0x0
80000180: 5e003157     	vmv.v.i	v2, 0x0
80000184: 5e0031d7     	vmv.v.i	v3, 0x0
80000188: 5e003257     	vmv.v.i	v4, 0x0
8000018c: 5e0032d7     	vmv.v.i	v5, 0x0
80000190: 5e003357     	vmv.v.i	v6, 0x0
80000194: 5e0033d7     	vmv.v.i	v7, 0x0
80000198: 5e003457     	vmv.v.i	v8, 0x0
8000019c: 5e0034d7     	vmv.v.i	v9, 0x0
800001a0: 5e003557     	vmv.v.i	v10, 0x0
800001a4: 5e0035d7     	vmv.v.i	v11, 0x0
800001a8: 5e003657     	vmv.v.i	v12, 0x0
800001ac: 5e0036d7     	vmv.v.i	v13, 0x0
800001b0: 5e003757     	vmv.v.i	v14, 0x0
800001b4: 5e0037d7     	vmv.v.i	v15, 0x0
800001b8: 8526         	mv	a0, s1
800001ba: 85a2         	mv	a1, s0
800001bc: 8662         	mv	a2, s8
800001be: 86d2         	mv	a3, s4
800001c0: 874e         	mv	a4, s3
800001c2: 00000097     	auipc	ra, 0x0
800001c6: 486080e7     	jalr	0x486(ra) <fmatmul_vec_16x16>
800001ca: 0dc1         	addi	s11, s11, 0x10
800001cc: 94ca         	add	s1, s1, s2
800001ce: 945a         	add	s0, s0, s6
800001d0: fb7de4e3     	bltu	s11, s7, 0x80000178 <fmatmul+0x68>
800001d4: 9d66         	add	s10, s10, s9
800001d6: 6502         	ld	a0, 0x0(sp)
800001d8: 9aaa         	add	s5, s5, a0
800001da: f93d61e3     	bltu	s10, s3, 0x8000015c <fmatmul+0x4c>
800001de: a051         	j	0x80000262 <fmatmul+0x152>
800001e0: 20000513     	li	a0, 0x200
800001e4: 09356e63     	bltu	a0, s3, 0x80000280 <fmatmul+0x170>
800001e8: 0d99fcd7     	vsetvli	s9, s3, e64, m2, ta, ma
800001ec: 0e0b8163     	beqz	s7, 0x800002ce <fmatmul+0x1be>
800001f0: 4901         	li	s2, 0x0
800001f2: 003c9513     	slli	a0, s9, 0x3
800001f6: e02a         	sd	a0, 0x0(sp)
800001f8: 00699d13     	slli	s10, s3, 0x6
800001fc: 006a1d93     	slli	s11, s4, 0x6
80000200: 41298533     	sub	a0, s3, s2
80000204: 01956363     	bltu	a0, s9, 0x8000020a <fmatmul+0xfa>
80000208: 8566         	mv	a0, s9
8000020a: 4b01         	li	s6, 0x0
8000020c: 00391c13     	slli	s8, s2, 0x3
80000210: 65c2         	ld	a1, 0x10(sp)
80000212: 9c2e         	add	s8, s8, a1
80000214: 0d957057     	vsetvli	zero, a0, e64, m2, ta, ma
80000218: 64a2         	ld	s1, 0x8(sp)
8000021a: 8456         	mv	s0, s5
8000021c: 5e003057     	vmv.v.i	v0, 0x0
80000220: 5e003157     	vmv.v.i	v2, 0x0
80000224: 5e003257     	vmv.v.i	v4, 0x0
80000228: 5e003357     	vmv.v.i	v6, 0x0
8000022c: 5e003457     	vmv.v.i	v8, 0x0
80000230: 5e003557     	vmv.v.i	v10, 0x0
80000234: 5e003657     	vmv.v.i	v12, 0x0
80000238: 5e003757     	vmv.v.i	v14, 0x0
8000023c: 8522         	mv	a0, s0
8000023e: 85a6         	mv	a1, s1
80000240: 8662         	mv	a2, s8
80000242: 86d2         	mv	a3, s4
80000244: 874e         	mv	a4, s3
80000246: 00000097     	auipc	ra, 0x0
8000024a: 2b8080e7     	jalr	0x2b8(ra) <fmatmul_vec_8x8>
8000024e: 0b21         	addi	s6, s6, 0x8
80000250: 946a         	add	s0, s0, s10
80000252: 94ee         	add	s1, s1, s11
80000254: fd7b64e3     	bltu	s6, s7, 0x8000021c <fmatmul+0x10c>
80000258: 9966         	add	s2, s2, s9
8000025a: 6502         	ld	a0, 0x0(sp)
8000025c: 9aaa         	add	s5, s5, a0
8000025e: fb3961e3     	bltu	s2, s3, 0x80000200 <fmatmul+0xf0>
80000262: 70e6         	ld	ra, 0x78(sp)
80000264: 7446         	ld	s0, 0x70(sp)
80000266: 74a6         	ld	s1, 0x68(sp)
80000268: 7906         	ld	s2, 0x60(sp)
8000026a: 69e6         	ld	s3, 0x58(sp)
8000026c: 6a46         	ld	s4, 0x50(sp)
8000026e: 6aa6         	ld	s5, 0x48(sp)
80000270: 6b06         	ld	s6, 0x40(sp)
80000272: 7be2         	ld	s7, 0x38(sp)
80000274: 7c42         	ld	s8, 0x30(sp)
80000276: 7ca2         	ld	s9, 0x28(sp)
80000278: 7d02         	ld	s10, 0x20(sp)
8000027a: 6de2         	ld	s11, 0x18(sp)
8000027c: 6109         	addi	sp, sp, 0x80
8000027e: 8082         	ret
80000280: 8556         	mv	a0, s5
80000282: 65a2         	ld	a1, 0x8(sp)
80000284: 6642         	ld	a2, 0x10(sp)
80000286: 86de         	mv	a3, s7
80000288: 8752         	mv	a4, s4
8000028a: 87ce         	mv	a5, s3
8000028c: 70e6         	ld	ra, 0x78(sp)
8000028e: 7446         	ld	s0, 0x70(sp)
80000290: 74a6         	ld	s1, 0x68(sp)
80000292: 7906         	ld	s2, 0x60(sp)
80000294: 69e6         	ld	s3, 0x58(sp)
80000296: 6a46         	ld	s4, 0x50(sp)
80000298: 6aa6         	ld	s5, 0x48(sp)
8000029a: 6b06         	ld	s6, 0x40(sp)
8000029c: 7be2         	ld	s7, 0x38(sp)
8000029e: 7c42         	ld	s8, 0x30(sp)
800002a0: 7ca2         	ld	s9, 0x28(sp)
800002a2: 7d02         	ld	s10, 0x20(sp)
800002a4: 6de2         	ld	s11, 0x18(sp)
800002a6: 6109         	addi	sp, sp, 0x80
800002a8: 00000317     	auipc	t1, 0x0
800002ac: 04430067     	jr	0x44(t1) <fmatmul_4x4>
800002b0: 4501         	li	a0, 0x0
800002b2: 85ce         	mv	a1, s3
800002b4: a801         	j	0x800002c4 <fmatmul+0x1b4>
800002b6: 0d867057     	vsetvli	zero, a2, e64, m1, ta, ma
800002ba: 9566         	add	a0, a0, s9
800002bc: 419585b3     	sub	a1, a1, s9
800002c0: fb3571e3     	bgeu	a0, s3, 0x80000262 <fmatmul+0x152>
800002c4: 862e         	mv	a2, a1
800002c6: ff95e8e3     	bltu	a1, s9, 0x800002b6 <fmatmul+0x1a6>
800002ca: 8666         	mv	a2, s9
800002cc: b7ed         	j	0x800002b6 <fmatmul+0x1a6>
800002ce: 4501         	li	a0, 0x0
800002d0: 85ce         	mv	a1, s3
800002d2: a801         	j	0x800002e2 <fmatmul+0x1d2>
800002d4: 0d967057     	vsetvli	zero, a2, e64, m2, ta, ma
800002d8: 9566         	add	a0, a0, s9
800002da: 419585b3     	sub	a1, a1, s9
800002de: f93572e3     	bgeu	a0, s3, 0x80000262 <fmatmul+0x152>
800002e2: 862e         	mv	a2, a1
800002e4: ff95e8e3     	bltu	a1, s9, 0x800002d4 <fmatmul+0x1c4>
800002e8: 8666         	mv	a2, s9
800002ea: b7ed         	j	0x800002d4 <fmatmul+0x1c4>

