function EFFECT:Init(data)
	local vOffset = data:GetOrigin()
	local Color = data:GetStart()
	local emitter = ParticleEmitter(vOffset, true)
	
	for i=1,60 do
		local Pos = Vector( math.Rand(-1,1), math.Rand(-1,1), math.Rand(-1,1) )
		local particle = emitter:Add( "pikmin/glow", vOffset + Pos * 8 )
		if particle then
			particle:SetVelocity( Pos * 110 ) 

			particle:SetLifeTime( 0 )
			particle:SetDieTime( 10 )
			
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			
			local Size = math.Rand( 2, 5 )
			particle:SetStartSize( Size )
			particle:SetEndSize( 0 )
			
			particle:SetRoll( math.Rand(0, 360) )
			particle:SetRollDelta( math.Rand(-2, 2) )
			
			particle:SetAirResistance( 750 )
			particle:SetGravity( Vector(0,0,225) )
			
			particle:SetColor(Color.r,Color.g,Color.b)
			
			particle:SetCollide( true )
			
			particle:SetAngleVelocity( Angle( math.Rand( -50, 50 ), math.Rand( -50, 50 ), math.Rand( -50, 50 ) ) )
			
			particle:SetBounce( 1 )
			particle:SetLighting( true )
		end
	end
	emitter:Finish()
end

function EFFECT:Think() return false end
function EFFECT:Render() end