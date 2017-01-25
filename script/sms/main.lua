PROJECT = "CALL"
VERSION = "1.0.0"
require"sys"
require"common" --test模块用到了common模块的接口
require"sms" --test模块用到了sms模块的接口
require"test"

sys.init(0,0)
sys.run()
