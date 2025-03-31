// Intel Peripheral Component Interconnect (PCI) driver
// https://github.com/usbarmory/tamago
//
// Copyright (c) WithSecure Corporation
//
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

// Package pci implements a driver for Intel Peripheral Component Interconnect
// (PCI) controllers adopting the following reference
// specifications:
//   - PCI Local Bus Specification, revision 3.0, PCI Special Interest Group
//
// This package is only meant to be used with `GOOS=tamago` as
// supported by the TamaGo framework for bare metal Go, see
// https://github.com/usbarmory/tamago.
package pci

import (
	"github.com/usbarmory/tamago/internal/reg"
)

const (
	CONFIG_ADDRESS = 0x0cf8
	CONFIG_DATA    = 0x0cfc
)

const (
	maxBuses   = 256
	maxDevices = 32
)

// Device represents a PCI device.
type Device struct {
	// Bus number
	Bus uint32
	// Vendor ID
	Vendor uint16
	// Device ID
	Device uint16

	// PCI Slot
	Slot uint32
	// Base Address #0 (BAR0)
	BaseAddress0 uint32
}

func (d *Device) read(bus uint32, slot uint32, fn uint32, offset uint32) uint32 {
	address := (bus << 16) | (slot << 11) | (fn << 8) | (offset & 0xfc) | 0x80000000

	reg.Out32(CONFIG_ADDRESS, address)
	return reg.In32(CONFIG_DATA) >> ((offset & 2) * 8)
}

func (d *Device) probe() bool {
	if d.Bus > maxBuses {
		return false
	}

	val := d.read(d.Bus, d.Slot, 0, 0)

	if d.Vendor = uint16(val); d.Vendor == 0xffff {
		return false
	}

	d.Device = uint16(val >> 16)
	d.BaseAddress0 = d.read(d.Bus, d.Slot, 0, 0x10)
	d.BaseAddress0 &= 0xfffffffc

	return true
}

// Probe probes a PCI device.
func Probe(bus int, vendor uint16, device uint16) *Device {
	d := &Device{
		Bus: uint32(bus),
	}

	for slot := uint32(0); slot < maxDevices; slot++ {
		d.Slot = slot

		if d.probe() {
			return d
		}
	}

	return nil
}

// Devices returns all found PCI devices on a given bus.
func Devices(bus int) (devices []*Device) {
	for slot := uint32(0); slot < maxDevices; slot++ {
		d := &Device{
			Bus:  uint32(bus),
			Slot: slot,
		}

		if d.probe() {
			devices = append(devices, d)
		}
	}

	return
}
