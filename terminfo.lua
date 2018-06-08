---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2011, Peter J Billam      --
--                       www.pjb.com.au                            --
--                                                                 --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- This module is a translation into Lua by Peter Billam
-- of the Term::Terminfo module by Paul Evans
-- The calling interface is similar, but does not create an object;
--  the $TERM parameter is passed as an optional second argument.

local M = {} -- public interface
M.Version     = '1.01' -- first working version
M.VersionDate = '12sep2013'

local Cache = {}  -- Cache[term] maintained by update_cache()
local ThisTerm = os.getenv('TERM') or 'vt100' -- if no idea, call it a VT100

-------------------- private utility functions -------------------
local function warn(str) io.stderr:write(str,'\n') end
local function die(str) io.stderr:write(str,'\n') ;  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
local function sorted_keys(t)
	local a = {}
	for k,v in pairs(t) do a[#a+1] = k end
	table.sort(a)
	return  a
end

---------------- from Lua Programming Gems p. 331 ----------------
local require, table = require, table -- save the used globals
local aux, prv = {}, {} -- auxiliary & private C function tables
local initialise = require 'C-terminfo'
initialise(aux, prv, M) -- initialise the C lib with aux,prv & module tables

---------------- private module-specific function ----------------
local function update_cache( term )
	if Cache[term] then return end
	Cache[term] = {}
	Cache[term]['flags_by_capname']   = prv.flags_by_capname(term)
	Cache[term]['nums_by_capname']    = prv.nums_by_capname(term)
	Cache[term]['strings_by_capname'] = prv.strings_by_capname(term)
	Cache[term]['flags_by_varname']   = prv.flags_by_varname(term)
	Cache[term]['nums_by_varname']    = prv.nums_by_varname(term)
	Cache[term]['strings_by_varname'] = prv.strings_by_varname(term)
	return
end

---------------- public functions from Terminfo.pm  ---------------

function M.get ( name, term )  -- not in the Perl module; looks everywhere
	-- most varnames contain an underscore...
	if (string.len(name) > 5) or string.find(name, '_') then
		local x = M.str_by_varname ( name, term )
		if x ~= nil then return x end
		x = M.flag_by_varname ( name, term )
		if x ~= nil then return x end
		x = M.num_by_varname ( name, term )
		if x ~= nil then return x end
		x = M.getstr ( name, term )
		if x ~= nil then return x end
		x = M.getflag ( name, term )
		if x ~= nil then return x end
		x = M.getnum ( name, term )
		return x
	else -- it's more likely to be a capname:
		local x = M.getstr ( name, term )
		if x ~= nil then return x end
		local x = M.getflag ( name, term )
		if x ~= nil then return x end
		local x = M.getnum ( name, term )
		if x ~= nil then return x end
		x = M.str_by_varname ( name, term )
		if x ~= nil then return x end
		x = M.flag_by_varname ( name, term )
		if x ~= nil then return x end
		x = M.num_by_varname ( name, term )
		return x
	end
end
-- could do a cap2varname, perhaps also varname2cap; probably not useful.

function M.getflag ( capname, term )
	term = term or ThisTerm
	update_cache( term )
	return Cache[term]['flags_by_capname'][capname]
end

function M.getnum ( capname, term )
	term = term or ThisTerm
	-- don't trust Cache, because of possible resizes
	local  nums_by_capname = prv.nums_by_capname(term)
	return nums_by_capname[capname]
end

function M.getstr ( capname, term )
	term = term or ThisTerm
	update_cache( term )
	return Cache[term]['strings_by_capname'][capname]
end

function M.flag_by_varname ( varname, term )
	term = term or ThisTerm
	update_cache( term )
	return Cache[term]['flags_by_varname'][varname]
end

function M.num_by_varname ( varname, term )
	term = term or ThisTerm
	-- don't trust Cache, because of possible resizes
	local  nums_by_varname = prv.nums_by_varname(term)
	return nums_by_varname[varname]
end

function M.str_by_varname ( varname, term )
	term = term or ThisTerm
	update_cache( term )
	return Cache[term]['strings_by_varname'][varname]
end

function M.flag_capnames ( term )
	term = term or ThisTerm
	update_cache( term )
	return sorted_keys(Cache[term]['flags_by_capname'])
end

function M.num_capnames ( term )
	term = term or ThisTerm
	update_cache( term )
	return sorted_keys(Cache[term]['nums_by_capname'])
end

function M.str_capnames ( term )
	term = term or ThisTerm
	update_cache( term )
	return sorted_keys(Cache[term]['strings_by_capname'])
end

function M.flag_varnames ( term )
	term = term or ThisTerm
	update_cache( term )
	return sorted_keys(Cache[term]['flags_by_varname'])
end

function M.num_varnames ( term )
	term = term or ThisTerm
	update_cache( term )
	return sorted_keys(Cache[term]['nums_by_varname'])
end

function M.str_varnames ( term )
	term = term or ThisTerm
	update_cache( term )
	return sorted_keys(Cache[term]['strings_by_varname'])
end

return M

--[[

=pod

=head1 NAME

C<terminfo> - access the I<terminfo> database

=head1 SYNOPSIS

 local T = require 'terminfo'

 print("Can a vt100 do overstrike ? ",
    tostring(T.getflag('os','vt100')))

 print("Tabs on this terminal are initially every ",
    T.getnum('it'))

 print("Can this terminal do overstrike ? ",
    tostring(T.flag_by_varname('over_strike')))

 print("Tabs on xterm are initially every ",
    T.num_by_varname('init_tabs', 'xterm'))

 if T.get('km') then  -- this kbd has a Meta-Key :-)
    if T.get('init_tabs') < 8 then
       print('someone changed the tabstop setting !')
    end
    print('testing the Home key:'..T.get('key_home'))
    if T.get('cud1') ~= T.get('cursor_down') then
       print('BUG: capname and varname gave different answers')
    end
 end
 -- see:  man terminfo

=head1 DESCRIPTION

This module provides access to I<terminfo> database entries,
see I<man terminfo>.

This database provides information about a terminal,
in three separate sets of capabilities.
Flag capabilities are boolean;
they indicate the presence of a particular ability, feature, or bug.
Number capabilities give the size,
count or other numeric detail of some feature of the terminal.
String capabilities are usually control strings
that the terminal will recognise, or send.

Each capability has two names; a short name called the I<capname>,
and a longer name called the I<varname>;
for details, see I<man terminfo>.
This module,
like the Perl I<Term::Terminfo> module, provides two sets of functions,
one that works on I<capnames>, one that works on I<varnames>.
It also, unlike the Perl module,
provides a general-purpose function B<get(name)> which returns
the capability whether it is a flag, number or string,
and whether the name is a I<capname> or a I<varname>.

Unlike the Perl I<Term::Terminfo> module, there is no separate constructor.
The TERM parameter is passed as an optional second argument.
If it is not present, the current terminal,
from the environment variable I<TERM>, is used.

=head1 FUNCTIONS

=head3 T.get( name [, TERM] )

Returns the value of the capability of the given name,
whether the capability is a flag, number or string,
and whether the name is a I<capname> or a I<varname>.
This function is not present in the Perl I<Term::Terminfo> module.

=head3 bool = T.getflag( capname [, TERM] )

=head3 num = T.getnum( capname [, TERM] )

=head3 str = T.getstr( capname [, TERM] )

Returns the value of the flag, number or string capability respectively,
of the given I<capname>.

=head3 bool = T.flag_by_varname( varname [, TERM] )

=head3 num = T.num_by_varname( varname [, TERM] )

=head3 str = T.str_by_varname( varname [, TERM] )

Returns the value of the flag, number or string capability respectively,
of the given I<varname>.

=head3 capnames = T.flag_capnames( [TERM] )

=head3 capnames = T.num_capnames( [TERM] )

=head3 capnames = T.str_capnames( [TERM] )

Return arrays of the I<capnames> of the supported flags, numbers, and strings
respectively.

=head3 varnames = T.flag_varnames( [TERM] )

=head3 varnames = T.num_varnames( [TERM] )

=head3 varnames = T.str_varnames( [TERM] )

Return arrays of the I<varnames> of the supported flags, numbers, and strings
respectively.

=head1 DOWNLOAD

This module is available as a LuaRock in
luarocks.org/repositories/rocks
so you should be able to install it with the command:

 $ su
 Password:
 # luarocks install terminfo

or:

 # luarocks install http://www.pjb.com.au/comp/lua/terminfo-1.0-0.rockspec

=head1 CHANGES

 20130915 1.0 first working version 

=head1 AUTHOR

Translated into Lua by Peter Billam (
http://www.pjb.com.au/comp/contact.html
) from the Perl CPAN module (
http://search.cpan.org/perldoc?Term::Terminfo
) by Paul Evans

=head1 SEE ALSO

=over 3

C<unibilium> - a terminfo parsing library -
https://github.com/mauke/unibilium

http://search.cpan.org/perldoc?Term::Terminfo

 $HOME/.terminfo
 /etc/terminfo
 /lib/terminfo
 /usr/share/terminfo

 tput
 tic

 man terminfo

=back

=cut
]]
