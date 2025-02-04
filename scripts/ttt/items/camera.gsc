#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include scripts\ttt\_util;

init()
{
	precacheShader("nightvision_overlay_goggles");
	precacheShader("compassping_enemy");

	camera = spawnStruct();
	camera.name = "CAMERA";
	camera.description = "^3Deployable Active Item\n^7Place on walls to ^2remotely observe an\narea^7. Equip the receiver once placed.\n\nPress [ ^3[{+actionslot 3}]^7 ] to equip.";
	camera.activateHint = &"Press [ ^3[{+attack}]^7 ] ^3on a wall ^7to place the camera";
	camera.icon = "cardicon_binoculars_1";
	camera.onBuy = ::OnBuyCamera;
	camera.onEquip = ::OnEquipCamera;
	camera.onUnequip = ::OnUnequipCamera;
	camera.onActivate = ::OnActivateCamera;
	camera.getIsAvailable = scripts\ttt\items::getIsAvailableRoleItem;
	camera.unavailableHint = scripts\ttt\items::getUnavailableHint("roleitem");
	camera.weaponName = "onemanarmy_mp";
	if (level.ttt.modEnabled) camera.weaponName = "oma_camera_mp";

	receiver = spawnStruct();
	receiver.name = "CAMERA RECEIVER";
	receiver.onBuy = ::OnBuyReceiver;
	receiver.onEquip = ::OnEquipReceiver;
	receiver.onStartUnequip = ::OnStartUnequipReceiver;
	receiver.onUnequip = ::OnUnequipReceiver;
	receiver.weaponName = "killstreak_ac130_mp";
	receiver.role = "detective";

	scripts\ttt\items::registerItem(camera, "detective");
	scripts\ttt\items::registerItem(receiver, undefined, "camera_receiver");
}

OnBuyCamera(item)
{
	self scripts\ttt\items::setRoleInventory(item);
}

OnEquipCamera(item, data)
{
	cameraEnt = spawn("script_model", self.origin);
	cameraEnt notSolid();
	cameraEnt hide();
	cameraEnt showToPlayer(self);
	cameraEnt.placed = false;
	cameraEnt.validPosition = false;
	data.cameraEnt = cameraEnt;

	if (level.ttt.modEnabled) cameraEnt scriptModelPlayAnim("security_camera_idle");

	self thread cameraPlacementThink(cameraEnt);
}

cameraPlacementThink(cameraEnt)
{
	self endon("disconnect");
	self endon("death");
	self endon("ttt_camera_placed");
	self endon("ttt_roleweapon_unequipped");

	for (i = 0; ; i++)
	{
		eyePos = self getEye();
		forward = anglesToForward(self getPlayerAngles());

		trace = bulletTrace(eyePos, eyePos + forward * 128, false, cameraEnt);
		normal = trace["normal"];
		position = trace["position"];
		if (!level.ttt.modEnabled) position += normal * 1.6;

		// If a surface is hit, flip the normal to have the correct orientation:
		if (trace["fraction"] == 1.0) normal *= -1;
		surfaceAngle = vectorToAngles(normal)[0];

		if (trace["fraction"] < 1.0 && (surfaceAngle < 40 || surfaceAngle > 360 - 40))
		{
			cameraEnt.validPosition = true;

			if (level.ttt.modEnabled)
				cameraEnt setModel("com_security_camera_tilt_animated");
			else
				cameraEnt setModel("weapon_c4");
		}
		else
		{
			cameraEnt.validPosition = false;

			if (level.ttt.modEnabled)
				cameraEnt setModel("com_security_camera_tilt_animated_bombsquad");
			else
				cameraEnt setModel("weapon_c4_bombsquad");
		}

		angles = vectorToAngles(normal);
		if (level.ttt.modEnabled)
			angles = combineAngles(angles, (0, 90, 0));
		else
			angles = combineAngles(angles, (90, 0, 0));

		if (i == 0)
		{
			cameraEnt.origin = position;
			cameraEnt.angles = angles;
		}
		else
		{
			cameraEnt moveTo(position, 0.05);
			cameraEnt rotateTo(angles, 0.05);
		}

		wait(0.05);

		cameraEnt.origin = position;
		cameraEnt.angles = angles;
	}
}

