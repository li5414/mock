module 'mock'

local _SceneManagerFactoryRegistry = {}
--TODO: release on module refreshing
function registerSceneManagerFactory( factory )
	local key = factory:getKey()
	if not key then return end
	for i, fac0 in pairs( _SceneManagerFactoryRegistry ) do
		local key0 = fac0:getKey()
		if key0 == key then
			_warn( 'duplicated scene config factory, overwrite', key )
			_SceneManagerFactoryRegistry[ i ] = factory
			return
		end
	end
	table.insert( _SceneManagerFactoryRegistry, factory )
end

function getSceneManagerFactoryRegistry()
	return _SceneManagerFactoryRegistry
end


--------------------------------------------------------------------
CLASS: SceneManagerFactory ()
	:MODEL{}

function SceneManagerFactory:create( scn )
	return false
end

function SceneManagerFactory:getKey()
	_error( 'scene config key required, override this function' )
end

function SceneManagerFactory:acceptEditorScene()
	return false
end

--------------------------------------------------------------------
CLASS: SceneManager ()
	:MODEL{}

function SceneManager:__init()
	self.scene = false
end

function SceneManager:init( scn )
	self.scene = scn
	self:onInit( scn )
end

function SceneManager:getScene()
	return self.scene
end

function SceneManager:getKey()
	return self._key
end

function SceneManager:onInit()
end

function SceneManager:serialize()
	return {}
end

function SceneManager:deserialize( data )
end

--------------------------------------------------------------------
