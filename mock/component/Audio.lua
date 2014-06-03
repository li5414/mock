module 'mock'
--------------------------------------------------------------------
--SOUND Listener
--------------------------------------------------------------------
--TODO: add multiple listener support (need host works) ?
CLASS: SoundListener ()
:MODEL{
	
}
wrapWithMoaiTransformMethods( SoundListener, '_listener' )

function SoundListener:__init()
	local listener = MOAIFmodEventMgr.getMicrophone()
	self._listener = listener
	listener:setVectorForward( 0,0,-1 )
	listener:setVectorUp( 0,1,0 )
end

function SoundListener:onAttach( entity )
	entity:_attachTransform( self._listener )
end

function SoundListener:onDetach( entity )
	-- do nothing...
end

registerComponent( 'SoundListener', SoundListener )

--------------------------------------------------------------------
--SOUND SOURCE
--------------------------------------------------------------------
CLASS: SoundSource ()
	:MODEL{
		Field 'defaultClip' :asset('fmod_event')  :getset('DefaultClip');
		Field 'autoPlay'    :boolean();
	}

function SoundSource:__init()
	self.eventInstances = {}
	self.eventNamePrefix = false
end

function SoundSource:onAttach( entity )
end

function SoundSource:onDetach( entity )
	for evt, k in pairs( self.eventInstances ) do
		evt:stop()
	end
	self.eventInstances = nil
end

function SoundSource:setDefaultClip( path )
	self.defaultClipPath = path
end

function SoundSource:getDefaultClip()
	return self.defaultClipPath
end

function SoundSource:onStart()
	if self.autoPlay then self:start() end	
end

function SoundSource:setEventPrefix( prefix )
	self.eventNamePrefix = prefix or false
end

function SoundSource:start()
	if self.defaultClipPath then
		return self:playEvent2D( self.defaultClipPath )
	end
end

--------------------------------------------------------------------
local inheritLoc = inheritLoc
function SoundSource:_addInstance( evt, follow )
	self:clearInstances()
	self.eventInstances[ evt ] = true
	if follow then
		self._entity:_attachTransform( evt )
		evt:forceUpdate()
	end
	return evt
end


local function _affirmFmodEvent( event )
	if not event then return nil end
	if type( event ) == 'string' then
		event, node = loadAsset( event ) 
		if node and node.type == 'fmod_event' then return event:getFullName() end
	else
		return event:getFullName()
	end
	_error( 'unknown sound event type:', event )
	return nil
end

function SoundSource:_playEvent3DAt( event, x,y,z, follow, looped )
	local eventId = _affirmFmodEvent( event )
	if not eventId then return false end

	local evt	
	evt = MOAIFmodEventMgr.playEvent3D( eventId, x,y,z )
	if evt then
		return self:_addInstance( evt, follow~=false )
	else
		_error( 'sound event not found:', eventId )
	end
end

function SoundSource:_playEvent2D( event, looped )
	local eventId = _affirmFmodEvent( event )
	if not eventId then return false end
	
	local evt = MOAIFmodEventMgr.playEvent2D( eventId, looped )
	if evt then
		return self:_addInstance( evt, false )
	else
		_error( 'sound event not found:', eventId )
	end
end

--------------------------------------------------------------------
function SoundSource:playEvent3DAt( event, x,y,z, follow )
	return self:_playEvent3DAt( event, x,y,z, follow, nil )
end

function SoundSource:playEvent3D( event, follow )
	local x,y,z
	x,y,z = self._entity:getWorldLoc()
	return self:playEvent3DAt( event, x,y,z, follow )
end

function SoundSource:playEvent2D( event )
	return self:_playEvent2D( event, nil )
end

function SoundSource:loopEvent3DAt( event, x,y,z, follow )
	return self:_playEvent3DAt( event, x,y,z, follow, true )
end

function SoundSource:loopEvent3D( event, follow )
	local x,y,z
	x,y,z = self._entity:getWorldLoc()
	return self:loopEvent3DAt( event, x,y,z, follow )
end

function SoundSource:loopEvent2D( event )
	return self:_playEvent2D( event, true )
end

--------------------------------------------------------------------
function SoundSource:isBusy()
	self:clearInstances()
	return next(self.eventInstances) ~= nil
end
	
function SoundSource:clearInstances()
	local t1 = {}
	for evt, k in pairs( self.eventInstances ) do
		if evt:isValid() then
			t1[ evt ] = k
		end
	end
	self.eventInstances = t1
end

--------------------------------------------------------------------
function SoundSource:onBuildGizmo()
	local giz = mock_edit.IconGizmo()
	giz:setIcon( 'sound.png' )
	giz:setTransform( self._entity:getProp() )
	return giz
end


registerComponent( 'SoundSource', SoundSource )
--------------------------------------------------------------------
