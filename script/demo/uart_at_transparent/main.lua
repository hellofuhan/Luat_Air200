PROJECT = "UART_AT_TRANSPARENT"
VERSION = "1.0.0"
require"sys"
require"ril"
require"uartat"

ril.setransparentmode(uartat.write)
sys.init(0,0)
sys.run()
