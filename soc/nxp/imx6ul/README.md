TamaGo - bare metal Go - i.MX 6UL support
=========================================

tamago | https://github.com/usbarmory/tamago  

Copyright (c) WithSecure Corporation  

![TamaGo gopher](https://github.com/usbarmory/tamago/wiki/images/tamago.svg?sanitize=true)

Authors
=======

Andrea Barisani  
andrea@inversepath.com  

Andrej Rosano  
andrej@inversepath.com  

Introduction
============

TamaGo is a framework that enables compilation and execution of unencumbered Go
applications on bare metal AMD64/ARM/RISC-V processors.

The [imx6ul](https://github.com/usbarmory/tamago/tree/master/soc/nxp/imx6ul)
package provides support for the NXP i.MX 6UL series of System-on-Chip (SoCs)
parts.

Documentation
=============

[![Go Reference](https://pkg.go.dev/badge/github.com/usbarmory/tamago.svg)](https://pkg.go.dev/github.com/usbarmory/tamago)

For TamaGo see its [repository](https://github.com/usbarmory/tamago) and
[project wiki](https://github.com/usbarmory/tamago/wiki) for information.

The package API documentation can be found on
[pkg.go.dev](https://pkg.go.dev/github.com/usbarmory/tamago).

Supported hardware
==================

| SoC                    | Related board packages                                                               | Peripheral drivers                                                                                                                                                                                                                                                                 |
|------------------------|--------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NXP i.MX 6ULZ/i.MX6UL  | [usbarmory/mk2](https://github.com/usbarmory/tamago/tree/master/board/usbarmory)     | [BEE, CAAM, CSU, DCP, ENET, GPIO, I2C, OCOTP, RNGB, TEMPMON, UART, USB, USDHC, WDOG](https://github.com/usbarmory/tamago/tree/master/soc/nxp), [GIC](https://github.com/usbarmory/tamago/tree/master/arm/gic), [TZASC](https://github.com/usbarmory/tamago/tree/master/arm/tzc380) |
| NXP i.MX 6ULL/i.MX6ULZ | [nxp/mx6ullevk](https://github.com/usbarmory/tamago/tree/master/board/nxp/mx6ullevk) | [BEE, CAAM, CSU, DCP, ENET, GPIO, I2C, OCOTP, RNGB, TEMPMON, UART, USB, USDHC, WDOG](https://github.com/usbarmory/tamago/tree/master/soc/nxp), [GIC](https://github.com/usbarmory/tamago/tree/master/arm/gic), [TZASC](https://github.com/usbarmory/tamago/tree/master/arm/tzc380) |

Build tags
==========

The following build tags allow application to override the package own definition of
[external functions required by the runtime](https://github.com/usbarmory/tamago/wiki/Internals#go-runtime-changes):

* `linkramstart`: exclude `ramStart` from `mem.go`
* `linkcpuinit`: exclude `cpuinit` imported from `arm/init.s`

License
=======

tamago | https://github.com/usbarmory/tamago  
Copyright (c) WithSecure Corporation

These source files are distributed under the BSD-style license found in the
[LICENSE](https://github.com/usbarmory/tamago/blob/master/LICENSE) file.

The TamaGo logo is adapted from the Go gopher designed by Renee French and
licensed under the Creative Commons 3.0 Attributions license. Go Gopher vector
illustration by Hugo Arganda.
