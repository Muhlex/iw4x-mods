init()
{
	precacheShader("damage_feedback");
	precacheShader("damage_feedback_j");
	precacheShader("damage_feedback_endgame");
	precacheShader("scavenger_pickup");

	if (level.ttt.enabled && level.ttt.modEnabled)
		precacheShader("damage_feedback_headshot");

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);

		player.hud_damagefeedback = newClientHudElem(player);
		player.hud_damagefeedback.horzAlign = "center";
		player.hud_damagefeedback.vertAlign = "middle";
		player.hud_damagefeedback.x = -12;
		player.hud_damagefeedback.y = -12;
		player.hud_damagefeedback.alpha = 0;
		player.hud_damagefeedback.archived = true;
		player.hud_damagefeedback setShader("damage_feedback", 24, 48);
	}
}

updateDamageFeedback( typeHit )
{
	if ( !isPlayer( self ) )
		return;

	x = -12;
	y = -12;

	if ( getDvarInt( "camera_thirdPerson" ) )
		yOffset = self GetThirdPersonCrosshairOffset() * 240;
	else
		yOffset = getdvarfloat( "cg_crosshairVerticalOffset" ) * 240;

	if ( level.splitscreen )
		yOffset *= 0.5;

	feedbackDurationOverride = 0;
	startAlpha = 1;

	self.hud_damagefeedback.color = (1.0, 1.0, 1.0);

	if ( typeHit == "hitBodyArmor" )
	{
		self.hud_damagefeedback setShader("damage_feedback_j", 24, 48);
		self playlocalsound("MP_hit_alert"); // TODO: change sound?
	}
	else if ( typeHit == "hitEndGame" )
	{
		self.hud_damagefeedback setShader("damage_feedback_endgame", 24, 48);
		self playlocalsound("MP_hit_alert");
	}
	else if ( typeHit == "stun" )
	{
		return;
	}
	else if ( typeHit == "none" )
	{
		return;
	}
	else if ( typeHit == "scavenger" && !level.hardcoreMode )
	{
		x = -36;
		y = 32;
		self.hud_damagefeedback setShader("scavenger_pickup", 64, 32);
		feedbackDurationOverride = 2.5;
	}
	else if (typeHit == "ttt_item")
	{
		x = -9;
		y = -9;
		startAlpha = 0.65;
		self.hud_damagefeedback.color = (0.75, 0.75, 0.75);
		self.hud_damagefeedback setShader("damage_feedback", 18, 36);
		self playLocalSound("MP_hit_alert");
	}
	else if (typeHit == "ttt_headshot")
	{
		self playLocalSound("MP_hit_alert");

		if (level.ttt.enabled && level.ttt.modEnabled)
		{
			self.hud_damagefeedback setShader("damage_feedback_headshot", 24, 48);
			self playLocalSound("headshot_hit_feedback");
		}
		else
		{
			self.hud_damagefeedback.color = (1.0, 0.4, 0.4);
			self.hud_damagefeedback setShader("damage_feedback", 24, 48);
			for (i = 0; i < 3; i++) self playLocalSound("bullet_mega_flesh");
		}
	}
	else
	{
		self.hud_damagefeedback setShader("damage_feedback", 24, 48);
		self playlocalsound("MP_hit_alert");
	}

	self.hud_damagefeedback.alpha = startAlpha;
	if ( feedBackDurationOverride != 0 )
		self.hud_damagefeedback fadeOverTime(feedbackDurationOverride);
	else
		self.hud_damagefeedback fadeOverTime(1);

	self.hud_damagefeedback.alpha = 0;

	// only update hudelem positioning when necessary
	if ( self.hud_damagefeedback.x != x )
		self.hud_damagefeedback.x = x;

	y = y - int( yOffset );
	if ( self.hud_damagefeedback.y != y )
		self.hud_damagefeedback.y = y;
}
