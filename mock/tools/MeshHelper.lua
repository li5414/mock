module 'mock'

local _icosphere = require 'icosphere'

--------------------------------------------------------------------
--by zipline
local vertexFormat = MOAIVertexFormat.new ()
vertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 3 )
vertexFormat:declareUV ( 2, MOAIVertexFormat.GL_FLOAT, 2 )
vertexFormat:declareColor ( 3, MOAIVertexFormat.GL_UNSIGNED_BYTE )

local function makeBoxMesh ( xMin, yMin, zMin, xMax, yMax, zMax, texture )
	
	local function pushPoint ( points, x, y, z )
	
		local point = {}
		point.x = x
		point.y = y
		point.z = z
		
		table.insert ( points, point )
	end

	local function writeTri ( vbo, p1, p2, p3, uv1, uv2, uv3 )
		
		vbo:writeFloat ( p1.x, p1.y, p1.z )
		vbo:writeFloat ( uv1.x, uv1.y )
		vbo:writeColor32 ( 1, 1, 1 )
		
		vbo:writeFloat ( p2.x, p2.y, p2.z )
		vbo:writeFloat ( uv2.x, uv2.y )
		vbo:writeColor32 ( 1, 1, 1 )

		vbo:writeFloat ( p3.x, p3.y, p3.z )
		vbo:writeFloat ( uv3.x, uv3.y  )
		vbo:writeColor32 ( 1, 1, 1 )
	end
	
	local function writeFace ( vbo, p1, p2, p3, p4, uv1, uv2, uv3, uv4 )

		writeTri ( vbo, p1, p2, p4, uv1, uv2, uv4 )
		writeTri ( vbo, p2, p3, p4, uv2, uv3, uv4 )
	end
	
	local p = {}
	
	pushPoint ( p, xMin, yMax, zMax ) -- p1
	pushPoint ( p, xMin, yMin, zMax ) -- p2
	pushPoint ( p, xMax, yMin, zMax ) -- p3
	pushPoint ( p, xMax, yMax, zMax ) -- p4
	
	pushPoint ( p, xMin, yMax, zMin ) -- p5
	pushPoint ( p, xMin, yMin, zMin  ) -- p6
	pushPoint ( p, xMax, yMin, zMin  ) -- p7
	pushPoint ( p, xMax, yMax, zMin  ) -- p8

	local uv = {}
	
	pushPoint ( uv, 0, 0, 0 )
	pushPoint ( uv, 0, 1, 0 )
	pushPoint ( uv, 1, 1, 0 )
	pushPoint ( uv, 1, 0, 0 )
	
	local vbo = MOAIGfxBuffer.new ()
	vbo:reserve ( 36 * vertexFormat:getVertexSize ())
	
	writeFace ( vbo, p [ 1 ], p [ 2 ], p [ 3 ], p [ 4 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 4 ], p [ 3 ], p [ 7 ], p [ 8 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 8 ], p [ 7 ], p [ 6 ], p [ 5 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 5 ], p [ 6 ], p [ 2 ], p [ 1 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 5 ], p [ 1 ], p [ 4 ], p [ 8 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 2 ], p [ 6 ], p [ 7 ], p [ 3 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])

	local mesh = MOAIMesh.new ()
	mesh:setTexture ( texture )

	mesh:setVertexBuffer ( vbo, vertexFormat )
	mesh:setTotalElements ( vbo:countElements ( vertexFormat ))
	mesh:setBounds ( vbo:computeBounds ( vertexFormat ))
	
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	mesh:setShader ( MOAIShaderMgr.getShader ( MOAIShaderMgr.MESH_SHADER ))
	
	return mesh
end

