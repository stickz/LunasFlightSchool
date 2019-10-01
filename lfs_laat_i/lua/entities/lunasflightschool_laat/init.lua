--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent.dOwnerEntLFS = ply
	ent:SetPos( tr.HitPos + tr.HitNormal * 50 )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:RunOnSpawn()
	self:GetDriverSeat().ExitPos = Vector(75,0,36)
	
	self:SetGunnerSeat( self:AddPassengerSeat( Vector(111.87,0,156), Angle(0,-90,0) ) )
	
	do
		local BallTurretPod = self:AddPassengerSeat( Vector(0,0,100), Angle(0,-90,0) )
		
		local ID = self:LookupAttachment( "muzzle_ballturret_left" )
		local Muzzle = self:GetAttachment( ID )
		
		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(0,-10,-45), Angle(180,0,-90), Muzzle.Pos, Muzzle.Ang )
			
			BallTurretPod:SetParent( NULL )
			BallTurretPod:SetPos( Pos )
			BallTurretPod:SetAngles( Ang )
			BallTurretPod:SetParent( self, ID )
			self:SetBTPodL( BallTurretPod )
		end
	end
	
	do
		local BallTurretPod = self:AddPassengerSeat( Vector(0,0,100), Angle(0,-90,0) )
		
		local ID = self:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = self:GetAttachment( ID )
		
		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(0,-10,-45), Angle(180,0,-90), Muzzle.Pos, Muzzle.Ang )
			
			BallTurretPod:SetParent( NULL )
			BallTurretPod:SetPos( Pos )
			BallTurretPod:SetAngles( Ang )
			BallTurretPod:SetParent( self, ID )
			self:SetBTPodR( BallTurretPod )
		end
	end
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() or not self:GetEngineActive() then return end

	local ID_L = self:LookupAttachment( "muzzle_frontgun_left" )
	local ID_R = self:LookupAttachment( "muzzle_frontgun_right" )
	local MuzzleL = self:GetAttachment( ID_L )
	local MuzzleR= self:GetAttachment( ID_R )
	
	if not MuzzleL or not MuzzleR then return end
	
	self:SetNextPrimary( 0.25 )
	
	self.MirrorPrimary = not self.MirrorPrimary
	
	if not isnumber( self.frontgunYaw ) then return end
	
	if math.abs( self.frontgunYaw ) > 90 then
		self:FireRearGun()
		
		return
	end
	
	if self.frontgunYaw > 5 and self.MirrorPrimary then return end
	if self.frontgunYaw < -5 and not self.MirrorPrimary then return end
	
	self:EmitSound( "LAATi_FIRE" )

	local Pos = self.MirrorPrimary and MuzzleL.Pos or MuzzleR.Pos
	local Dir =  (self.MirrorPrimary and MuzzleL.Ang or MuzzleR.Ang):Up()
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= Pos
	bullet.Dir 	= Dir
	bullet.Spread 	= Vector( 0.01,  0.01, 0 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_green"
	bullet.Force	= 100
	bullet.HullSize 	= 20
	bullet.Damage	= 125
	bullet.Attacker 	= self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
	end
	self:FireBullets( bullet )
	
	self:TakePrimaryAmmo()
end

function ENT:FireRearGun()
	local ID = self:LookupAttachment( "muzzle_reargun" )
	local Muzzle = self:GetAttachment( ID )
	
	if not Muzzle then return end
	
	self:SetNextPrimary( 0.35 )
	
	self:EmitSound( "LAATi_FIRE" )
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= Muzzle.Pos
	bullet.Dir 	= Muzzle.Ang:Up()
	bullet.Spread 	= Vector( 0.04,  0.04, 0 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_green"
	bullet.Force	= 100
	bullet.HullSize 	= 20
	bullet.Damage	= 125
	bullet.Attacker 	= self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
	end
	self:FireBullets( bullet )
	
	self:TakePrimaryAmmo()
end

function ENT:MainGunPoser( EyeAngles )
	local startpos =  self:GetRotorPos()
	local TracePlane = util.TraceHull( {
		start = startpos,
		endpos = (startpos + EyeAngles:Forward() * 50000),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = self
	} )
	
	local AimAngles = self:WorldToLocalAngles( (TracePlane.HitPos - self:LocalToWorld(  Vector(256,0,36) ) ):GetNormalized():Angle() )
	
	self.frontgunYaw = -AimAngles.y
	
	self:SetPoseParameter("frontgun_pitch", -AimAngles.p )
	self:SetPoseParameter("frontgun_yaw", -AimAngles.y )
	
	
	local Pos,Ang = WorldToLocal( Vector(0,0,0), (TracePlane.HitPos - self:LocalToWorld( Vector(-436,0,158.5)) ):GetNormalized():Angle(), Vector(0,0,0), self:LocalToWorldAngles( Angle(0,180,0) ) )
	
	if math.abs( self.frontgunYaw ) < 90 then Ang = Angle(30,0,0) end
	
	self:SetPoseParameter("reargun_pitch", -Ang.p )
	self:SetPoseParameter("reargun_yaw", -Ang.y )
end

function ENT:OnGravityModeChanged( b )
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:OnKeyThrottle( bPressed )
end

function ENT:OnEngineStarted()
	--self:EmitSound( "lfs/crysis_vtol/engine_start.wav" )
	
	local RotorWash = ents.Create( "env_rotorwash_emitter" )
	
	if IsValid( RotorWash ) then
		RotorWash:SetPos( self:LocalToWorld( Vector(50,0,0) ) )
		RotorWash:SetAngles( Angle(0,0,0) )
		RotorWash:Spawn()
		RotorWash:Activate()
		RotorWash:SetParent( self )
		
		RotorWash.DoNotDuplicate = true
		self:DeleteOnRemove( RotorWash )
		self:dOwner( RotorWash )
		
		self.RotorWashEnt = RotorWash
	end
end

function ENT:OnEngineStopped()
	--self:EmitSound( "lfs/crysis_vtol/engine_stop.wav" )
	
	if IsValid( self.RotorWashEnt ) then
		self.RotorWashEnt:Remove()
	end
	
	self:SetGravityMode( true )
end

function ENT:OnVtolMode( IsOn )
end

function ENT:OnLandingGearToggled( bOn )
	if self:GetAI() then return end

	if self:GetBodygroup( 2 ) == 0 then
		local DoorMode = self:GetDoorMode() + 1

		self:SetDoorMode( DoorMode )
		
		if DoorMode == 1 then
			self:EmitSound( "lfs/laat/door_open.wav" )
		end
		
		if DoorMode == 2 then
			self:PlayAnimation( "doors_open" )
			self:EmitSound( "lfs/laat/door_large_open.wav" )
		end
		
		if DoorMode == 3 then
			self:PlayAnimation( "doors_close" )
			self:EmitSound( "lfs/laat/door_large_close.wav" )
		end
		
		if DoorMode >= 4 then
			self:SetDoorMode( 0 )
			self:EmitSound( "lfs/laat/door_close.wav" )
		end
	else
		local DoorMode = self:GetDoorMode() + 1

		self:SetDoorMode( DoorMode )

		if DoorMode == 1 then
			self:PlayAnimation( "doors_open" )
			self:EmitSound( "lfs/laat/door_large_open.wav" )
		end
		
		if DoorMode >= 2 then
			self:PlayAnimation( "doors_close" )
			self:EmitSound( "lfs/laat/door_large_close.wav" )
			self:SetDoorMode( 0 )
		end
	end
end

function ENT:OnTick()
	do
		local DoorMode = self:GetDoorMode()
		local TargetValue = DoorMode >= 1 and 1 or 0
		self.SDsm = isnumber( self.SDsm ) and (self.SDsm + math.Clamp((TargetValue - self.SDsm) * 5,-1,2) * FrameTime() ) or 0
		self:SetPoseParameter("sidedoor_extentions", self.SDsm )
	end

	do
		local Pod = self:GetBTPodL()
		
		if IsValid( Pod ) then
			local ply = Pod:GetDriver()
			
			if ply ~= self:GetBTGunnerL() then
				self:SetBTGunnerL( ply )
			end
			
			if IsValid( ply ) then
				self:BallTurretL( ply, Pod )
				self:SetBTLFire( ply:KeyDown( IN_ATTACK ) )
			else
				self:SetBTLFire( false )
			end
		end
	end
	
	do
		local Pod = self:GetBTPodR()
		
		if IsValid( Pod ) then
			local ply = Pod:GetDriver()
			
			if ply ~= self:GetBTGunnerR() then
				self:SetBTGunnerR( ply )
			end
			
			if IsValid( ply ) then
				self:BallTurretR( ply, Pod )
				self:SetBTRFire( ply:KeyDown( IN_ATTACK ) )
			else
				self:SetBTRFire( false )
			end
		end
	end
	
	self:WingTurretsFire( self:GetGunner(), self:GetGunnerSeat() )
end

function ENT:BallTurretL( Driver, Pod )
	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	
	local _,LocalAng = WorldToLocal( Vector(0,0,0), EyeAngles, Vector(0,0,0), self:LocalToWorldAngles( Angle(0,90,0)  ) )

	self:SetPoseParameter("ballturret_left_pitch", LocalAng.p )
	self:SetPoseParameter("ballturret_left_yaw", LocalAng.y )
	
	if self:GetBTLFire() then
		local ID = self:LookupAttachment( "muzzle_ballturret_left" )
		local Muzzle = self:GetAttachment( ID )
		
		if Muzzle then
			local Dir = Muzzle.Ang:Up()
			local startpos = Muzzle.Pos
			
			local Trace = util.TraceLine( {
				start = startpos,
				endpos = (startpos + Dir * 50000),
			} )
			
			self:BallturretDamage( Trace.Entity, Driver )
		end
	end
end

function ENT:BallTurretR( Driver, Pod )
	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	
	local _,LocalAng = WorldToLocal( Vector(0,0,0), EyeAngles, Vector(0,0,0), self:LocalToWorldAngles( Angle(0,-90,0)  ) )

	self:SetPoseParameter("ballturret_right_pitch", LocalAng.p )
	self:SetPoseParameter("ballturret_right_yaw", -LocalAng.y )
	
	if self:GetBTRFire() then
		local ID = self:LookupAttachment( "muzzle_ballturret_right" )
		local Muzzle = self:GetAttachment( ID )
		
		if Muzzle then
			local Dir = Muzzle.Ang:Up()
			local startpos = Muzzle.Pos
			
			local Trace = util.TraceLine( {
				start = startpos,
				endpos = (startpos + Dir * 50000),
			} )
			
			self:BallturretDamage( Trace.Entity, Driver )
		end
	end
end

function ENT:WingTurretsFire( Driver, Pod )
	if not IsValid( Pod ) or not IsValid( Driver ) then self:SetWingTurretFire( false ) return end
	
	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	local KeyAttack = Driver:KeyDown( IN_ATTACK ) 
	
	if KeyAttack then
		local startpos = self:GetRotorPos() + EyeAngles:Up() * 250
		local TracePlane = util.TraceLine( {
			start = startpos,
			endpos = (startpos + EyeAngles:Forward() * 50000),
			filter = self
		} )
		self:SetWingTurretTarget( TracePlane.HitPos )
	end
	self:SetWingTurretFire( KeyAttack )
	
	
	local DesEndPos = self:GetWingTurretTarget()
	local DesStartPos = Vector(-172.97,334.04,93.25)
	for i = -1,1,2 do
		local StartPos = self:LocalToWorld( DesStartPos * Vector(1,i,1) )
		
		local Trace = util.TraceLine( { start = StartPos, endpos = DesEndPos} )
		local EndPos = Trace.HitPos
		
		if self.Entity:WorldToLocal( EndPos ).z < 0 then
			DesStartPos = Vector(-172.97,334.04,93.25)
		else
			DesStartPos = Vector(-174.79,350.05,125.98)
		end
		
		self:BallturretDamage( Trace.Entity, Driver )
	end
end

function ENT:BallturretDamage( target, attacker )
	if not IsValid( target ) or not IsValid( attacker ) then return end

	if target ~= self then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( 1000 * FrameTime() )
		dmginfo:SetAttacker( attacker )
		dmginfo:SetDamageType( DMG_ENERGYBEAM )
		dmginfo:SetInflictor( self ) 
		target:TakeDamageInfo( dmginfo )
	end
end

function ENT:HitGround()
	local tr = util.TraceLine( {
		start = self:LocalToWorld( Vector(0,0,100) ),
		endpos = self:LocalToWorld( Vector(0,0,-20) ),
		filter = function( ent ) 
			if ( ent == self ) then 
				return false
			end
		end
	} )
	
	return tr.Hit 
end