OnUnequipCamera(item, data)
{
	if (!isDefined(data.cameraEnt.placed) || !data.cameraEnt.placed) data.cameraEnt delete();
}

OnActivateCamera(item, data)
{
	cameraEnt = data.cameraEnt;
	if (cameraEnt.placed) return;

	if (!isDefined(cameraEnt.validPosition) || !cameraEnt.validPosition)
	{
		self iPrintLnBold("Camera needs to be placed on a wall");
		return;
	}

	cameraEnt.placed = true;

	angles = cameraEnt.angles;
	if (level.ttt.modEnabled)
		angles = combineAngles(angles, (0, -90, 0));
	else
		angles = combineAngles(angles, (-90, 0, 0));
	cameraEnt.viewTargetEnt = spawn("script_model", cameraEnt.origin + anglesToForward(angles) * 32 + anglesToUp(angles) * -48);
	cameraEnt.viewTargetEnt.angles = angles;
	cameraEnt.viewTargetEnt setModel("sentry_minigun");
	cameraEnt.viewTargetEnt linkTo(cameraEnt);
	cameraEnt.viewTargetEnt hide();

	offset = (-3.5, 2, -3);
	if (level.ttt.modEnabled) offset = (-0.5, 7, 0.75);
	cameraEnt.fxTargetIdle = spawn(
		"script_model",
		cameraEnt.origin + anglesToRight(angles) * offset[0] + anglesToForward(angles) * offset[1] + anglesToUp(angles) * offset[2]
	);
	cameraEnt.fxTargetIdle setModel("tag_origin");
	cameraEnt.fxTargetIdle linkTo(cameraEnt);
	// It's necessary to wait for the entity to be networked to players or something.
	// Waiting a single tick isn't always enough:
	thread playFxOnTagDelayed(level.ttt.effects.cameraIdle, cameraEnt.fxTargetIdle, "tag_origin", 0.25);

	cameraEnt.fxTargetActive = spawn(
		"script_model",
		cameraEnt.fxTargetIdle.origin + anglesToRight(angles) * 2.5
	);
	cameraEnt.fxTargetActive setModel("tag_origin");
	cameraEnt.fxTargetActive linkTo(cameraEnt);

	cameraEnt.targetname = "ttt_destructible_item";
	cameraEnt solid();
	cameraEnt setCanDamage(true);
	cameraEnt.maxhealth = 300;
	cameraEnt.health = cameraEnt.maxhealth;
	cameraEnt.damageTaken = 0;
	cameraEnt.destroyed = false;
	cameraEnt.usingPlayer = undefined;
	cameraEnt thread OnCameraDamage();
	cameraEnt thread OnCameraDeath(data);

	self notify("ttt_camera_placed");
	cameraEnt show();

	self scripts\ttt\items::takeRoleWeapon();
	self switchToLastWeapon();
	self scripts\ttt\items::resetRoleInventory();

	receiverData = spawnStruct();
	receiverData.beingUsed = false;
	receiverData.cameraEnt = cameraEnt;
	self scripts\ttt\items::giveItem(level.ttt.items["internal"]["camera_receiver"], receiverData);
}

OnCameraDamage()
{
	self endon("death");

	for (;;)
	{
		self waittill("damage", damage, attacker);

		self.damageTaken += damage;

		attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback("ttt_item");
		playFX(level._effect["sentry_smoke_mp"], self.origin);
		self playSound("bullet_ap_crate");

		if (self.damageTaken > self.maxhealth) self notify("death");
	}
}

