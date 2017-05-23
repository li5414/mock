module 'mock'

local GlobalAnimatorVarChangeListeners = {}
function addGlobalAnimatorVarChangeListener( l )
	GlobalAnimatorVarChangeListeners[ l ] = true
end

--------------------------------------------------------------------
CLASS: Animator ( Component )
	:MODEL{
		Field 'data'         :asset_pre('animator_data') :getset( 'DataPath' );
		'----';
		Field 'throttle'     :number() :range( 0 ) :meta{ step=0.1 } :getset( 'Throttle' );
		'----';
		Field 'default'      :string() :selection( 'getClipNames' );
		Field 'autoPlay'     :boolean();
		Field 'autoPlayMode' :enum( EnumTimerModeWithDefault );
	}

function Animator:__init()
	self.dataPath    = false
	self.data        = false
	self.default     = 'default' --default clip
	self.activeState = false
	self.throttle    = 1
	self.scale       = 1
	self.autoPlay    = true
	self.autoPlayMode= false
	self.vars        = {}
	self.varSeq      = 0
	self.states      = {}
	self.statePool   = {}
	self.activeStateLocked = false
end



--------------------------------------------------------------------
function Animator:onAttach( entity )
end
--------------------------------------------------------------------

function Animator:setDataPath( dataPath )
	self.dataPath = dataPath
	self.data = mock.loadAsset( dataPath )
	if self.data then
		self.data:prebuildAll()
	end
	self:stop()
	self.statePool = {}
end

function Animator:getDataPath()
	return self.dataPath
end

function Animator:getData()
	return self.data
end

function Animator:getClipNames()
	local data = self.data
	if not data then return nil end
	return data:getClipNames()
end

--------------------------------------------------------------------
--Track access
--------------------------------------------------------------------
function Animator:getClip( clipName )
	if not self.data then return nil end
	return self.data:getClip( clipName )
end

function Animator:findTrack( clipName, trackName, trackType )
	local clip = self:getClip( clipName )
	if not clip then
		_warn('Animator has no clip', clipName)
		return nil
	end
	return clip:findTrack( trackName, trackType )
end

function Animator:findTrackByType( clipName, trackType )
	local clip = self:getClip( clipName )
	if not clip then
		_warn('Animator has no clip', clipName)
		return nil
	end
	return clip:findTrackByType( trackType )
end

--------------------------------------------------------------------
--playback
function Animator:hasClip( name )
	if not self.data then
		return false
	end
	return self.data:getClip( name ) and true or false
end

function Animator:_loadClip( clip, makeActive, _previewing )
	local state
	if not _previewing then --try pool
		state = self:popStateFromPool( clip )
	end
	if not state then
		state = AnimatorState()
		state.previewing = _previewing
		state:setParentThrottle( self.throttle )
		state:loadClip( self, clip )
	end
	if makeActive ~= false then 
		self:stop()
		self.activeState = state
	end
	self.states[ state ] = true
	return state
end

function Animator:loadClip( name, makeActive, _previewing )
	makeActive = makeActive ~= false
	if self.activeStateLocked and makeActive then
		_warn( singletraceback(3) )
		_warn( 'attempt to change clip of locked animator', name, self:getEntityName() )
		return false
	end

	if not self.data then
		_warn('Animator has no data')
		return false
	end
	local clip = self.data:getClip( name )
	if not clip then
		_warn( 'Animator has no clip', name )
		return false
	end
	return self:_loadClip( clip, makeActive, _previewing )
end

function Animator:getActiveState()
	return self.activeState
end

function Animator:getActiveClipName()
	local state = self.activeState
	return state and state:getClipName()
end

function Animator:onStateStart( state )
end

function Animator:onStateStop( state )
	--push into pool
	if not state.previewing then
		self:pushStateIntoPool( state )
	end
end

function Animator:pushStateIntoPool( state )
	local pool = self.statePool
	if not pool then return end
	local clip = state.clip
	local list = pool[ clip ]
	if not list then
		list = {}
		pool[ clip ] = list
	end
	table.insert( list, state )
end

function Animator:popStateFromPool( clip )
	local list = self.statePool[ clip ]
	if not list then return false end
	local state = table.remove( list, 1 )
	if state then
		state.stopping = false
		state:reset()
		return state
	end
end

function Animator:loopClip( clipName )
	return self:playClip( clipName, MOAITimer.LOOP )
end

function Animator:playClip( clipName, mode )
	local state = self:loadClip( clipName )
	if state then	
		state:setMode( mode )
		state:start()
	end
	return state
end

function Animator:lockClip( locked )
	self.activeStateLocked = locked ~= false
end

function Animator:unlockClip()
	return self:lock( false )
end

function Animator:stop()
	if not self.activeState then return end
	self.activeState:stop()
	-- for state in pairs( self.states ) do
	-- 	state:stop()
	-- end
	-- self.states = {}
end

function Animator:pause( paused )
	if not self.activeState then return end
	self.activeState:pause( paused )
end

function Animator:resume()
	return self:pause( false )
end

function Animator:startDefaultClip()
	if self.default and self.data then
		if self.default == '' then return end
		return self:playClip( self.default, self.autoPlayMode )
	end
	return false
end

function Animator:setThrottle( th )
	self.throttle = th
	if self.activeState then
		self.activeState:setParentThrottle( th )
	end
end

function Animator:getThrottle()
	return self.throttle
end

-----
function Animator:onStart( ent )	
	if self.autoPlay then
		self:startDefaultClip()
	end
end

function Animator:onDetach( ent )
	self.statePool = false
	self:stop()
	for s in pairs( self.states ) do
		s:clear()
	end
	self.activeState = false
	self.states = {}
end

function Animator:setVar( id, value )
	self.vars[ id ] = value
	self.varSeq = self.varSeq + 1
	for listener in pairs( GlobalAnimatorVarChangeListeners ) do
		listener( self, id, value )
	end
end

function Animator:getVar( id, default )
	local v = self.vars[ id ]
	if v == nil then return default end
	return v
end

function Animator:seekVar( id, value, duration ,easeMode )
	--TODO
end

function Animator:getDepAnimators()

end

--------------------------------------------------------------------
mock.registerComponent( 'Animator', Animator )
