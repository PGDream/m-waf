-- -*- coding: utf-8 -*-
-- @Date    : 2016-04-20 23:13
-- @Author  : Alexa (AlexaZhou@163.com)
-- @Link    : 
-- @Disc    : request frequency limit

local _M = {}


local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local util = require "util"

local limit_dict = ngx.shared.frequency_limit
local limit_time_dict = ngx.shared.frequency_limit_time
-- 封闭时间为10分钟
local frequency_block_time = 600
-- 触发规则后执行的action
local function returnResponse(response_lis, rule, response)
    if rule['response'] ~= nil then
        ngx.status = tonumber(rule['code'])
        response = response_list[rule['response']]
        if response ~= nil then
            ngx.header.content_type = response['content_type']
            ngx.say(response['body'])
        end
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.exit(tonumber(rule['code']))
    end
end

function _M.filter()
    if VeryNginxConfig.configs["frequency_limit_enable"] ~= true then
        return
    end
    -- verynginxconfig 对象
    local matcher_list = VeryNginxConfig.configs['matcher']
    local response_list = VeryNginxConfig.configs['response']
    local response
    -- 匹配规则
    for i, rule in ipairs(VeryNginxConfig.configs["frequency_limit_rule"]) do
        local enable = rule['enable']
        local matcher = matcher_list[rule['matcher']]
        if enable == true and request_tester.test(matcher) == true then
            -- 根据规则获取监听的对象(ip,uri)
            local key = i
            if util.existed(rule['separate'], 'ip') then
                key = key .. '-' .. ngx.var.remote_addr
            end
            if util.existed(rule['separate'], 'uri') then
                key = key .. '-' .. ngx.var.uri
            end
            local count = rule['count']
            local time = rule['time']
            local code = rule['code']
            --ngx.log(ngx.STDERR,'-----');
            --ngx.log(ngx.STDERR,key);
            local count_now = limit_dict:get(key)
            local blockKey = limit_time_dict:get(key)
            -- 当count_now 不为空  blockKey的值大于配置的数时
            if count_now ~= nil and blockKey ~= nil and blockKey >= tonumber(count) then
                returnResponse(response_lis, rule, response)
            end
            --ngx.log(ngx.STDERR, tonumber(count_now) );
            -- 初始化计数对象
            if count_now == nil then
                limit_dict:set(key, 1, tonumber(time))
                count_now = 0
            end
            -- 自增1
            limit_dict:incr(key, 1)
            if count_now > tonumber(count) then
                -- 添加封闭ip时间
                limit_time_dict:set(key, count_now, frequency_block_time)
                returnResponse(response_lis, rule, response)
            end
            return
        end
    end
end

return _M
