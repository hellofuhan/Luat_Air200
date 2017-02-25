PROJECT = "XIAOMAN_WHOLE_TEST"
VERSION = "1.0.0"
require"chg"
require"pins"
require"gsensor"
require"light"
require"gpsapp"
require"wdt153b"
require"keypad"
require"link"
require"linkapp"
require"sck"

sys.init(0,0)
--ril.request("AT*TRACE=\"SXS\",1,0")
--ril.request("AT*TRACE=\"DSS\",1,0")
--ril.request("AT*TRACE=\"SXS\",1,0")
sys.run()
