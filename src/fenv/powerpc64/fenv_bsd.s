.global feenableexcept
.type feenableexcept, @function
feenableexcept:
	mffs f0
	stfd f0, -8(r1)
	lfd f1, -8(r1)
	mftcr r3, f1
	srwi r4, r3, 22
	not r4
	andi r4, r4, 0x3f000000
	andi. r5, r3, ~((0x3f000000))
	mtfsf 0xff, f0
	mr r3, r4
	blr

.global fedisableexcept
.type fedisableexcept, @function
fedisableexcept:
	mffs f0
	stfd f0, -8(r1)
	lfd f1, -8(r1)
	mftcr r3, f1
	srwi r4, r3, 22
	not r4
	andi r4, r4, 0x3f000000
	ori r3, r3, 0x3f000000
	mtfsf 0xff, f0
	mr r3, r4
	blr

.global fegetexcept
.type fegetexcept, @function
fegetexcept:
	mffs f0
	stfd f0, -8(r1)
	lfd f1, -8(r1)
	mftcr r3, f1
	srwi r3, r3, 22
	not r3
	andi r3, r3, 0x3f000000
	blr
