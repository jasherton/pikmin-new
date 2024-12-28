/*Modified GMDM death soul effect*/

local matSoul 	= Material( "pikmin/death_soul" )

/*---------------------------------------------------------
   Initializes the effect. The data is a table of data 
   which was passed from the server.
---------------------------------------------------------*/
function EFFECT:Init( data )

	// Keep the start and end pos - we're going to interpolate between them
	local NumParticles = 0
	local Pos = data:GetOrigin()
	self.color = data:GetStart();
		
	local emitter = ParticleEmitter( Pos )
	
			local particle = emitter:Add( "sprites/light_ignorez", Pos )
				particle:SetDieTime( 0.5 )
				particle:SetStartAlpha( 250 )
				particle:SetEndAlpha( 250 )
				particle:SetStartSize( 32 )
				particle:SetEndSize( 0 )
				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -5.5, 5.5 ) )
				particle:SetColor(Color( self.color.r, self.color.g, self.color.b ))
				
	emitter:Finish()
	
	self.Alpha = 255
	self.Speed = Vector( 0, 0, math.Rand( 16, 24 ) )
	self.Size = math.Rand( 1, 2 )
	self.SpawnTime = CurTime() + math.Rand( 0, 2 )
	self.Scale = 2
	
	self.Entity:SetCollisionBounds( Vector( -32, -32, -64 ), Vector( 32, 32, 64 ) )
	
	if ( data:GetEntity() == LocalPlayer() ) then
		ColorModify[ "$pp_colour_addb" ] = ColorModify[ "$pp_colour_addb" ] + 0.4	
	end
	
end


/*---------------------------------------------------------
   THINK
   Returning false makes the entity die
---------------------------------------------------------*/
function EFFECT:Think( )

	self.Alpha = self.Alpha - 1
	self.Entity:SetPos( self.Entity:GetPos() + self.Speed * FrameTime() )
	
	if ( self.Alpha <= 0 ) then return false end
	
	return true
	
end


/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()

	render.SetMaterial( matSoul )
	local Pos = self.Entity:GetPos()
	local EyeNormal = (EyePos() - Pos):GetNormal()
	EyeNormal:Mul( self.Scale )	
	EyeNormal.z = 0
	
	local Rot = 180 + math.sin( (self.SpawnTime + CurTime()) * 2 ) * 10
	
	Pos = Pos + EyeAngles():Right() * math.cos( (self.SpawnTime + CurTime()) * 2 ) * 4 * self.Scale
	
	local r = math.Clamp((self.color.r * 2.25), 0, 255);
	local g = math.Clamp((self.color.g * 2.25), 0, 255);
	local b = math.Clamp((self.color.b * 2.25), 0, 255);
	
	render.DrawQuadEasy( Pos, EyeNormal, 18, 36, Color( r, g, b, self.Alpha ), Rot )
end
