module 'character'

--------------------------------------------------------------------
CLASS: EventSpineAnimation ( CharacterActionEvent )
	:MODEL{
		Field 'clip'  :string();
		Field 'loop'  :boolean();
		Field 'resetOnPlay'  :boolean();
	}

function EventSpineAnimation:__init()
	self.length = 1
	self.clip   = ''
	self.loop   = false
	self.resetOnPlay = true
end

function EventSpineAnimation:isResizable()
	return false
end

function EventSpineAnimation:onStart( target, pos )
	if self.clip == '' then
		return target:stopAnim( self.resetOnPlay )
	end
	target:playAnim( self.clip, self.loop, self.resetOnPlay )
end

function EventSpineAnimation:toString()
	local clip = self.clip
	if not clip or clip == '' then return '<nil>' end
	if self.loop then
		return '<loop> '..clip
	else
		return clip
	end
end

function EventSpineAnimation:setClip( name )
	self.clip = name
end
--------------------------------------------------------------------
CLASS: TrackSpineAnimation ( CharacterActionTrack )
	:MODEL{}

function TrackSpineAnimation:__init()
	self.name = 'animation'
end

function TrackSpineAnimation:createEvent()
	return EventSpineAnimation()
end

function TrackSpineAnimation:getType()
	return 'spine'
end

function TrackSpineAnimation:toString()
	return '<spine>' .. tostring( self.name )
end
--------------------------------------------------------------------
registerCharacterActionTrackType( 'Spine Animation', TrackSpineAnimation )
