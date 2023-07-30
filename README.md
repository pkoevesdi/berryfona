# berryfona
GSM library for berry script

This is a library, inspired by Arduino FONA, to send AT commands to an GSM module. Tested on Liligo T-Call 1.4 (ESP32 with SIM800L) with tasmota.

## Status
First working draft. No further development planned from my side, but pull requests are welcome. Please share, what You've improved and extended.

## Installation on tasmota
1. Copy the file `fona.be` to your tasmota instance via webgui ("Console" -> "Manage File System").
1. In the template of tasmota set "SerBr RX" and "SerBr TX" to the RX and TX GPIO connected to the TX and RX of the GSM module (Liligo T-Call: 26, 27).
1. Set "Relay 1" to the power pin of the GSM module (Liligo T-Call: 23)
1. Set "Relay 2" to the reset pin of the GSM module (Liligo T-Call: 4) - unused at the moment
1. Set "Led 1" to the LED in case You have one (Liligo T-Call: 13) - unused at the moment
1. Set `self.debug` in `fone.be` to `true` if wanted.
1. If You want to start fona on system start, execute `Rule1 ON System#Boot DO br load('fona') ENDON` and `Rule1 1` on the tasmota (not berry) console.

## Starting
1. If not started on system start (see last point in installation), go to the berry console and execute `load("fona")`.
1. Instantiate by executing `f = fona()`
1. execute commands like `f.getReply("AT")` - see source code for more commands

## For SIM800L, maybe others
The module is ready to send SMS when it has sent the URC (Unsolicited Result Code) "SMS Ready". To enable us to receive the first URCs after booting, the auto baud feature must be disabled, i.e. the baud rate must be set to a fixed value. Send the following commands to the module:  
`AT+IPR=115200` # set baud rate fixed  
`AT&W` # save this setting to survive boot  
You can use `f.getReply("AT+IPR=115200")` and `f.getReply("AT&W")` for that.  
Also set `AT+CMGF=1` to set text mode for SMS. 

## Sending SMS
Execute `f.sendSMS(<number>,<text>)` on the berry console. If You execute this a second time before the first SMS got sent out, the library will wait with the second SMS 1 second and retry. So, You can trigger more than one SMS at a time, it should work.
