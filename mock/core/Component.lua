module 'mock'
CLASS: Component ()
 	:MODEL{}

--------------------------------------------------------------------
wrapWithMoaiPropMethods( Component, '_entity._prop' )
--------------------------------------------------------------------

--------------------------------------------------------------------
--basic
--------------------------------------------------------------------
function Component:getEntity()
	return self._entity
end

function Component:findEntity( name )
	return self._entity:findEntity( name )
end

function Component:findChild( name )
	return self._entity:findChild( name )
end

function Component:getParent()
	return self._entity.parent
end

--------------------------------------------------------------------
function Component:getComponent( comType )
	return self._entity:getComponent( comType )
end

function Component:getComponentByName( comTypeName )
	return self._entity:getComponentByName( comTypeName )
end

function Component:com( id )
	return self._entity:com( id )
end

function Component:getScene()
	return self._entity.scene
end

--------------------------------------------------------------------
--Scene
--------------------------------------------------------------------
function Component:getScene()
	return self._entity.scene
end

function Component:getLayer()
	return self._entity:getLayer()
end

--------------------------------------------------------------------
--message & state
--------------------------------------------------------------------
function Component:broadcast( ... )
	return self._entity:broadcast( ... )
end

function Component:tell( ... )
	return self._entity:tell( ... )
end

function Component:pollMsg()
	msg, arg = self._entity:pollMsg()
	return msg,arg
end

function Component:peekMsg()
	return self._entity:peekMsg()
end

function Component:pollFindMsg( ... )
	return self._entity:pollFindMsg( ... )
end

function Component:getState()
	return self._entity.state()
end

function Component:inState( ... )
	return self._entity:inState( ... )
end

function Component:setState( state )
	return self._entity:setState( state )
end

function Component:inStateGroup( ... )
	return self._entity:inStateGroup( ... )
end



--------------------------------------------------------------------
--signals
--------------------------------------------------------------------
function Component:connect( sig, methodName )
	return self._entity:connectForObject( self, sig, methodName )
end

--------------------------------------------------------------------
-- Wait wrapping
--------------------------------------------------------------------
function Component:waitStateEnter(...)
	return self._entity:waitStateEnter(...)
end

function Component:waitStateExit(s)
	return self._entity:waitStateExit(s)
end

function Component:waitStateChange()
	return self._entity:waitStateChange()
end

function Component:waitFieldEqual( name, v )
	return self._entity:waitFieldEqual( name, v )
end

function Component:waitFieldNotEqual( name, v )
	return self._entity:waitFieldNotEqual( name, v )
end

function Component:waitFieldTrue( name )
	return self._entity:waitFieldTrue( name )
end

function Component:waitFieldFalse( name )
	return self._entity:waitFieldFalse( name )
end

function Component:waitSignal(sig)
	return self._entity:waitSignal(sig)
end

function Component:waitFrames(f)
	return self._entity:waitFrames(f)
end

function Component:waitTime(t)
	return self._entity:waitTime(t)
end

function Component:pauseThisThread( noyield )
	return self._entity:pauseThisThread( noyield )
end

function Component:wait( a )
	return self._entity:wait( a )
end

function Component:waitMsg( ... )
	return self._entity:waitMsg( ... )
end

--------------------------------------------------------------------
---------coroutine control
--------------------------------------------------------------------

local function coroutineFunc( coroutines, coro, func, ...)
	func( ... )
	coroutines[ coro ] = nil  --automatically remove self from thread list
end

function Component:addCoroutine( func, ... )
	
	local coro=MOAICoroutine.new()
	
	local coroutines = self.coroutines
	if not coroutines then
		coroutines = {}
		self.coroutines = coroutines
	end
	local tt = type( func )
	if tt == 'string' then --method name
		local _func = self[ func ]
		assert( type(_func) == 'function' , 'method not found:'..func )
		coro:run( coroutineFunc,
			coroutines, coro, _func, self,
			...)
	elseif tt=='function' then --function
		coro:run( coroutineFunc,
			coroutines, coro, func,
			...)
	else
		error('unknown coroutine func type:'..tt)
	end

	coroutines[coro] = true
	return coro
end

function Component:clearCoroutines()
	if not self.coroutines  then return end
	for coro in pairs( self.coroutines ) do
		coro:stop()
	end
end

--------------------------------------------------------------------
-------Component management
--------------------------------------------------------------------
local componentRegistry = {}
function registerComponent( name, creator )
	-- assert( not componentRegistry[ name ], 'duplicated component type:'..name )
	componentRegistry[ name ] = creator
end

function getComponentRegistry()
	return componentRegistry
end

function getComponentType( name )
	return componentRegistry[ name ]
end

