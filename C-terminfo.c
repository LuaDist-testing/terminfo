/*
    C-terminfo.c - terminfo bindings for Lua

   This Lua5 module is Copyright (c) 2013, Peter J Billam
                     www.pjb.com.au

 This module is free software; you can redistribute it and/or
       modify it under the same terms as Lua5 itself.
*/

#include <lua.h>
#include <lauxlib.h>
#include <string.h>  /* thats where strlen & friends are declared */

/* -------- from Term-Terminfo-0.08/lib/Term/Terminfo.xs ------- */
#ifdef HAVE_UNIBILIUM
# include <unibilium.h>
#else
# include <term.h>
#endif


/* see Programming in Lua p.233 */
void set_boolval (lua_State *L, const char *key, int val) {
	lua_pushboolean(L, val);
	lua_setfield(L, -2, key);
}
void set_numval (lua_State *L, const char *key, int val) {
	lua_pushinteger(L, val);
	lua_setfield(L, -2, key);
}
void set_strval (lua_State *L, const char *key, const char *val) {
	lua_pushstring(L, val);
	lua_setfield(L, -2, key);
}
void ncroak (char *msg) {  /* just warn and exit ... */
	fprintf(stderr, "Terminfo.lua: %s\n", msg);
	return;
	/* exit(1); needs stdlib.h */
}

#ifdef HAVE_UNIBILIUM
#define SETUP size_t len; \
  const char *termtype = lua_tolstring(L, 1, &len); int i; lua_newtable(L); \
  unibi_term *unibi = unibi_from_term(termtype); \
  if(!unibi) {ncroak("unibi_from_term(\"%s\"): %s",termtype,strerror(errno));}
#define CLEANUP unibi_destroy(unibi); \
  return 1;
#else
#define SETUP size_t len; \
  const char *termtype = lua_tolstring(L, 1, &len); int i; lua_newtable(L); \
  TERMINAL *oldterm = cur_term; setupterm(termtype, 0, NULL);
#define CLEANUP oldterm=set_curterm(oldterm); del_curterm(oldterm); \
  return 1;
#endif

