local summary = require "summary"
local filter = require "filter"
local browser_verify = require "browser_verify"
local frequency_limit = require "frequency_limit"
local router = require "router"
local backend_static = require "backend_static"
local backend_proxy = require "backend_proxy"

if ngx.var.vn_exec_flag and ngx.var.vn_exec_flag ~= '' then
    return
end

summary.pre_run_matcher()
--规则过滤器
filter.filter()
--浏览器过滤
browser_verify.filter()
--访问频率过滤器
frequency_limit.filter()
--启动dashboard路由
router.filter()
--后台静态文件
backend_static.filter()
--后台代理
backend_proxy.filter()