OnCameraDeath(data)
{
	self waittill("death", attacker);

	self.destroyed = true;

	attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback("ttt_item");
	self.viewTargetEnt delete(); // automatically disconnects the player's view
	self.fxTargetIdle delete();
	self.fxTargetActive delete();

	self notify("destroyed");

	if (level.ttt.modEnabled)
	{
		self scriptModelClearAnim();
		self setModel("com_security_camera_d_tilt_animated");
		self scriptModelPlayAnim("security_camera_destroy");
		self playSound("security_camera_sparks");
		thread playFxOnTagDelayed(level.ttt.effects.cameraExplosion, self, "tag_fx", 0.1);
	}
	else
	{
		self playSound("sentry_explode");
		playFX(level._effect["sentry_explode_mp"], self.origin);

		wait(4);

		self delete();
	}
}

OnBuyReceiver(item, data)
{
	self scripts\ttt\items::setRoleInventory(item, 1, 0, data);
}

OnEquipReceiver(item, data)
{
	self endon("disconnect");
	self endon("death");
	self endon("ttt_roleweapon_unequipped");
	self endon("ttt_cam_receiver_unequip_started");

	self scripts\ttt\ui::destroySelfHud();

	wait (1.1);

	self thread trySetPlayerToCamera(data);
	self thread OnCamReceiverEsc(data);
}

OnCamReceiverEsc(data)
{
	self endon("ttt_roleweapon_unequipped");

	for (;;)
	{
		self waittill("menuresponse", menu, response);
		if (response != "ttt_esc_menu_blocked") continue;

		self notify("ttt_roleweapon_toggle");
		break;
	}
}

OnStartUnequipReceiver(item, data, switchToWeaponName)
{
	if (switchToWeaponName == "none") return;

	self thread tryUnsetPlayerFromCamera(data);
	self notify("ttt_cam_receiver_unequip_started");
}

OnUnequipReceiver(item, data)
{
	if (isAlive(self))
	{
		self scripts\ttt\ui::destroySelfHud();
		self scripts\ttt\ui::displaySelfHud();
	}
	self thread tryUnsetPlayerFromCamera(data);

	if (self getCurrentWeapon() == "none") self switchToLastWeapon();
}

trySetPlayerToCamera(data)
{
	if (data.beingUsed) return;
	data.beingUsed = true;

	cameraEnt = data.cameraEnt;
	cameraValid = isDefined(cameraEnt) && !cameraEnt.destroyed;

	if (cameraValid) cameraEnt.usingPlayer = self;
	self.ttt.use.canUse = false;
	self.ttt.pickups.canDropWeapons = false;
	self setClientDvar("ui_ttt_block_esc_menu", true);

	if (cameraValid)
		playFxOnTag(level.ttt.effects.cameraActive, cameraEnt.fxTargetActive, "tag_origin");

	self visionSetNakedForPlayer("black_bw", 0.25);

	wait(0.25);

	// Camera view could have been unset in the meantime, so don't continue in that case:
	if (!data.beingUsed) return;

	self visionSetThermalForPlayer("black_bw", 0);
	self visionSetThermalForPlayer(game["thermal_vision"], 0.25);
	self thermalVisionOn();
	self visionSetNakedForPlayer(getDvar("mapname"), 0);

	/**
	 * The killstreak weapons have very low a ADS FoV of 26. When the player's view is linked to
	 * an external entity, the ADS FoV of the current weapon is used. To increase and customize the
	 * FoV, the min FoV on the client is forced with this dvar:
	 */
	self setClientDvar("cg_fovMin", 60);

	self _disableOffhandWeapons();
	self displayCameraHud(cameraEnt);

	if (cameraValid)
	{
		self playerLinkWeaponviewToDelta(cameraEnt.viewTargetEnt, "tag_player", 1.0, 60, 60, 25, 25);
		self setPlayerAngles(cameraEnt.viewTargetEnt.angles);
	}
}

