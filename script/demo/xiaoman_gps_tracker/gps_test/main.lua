PROJECT = "XIAOMAN_GPS_TEST"
VERSION = "1.0.0"
require"chg"
require"pins"
require"gpsapp"
require"wdt"
require"testgps"

sys.init(0,0)
--ril.request("AT*TRACE=\"SXS\",1,0")
--ril.request("AT*TRACE=\"DSS\",1,0")
--ril.request("AT*TRACE=\"SXS\",1,0")
sys.run()
