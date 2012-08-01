'' =================================================================================================
''
''   File....... sircs_rx.spin
''   Purpose.... SIRCS receiver
''   Author..... Jon "JonnyMac" McPhalen
''               Terms of Use: MIT License
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 27 APR 2009
''   Updated.... 04 JUL 2012
''
'' =================================================================================================    
var

  long  cog                                                     ' cog id

  long  ircode                                                  ' rx'd code
  long  irbits                                                  ' bits in code
  long  irframe                                                 ' pin used


pub start(pin)

'' Setup IR input on pin p

  stop

  if ((pin => 0) and (pin =< 27))                               ' protect rx, tx, i2c

    ' pass pin and timing to SIRCS cog

    ircode  := pin
    irbits  := (clkfreq / 1_000_000) * 2_160                    ' 90% of 2.4ms
    irframe := (clkfreq / 10_000) * 445                         ' ticks in 44.5ms (1 frame)  

    cog := cognew(@rxsircs, @ircode) + 1                        ' start cog
    if (cog)                                                    ' if successful
      waitcnt(cnt + (clkfreq >> 10))                            '  wait about 1ms
      enable                                                    '  enable device rx

  return cog
  

pub stop

'' Stops SIRCS cog if running

  if (cog)                                                      ' if running
    cogstop(cog - 1)                                            ' stop, unload cog
    cog := 0                                                    ' mark as free


pub enable

'' Enables IR receive process

  longfill(@ircode, 0, 2)


pub disable

'' Disable IR receive process

  longfill(@ircode, -1, 2)  

    
pub rx

'' Enables and waits for ir input
'' -- warning: blocks until IR code received!
'' -- does not remove code/bits from buffer

  enable                                                        ' allow ir rx
  repeat until (irbits > 0)                                     ' wait for code

  return ircode 


pub rxcheck

'' Returns code if available, -1 if none
'' -- must have previously been enabled
'' -- does not remove code/bits from buffer

  if (irbits > 0)                                               ' if code ready
    return ircode
  else
    return -1  


pub bit_count

'' Returns bit count of last ir code
'' -- check status before using
'' -- if 0, no code is available or disabled

  if (irbits => 0)
    return irbits
  else
    return 0
  

dat

                        org     0

rxsircs                 mov     t1, par                         ' get address of parameters
                        rdlong  t2, t1                          ' get IR pin
                        mov     rxmask, #1                      ' convert to mask
                        shl     rxmask, t2

                        add     t1, #4
                        rdlong  starttix, t1                    ' get ticks in start bit
                        
                        mov     bittix, starttix                ' copy
                        shr     bittix, #1                      ' "1" bit is 1/2 start bit
                        
                        add     t1, #4
                        rdlong  frametix, t1                    ' get ticks in SIRCS frame (~45ms)
                        
                        movi    ctra, FREE_RUN                  ' ctra used for bit timing
                        mov     frqa, #1

                        movi    ctrb, FREE_RUN                  ' ctrb used for frame timing
                        mov     frqb, #1  

waitok                  mov     t1, par
                        add     t1, #4                          ' point to irbits (flag)
                        rdlong  t2, t1                  wz      ' read
        if_nz           jmp     #waitok                         ' wait for 0 (enabled)

waitstart               waitpeq rxmask, rxmask                  ' wait for high
                        nop
                        waitpne rxmask, rxmask                  ' wait for low
                        mov     phsa, #0                        ' start bit timer
                        mov     phsb, #0                        ' start frame timer
                        waitpeq rxmask, rxmask                  ' wait for high
                        cmp     starttix, phsa          wc, wz  ' valid start bit?
        if_a            jmp     #waitstart                      ' try again if no

rxsetup                 mov     incode, #0                      ' clear workspace
                        mov     inbits, #0                      ' reset bit count

checkframe              cmp     frametix, phsb          wc, wz  ' check frame timer
        if_be           jmp     #irdone                         ' abort @44.5ms

waitbit                 test    rxmask, ina             wz      ' look for new bit
        if_nz           jmp     #checkframe                     ' check for end if no bit
        
measurebit              mov     phsa, #0                        ' resstart bit timer
                        waitpeq rxmask, rxmask                  ' wait for high (end of bit)
                        cmp     starttix, phsa          wc      ' check for restart
        if_c            mov     phsb, starttix                  ' if yes, reset frame timing
        if_c            jmp     #rxsetup                        '  and start over 
                        cmp     bittix, phsa            wc      ' ir bit --> C
                        rcr     incode, #1                      ' C --> incode.31
                
                        add     inbits, #1                      ' inc bit count
                        cmp     inbits, #20             wc      ' at max?
        if_b            jmp     #checkframe                     ' keep scanning if no
                        
irdone                  mov     t1, #32
                        sub     t1, inbits
                        shr     incode, t1                      ' right align ir code  

report                  mov     t1, par                         ' point to parameters
                        rdlong  t2, t1                          ' look for disable
                        cmps    t2, #0                  wc, wz  ' 
        if_b            jmp     #waitok

                        wrlong  incode, t1                      ' write the code
                        add     t1, #4
                        wrlong  inbits, t1                      ' write bit count
                        
                        jmp     #waitok
                        
' -------------------------------------------------------------------------------------------------

FREE_RUN                long    %11111_000                      ' free run (for movi)

rxmask                  res     1                               ' mask for rx pin
starttix                res     1                               ' ticks in start bit
bittix                  res     1                               ' ticks in "1" bit
frametix                res     1                               ' ticks in SIRCS frame

incode                  res     1                               ' workspace for ir input
inbits                  res     1                               ' # bits in rx'd code

t1                      res     1                               ' work vars
t2                      res     1
                        
                        fit     496


dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}              