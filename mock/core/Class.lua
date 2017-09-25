--[[
* MOCK framework for Moai

* Copyright (C) 2012 Tommo Zhou(tommo.zhou@gmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local setmetatable  = setmetatable
local getmetatable  = getmetatable

local rawget, rawset = rawget, rawset
local insert = table.insert
local type = type
local next = next
--------------------------------------------------------------------
-- CLASS
--------------------------------------------------------------------
local newClass
local separatorField
local globalClassRegistry = setmetatable( {}, { __no_traverse = true } )
local tracingObjectMark            = 0
local tracingObjectAllocation      = false
local tracingObjectAllocationStack = false
local tracingObjectTable = setmetatable( {}, { __mode = 'kv', __no_traverse = true } )

local buildInstanceBuilder

local reservedMembers = {
	['__init']  = true,
	['__name']  = true,
	['__env']   = true,
	['__model'] = true,
}

local function getDefaultValueForType( ftype )
	if ftype == 'number'   then return {0} end
	if ftype == 'int'      then return {0} end
	if ftype == 'string'   then return {''} end
	if ftype == 'boolean'  then return {false} end
	if ftype == '@asset'   then return {false} end
	if ftype == 'vec2'     then return {0,0} end
	if ftype == 'vec3'     then return {0,0,0} end
	if ftype == 'vec4'     then return {0,0,0,0} end
	if ftype == 'color'    then return {1,1,1,1} end
	return nil
end

function setTracingObjectAllocation( tracing )
	tracingObjectAllocation = tracing ~= false
end

function isTracingObjectAllocation()
	return tracingObjectAllocation
end

function getTracingObjectTable()
	return tracingObjectTable
end

function getTracingObjectCount()
	return table.len( tracingObjectTable )
end

function clearTracingTable()
	tracingObjectTable = setmetatable( {}, { __mode = 'kv', __no_traverse = true } )
end

function countTracingObject( filter, ignoreMockObject )
	local objectCounts = {}
	for o in pairs( tracingObjectTable ) do
		local name = o:getClassFullName() or '<unknown>'
		if ignoreMockObject and name:sub( 1, 4 ) == 'mock' then
			--do nothing
		elseif name == 'Model' or name == 'Field' then
			--do nothing
		elseif not filter or ( name:find( filter ) ) then
				objectCounts[ name ] = ( objectCounts[ name ] or 0 ) + 1
		end
	end
	return objectCounts
end

function reportTracingObject( filter, ignoreMockObject )
	local objectCounts = countTracingObject( filter, ignoreMockObject )
	local total  = 0
	local output = {}
	for name, count in pairs( objectCounts ) do
		insert( output, { name, count } )
	end
	table.sort( output, function( i1, i2 ) return i1[1] < i2[1] end )
	print( '--------' )
	for i, item in ipairs( output ) do
		print( string.format( '%9d\t%s',item[2], item[1] ) )
		total = total + item[2]
	end
	print( '-- total objects:', total )
	return objectCounts
end

function _incObjectTracingMark()
	tracingObjectMark = tracingObjectMark + 1
end


--------------------------------------------------------------------
local BaseClass = {
	__subclasses  = {},
	__signals     = false,
	__serialize   = false,
	__deserialize = false,
	__clone       = false,
}

_BASECLASS = BaseClass --use this to extract whole class tree

--Class build DSL
function BaseClass:MODEL( t )
	local m = Model( self )
	m:update( t )
	return self
end

function BaseClass:DEPRECATED( msg )
	self.__deprecated = { msg = msg }
	return self
end

function BaseClass:MEMBER( t )
	for k, v in pairs( t ) do
		self[k] = v
	end
	return self
end

function BaseClass:META( t )
	self.__meta = t
	return self
end

local signalEmit = signalEmit
function BaseClass:SIGNAL( t )
	self.__signals = t
	buildInstanceBuilder( self )
	return self
end

function BaseClass:rawInstance( t )
	return setmetatable( t, self )
end

function BaseClass:isSubclass( superclass )
	local s = self.__super
	while s do
		if s == superclass then return true end
		s = s.__super
	end
	return false
end

function BaseClass:isSubclassByName( superclassName )
	local s = self.__super
	while s do
		if s.__name == superclassName then return true end
		s = s.__super
	end
	return false
end

function BaseClass:isValidClass()
	return globalClassRegistry[ self.__fullname ] == self
end


--Instance Methods
function BaseClass:getClass()
	return self.__class
end

function BaseClass:getClassName()
	return self.__class.__name
end

function BaseClass:getClassSourceFile()
	return self.__class.__source
end

function BaseClass:getClassFullName()
	return self.__class.__fullname
end

function BaseClass:isInstance( clas )
	if type( clas ) == 'string' then return self:isInstanceByName( clas ) end
	local c = self.__class
	if c == clas then return true end
	return c:isSubclass( clas )
end

function BaseClass:isInstanceByName( className )
	local c = self.__class
	if c.__name == className then return true end
	return c:isSubclassByName( className )
end

function BaseClass:assertInstance( superclass )
	if self:isInstance( superclass ) then
		return self 
	else
		return error( 'object is not instance of given class', 2 )
	end
end

function BaseClass:__repr()
	return string.format( '%s<%s>', self.__class.__name, tostring( self ) )
end

--Signals

-- function BaseClass:superCall( name, ... )
-- 	local m = self[ name ]
-- 	local super = self.__super
-- 	while super do
-- 		local m1 = super[ name ]
-- 		if not m1 then break end
-- 		if m1 ~= m then return m1( self, ... ) end
-- 		super = super.__super
-- 	end
-- 	error( 'no super method: '.. name, 2 )
-- end


--------------------------------------------------------------------
local function buildInitializer(class,f)
	if not class then return f end
	local init = rawget( class, '__init' )
	
	if type( init ) == 'table' then --copy
		local t1 = init
		init = function(a)
			for k,v in pairs( t1 ) do
				a[ k ] = v
			end
		end
	end

	if init then
		if f then
			local f1 = f
			f = function( a, ... )
				init( a, ... )
				return f1( a, ... )
			end
		else
			f = init
		end
	end

	return buildInitializer( class.__super, f )
end


local newSignal        = newSignal
local signalConnect    = signalConnect
local signalDisconnect = signalDisconnect

local function collectSignalInfo( class, info )
	if not class then return info end
	local signals = rawget( class, '__signals' )
	if signals then
		for id, handler in pairs( signals ) do
			if handler and handler ~= '' then
				if info[ id ] == nil then
					info[ id ] = handler
				end
			else
				info[ id ] = false
			end
		end
	end
	return collectSignalInfo( class.__super, info )
end

local function buildSignalInitializer( class, f )
	local signals = collectSignalInfo( class, {} )
	--FIXME: replace this NAIVE impl.
	if not next( signals ) then return false end
	
	local signalMethods = false
	local function init( obj )
		if not signalMethods then --collect signal methods at first instance creation
			signalMethods = {}
			for id, handler in pairs( signals ) do
				if handler and handler ~= '' then
					local func = class[ handler ]
					if type( func ) ~= 'function' then
						error( 'signal handler is not a function!' )
					end
					signalMethods[ id ] = func
				else
					signalMethods[ id ] = false
				end
			end
		end

		for id, func in pairs( signalMethods ) do
			local sig = newSignal()				
			obj[ id ] = sig
			if func then
				signalConnect( sig, obj, func )
			end
		end

	end

	return init
end

function clearAllSignalConnections( owner, obj )
	for key in pairs( owner.__signals ) do
		local signal = owner[ key ]
		--assert
		signalDisconnect( signal, obj )
	end
end

function buildInstanceBuilder( class )
	local init = buildInitializer( class )
	local initSignals = buildSignalInitializer( class )

	local newinstance = function (t,...)
		local o=setmetatable({}, class)
		if initSignals then initSignals(o,...) end
		if init then init(o,...) end
		if tracingObjectAllocation then
			tracingObjectTable[ o ] = tracingObjectMark
			if tracingObjectAllocationStack then
				o.__createtraceback = debug.traceback( 2 )
			end
		end
		return o
	end

	local mt = getmetatable( class )
	mt.__call = newinstance

	for s in pairs( class.__subclasses ) do
		buildInstanceBuilder(s)
	end
end

--------------------------------------------------------------------
function newClass( b, superclass, name  )		
	b=b or {}
	local index
	superclass = superclass or BaseClass
	b.__super  = superclass

	for k,v in pairs(superclass) do --copy super method to reduce index time
		if not reservedMembers[k] and rawget(b,k)==nil then 
			b[k]=v
		end
	end

	superclass.__subclasses[b] = true

	b.__index       = b
	b.__class       = b
	b.__subclasses  = {}

	b.__serialize   = superclass.__serialize
	b.__deserialize = superclass.__deserialize
	b.__clone       = superclass.__clone

	if not name then
		local s = superclass
		while s do
			local sname = s.__name
			if sname and sname ~= '??' then
				name = s.__name..':??'
				break
			end
			s = s.__super
		end
	end

	b.__name  = name or '??'
	b.__classdirty = false
	--TODO: automatically spread super class modification

	local newindex=function( t, k, v )
		b.__classdirty = true
		rawset( b, k, v )
		if k=='__init' then
			buildInstanceBuilder(b)
		else --spread? TODO
		end
	end
	
	setmetatable( b, {
			__newindex = newindex,
			__isclass  = true
		}
	)

	buildInstanceBuilder(b)
	if superclass.__initclass then
		superclass:__initclass( b )
	end
	return b
	
end

function updateAllSubClasses( c, force )
	for s in pairs(c.__subclasses) do
		local updated = false
		for k,v in pairs(c) do
			if not reservedMembers[k] and ( force or rawget( s, k ) == nil ) then 
				updated = true
				s[k] = v
			end
		end
		if updated then updateAllSubClasses(s) end
	end
end

function isClass( c )
	local mt = getmetatable( c )
	return mt and mt.__isclass or false
end

function isSubclass( c, super )
	if c == super then return true end
	return isClass( c ) and c:isSubclass( super )
end

function isClassInstance( o )
	return getClass( o ) ~= nil
end

function isInstance( o, clas )
	return isClassInstance(o) and o:isInstance( clas )
end

function affirmInstance( o, clas )
	return o and isInstance( o, clas ) and o or nil
end

function getClass( o )
	if type( o ) ~= 'table' then return nil end
	local clas = getmetatable( o )
	if not clas then return nil end
	local mt = getmetatable( clas )
	return mt and mt.__isclass and clas or nil
end

local classBuilder
local function affirmClass( t, id )
	if type(id) ~= 'string' then error('class name expected',2) end

	return function( a, ... )
			local superclass
			if select( '#', ... ) >= 1 then 
				superclass = ...
				if not superclass then
					error( 'invalid superclass for:' .. id, 2 )
				end
			end
			
			if a ~= classBuilder then
				error( 'Class syntax error', 2 )
			end
			if superclass and not isClass( superclass ) then
				error( 'Superclass expected, given:'..type( superclass ), 2)
			end
			local clas = newClass( {}, superclass, id )
			local env = getfenv( 2 )
			env[ id ] = clas
			local info = debug.getinfo( 2, 'S' )
			clas.__source = info.source
			if env ~= _G then
				local prefix = env._NAME or tostring( env )
				clas.__fullname = prefix .. '.' .. clas.__name
			else
				clas.__fullname = clas.__name
			end
			clas.__env = env

			clas.__definetraceback = debug.traceback( 2 )
			local clas0 = globalClassRegistry[ clas.__fullname ]
			if clas0  then
				_error( 'duplicated class:', clas.__fullname )
				print( '-->from:',clas.__definetraceback )
				print( '-->first defined here:',clas0.__definetraceback )

			end
			globalClassRegistry[ clas.__fullname ] = clas
			return clas
		end

end

classBuilder = setmetatable( {}, { __index = affirmClass } )

local function rawClass( superclass )	
	local clas = newClass( {}, superclass, '(rawclass)' )
	clas.__fullname = clas.__name
	return clas
end

--------------------------------------------------------------------
_G.CLASS     = classBuilder
_G._rawClass = rawClass

local classSearchCache = setmetatable({}, {__mode ='v'})

function findClass( term )
	local result = classSearchCache[ term ]
	if result then return result end
	local l = #term
	local candidates = {}
	for n, clas in pairs( globalClassRegistry ) do		
		if clas.__name == term then
			insert( candidates, clas )
		end
	end
	local count = #candidates
	if count > 1 then
		_warn( 'more than one class found for name', term )
		result = candidates[ 1 ]
		classSearchCache[ term ] = result
		return result

	elseif count == 0 then
		return nil

	else
		result = candidates[ 1 ]
		classSearchCache[ term ] = result
		return result

	end
end

function getClassByName( fullname )
	return globalClassRegistry[ fullname ]
end

function validateAllClasses()
	--TODO
	return true
end

--------------------------------------------------------------------
--MODEL & Field
--------------------------------------------------------------------

CLASS: Model ()
function Model:__init( clas, clasName )
	self.__src_class = clas
	self.__name  = clas.__fullname or clasName or 'LuaObject'
	rawset( clas, '__model', self )
end

function Model.fromObject( obj )
	local clas = getClass( obj )
	-- if not clas then return nil end
	assert( clas, 'not class object' )
	return Model.fromClass( clas )
end

function Model.fromClass( clas )
	if not isClass(clas) then
		return nil
	end
	--TODO:support moai class
	local m = rawget( clas, '__model' )
	if not m then
		-- print( 'create model for', clas.__name )
		m = Model( clas )
	end
	assert( m.__name == clas.__fullname )
	return m	
end

function Model.find( term )
	local clas = findClass( term )
	return clas and Model.fromClass( clas ) or nil
end

function Model.findName( term )
	local m = Model.find( term )
	return m and m.__name or nil
end

function Model.fromName( fullname )
	local clas = globalClassRegistry[ fullname ]
	if clas then return Model.fromClass( clas ) end
	return nil
end

function Model:__call( body )
	self:update( body )
	return self
end

function Model:getName()
	return self.__name
end

local function _collectFieldForUpdate( model, group, fields, fieldMap, f )
	local mt = getmetatable( f )
	if mt == FieldGroup then
		for i, child in ipairs( f:getChildren() ) do
			_collectFieldForUpdate( model, nil, fields, fieldMap, child )
		end
		f.__model = model
	elseif mt == Field then
		local id = f.__id
		if fieldMap[id] then error( 'duplicated Field:'..id, 3 ) end
		fieldMap[ id ] = f
		insert( fields, f )
		f.__model = model
		if group then
			group:_addChild( f )
		end
	elseif f == '----' then
		insert( fields, separatorField )
		if group then
			group:_addChild( f )
		end
	else
		error('Field/FieldGroup expected in Model, given:'..type( f ), 3)
	end
end

function Model:update( body )
	local fields   = {}
	local fieldMap = {}
	local rootGroup = FieldGroup()
	for i, f in ipairs( body ) do
		_collectFieldForUpdate( self, rootGroup, fields, fieldMap, f )
	end
	self.__fields   = fields
	self.__fieldMap = fieldMap
	self.__rootGroup = rootGroup
	return self
end

function Model:getMeta()
	return rawget( self.__src_class, '__meta' )
end

function Model:getField( name, findInSuperClass )
	local fields = self.__fields
	if fields then 
		for i, f in ipairs( self.__fields ) do
			if f.__id == name then return f end
		end
	end
	findInSuperClass = findInSuperClass~=false
	if findInSuperClass then
		local superModel = self:getSuperModel()
		if superModel then return superModel:getField( name, true ) end
	end
	return nil
end

function Model:getFieldType( name, findInSuperClass )
	local field = self:getField( findInSuperClass )
	if field then
		return field:getType()
	else
		return nil
	end
end


local function _collectFields( model, includeSuperFields, list, dict )
	list = list or {}
	dict = dict or {}
	if includeSuperFields then
		local s = model:getSuperModel()
		if s then _collectFields( s, true, list, dict ) end
	end
	local fields = model.__fields
	if fields then
		for i, f in ipairs( fields ) do
			local id = f.__id
			local i0 = dict[id]
			if i0 and f ~= separatorField then --override
				list[i0] = f
			else
				local n = #list
				list[ n + 1 ] = f
				dict[ id ] = n + 1
			end
		end
	end
	return list
end

function Model:getFieldList( includeSuperFields )
	return _collectFields( self, includeSuperFields ~= false )
end


local function _collectMeta( clas, meta )
	meta = meta or {}
	local super = clas.__super
	if super then
		_collectMeta( super, meta )
	end
	local m = rawget( clas, '__meta' )
	if not m then return meta end
	for k, v in pairs( m ) do
		meta[ k ] = v
	end
	return meta
end

function Model:getCombinedMeta()
	return _collectMeta( self.__src_class )
end

function Model:getSuperModel( name )
	local superclass = self.__src_class.__super
	if not superclass then return nil end
	local m = rawget( superclass, '__model' )
	if not m then
		m = Model( superclass )
	end
	return m
end

function Model:getClass()
	return self.__src_class
end

function Model:newInstance( ... )
	local clas = self:getClass()
	return clas( ... )
end

function Model:isInstance( obj )
	if type(obj) ~= 'table' then return false end
	local clas = getmetatable( obj )
	local clas0 = self.__src_class
	while clas do
		if clas == clas0 then return true end
		clas = rawget( clas, '__super' )
	end
	return false
end

function Model:getFieldValue( obj, name )
	if not self:isInstance( obj ) then return nil end
	local f = self:getField( name )
	if not f then return nil end
	return f:getValue( obj )
end

function Model:setFieldValue( obj, name, ... )
	if not self:isInstance( obj ) then return nil end
	local f = self:getField( name )
	if not f then return nil end
	return f:setValue( obj, ... )
end

--------------------------------------------------------------------
CLASS: Field ()
function Field:__init( id )
	self.__id       = id
	self.__type     = 'number'
	self.__getter   = true 
	self.__setter   = true
	self.__objtype  = false
	self.__group    = false
end

function Field:type( t )
	self.__type = t
	return self
end

function Field:array( t ) 
	self.__type     = '@array'
	self.__itemtype = t or 'number'
	return self
end

function Field:asset_array(t)
	self:array( '@asset' )
	self.__assettype = t
	return self
end

function Field:collection( t ) 
	self.__type     = '@array'
	self.__itemtype = t or 'number'
	self:meta{ ['collection'] = true }
	return self
end

function Field:enum( t )
	self.__type  = '@enum'
	self.__enum  = t
	return self
end

function Field:selection( s )
	if not s then return self end	
	return self:meta{ selection = s }
end

function Field:table( ktype, vtype ) 
	self.__type    = v
	self.__keytype = ktype
	return self
end

function Field:asset( assetType )
	self.__type      = '@asset'
	self.__assettype = assetType
	return self
end

function Field:asset_pre( assetType )
	return self:asset( assetType ):meta{ preload = true }
end

function Field:asset_array_pre( assetType )
	return self:asset_array( assetType ):meta{ preload = true }
end

--type shortcut
function Field:number()
	return self:type('number')
end

function Field:float()
	return self:type('number')
end

function Field:boolean()
	return self:type('boolean')
end

function Field:string()
	return self:type('string')
end

function Field:int()
	return self:type('int')
end

function Field:variable() --any atomic values
	return self:type('variable')
end

function Field:action( methodName )
	self:type('@action')	
	self.__actionname = methodName
	return self
end

function Field:no_nil()
	return self:meta { no_nil = true } --will get validated against onStart
end

---
function Field:label( l )
	self.__label = l
	return self
end

function Field:desc( desc )
	return self:meta{ description = desc }
end

function Field:meta( meta )
	assert( type(meta) == 'table', 'metadata should be table' )
	local meta0 = self.__meta or {} --copy into old meta
	for k, v in pairs( meta ) do
		meta0[k] = v
	end
	self.__meta = meta0
	return self
end

function Field:sub()
	self.__objtype = 'sub'
	return self
end

function Field:ref()
	self.__objtype = 'ref'
	return self
end

function Field:no_edit() --short cut
	return self:meta{ no_edit = true }
end

function Field:preload()
	return self:meta{ preload = true }
end

function Field:no_save() --short cut
	return self:meta{ no_save = true }
end

function Field:readonly( option ) --short cut
	if type(option) == 'string' then --function
		local checkerName = option
		local checker = function( obj, ... )
			local f = obj[checkerName]
			if f then return f( obj, ... ) else error( 'readonly checker not found:'..checkerName ) end
		end
		self:meta{ readonly = checker }
	elseif type(option) == 'function' then
		local checker = option
		return self:meta{ readonly = checker }
	else
		return self:meta{ readonly = option ~= false }
	end
end
function Field:hidden( option ) --short cut
	if type(option) == 'string' then --function
		local checkerName = option
		local checker = function( obj, ... )
			local f = obj[checkerName]
			if f then return f( obj, ... ) else error( 'hidden checker not found:'..checkerName ) end
		end
		self:meta{ hidden = checker }
	elseif type(option) == 'function' then
		return self:meta{ hidden = option }
	else
		return self:meta{ hidden = option ~= false }
	end
end

function Field:range( min, max )
	if min then self:meta{ min = min } end
	if max then self:meta{ max = max } end
	return self
end

function Field:widget( name )
	if name then self:meta{ widget = name } end
	return self
end

function Field:default( ... )
	return self:meta{ default_value = {...} }
end

function Field:resetDefaultValue( obj )
	local defaultValue = self:getMeta( 'default_value', nil )
	if defaultValue == nil then
		local ftype = self:getType()
		defaultValue = getDefaultValueForType( ftype )
	end
	if defaultValue then 
		self:setValue( obj, unpack( defaultValue ) )
		return true
	else
		return false
	end
end

function Field:get( getter )
	if type(getter) == 'string' then
		local getterName = getter
		getter = function( obj )
			local f = obj[getterName]
			if f then return f( obj ) else 
				error( string.format( 'getter not found: %s -> %s', self.__model.__name, getterName ) )
			end
		end
	end
	self.__getter = getter
	return self
end

function Field:set( setter )
	if type(setter) == 'string' then
		local setterName = setter
		setter = function( obj, ... )
			local f = obj[setterName]
			if f then return f( obj, ... ) else 
				error( string.format( 'setter not found: %s -> %s', self.__model.__name, setterName ) )
			end
		end
	end
	self.__setter = setter
	return self
end

function Field:getset( fieldName )
	return self:get('get'..fieldName):set('set'..fieldName)
end

--use a generic tuple value getter/setter
function Field:tuple_getset( fieldId )
	self.__is_tuple = true
	local id = fieldId or self.__id
	self.__getter = function( obj )
		local k = obj[ id ]
		if k then return unpack( k ) end		
	end
	self.__setter = function( obj, ... )
		obj[ id ] = { ... }		
	end
	return self
end


--generic multiple fields getter/setter
function Field:fields_getset( ... )	
	self.__is_tuple = true
	local fieldList = ''
	local argList = ''
	local ids = {...}
	for i, id in ipairs( ids ) do
		assert( type( id ) == 'string' )
		if i > 1 then
			fieldList = fieldList..','
			argList    = argList..','
		end
		fieldList = fieldList..string.format( 'obj[%q]', id )		
		argList    = argList..('arg'..i)
	end
	---setter
	local getterCode = 'return function( obj ) return '..fieldList..'end'
	local getterFunc = loadstring( getterCode )()
	---setter	
	local setterCode = string.format(
		'return function( obj, %s ) %s = %s end',
		argList, fieldList, argList
	)
	local setterFunc = loadstring( setterCode )()
	---
	self.__getter = getterFunc
	self.__setter = setterFunc
	return self	
end


function Field:onset( methodName )	
	local setter0 = self.__setter
	if not setter0 then
		error( 'attempt to add onSet for readonly field' )
	end

	if setter0 == true then --plain field setting
		local id = self.__id
		self.__setter = function( obj, ... )
			obj[ id ] = ...
			local onset = obj[ methodName ]
			if not onset then
				error( 'onset method not found:'..methodName )
			end
			return onset( obj, ... )
		end
	else
		self.__setter = function( obj, ... )
			setter0( obj, ... )
			local onset = obj[ methodName ]
			if not onset then
				error( 'onset method not found:'..methodName )
			end
			return onset( obj, ... )
		end
	end
	return self	
end

function Field:on_set( ... )
	return self:onset( ... )
end

function Field:isset( fieldName )
	return self:get('is'..fieldName):set('set'..fieldName)
end

function Field:getValue( obj )
	local getter = self.__getter
	if not getter then return nil end 
	if getter == true then return obj[ self.__id ] end
	return getter( obj )
end

function Field:setValue( obj, ... )
	local setter = self.__setter
	if not setter then return end 
	if setter == true then obj[ self.__id ] = ... return end
	setter( obj, ... )
end

function Field:getIndexValue( obj, idx )
	local t = self:getValue( obj )	
	return t[idx]
end

function Field:setIndexValue( obj, idx, v )
	local t = self:getValue( obj )	
	t[idx] = v
end

function Field:getId()
	return self.__id
end

function Field:getType()
	return self.__type
end

function Field:getMeta( key, default )
	local v
	if self.__meta then 
		v= self.__meta[key]
	end
	if v == nil then return default end
	return v
end

--------------------------------------------------------------------
--FieldGroup
--------------------------------------------------------------------
CLASS: FieldGroup ()	
function FieldGroup:__init( id )
	self.__id = id
	self.__children = {}
end

function FieldGroup:__call( t )
	local tt = type( t )
	if tt == 'string' then
		self.__name = t
		return self
	elseif tt == 'table' then
		local children = {}
		self.__children = children
		for i, f in ipairs( t ) do
			local mt = getmetatable( f )
			if mt == Field or mt == FieldGroup then
				insert( children, f )
				f.__group = self
			elseif f == '----' then
				insert( children, f )
			else
				error( 'Field/FieldGroup expected in Model, given:'..type( f ), 3 )
			end
		end
		return self
	else
		error( 'invalid FieldGroup usage' )
	end
end

function FieldGroup:getChildren()
	return self.__children
end

function FieldGroup:_addChild( f )
	insert( self.__children, f )
end

function FieldGroup:label( label )
	self.__label = label
end

function FieldGroup:folded()
	self.__folded = true
end

--------------------------------------------------------------------
---CLASS Replacement?
--------------------------------------------------------------------
function findClassesFromEnv( env )
	local collected = {}
	for key , clas in pairs( globalClassRegistry )  do
		if clas.__env == env then
			collected[ key ] = clas
		end
	end
	return collected
end

function releaseClassesFromEnv( env )
	local toremove = findClassesFromEnv( env )
	for key, clas in pairs( toremove ) do
		globalClassRegistry[ key ] = nil
	end
	return toremove
end


--------------------------------------------------------------------
CLASS: MoaiModel (Model)
function MoaiModel:newinstance( ... )
	return self.__src_class.new()
end

--------------------------------------------------------------------
separatorField = Field('----') :no_save() :no_edit()
--------------------------------------------------------------------

--some utils
function _ENUM( t )
	return t
end

function _ENUM_I( t )
	local t1 = {}
	for i, id in ipairs( t ) do
		t1[ i ] = { id, i }
	end
	return t1
end

function _ENUM_V( t )
	local t1 = {}
	for i, id in ipairs( t ) do
		t1[ i ] = { id, id }
	end
	return t1
end

function _ENUM_NAME( enum, value, fallback )
	for i, entry in ipairs( enum ) do
		local n, v = unpack( entry )
		if value == v then return n end
	end
	return fallback or nil
end
