// x86-64 processor support
// https://github.com/usbarmory/tamago
//
// Copyright (c) WithSecure Corporation
//
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

#include "go_asm.h"
#include "textflag.h"

// Interrupt Descriptor Table
GLOBL	idt<>(SB),RODATA,$(const_vectors*16)

DATA	idtptr<>+0x00(SB)/2, $(const_vectors*16-1)	// IDT Limit
DATA	idtptr<>+0x02(SB)/8, $idt<>(SB)			// IDT Base Address
GLOBL	idtptr<>(SB),RODATA,$(2+8)

// func load_idt() (idt uintptr, irqHandler uintptr)
TEXT ·load_idt(SB),$0-16
	MOVQ	$idtptr<>(SB), AX
	LIDT (AX)

	MOVQ	$idt<>(SB), AX
	MOVQ	AX, ret+0(FP)

	// return irqHandler.abi0 pointer
	MOVQ	$·irqHandler(SB), AX
	MOVQ	AX, ret+8(FP)

	RET

// func irq_enable()
TEXT ·irq_enable(SB),$0
	STI
	RET

// func irq_disable()
TEXT ·irq_disable(SB),$0
	CLI
	RET

// func WaitForInterrupt()
TEXT ·WaitForInterrupt(SB),$0
	HLT
	RET

TEXT ·handleInterrupt(SB),NOSPLIT|NOFRAME,$0
	// save caller registers
	MOVQ	R15, r15-(14*8+8)(SP)
	MOVQ	R14, r14-(13*8+8)(SP)
	MOVQ	R13, r13-(12*8+8)(SP)
	MOVQ	R12, r12-(11*8+8)(SP)
	MOVQ	R11, r11-(10*8+8)(SP)
	MOVQ	R10, r10-(9*8+8)(SP)
	MOVQ	R9, r9-(8*8+8)(SP)
	MOVQ	R8, r8-(7*8+8)(SP)
	MOVQ	DI, di-(6*8+8)(SP)
	MOVQ	SI, si-(5*8+8)(SP)
	MOVQ	BP, bp-(4*8+8)(SP)
	MOVQ	BX, bx-(3*8+8)(SP)
	MOVQ	DX, dx-(2*8+8)(SP)
	MOVQ	CX, cx-(1*8+8)(SP)
	MOVQ	AX, ax-(0*8+8)(SP)

	// AMD64 Architecture Programmer’s Manual
	// Volume 2 - 8.9.3 Interrupt Stack Frame

	// find ISR offset from stack linking information (see irqHandler)
	MOVQ	isr-(0)(SP), AX
	SUBQ	$(const_callSize), AX
	MOVQ	AX, ·currentVector(SB)

	// the IRQ handling goroutine is expected to unmask IRQs
	MOVQ	rflags+(24)(SP), AX
	ANDL	$~(1<<9), AX		// clear RFLAGS.IF
	MOVQ	AX, rflags+(24)(SP)

	SUBQ	$(15*8+8), SP

	MOVQ	·irqHandlerG(SB), AX
	CMPQ	AX, $0
	JE	done
	CALL	runtime·WakeG(SB)
done:
	ADDQ	$(15*8+8), SP

	// restore caller registers
	MOVQ	ax-(0*8+8)(SP), AX
	MOVQ	cx-(1*8+8)(SP), CX
	MOVQ	dx-(2*8+8)(SP), DX
	MOVQ	bx-(3*8+8)(SP), BX
	MOVQ	bp-(4*8+8)(SP), BP
	MOVQ	si-(5*8+8)(SP), SI
	MOVQ	di-(6*8+8)(SP), DI
	MOVQ	r8-(7*8+8)(SP), R8
	MOVQ	r9-(8*8+8)(SP), R9
	MOVQ	r10-(9*8+8)(SP), R10
	MOVQ	r11-(10*8+8)(SP), R11
	MOVQ	r12-(11*8+8)(SP), R12
	MOVQ	r13-(12*8+8)(SP), R13
	MOVQ	r14-(13*8+8)(SP), R14
	MOVQ	r15-(14*8+8)(SP), R15

	ADDQ	$8, SP

	// return to caller
	IRETQ

TEXT ·handleException(SB),NOSPLIT|NOFRAME,$0
	CLI

	// find ISR offset from stack linking information (see irqHandler)
	MOVQ	isr-(0)(SP), AX
	SUBQ	$(const_callSize), AX
	MOVQ	AX, ·currentVector(SB)

	// TODO: implement runtime.CallOnG0 for a cleaner approach
	CALL	·DefaultExceptionHandler(SB)

// To allow a single user-defined ISR for all vectors, a jump table of CALLs,
// which save the vector PC on the stack, is built to use as IDT offsets.
TEXT ·irqHandler(SB),NOSPLIT|NOFRAME,$0
	// 0 to 31 - Exceptions
	CALL	·handleException(SB) //  0 - Divide by Zero
	CALL	·handleException(SB) //  1 - Debug
	CALL	·handleException(SB) //  2 - Reserved
	CALL	·handleException(SB) //  3 - Breakpoint
	CALL	·handleException(SB) //  4 - Overflow
	CALL	·handleException(SB) //  5 - Bound Range
	CALL	·handleInterrupt(SB) //  6 - Invalid Opcode
	CALL	·handleException(SB) //  7 - Device Not Available
	CALL	$0 // triple fault   //  8 - Double Fault
	CALL	·handleException(SB) //  9 - Reserved
	CALL	·handleException(SB) // 10 - Invalid TSS
	CALL	·handleException(SB) // 11 - Segment Not Present
	CALL	·handleException(SB) // 12 - Stack Fault
	CALL	·handleException(SB) // 13 - General Protection
	CALL	$0 // triple fault   // 14 - Page Fault
	CALL	·handleException(SB) // 15 - Reserved
	CALL	·handleException(SB) // 16 - x87 Floating Point
	CALL	·handleException(SB) // 17 - Alignment Check
	CALL	·handleException(SB) // 18 - Machine Check
	CALL	·handleException(SB) // 19 - SIMD Floating Point
	CALL	·handleException(SB) // 20 - Virtualization
	CALL	·handleException(SB) // 21 - Control Protection
	CALL	·handleException(SB) // 22 - Reserved
	CALL	·handleException(SB) // 23 - Reserved
	CALL	·handleException(SB) // 24 - Reserved
	CALL	·handleException(SB) // 25 - Reserved
	CALL	·handleException(SB) // 26 - Reserved
	CALL	·handleException(SB) // 27 - Reserved
	CALL	·handleException(SB) // 28 - Hypervisor Injection
	CALL	·handleException(SB) // 29 - VMM Communication
	CALL	·handleException(SB) // 30 - Security
	CALL	·handleException(SB) // 31 - Reserved

	// 32 to 255 - User Defined Interrupts
	CALL	·handleInterrupt(SB) // 32
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // ...
	CALL	·handleInterrupt(SB) // 255
