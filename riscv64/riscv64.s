// RISC-V processor support
// https://github.com/usbarmory/tamago
//
// Copyright (c) WithSecure Corporation
//
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

// func exit(int32)
TEXT ·exit(SB),$0-8
	// wait forever in low-power state
	WORD $0x10500073 // wfi