static int c_flags_by_capname(lua_State *L) {  /* Lua stack: termtype */
  SETUP
#ifdef HAVE_UNIBILIUM
  for (i = unibi_boolean_begin_+1; i < unibi_boolean_end_; i++) {
    const char *capname = unibi_short_name_bool(i);
    int value = unibi_get_bool(unibi, i);
#else
  for (i = 0; boolnames[i]; i++) {
    const char *capname = boolnames[i];
    int value = tigetflag(capname);
#endif
    if(!value) continue;  /* is this appropriate ? the value might be false */
    set_boolval(L, capname, value);
  }
  CLEANUP
}

static int c_flags_by_varname(lua_State *L) {  /* Lua stack: termtype */
  SETUP
#ifdef HAVE_UNIBILIUM
  for (i = unibi_boolean_begin_+1; i < unibi_boolean_end_; i++) {
    const char *varname = unibi_name_bool(i);
    int value = unibi_get_bool(unibi, i);
#else
  for (i = 0; boolnames[i]; i++) {
    const char *capname = boolnames[i];
    const char *varname = boolfnames[i];
    int value = tigetflag(capname);
#endif
    if(!value) continue;  /* is this appropriate ? the value might be false */
    set_boolval(L, varname, value);
  }
  CLEANUP
}

static int c_nums_by_capname(lua_State *L) {  /* Lua stack: termtype */
  SETUP
#ifdef HAVE_UNIBILIUM
  for(i = unibi_numeric_begin_+1; i < unibi_numeric_end_; i++) {
    const char *capname = unibi_short_name_num(i);
    int value = unibi_get_num(unibi, i);
#else
  for(i = 0; numnames[i]; i++) {
    const char *capname = numnames[i];
    int value = tigetnum(capname);
#endif
    if(value == -1) continue;
    set_numval(L, capname, value);
  }
  CLEANUP
}

static int c_nums_by_varname(lua_State *L) {  /* Lua stack: termtype */
  SETUP
#ifdef HAVE_UNIBILIUM
  for(i = unibi_numeric_begin_+1; i < unibi_numeric_end_; i++) {
    const char *varname = unibi_name_num(i);
    int value = unibi_get_num(unibi, i);
#else
  for(i = 0; numnames[i]; i++) {
    const char *capname = numnames[i];
    const char *varname = numfnames[i];
    int value = tigetnum(capname);
#endif
    if(value == -1) continue;
    set_numval(L, varname, value);
  }
  CLEANUP
}

static int c_strings_by_capname(lua_State *L) {  /* Lua stack: termtype */
  SETUP
#ifdef HAVE_UNIBILIUM
  for(i = unibi_string_begin_+1; i < unibi_string_end_; i++) {
    const char *capname = unibi_short_name_str(i);
    const char *value = unibi_get_str(unibi, i);
#else
  for(i = 0; strnames[i]; i++) {
/* the last legit strname is set_pglen_inch = slength, but i careens on :-( */
    const char *capname = strnames[i];
    const char *value = tigetstr(capname);
#endif
    if(!value) continue;
	if(strlen(value) == 0) continue;
    set_strval(L, capname, value);
  }
  CLEANUP
}

static int c_strings_by_varname(lua_State *L) {  /* Lua stack: termtype */
  SETUP
#ifdef HAVE_UNIBILIUM
  for(i = unibi_string_begin_+1; i < unibi_string_end_; i++) {
    const char *varname = unibi_name_str(i);
    const char *value = unibi_get_str(unibi, i);
#else
  for(i = 0; strnames[i]; i++) {
    const char *capname = strnames[i];
    const char *varname = strfnames[i];
    const char *value = tigetstr(capname);
#endif
    if(!value) continue;
	if(strlen(value) == 0) continue;
    set_strval(L, varname, value);
  }
  CLEANUP
}

static int c_tparm(lua_State *L) {  /* Lua stack: str, p1,p2, ... p9 */
  /* Portable applications should provide 9 params after the format; zeroes
     are fine for this purpose. ...  A delay in mS  may appear anywhere in a
     string capability, in $<..> brackets, as in el=\EK$<5> (man tparm)
     In xterm, it's only used in flash, but in vt100 it's everywhere */
  size_t len;  /* none of them should contain zeroes */
  const char *str = lua_tolstring(L, 1, &len);
  lua_Integer p1  = lua_tointeger(L, 2);
  lua_Integer p2  = lua_tointeger(L, 3);
  lua_Integer p3  = lua_tointeger(L, 4);
  lua_Integer p4  = lua_tointeger(L, 5);
  lua_Integer p5  = lua_tointeger(L, 6);
  lua_Integer p6  = lua_tointeger(L, 7);
  lua_Integer p7  = lua_tointeger(L, 8);
  lua_Integer p8  = lua_tointeger(L, 9);
  lua_Integer p9  = lua_tointeger(L, 10);
  const char *value = tparm(str, p1,p2,p3,p4,p5,p6,p7,p8,p9);
  lua_pushstring(L, value);
  return 1;
}

/* ----------------- evolved from C-midialsa.c ---------------- */
struct constant {  /* Gems p. 334 */
    const char * name;
    int value;
};
static const struct constant constants[] = {
    /* {"Version", Version}, */
    {NULL, 0}
};

static const luaL_Reg prv[] = {  /* private functions */
    {"flags_by_varname",   c_flags_by_varname},
    {"nums_by_varname",    c_nums_by_varname},
    {"strings_by_varname", c_strings_by_varname},
    {"flags_by_capname",   c_flags_by_capname},
    {"nums_by_capname",    c_nums_by_capname},
    {"strings_by_capname", c_strings_by_capname},
    {"tparm",              c_tparm},
    {NULL, NULL}
};

static int initialise(lua_State *L) {  /* Lua Programming Gems p. 335 */
    /* Lua stack: aux table, prv table, dat table */
    int index;  /* define constants in module namespace */
    for (index = 0; constants[index].name != NULL; ++index) {
        lua_pushinteger(L, constants[index].value);
        lua_setfield(L, 3, constants[index].name);
    }
    /* lua_pushvalue(L, 1);   * set the aux table as environment */
    /* lua_replace(L, LUA_ENVIRONINDEX);
       unnecessary here, fortunately, because it fails in 5.2 */
    lua_pushvalue(L, 2); /* register the private functions */
#if LUA_VERSION_NUM >= 502
    luaL_setfuncs(L, prv, 0);    /* 5.2 */
    return 0;
#else
    luaL_register(L, NULL, prv); /* 5.1 */
    return 0;
#endif
}

int luaopen_terminfo(lua_State *L) {
    lua_pushcfunction(L, initialise);
    return 1;
}