tryUnsetPlayerFromCamera(data)
{
	if (!data.beingUsed) return;
	data.beingUsed = false;

	cameraEnt = data.cameraEnt;
	cameraValid = isDefined(cameraEnt) && !cameraEnt.destroyed;

	if (cameraValid) cameraEnt.usingPlayer = undefined;
	self setClientDvar("ui_ttt_block_esc_menu", false);

	stopFxOnTag(level.ttt.effects.cameraActive, cameraEnt.fxTargetActive, "tag_origin");

	if (isAlive(self))
	{
		self visionSetThermalForPlayer("black_bw", 0.25);

		wait (0.25);
	}

	self.ttt.use.canUse = true;
	self.ttt.pickups.canDropWeapons = true;

	self visionSetNakedForPlayer("black_bw", 0);
	self visionSetNakedForPlayer(getDvar("mapname"), 0.25);
	self thermalVisionOff();
	self visionSetThermalForPlayer(game["thermal_vision"], 0);

	self setClientDvar("cg_fovMin", 1);

	self _enableOffhandWeapons();
	self unlink();
	self destroyCameraHud();
}

displayCameraHud(cameraEnt)
{
	destroyed = !isDefined(cameraEnt) || cameraEnt.destroyed;

	self.ttt.ui["hud"]["self"]["camera"] = [];

	self.ttt.ui["hud"]["self"]["camera"]["static"] = newClientHudElem(self);
	self.ttt.ui["hud"]["self"]["camera"]["static"].horzAlign = "fullscreen";
	self.ttt.ui["hud"]["self"]["camera"]["static"].vertAlign = "fullscreen";
	self.ttt.ui["hud"]["self"]["camera"]["static"] setShader("ac130_overlay_grain", 640, 480);
	self.ttt.ui["hud"]["self"]["camera"]["static"].sort = 1;
	self.ttt.ui["hud"]["self"]["camera"]["static"].alpha = 0.4;

	if (destroyed)
	{
		self.ttt.ui["hud"]["self"]["camera"]["static"].alpha = 1.0;

		self.ttt.ui["hud"]["self"]["camera"]["white"] = newClientHudElem(self);
		self.ttt.ui["hud"]["self"]["camera"]["white"].horzAlign = "fullscreen";
		self.ttt.ui["hud"]["self"]["camera"]["white"].vertAlign = "fullscreen";
		self.ttt.ui["hud"]["self"]["camera"]["white"] setShader("black", 640, 480);
		self.ttt.ui["hud"]["self"]["camera"]["white"].alpha = 0.5;

		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"] = self createFontString("objective", 3);
		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"] setPoint("CENTER", "CENTER", 0, 0);
		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"].label = &"NO SIGNAL ...";
		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"].glowColor = (0.4, 0.45, 0.8);
		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"].glowAlpha = 1;
		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"].sort = 5;
		self.ttt.ui["hud"]["self"]["camera"]["nosignal_text"].hidewheninmenu = true;
	}
	else
	{
		self.ttt.ui["hud"]["self"]["camera"]["overlay"] = newClientHudElem(self);
		self.ttt.ui["hud"]["self"]["camera"]["overlay"].horzAlign = "fullscreen";
		self.ttt.ui["hud"]["self"]["camera"]["overlay"].vertAlign = "fullscreen";
		self.ttt.ui["hud"]["self"]["camera"]["overlay"] setShader("nightvision_overlay_goggles", 640, 480);
		self.ttt.ui["hud"]["self"]["camera"]["overlay"].alpha = 1.0;

		self.ttt.ui["hud"]["self"]["camera"]["live_dot"] = self createIcon("compassping_enemy", 40, 40);
		self.ttt.ui["hud"]["self"]["camera"]["live_dot"].color = (1.0, 0.5, 0.5);
		self.ttt.ui["hud"]["self"]["camera"]["live_dot"] setPoint("TOP LEFT", "TOP LEFT", 16, 16);
		self.ttt.ui["hud"]["self"]["camera"]["live_dot"].sort = 5;
		self.ttt.ui["hud"]["self"]["camera"]["live_dot"].hidewheninmenu = true;

		self.ttt.ui["hud"]["self"]["camera"]["live_text"] = self createFontString("objective", 1.5);
		self.ttt.ui["hud"]["self"]["camera"]["live_text"] setParent(self.ttt.ui["hud"]["self"]["camera"]["live_dot"]);
		self.ttt.ui["hud"]["self"]["camera"]["live_text"] setPoint("CENTER LEFT", "CENTER RIGHT", -2, -1.5);
		self.ttt.ui["hud"]["self"]["camera"]["live_text"].label = &"LIVE";
		self.ttt.ui["hud"]["self"]["camera"]["live_text"].glowColor = (0.7, 0.7, 0.7);
		self.ttt.ui["hud"]["self"]["camera"]["live_text"].glowAlpha = 1;
		self.ttt.ui["hud"]["self"]["camera"]["live_text"].sort = 5;
		self.ttt.ui["hud"]["self"]["camera"]["live_text"].hidewheninmenu = true;

		self.ttt.ui["hud"]["self"]["camera"]["time"] = [];

		self.ttt.ui["hud"]["self"]["camera"]["time"]["h"] = self createFontString("objective", 1.5);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["h"] setPoint("BOTTOM CENTER", "BOTTOM LEFT", 28, -24);

		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_1"] = self createFontString("objective", 1.5);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_1"] setParent(self.ttt.ui["hud"]["self"]["camera"]["time"]["h"]);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_1"] setPoint("CENTER", "CENTER", 14, 0);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_1"].label = &":";

		self.ttt.ui["hud"]["self"]["camera"]["time"]["m"] = self createFontString("objective", 1.5);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["m"] setPoint("CENTER", "CENTER", 14, 0);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["m"] setParent(self.ttt.ui["hud"]["self"]["camera"]["time"]["col_1"]);

		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_2"] = self createFontString("objective", 1.5);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_2"] setParent(self.ttt.ui["hud"]["self"]["camera"]["time"]["m"]);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_2"] setPoint("CENTER", "CENTER", 14, 0);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["col_2"].label = &":";

		self.ttt.ui["hud"]["self"]["camera"]["time"]["s"] = self createFontString("objective", 1.5);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["s"] setParent(self.ttt.ui["hud"]["self"]["camera"]["time"]["col_2"]);
		self.ttt.ui["hud"]["self"]["camera"]["time"]["s"] setPoint("CENTER", "CENTER", 14, 0);

		foreach (timeEl in self.ttt.ui["hud"]["self"]["camera"]["time"])
		{
			timeEl.glowColor = (0.7, 0.7, 0.7);
			timeEl.glowAlpha = 1;
			timeEl.sort = 5;
			timeEl.hidewheninmenu = true;
		}

		self thread cameraHudThink(cameraEnt);
		self thread OnPlayerCameraDestroyed(cameraEnt);
	}
}

