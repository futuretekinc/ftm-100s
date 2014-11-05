## Generic - configuration and logging
----------------------

  * [device protocol](docs/deviceProtocol.md)
  * [device configuration](docs/config.md)
  * [device logging](docs/logging.md)


# Getting started
----------------------

## Gateway initial setup
![Thingworks gateway](docs/image/thingworks.jpg "Thingworks gateway")

### preparing micro SD card with prebuilt image.
[Download Thing+ Gateway image here 20140725](https://www.dropbox.com/s/j4vzm3izs9juz9f/bbb_tp_20140725_2.img.zip)

### initial use
 * BBB side
   * power on BBB: micro sd card, ethernet, and power are connected.
     * before turning on the board, you need to insert the sd card and connect the board by ethernet.
   * wait until all 4 leds stop blinking and remain solid. It will take around 10 min.
   * turn off BBB
   * remove micro sd card
   * turn on BBB (ready to sensor setup)
 * PC side
   * browsing http://[BBB’s IP address]
     * ID / PW -> admin / admin123
     * Settings->'Software Control'->'Gateway Update' button (when you can access normally http://[BBB’s IP address])
       * getting the latest gateway S/W version

## Thing+ service how to
  * Open https://thingplus.net
  * (User Registration then) Login as {your id}

## gateway registration to server
  * (Your login id should be [service, system, site] admin)
  * Go to Gateway Management menu then select New (or +)
  * Input 'Gateway ID' which is Mac-address of gateway to register and 'Gateway Name'
    Select 'Site Code'
  * Click 'Register Gateway & Download Certification' button
  * Store a certificate file

## gateway activation
  * Open http://[BBB’s IP address]
  * Settings->'Register Gateway Cert'
  * Select a certificate file
  * Click 'Update Certificate'
  * Check REST, MQTT Channel

## Sensor setup
 * Requirement
   * Network (Wired or Wireless) connection

 * Procedure
   * Step 1
   	 - Connect all sensors
   	 - ![BBB GPIO](docs/image/bbb_gpio.jpg "BBB GPIO")
   * Step 2
     - Open http://[BBB’s IP address]/#/home

     - ![Gateway home](docs/image/gatewayui_home.png "Gateway home")

   * Step 3
     - Add sensor information with plus button at home
     - Select(click) agent type and fill ALL attributes
     	- If sensor’s id is detected automatically, you can select the ID
     	- If not, you must input the sensor ID or the Sensor ID is assigned
     - Test
     - Save and add additional sensors
     - ![Gateway sensor](docs/image/gatewayui_sensor.png "Gateway sensor")

## 3G setup
![Thingworks modem](docs/image/bbb_modem_z.jpg "Thingworks modem")
 * Requirement
   * Update the gateway software
   * Make sure the modem on your PC works
   * LAN connection for the first time configration
 * Procedure
   * Step 1
     - Connect all your asset as shown above
     - Power on
   * Step 2
     - Browsing http://[BBB’s IP address]
     - Fill out modem information in Setting Menu
     - Reboot (No LAN requires now)
 * Example procedure (carrier: sk telecom network, without ethernet connection)
   * Step 1 PC side: setup network over USB
     - install driver on your pc (Windows, Mac OS X, Linux)
       - see http://beagleboard.org/static/beaglebone/latest/README.htm
     - browser open http://192.168.7.2
   * Step 2 Gateway side: modem setting
     - HOME -> Modem -> Modem Configuration:
        - APN: web.sktelecom.com
        - id: skt
        - pass: skt
        - SIM pass: 1234
        - check enabled
     - Press "Change Configuration" button
     - ![modem setting](docs/image/bbb_modem_setting.png "modem setting")
   * Step 3 Gateway side: remember mac adress
     - HOME->Cloud Connection->Mac address
   * Step 4 PC side: [gateway registration to server](#gateway-registration-to-server)
   * Step 5 Gateway side: [gateway activation](#gateway-activation)
   * Step 6 Gateway Side:
     - SETTINGS->Gateway Control ->reboot
     - wait 5 min
