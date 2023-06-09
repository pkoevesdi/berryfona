class fona_driver : Driver
  var f, keyword, timeout, statusfield
  def init(fona_inst, keyword, timeout, statusfield)
    self.f = fona_inst
    self.keyword = keyword
    self.timeout = tasmota.millis(timeout)
    self.statusfield = statusfield
  end

  def every_second()
    if tasmota.millis() < self.timeout 
      var res=self.f.readline(500,true)
      if res
        import string
        for i: res
          if string.count(i, self.keyword)
            tasmota.remove_driver(self)
            self.f.status[self.statusfield] = true
            self.f.status["failed"] = false
            print(i)
          end
        end
      end
    else
      tasmota.remove_driver(self)
      self.f.status[self.statusfield] = true
      self.f.status["failed"] = true
      print("waiting for '" + self.keyword + "' failed")
    end
  end
end

class fona

  var ser, debug, fd, status

  def init()
    self.status = {"ready": false}
    self.debug = false
    self.DEBUG_PRINT("Configured pins: ")
    self.DEBUG_PRINT("LED:",gpio.pin(gpio.LED1))
    self.DEBUG_PRINT("Power SIM module:",gpio.pin(gpio.REL1))
    self.DEBUG_PRINT("PWR_KEY SIM module:",gpio.pin(gpio.REL1,1))
    self.DEBUG_PRINT("RX:",gpio.pin(gpio.SBR_RX))
    self.DEBUG_PRINT("TX:",gpio.pin(gpio.SBR_TX))
    # tasmota.set_power(0, true)
    gpio.digital_write(gpio.pin(gpio.REL1), gpio.HIGH)
    self.ser = serial(gpio.pin(gpio.SBR_RX), gpio.pin(gpio.SBR_TX), 115200)
    self.fd = fona_driver(self, "SMS Ready", 20000, "ready")
    tasmota.add_driver(self.fd)
    print("Starting fona...")
  end

  def deinit()
    #gpio.digital_write(gpio.pin(gpio.REL1), gpio.LOW)
    # tasmota.set_power(0, false)
    print("fona deinited!")
  end

  def sendSMS(smsaddr, smsmsg)
    if !self.status["ready"]
      self.DEBUG_PRINT("fona busy, setting timer so send later...")
      tasmota.set_timer(1000,/->self.sendSMS(smsaddr, smsmsg))
      return false
    end
    print("Sending SMS to " + smsaddr + " ...")
    self.status["ready"] = false
    var sendcmd = 'AT+CMGS="'+smsaddr+'"'

    if !self.sendCheckReply(sendcmd, "> ")
      self.status["ready"] = true
      return false 
    end

    self.ser.write(bytes().fromstring(smsmsg))
    self.DEBUG_PRINT(smsmsg)
    self.ser.write(0x1A)
    self.DEBUG_PRINT("^z");

    self.fd = fona_driver(self, "OK", 30000, "ready")
    tasmota.add_driver(self.fd)
    return true
  end

  def sendCheckReply(send, reply, timeout) 
    var replybuffer = self.getReply(send, timeout)
    if (!replybuffer)
      return false;
    end
    return replybuffer == reply;
  end

  def getReply(send, timeout)
    self.DEBUG_PRINT("\t---> " + send)
    self.ser.write(bytes().fromstring(send+"\r\n"))
    var replybuffer = self.readline(timeout)
    
#    if replybuffer
      self.DEBUG_PRINT("\t<--- "+replybuffer)
#    end

    return replybuffer;
  end

  def readline(timeout, multiline, replybuffer)
    timeout = timeout ? timeout : 50000
    multiline = multiline ? multiline : false
    replybuffer = replybuffer ? replybuffer : ""
    while timeout
      timeout-=1
      while self.ser.available()
        replybuffer += self.ser.read().asstring()
      end
      import string
      var res = string.split(replybuffer, "\r\n") 
      # delete newlines:
      var i=0
      while i<res.size()
        if res[i]
          i+=1
        else 
          res.remove(i)
        end
      end
      if res.size()>0
        return multiline ? res : res[0]
      #else
      #  return multiline ? [] : ""
      end
    end
    return
  end


  def DEBUG_PRINT(string)
    if self.debug
      print(string)
    end
  end
  def DEBUG_PRINTLN(string)
    if self.debug
      print(string)
    end
  end
end

f=fona()