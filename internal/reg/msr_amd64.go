// https://github.com/usbarmory/tamago
//
// Copyright (c) WithSecure Corporation
//
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

package reg

// defined in msr_amd64.s
func Msr(addr uint32) (val uint32)