cameraHudThink(cameraEnt)
{
	self endon("disconnect");
	self endon("death");
	self endon("ttt_ui_camera_hud_destroyed");

	for (;;)
	{
		hms = secsToHMS((getTime() - cameraEnt.birthtime) / 1000);

		foreach (key, value in hms)
		{
			self.ttt.ui["hud"]["self"]["camera"]["time"][key] setValue(value);
			if (value < 10)
				self.ttt.ui["hud"]["self"]["camera"]["time"][key].label = &"0";
			else
				self.ttt.ui["hud"]["self"]["camera"]["time"][key].label = &"";
		}

		wait(0.5);
		self.ttt.ui["hud"]["self"]["camera"]["live_dot"].alpha = 0.0;

		wait(0.5);
		self.ttt.ui["hud"]["self"]["camera"]["live_dot"].alpha = 1.0;
	}
}

OnPlayerCameraDestroyed(cameraEnt)
{
	self endon("ttt_ui_camera_hud_destroyed");

	cameraEnt waittill("destroyed");

	self thread restartCameraHud(cameraEnt);
}

restartCameraHud(cameraEnt)
{
	self destroyCameraHud();
	self displayCameraHud(cameraEnt);
}

destroyCameraHud(cameraEnt)
{
	recursivelyDestroyElements(self.ttt.ui["hud"]["self"]["camera"]);
	self notify("ttt_ui_camera_hud_destroyed");
}
