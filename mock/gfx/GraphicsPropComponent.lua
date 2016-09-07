module 'mock'

CLASS: GraphicsPropComponent ( RenderComponent )
	:MODEL{
		Field 'index' :int() :range(0) :getset( 'Index' );
}

function GraphicsPropComponent:__init()
	self.billboard = false
	self.depthMask = false
	self.depthTest = false
	self.prop = MOAIProp.new()
	self:setBlend('normal')
end

function GraphicsPropComponent:setBlend( b )
	self.blend = b
	setPropBlend( self.prop, b )
end

function GraphicsPropComponent:setBillboard( billboard )
	self.billboard = billboard
	self.prop:setBillboard( billboard )
end

function GraphicsPropComponent:getMoaiDeck()
	return self._moaiDeck
end

function GraphicsPropComponent:setIndex( i )
	self.prop:setIndex( i )
end

function GraphicsPropComponent:getIndex()
	return self.prop:getIndex()
end

function GraphicsPropComponent:setShader( shaderPath )
	self.shader = shaderPath	
	if shaderPath then
		local shader = mock.loadAsset( shaderPath )
		if shader then
			local moaiShader = shader:getMoaiShader()
			return self.prop:setShader( moaiShader )
		end
	end
	local default = self:getDefaultShader()
	if default then 
		return self.prop:setShader( default )
	end
	return self.prop:setShader( nil )
end

function GraphicsPropComponent:getPickingProp()
	return self.prop
end

function GraphicsPropComponent:setVisible( f )
	self.prop:setVisible( f )
end

function GraphicsPropComponent:isVisible()
	return self.prop:getAttr( MOAIProp.ATTR_VISIBLE ) ~= 0
end

function GraphicsPropComponent:setScissorRect( s )
	self.prop:setScissorRect( s )
end

function GraphicsPropComponent:setLayer( layer )
	layer:insertProp( self.prop )
end

function GraphicsPropComponent:setGrid( grid )
	self.prop:setGrid( grid )
end

--------------------------------------------------------------------
function GraphicsPropComponent:getMoaiProp()
	return self.prop
end

function GraphicsPropComponent:onAttach( entity )
	entity:_attachProp( self.prop, 'render' )
end

function GraphicsPropComponent:onDetach( entity )
	entity:_detachProp( self.prop, 'render' )
end


function GraphicsPropComponent:getDefaultShader()
	return nil
end

function GraphicsPropComponent:hide()
	return self.prop:setVisible( false )
end

function GraphicsPropComponent:show()
	return self.prop:setVisible( true )
end

function GraphicsPropComponent:getBounds()
	return self.prop:getBounds()
end

function GraphicsPropComponent:setBounds( x0,y0,z0, x1,y1,z1 )
	return self.prop:setBounds( x0,y0,z0, x1,y1,z1 )
end

function GraphicsPropComponent:inside( x, y, z, pad )
	local _,_,z1 = self.prop:getWorldLoc()
	return self.prop:inside( x,y,z1, pad )
end

function GraphicsPropComponent:getWorldBounds()
	return self.prop:getWorldBounds()
end

function GraphicsPropComponent:applyMaterial( material )
	material:applyToMoaiProp( self.prop )
end

function GraphicsPropComponent:setUVTransform( trans )
	print( 'setting uv transform', trans )
	return self.prop:setUVTransform( trans )
end

wrapWithMoaiPropMethods( GraphicsPropComponent, ':getMoaiProp()' )