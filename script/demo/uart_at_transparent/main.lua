PROJECT = "UART_AT_TRANSPARENT"
VERSION = "1.0.0"
require"sys"
require"ril"
require"uartat"

--设置虚拟ATC串口工作模式为透传模式
--虚拟ATC串口收到数据，会直接调用uartat.write接口
--uartat.write接口，会把虚拟ATC串口收到的数据通过物理uart转发给外设
ril.setransparentmode(uartat.write)
sys.init(0,0)
sys.run()
