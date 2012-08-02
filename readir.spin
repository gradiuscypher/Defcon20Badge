CON
        _clkmode=xtal1+pll16x
        _xinfreq=5_000_000

OBJ
        pst: "Parallax Serial Terminal"
        irr: "sircs_rx"

VAR
        long code

PUB main
        pst.Start(115200)
        irr.start(12)
        repeat
                code := irr.rx
                pst.bin(code,irr.bit_count)
                pst.str(string(":"))
                pst.dec(irr.bit_count)
                pst.str(string(" ",13))               