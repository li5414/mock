module 'mock'

local _GlobalManagerRegistry = {}

function getGlobalManagerRegistry()
	return _GlobalManagerRegistry
end


--------------------------------------------------------------------
CLASS: GlobalManager ()
	:MODEL{}

function GlobalManager:__init()
	local key = self:getKey()
	if not key then return end
	for i, m in ipairs( _GlobalManagerRegistry ) do
		if m:getKey() == key then
			_warn( 'duplciated global manager, overwrite', key )
			_GlobalManagerRegistry[ i ] = self
			return
		end		
	end
	table.insert( _GlobalManagerRegistry, self )
end

--instance methods
function GlobalManager:getKey()
	return self:getClassName()
	-- _error('global manager key required, override this function!', self:getClassName() )
end

function GlobalManager:onInit( game )
end

function GlobalManager:onUpdate( game, dt )
end

function GlobalManager:saveConfig()
end

function GlobalManager:loadConfig( configData )
end

function GlobalManager:onSceneInit( scene )
end

function GlobalManager:onSceneReset( scene )
end

function GlobalManager:onSceneClear( scene )
end

function GlobalManager:onSceneStart( scene )
end

function GlobalManager:postSceneStart( scene )
end
