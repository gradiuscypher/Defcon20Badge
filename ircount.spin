CON
        _clkmode=xtal1+pll16x
        _xinfreq=5_000_000

OBJ
        irw: "sircs_tx"
		pin: "Input Output Pins"
		time: "Timing"

VAR
        long code
		long count
		long pinc

PUB main
	irw.start(13,40000)
	count := 0
	pinc := 16
	repeat
		if (count > 128)
			count := 0
		if (pinc > 16)
			pin.low(pinc-1)
		if (pinc > 23)
			pinc := 16

		pin.high(pinc)
		irw.tx(count,12,3)
		count := count + 1
		pinc := pinc + 1
		time.pause(500)
