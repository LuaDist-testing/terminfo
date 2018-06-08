#! /usr/bin/lua
local M = require 'terminfo'
require 'DataDumper'

--------------------------- infrastructure -----------------------
local eps = .000000001
function equal(x, y)  -- unused here
    if #x ~= #y then return false end
    local i; for i in pairs(x) do
        if math.abs(x[i]-y[i]) > eps then return false end
    end
    return true
end
-- use Test::Simple tests => 6;
local Test = 73 ; local i_test = 0; local Failed = 0;
function ok(b,s)
    i_test = i_test + 1
    if b then
        io.write('ok '..i_test..' - '..s.."\n")
		return true
    else
        io.write('not ok '..i_test..' - '..s.."\n")
        Failed = Failed + 1
		return false
    end
end

local function get_dict_of_attributes (attributes)
	local dict_of_attributes = {}
	local err_fn = os.tmpname()
	local pipe = assert(io.popen('stty -a 2>'..err_fn, 'r'))
	local stty_output = pipe:read('*all')
	err_fh = assert(io.open(err_fn))
	local err_msg = err_fh:read('*all')
	err_fh:close()  -- 4.8
	os.remove(err_fn)
	pipe:close()
	-- split stty_output into words and put each word in the dict
	for w in string.gmatch(stty_output, '([-%l%d]+)') do
		dict_of_attributes[w] = true
	end
	-- os.execute('stty -a')
	return dict_of_attributes
end
local function qw(s)  -- t = qw([[ foo  bar  baz ]])
    local t = {}
	for x in s:gmatch("([-%s]+)") do t[#t+1] = x end
	return t
end

local function current_state()
	local pipe = assert(io.popen('stty -a', 'r'))
	local stty_output = pipe:read('*all')
	pipe:close()
	return string.gsub(stty_output, 'line%s*=%s*%d+', '')
end

----------------------- here we go... -------------------------

print('Testing terminfo.lua '..M.Version..', '..M.VersionDate..
 ' on a '..os.getenv('TERM'))

if not ok(type(M) == 'table', 'type of M is table') then
	print('type was '..type(M))
end

local xc = M.getflag('km')
local xv = M.flag_by_varname('has_meta_key')
if not ok(xc==xv, "getflag('km') matches flag_by_varname('has_meta_key')") then
	print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.getnum('it')
xv = M.num_by_varname('init_tabs')
if not ok(xc==xv, "getnum('it') matches num_by_varname('init_tabs')") then
	print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.getnum('cols')
xv = M.num_by_varname('columns')
if not ok(xc==xv, "getnum('cols') matches num_by_varname('columns')") then
	print('xc='..tostring(xc)..' xv='..tostring(xv))
end
if not ok(xc>5, "getnum('cols') returns "..tostring(xc)) then
	print('xc='..tostring(xc))
end

xc = M.getstr('el')
xv = M.str_by_varname('clr_eol')
if not ok(xc==xv, "getstr('el') matches str_by_varname('clr_eol')") then
	print('xc='..tostring(xc)..' xv='..tostring(xv))
end

local xc = M.get('km')
local xv = M.get('has_meta_key')
if not ok(xc==xv, "get('km') matches get('has_meta_key')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.get('it')
xv = M.get('init_tabs')
if not ok(xc==xv, "get('it') matches get('init_tabs')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.get('cols')
xv = M.get('columns')
if not ok(xc==xv, "get('cols') matches get('columns')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end
if not ok(xc>5, "get('cols') returns "..tostring(xc)) then
    print('xc='..tostring(xc))
end

xc = M.get('el')
xv = M.get('clr_eol')
if not ok(xc==xv, "get('el') matches get('clr_eol')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.get('Q2cY?')
if not ok(xc==nil, "get('Q2cY?') returns nil") then
	print('xc='..tostring(xc))
end
xv = M.get('Skwuurbth_woklifaticAtiroary67_glurk')
if not ok(xv==nil, "get('Skwuurbth_woklifaticAtiroary67_glurk') returns nil") then
	print('xv='..tostring(xv))
end

xc = M.getflag('km','xterm')
xv = M.flag_by_varname('has_meta_key','xterm')
if not ok(xc == true, "getflag('km','xterm') returns true") then
	print("type(M.getflag('km','xterm') returned "..tostring(xc))
end
if not ok(xc==xv,
  "getflag('km','xterm') matches flag_by_varname('has_meta_key','xterm')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.getnum('it','vt100')
xv = M.num_by_varname('init_tabs','vt100')
if not ok(xc==xv, "getnum('it','vt100') matches num_by_varname('init_tabs','vt100')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end

xc = M.getnum('cols','vt200')
xv = M.num_by_varname('columns','vt200')
if not ok(xc==xv, "getnum('cols','vt200') matches num_by_varname('columns','vt200')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end
if not ok(xc>5, "getnum('cols','vt200') returns "..tostring(xc)) then
    print('xc='..tostring(xc))
end

xc = M.getstr('el','vt100')
xv = M.str_by_varname('clr_eol','vt100')
if not ok(xc==xv, "getstr('el','vt100') matches str_by_varname('clr_eol','vt100')") then
    print('xc='..tostring(xc)..' xv='..tostring(xv))
end

local bool_caps = M.flag_capnames('vt100')
local bool_vars = M.flag_varnames('vt100')
if not ok(#bool_caps==#bool_vars, 'for a vt100 #bool_caps == #bool_vars') then
	print('bool_caps = '..DataDumper(bool_caps))
	print('bool_vars = '..DataDumper(bool_vars))
end
ok(#bool_caps > 3, '#bool_caps is '..tostring(#bool_caps))

local num_caps = M.num_capnames('vt220')
local num_vars = M.num_varnames('vt220')
if not ok(#num_caps==#num_vars, 'for a vt220 #num_caps == #num_vars') then
	print('num_caps = '..DataDumper(num_caps))
	print('num_vars = '..DataDumper(num_vars))
end
ok(#num_caps > 3, '#num_caps is '..tostring(#num_caps))

local str_caps = M.str_capnames()
local str_vars = M.str_varnames()
if not ok(#str_caps==#str_vars, '#str_caps == #str_vars') then
	print('str_caps = '..DataDumper(str_caps))
	print('str_vars = '..DataDumper(str_vars))
end
ok(#str_caps > 20, '#str_caps is '..tostring(#str_caps))

-- for k,v in pairs(M) do print(k,v) end

-- local cap = M.get('cursor_address', 'xterm')
-- print('cap='..cap)
local cap = '[%i%p1%d;%p2%dH'
local str = M.tparm(cap, 20,30)
if not ok(str=='[21;31H', 'tparm("'..cap..'",20,30) returned "[21;31H"') then
	print('str = '..tostring(str))
end

cap = '[%i%p1%d$<21>;%p2%d$<3>H'
local str = M.tparm(cap, 20,30)
str = string.gsub(str, '%$<[*/%d]+>', '')
if not ok(str=='[21;31H', 'tparm("'..cap..'",20,30) returned "[21;31H"') then
	print('str = '..tostring(str))
end

cap = '[%i%p1%d$<21/>;%p2%d$<3*>H'
local str = M.tparm(cap, 20,30)
if not ok(str=='[21;31H', 'tparm("'..cap..'",20,30) returned "[21;31H"') then
	print('str = '..tostring(str))
end

if Failed == 0 then
	print('Passed all '..i_test..' tests')
else
	print('Failed '..Failed..' tests out of '..i_test)
end

os.exit()