local function makeSkewBoxMesh ( xMin, yMin, zMin, xMax, yMax, zMax, texture )
	
	local function pushPoint ( points, x, y, z )
	
		local point = {}
		point.x = x
		point.y = y
		point.z = z
		
		table.insert ( points, point )
	end

	local function writeTri ( vbo, p1, p2, p3, uv1, uv2, uv3 )
		
		vbo:writeFloat ( p1.x, p1.y, p1.z )
		vbo:writeFloat ( uv1.x, uv1.y )
		vbo:writeColor32 ( 1, 1, 1 )
		
		vbo:writeFloat ( p2.x, p2.y, p2.z )
		vbo:writeFloat ( uv2.x, uv2.y )
		vbo:writeColor32 ( 1, 1, 1 )

		vbo:writeFloat ( p3.x, p3.y, p3.z )
		vbo:writeFloat ( uv3.x, uv3.y  )
		vbo:writeColor32 ( 1, 1, 1 )
	end
	
	local function writeFace ( vbo, p1, p2, p3, p4, uv1, uv2, uv3, uv4 )

		writeTri ( vbo, p1, p2, p4, uv1, uv2, uv4 )
		writeTri ( vbo, p2, p3, p4, uv2, uv3, uv4 )
	end
	
	local p = {}
	
	-- pushPoint ( p, xMin, yMax, zMax - yMax ) -- p1
	-- pushPoint ( p, xMin, yMin, zMax - yMin ) -- p2
	-- pushPoint ( p, xMax, yMin, zMax - yMin ) -- p3
	-- pushPoint ( p, xMax, yMax, zMax - yMax ) -- p4
	
	-- pushPoint ( p, xMin, yMax, zMin - yMax ) -- p5
	-- pushPoint ( p, xMin, yMin, zMin - yMin  ) -- p6
	-- pushPoint ( p, xMax, yMin, zMin - yMin  ) -- p7
	-- pushPoint ( p, xMax, yMax, zMin - yMax  ) -- p8
	
	pushPoint ( p, xMin, yMax - zMax, zMax ) -- p1
	pushPoint ( p, xMin, yMin - zMax, zMax ) -- p2
	pushPoint ( p, xMax, yMin - zMax, zMax ) -- p3
	pushPoint ( p, xMax, yMax - zMax, zMax ) -- p4
	
	pushPoint ( p, xMin, yMax - zMin, zMin ) -- p5
	pushPoint ( p, xMin, yMin - zMin, zMin ) -- p6
	pushPoint ( p, xMax, yMin - zMin, zMin ) -- p7
	pushPoint ( p, xMax, yMax - zMin, zMin ) -- p8

	local uv = {}
	
	pushPoint ( uv, 0, 0, 0 )
	pushPoint ( uv, 0, 1, 0 )
	pushPoint ( uv, 1, 1, 0 )
	pushPoint ( uv, 1, 0, 0 )
	
	local vbo = MOAIGfxBuffer.new ()
	vbo:reserve ( 36 * vertexFormat:getVertexSize ())
	
	writeFace ( vbo, p [ 1 ], p [ 2 ], p [ 3 ], p [ 4 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 4 ], p [ 3 ], p [ 7 ], p [ 8 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 8 ], p [ 7 ], p [ 6 ], p [ 5 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 5 ], p [ 6 ], p [ 2 ], p [ 1 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 5 ], p [ 1 ], p [ 4 ], p [ 8 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])
	writeFace ( vbo, p [ 2 ], p [ 6 ], p [ 7 ], p [ 3 ], uv [ 1 ], uv [ 2 ], uv [ 3 ], uv [ 4 ])

	local mesh = MOAIMesh.new ()
	mesh:setTexture ( texture )

	mesh:setVertexBuffer ( vbo, vertexFormat )
	mesh:setTotalElements ( vbo:countElements ( vertexFormat ))
	mesh:setBounds ( vbo:computeBounds ( vertexFormat ))
	
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	mesh:setShader ( MOAIShaderMgr.getShader ( MOAIShaderMgr.MESH_SHADER ))
	
	return mesh
end

local function makeCubeMesh ( size, texture )
	size = size * 0.5
	return makeBoxMesh ( -size, -size, -size, size, size, size, texture )
end

local function makeICOSphereMesh( radius, subdivision, texture )
	subdivision = subdivision or 0
	local verts, indices = _icosphere( subdivision, radius )
	--no uv support yet
	local vbo = MOAIGfxBuffer.new ()
	vbo:setTarget ( MOAIGfxBuffer.VERTEX_BUFFER )
	local vertCount = #verts
	vbo:reserve( vertCount * vertexFormat:getVertexSize() )
	for i, v in ipairs( verts ) do
		vbo:writeFloat( v[1], v[2], v[3] ) --vertice
		vbo:writeFloat( 0, 0 ) --UV
		vbo:writeColor32( 1,1,1 )
	end
	local ibo = MOAIGfxBuffer.new()
	ibo:setTarget ( MOAIGfxBuffer.INDEX_BUFFER )
	local indiceCount = #indices
	local SIZE_U16 = 2
	ibo:reserve( indiceCount * SIZE_U16 )
	for i, idx in ipairs( indices ) do
		ibo:writeU16( idx - 1 )
	end

	local mesh = MOAIMesh.new()
	mesh:setVertexBuffer( vbo, vertexFormat	)
	mesh:setIndexBuffer( ibo )
	mesh:setTotalElements( indiceCount )
	local bounds = { vbo:computeBounds( vertexFormat ) }
	mesh:setBounds (  unpack( bounds ) )
	mesh:setPrimType( MOAIMesh.GL_TRIANGLES )
	mesh:setShader ( MOAIShaderMgr.getShader ( MOAIShaderMgr.MESH_SHADER ))
	return mesh
end

MeshHelper = {
	makeSkewBox       = makeSkewBoxMesh;
	makeBox           = makeBoxMesh;
	makeCube          = makeCubeMesh;
	makeICOSphere     = makeICOSphereMesh;
}


