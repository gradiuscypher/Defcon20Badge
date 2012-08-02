CON
	_clkmode=xtal1+pll16x
	_xinfreq= 5_000_000

OBJ
	pst: "Parallax Serial Terminal"

PUB TestTerm
	pst.start(115200)

	repeat
			pst.str(string("TEST"))
