#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include scripts\ttt\_util;

init()
{
	precacheShader("cardicon_vest_1");
	precacheShader("hud_suitcase_bomb");

	precacheShader("cardicon_comic_shepherd");
	precacheShader("cardtitle_silencer");

	level.ttt.ui = [];
	level.ttt.ui["hud"] = [];

	level.ttt.colors["preparing"] = (0.5, 0.5, 0.5);
	level.ttt.colors["innocent"] = (0.4, 0.75, 0); // exact ^2 color code is (0.52, 0.75, 0)
	level.ttt.colors["detective"] = (0.0, 0.52, 0.64);
	level.ttt.colors["traitor"] = (1.0, 0.19, 0.19);
	level.ttt.colorsScoreboard["innocent"] = (1.0, 1.0, 1.0);
	level.ttt.colorsScoreboard["detective"] = (0.45, 0.8, 1.0);
	level.ttt.colorsScoreboard["traitor"] = (1.0, 0.45, 0.45);
	level.ttt.colorsScoreboard["self"] = (0.5, 0.5, 0.5);
	level.ttt.colorsBuyMenu["item_bg"] = (0.35, 0.35, 0.35);
	level.ttt.colorsBuyMenu["item_selected"] = (1.0, 0.84, 0.68);
	level.ttt.colorsBuyMenu["traitor"] = (0.2, 0.0, 0.0);
	level.ttt.colorsBuyMenu["detective"] = (0.0, 0.05, 0.2);

	level.ttt.buyMenu["columns"] = 3;
	level.ttt.buyMenu["padding"] = 4;
	level.ttt.buyMenu["desc_width"] = 140;
}

initPlayer()
{
	self.ttt.ui = [];
	self.ttt.ui["hud"] = [];
	self.ttt.ui["hud"]["self"] = [];
}

displaySelfHud()
{
	self.ttt.ui["hud"]["self"]["role"] = self createFontString("hudbig", 0.8);
	self.ttt.ui["hud"]["self"]["role"] setPoint("TOP RIGHT", "TOP RIGHT", -20, 10);
	self.ttt.ui["hud"]["self"]["role"].hidewheninmenu = true;
	self.ttt.ui["hud"]["self"]["role"].foreground = true;
	self.ttt.ui["hud"]["self"]["role"].color = (1, 1, 1);
	self.ttt.ui["hud"]["self"]["role"].glowAlpha = 1;

	self.ttt.ui["hud"]["self"]["health"] = self createFontString("hudbig", 1.0625);
	self.ttt.ui["hud"]["self"]["health"] setPoint("BOTTOM CENTER", "BOTTOM RIGHT", -46, -33);
	self.ttt.ui["hud"]["self"]["health"].hidewheninmenu = true;
	self.ttt.ui["hud"]["self"]["health"].foreground = true;
	self.ttt.ui["hud"]["self"]["health"].glowAlpha = 1;
	self.ttt.ui["hud"]["self"]["health"].label = &"";

	self.ttt.ui["hud"]["self"]["armor"] = self createIcon("cardicon_vest_1", 16, 16);
	self.ttt.ui["hud"]["self"]["armor"] setPoint("BOTTOM RIGHT", "BOTTOM RIGHT", -126, -15);
	self.ttt.ui["hud"]["self"]["armor"].hidewheninmenu = true;
	self.ttt.ui["hud"]["self"]["armor"].alpha = isInArray(self.ttt.items.boughtItems, level.ttt.items["traitor"][0]);

	self displayBombHud();

	self updatePlayerRoleDisplay();
	self updatePlayerHealthDisplay();
	self updatePlayerArmorDisplay();
}

destroySelfHud()
{
	recursivelyDestroyElements(self.ttt.ui["hud"]["self"]);
}

updatePlayerHealthDisplay()
{
	if (!isDefined(self.ttt.ui["hud"]["self"]["health"])) return;

	text = "";
	if (isAlive(self))
	{
		// use cached maxhealth, because disabling health regen messes with the value
		healthPct = self.health / level.ttt.maxhealth;
		healthProxToHalf = (1 - abs(healthPct - 0.5)) * 2;
		healthGlowAlpha = (1 - healthPct + 0.75) * 0.35;

		self.ttt.ui["hud"]["self"]["health"].color = (
			(1 - healthPct) + healthProxToHalf * 0.5,
			healthPct + healthProxToHalf * 0.5,
			0.5
		);
		self.ttt.ui["hud"]["self"]["health"].glowColor = (
			((1 - healthPct) * 0.6 + healthProxToHalf) * healthGlowAlpha,
			(healthPct * 0.6 + healthProxToHalf) * healthGlowAlpha,
			healthGlowAlpha
		);
	}
	self.ttt.ui["hud"]["self"]["health"] setValue(self.health);
}

updatePlayerArmorDisplay()
{
	if (!isDefined(self.ttt.ui["hud"]["self"]["armor"])) return;

	self.ttt.ui["hud"]["self"]["armor"].alpha = isInArray(self.ttt.items.boughtItems, level.ttt.items["traitor"][0]);
}

updatePlayerRoleDisplay()
{
	role = self.ttt.role;

	text = "";
	if (!isDefined(role))
	{
		role = "preparing";
		text = "PREPARING";
	}
	else if (role == "innocent") text = "INNOCENT";
	else if (role == "detective") text = "DETECTIVE";
	else if (role == "traitor") text = "TRAITOR";
	self.ttt.ui["hud"]["self"]["role"].glowColor = level.ttt.colors[role];
	self.ttt.ui["hud"]["self"]["role"] setText(text);

	if ((role == "traitor" || role == "detective") && !isDefined(self.ttt.ui["hud"]["self"]["shop_hint"]))
	{
		self.ttt.ui["hud"]["self"]["shop_hint"] = self createFontString("default", 0.8);
		self.ttt.ui["hud"]["self"]["shop_hint"] setParent(self.ttt.ui["hud"]["self"]["role"]);
		self.ttt.ui["hud"]["self"]["shop_hint"] setPoint("TOP RIGHT", "BOTTOM RIGHT", 0, 10);
		self.ttt.ui["hud"]["self"]["shop_hint"].color = (1, 1, 1);
		self.ttt.ui["hud"]["self"]["shop_hint"].alpha = 0.5;
		self.ttt.ui["hud"]["self"]["shop_hint"].archived = false;
		self.ttt.ui["hud"]["self"]["shop_hint"].hidewheninmenu = true;
		self.ttt.ui["hud"]["self"]["shop_hint"].label = &"Press ^3[{+actionslot 2}]^7 to open shop";
	}
}

pulsePlayerRoleDisplay(duration)
{
	self.ttt.ui["hud"]["self"]["role"] thread scripts\ttt\_util::fontPulseCustom(self, 2.0, duration);
}

displayUseAvailableHint(label, text, value)
{
	self.ttt.ui["hud"]["self"]["use_hint"] = [];
	self.ttt.ui["hud"]["self"]["use_hint"]["text"] = self createFontString("default", 1.5);
	self.ttt.ui["hud"]["self"]["use_hint"]["text"] setPoint("BOTTOM CENTER", "BOTTOM CENTER", 0, -120);
	self.ttt.ui["hud"]["self"]["use_hint"]["text"].color = (1, 1, 1);
	self.ttt.ui["hud"]["self"]["use_hint"]["text"].alpha = 0.85;
	self.ttt.ui["hud"]["self"]["use_hint"]["text"].archived = false;
	self.ttt.ui["hud"]["self"]["use_hint"]["text"].hidewheninmenu = true;
	updateUseAvailableHint(label, text, value);
}

updateUseAvailableHint(label, text, value)
{
	if (isDefined(label)) self.ttt.ui["hud"]["self"]["use_hint"]["text"].label = label;
	if (isDefined(text)) self.ttt.ui["hud"]["self"]["use_hint"]["text"] setText(text);
	if (isDefined(value)) self.ttt.ui["hud"]["self"]["use_hint"]["text"] setValue(value);
}

destroyUseAvailableHint()
{
	recursivelyDestroyElements(self.ttt.ui["hud"]["self"]["use_hint"]);
}

setupHeadIconAnchor()
{
	TAG = "j_head";

	headPos = self getTagOrigin(TAG);
	headAngles = self getTagAngles(TAG);

	iconPos = headPos;
	iconPos += anglesToForward(headAngles) * 20.0;
	iconPos += anglesToRight(headAngles) * 4.0;
	iconAnchor = spawn("script_model", iconPos);
	iconAnchor linkTo(self, TAG);
	self.headiconAnchor = iconAnchor;
	self thread OnHeadIconAnchorDestroy();
}

OnHeadIconAnchorDestroy()
{
	self waittill_any("disconnect", "death");

	self.headiconAnchor delete();
}

displayHeadIcons()
{
	self.ttt.ui["hud"]["headicons"] = [];

	foreach (target in getLivingPlayers())
	{
		if (self == target) continue;

		if (self.ttt.role == "traitor" && target.ttt.role == "traitor")
			self displayHeadIconOnPlayer(target, game["entity_headicon_axis"]);
		if (target.ttt.role == "detective")
			self displayHeadIconOnPlayer(target, game["entity_headicon_allies"]);
	}
}

destroyHeadIcons()
{
	recursivelyDestroyElements(self.ttt.ui["hud"]["headicons"]);
}

displayHeadIconOnPlayer(target, image)
{
	i = self.ttt.ui["hud"]["headicons"].size;

	self.ttt.ui["hud"]["headicons"][i] = newClientHudElem(self);
	self.ttt.ui["hud"]["headicons"][i] setShader(image, 8, 8);
	self.ttt.ui["hud"]["headicons"][i].color = level.ttt.colors[target.ttt.role];
	self.ttt.ui["hud"]["headicons"][i].alpha = 0.75;
	self.ttt.ui["hud"]["headicons"][i] setWaypoint(false, false);
	self.ttt.ui["hud"]["headicons"][i] setTargetEnt(target.headiconAnchor);
	self.ttt.ui["hud"]["headicons"][i] thread OnHeadIconDestroy(self, target);
}

OnHeadIconDestroy(showToPlayer, target)
{
	//self endon("death"); // apparently this always fires instantly
	showToPlayer endon("disconnect");

	target waittill_any("death", "disconnect");
	self destroy();
}

displayRoundEnd(winner, reason)
{
	winnerText = "";
	reasonText = "";
	if (winner == "traitor") winnerText = "THE TRAITORS WIN";
	else winnerText = "THE INNOCENT WIN";

	switch (reason)
	{
		case "death":
			if (winner == "traitor") reasonText = "All innocent players are dead";
			else reasonText = "All traitors have been killed";
			break;
		case "timelimit":
			reasonText = "Time is up";
			break;
	}

	level.ttt.ui["hud"]["outcome"] = [];

	level.ttt.ui["hud"]["outcome"]["bg"] = createRectangle(1000, 80, (0, 0, 0), true);
	level.ttt.ui["hud"]["outcome"]["bg"] setPoint("TOP CENTER", "TOP CENTER", 0, 40);
	level.ttt.ui["hud"]["outcome"]["bg"].archived = false;
	level.ttt.ui["hud"]["outcome"]["bg"].hidewheninmenu = true;
	level.ttt.ui["hud"]["outcome"]["bg"].alpha = 0.35;
	level.ttt.ui["hud"]["outcome"]["bg"].sort = -1;

	level.ttt.ui["hud"]["outcome"]["title"] = createServerFontString("objective", 2.0);
	level.ttt.ui["hud"]["outcome"]["title"] setParent(level.ttt.ui["hud"]["outcome"]["bg"]);
	level.ttt.ui["hud"]["outcome"]["title"] setPoint("TOP CENTER", "TOP CENTER", 0, 28);
	level.ttt.ui["hud"]["outcome"]["title"].archived = false;
	level.ttt.ui["hud"]["outcome"]["title"].hidewheninmenu = true;
	level.ttt.ui["hud"]["outcome"]["title"].glowColor = level.ttt.colors[winner];
	level.ttt.ui["hud"]["outcome"]["title"].glowAlpha = 1;
	level.ttt.ui["hud"]["outcome"]["title"] setText(winnerText);

	level.ttt.ui["hud"]["outcome"]["reason"] = createServerFontString("default", 1.5);
	level.ttt.ui["hud"]["outcome"]["reason"] setParent(level.ttt.ui["hud"]["outcome"]["title"]);
	level.ttt.ui["hud"]["outcome"]["reason"] setPoint("TOP CENTER", "BOTTOM CENTER", 0, 10);
	level.ttt.ui["hud"]["outcome"]["reason"].archived = false;
	level.ttt.ui["hud"]["outcome"]["reason"].hidewheninmenu = true;
	level.ttt.ui["hud"]["outcome"]["reason"] setText(reasonText);
}

destroyRoundEnd()
{
	recursivelyDestroyElements(level.ttt.ui["hud"]["outcome"]);
}

displayScoreboard()
{
	self.ttt.ui["sb"] = [];
	self.ttt.ui["sb"]["icon"] = [];
	self.ttt.ui["sb"]["headings"] = [];
	self.ttt.ui["sb"]["names"] = [];

	players = [];
	players["alive"] = [];
	players["missing"] = [];
	players["confirmed"] = [];

	foreach (player in level.players)
	{
		if (!level.ttt.preparing && !isDefined(player.ttt.role)) continue; // exclude players who joined late

		if (!isAlive(player) && player.ttt.bodyFound)
			players["confirmed"][players["confirmed"].size] = player;
		else if (!isAlive(player) && (self.ttt.role == "traitor" || level.gameEnded || !isAlive(self)))
			players["missing"][players["missing"].size] = player;
		else
			players["alive"][players["alive"].size] = player;
	}

	vertPadding = 8;
	totalVertPadding = vertPadding * 2; // top and bottom padding

	self.ttt.ui["sb"]["bg"] = self createRectangle(240, 0, (0, 0, 0));
	self.ttt.ui["sb"]["bg"] setPoint("CENTER", "CENTER", 0, 0);
	self.ttt.ui["sb"]["bg"].alpha = 0.65;
	self.ttt.ui["sb"]["bg"].archived = false;
	self.ttt.ui["sb"]["bg"].foreground = true; // gets it displayed over the crosshair
	self.ttt.ui["sb"]["bg"].sort = -1;

	self.ttt.ui["sb"]["icon"]["face"] = self createIcon("cardicon_comic_shepherd", 32, 32);
	self.ttt.ui["sb"]["icon"]["face"] setParent(self.ttt.ui["sb"]["bg"]);
	self.ttt.ui["sb"]["icon"]["face"] setPoint("BOTTOM LEFT", "TOP LEFT", 4, 2);
	self.ttt.ui["sb"]["icon"]["face"].archived = false;
	self.ttt.ui["sb"]["icon"]["face"].foreground = true;
	self.ttt.ui["sb"]["icon"]["face"].sort = 5;

	self.ttt.ui["sb"]["icon"]["pipe"] = self createIcon("cardtitle_silencer", 20, 4);
	self.ttt.ui["sb"]["icon"]["pipe"] setParent(self.ttt.ui["sb"]["icon"]["face"]);
	self.ttt.ui["sb"]["icon"]["pipe"] setPoint("TOP LEFT", "TOP LEFT", 14, 22);
	self.ttt.ui["sb"]["icon"]["pipe"].archived = false;
	self.ttt.ui["sb"]["icon"]["pipe"].foreground = true;
	self.ttt.ui["sb"]["icon"]["pipe"].sort = 10;

	// ALIVE PLAYERS

	self.ttt.ui["sb"]["headings"]["alive"] = self createFontString("objective", 1.5);
	self.ttt.ui["sb"]["headings"]["alive"] setParent(self.ttt.ui["sb"]["bg"]);
	self.ttt.ui["sb"]["headings"]["alive"] setPoint("TOP CENTER", "TOP CENTER", 0, vertPadding);
	self.ttt.ui["sb"]["headings"]["alive"].archived = false;
	self.ttt.ui["sb"]["headings"]["alive"] setText("PLAYERS (" + players["alive"].size + ")");

	foreach (i, player in players["alive"])
	{
		self.ttt.ui["sb"]["names"][i] = self createFontString("default", 1.5);
		if (i == 0) self.ttt.ui["sb"]["names"][i] setParent(self.ttt.ui["sb"]["headings"]["alive"]);
		else self.ttt.ui["sb"]["names"][i] setParent(self.ttt.ui["sb"]["names"][i - 1]);
		self.ttt.ui["sb"]["names"][i] setPoint("TOP CENTER", "BOTTOM CENTER", 0, 0);
		self.ttt.ui["sb"]["names"][i].archived = false;
		if (player.guid == self.guid)
		{
			self.ttt.ui["sb"]["names"][i].glowColor = level.ttt.colorsScoreboard["self"];
			self.ttt.ui["sb"]["names"][i].glowAlpha = 1;
		}
		if (player.ttt.role == "detective" || self.ttt.role == "traitor" || level.gameEnded || !isAlive(self))
			self.ttt.ui["sb"]["names"][i].color = level.ttt.colorsScoreboard[player.ttt.role];
		self.ttt.ui["sb"]["names"][i] setText(removeColorsFromString(player.name));
	}

	// MISSING PLAYERS

	if (players["missing"].size > 0)
	{
		self.ttt.ui["sb"]["headings"]["missing"] = self createFontString("objective", 1.5);
		if (players["alive"].size > 0)
			self.ttt.ui["sb"]["headings"]["missing"] setParent(self.ttt.ui["sb"]["names"][self.ttt.ui["sb"]["names"].size - 1]);
		else
			self.ttt.ui["sb"]["headings"]["missing"] setParent(self.ttt.ui["sb"]["headings"]["alive"]);
		self.ttt.ui["sb"]["headings"]["missing"] setPoint("TOP CENTER", "BOTTOM CENTER", 0, vertPadding);
		self.ttt.ui["sb"]["headings"]["missing"].archived = false;
		totalVertPadding += vertPadding;
		self.ttt.ui["sb"]["headings"]["missing"] setText("MISSING IN ACTION (" + players["missing"].size + ")");

		foreach (i, player in players["missing"])
		{
			j = i + players["alive"].size;
			self.ttt.ui["sb"]["names"][j] = self createFontString("default", 1.5);
			if (i == 0) self.ttt.ui["sb"]["names"][j] setParent(self.ttt.ui["sb"]["headings"]["missing"]);
			else self.ttt.ui["sb"]["names"][j] setParent(self.ttt.ui["sb"]["names"][j - 1]);
			self.ttt.ui["sb"]["names"][j] setPoint("TOP CENTER", "BOTTOM CENTER", 0, 0);
			self.ttt.ui["sb"]["names"][j].archived = false;
			if (player.guid == self.guid)
			{
				self.ttt.ui["sb"]["names"][j].glowColor = level.ttt.colorsScoreboard["self"];
				self.ttt.ui["sb"]["names"][j].glowAlpha = 1;
			}
			if (player.ttt.role == "detective" || self.ttt.role == "traitor" || level.gameEnded || !isAlive(self))
				self.ttt.ui["sb"]["names"][j].color = level.ttt.colorsScoreboard[player.ttt.role];
			self.ttt.ui["sb"]["names"][j] setText(removeColorsFromString(player.name));
		}
	}

	// DEAD PLAYERS

	if (players["confirmed"].size > 0)
	{
		self.ttt.ui["sb"]["headings"]["confirmed"] = self createFontString("objective", 1.5);
		if (players["missing"].size > 0)
			self.ttt.ui["sb"]["headings"]["confirmed"] setParent(self.ttt.ui["sb"]["names"][self.ttt.ui["sb"]["names"].size - 1]);
		else if (isDefined(self.ttt.ui["sb"]["headings"]["missing"]))
			self.ttt.ui["sb"]["headings"]["confirmed"] setParent(self.ttt.ui["sb"]["headings"]["missing"]);
		else if (players["alive"].size > 0)
			self.ttt.ui["sb"]["headings"]["confirmed"] setParent(self.ttt.ui["sb"]["names"][self.ttt.ui["sb"]["names"].size - 1]);
		else
			self.ttt.ui["sb"]["headings"]["confirmed"] setParent(self.ttt.ui["sb"]["headings"]["alive"]);
		self.ttt.ui["sb"]["headings"]["confirmed"] setPoint("TOP CENTER", "BOTTOM CENTER", 0, vertPadding);
		self.ttt.ui["sb"]["headings"]["confirmed"].archived = false;
		totalVertPadding += vertPadding;
		self.ttt.ui["sb"]["headings"]["confirmed"] setText("CONFIRMED DEAD (" + players["confirmed"].size + ")");

		foreach (i, player in players["confirmed"])
		{
			j = i + players["alive"].size + players["missing"].size;
			self.ttt.ui["sb"]["names"][j] = self createFontString("default", 1.5);
			if (i == 0) self.ttt.ui["sb"]["names"][j] setParent(self.ttt.ui["sb"]["headings"]["confirmed"]);
			else self.ttt.ui["sb"]["names"][j] setParent(self.ttt.ui["sb"]["names"][j - 1]);
			self.ttt.ui["sb"]["names"][j] setPoint("TOP CENTER", "BOTTOM CENTER", 0, 0);
			self.ttt.ui["sb"]["names"][j].archived = false;
			if (player.guid == self.guid)
			{
				self.ttt.ui["sb"]["names"][j].glowColor = level.ttt.colorsScoreboard["self"];
				self.ttt.ui["sb"]["names"][j].glowAlpha = 1;
			}
			self.ttt.ui["sb"]["names"][j].color = level.ttt.colorsScoreboard[player.ttt.role];
			self.ttt.ui["sb"]["names"][j] setText(removeColorsFromString(player.name));
		}
	}

	sbHeight = 0;
	foreach (heading in self.ttt.ui["sb"]["headings"]) sbHeight += heading.height;
	foreach (name in self.ttt.ui["sb"]["names"]) sbHeight += name.height;
	sbHeight += totalVertPadding;
	self.ttt.ui["sb"]["bg"] setDimensions(undefined, int(sbHeight));
}

destroyScoreboard()
{
	recursivelyDestroyElements(self.ttt.ui["sb"]);
}

displayBuyMenu(role)
{
	COLUMNS = level.ttt.buyMenu["columns"];
	PADDING = level.ttt.buyMenu["padding"];
	DESC_WIDTH = level.ttt.buyMenu["desc_width"];

	rowCount = intUp(level.ttt.items[role].size / COLUMNS);
	columnCount = level.ttt.items[role].size;
	if (level.ttt.items[role].size > COLUMNS) columnCount = COLUMNS;

	self.ttt.ui["bm"] = [];

	self.ttt.ui["bm"]["bg"] = self createRectangle(0, 0, level.ttt.colorsBuyMenu[role]);
	self.ttt.ui["bm"]["bg"] setPoint("CENTER", "CENTER", 0, 0);
	self.ttt.ui["bm"]["bg"].alpha = 0.65;
	self.ttt.ui["bm"]["bg"].hidewheninmenu = true;
	self.ttt.ui["bm"]["bg"].foreground = true; // gets it displayed over the crosshair
	self.ttt.ui["bm"]["bg"].sort = -1;

	self.ttt.ui["bm"]["title"] = self createFontString("hudbig", 1.0);
	self.ttt.ui["bm"]["title"] setParent(self.ttt.ui["bm"]["bg"]);
	self.ttt.ui["bm"]["title"] setPoint("TOP CENTER", "TOP CENTER", 0, 0);
	self.ttt.ui["bm"]["title"].hidewheninmenu = true;
	self.ttt.ui["bm"]["title"].foreground = true;
	self.ttt.ui["bm"]["title"].label = &"CREDIT SHOP";

	self.ttt.ui["bm"]["items_bg"] = [];
	foreach(i, item in level.ttt.items[role])
	{
		parent = undefined;
		pointParent = undefined;

		squareLength = 48;
		self.ttt.ui["bm"]["items_bg"][i] = self createRectangle(squareLength, squareLength, level.ttt.colorsBuyMenu["item_bg"]);
		self.ttt.ui["bm"]["items_bg"][i].alpha = 0.8;
		self.ttt.ui["bm"]["items_bg"][i].foreground = true;
		self.ttt.ui["bm"]["items_bg"][i].hidewheninmenu = true;

		iconWidth = 32;
		iconHeight = 32;
		if (isDefined(item.iconWidth)) iconWidth = item.iconWidth;
		if (isDefined(item.iconHeight)) iconHeight = item.iconHeight;
		self.ttt.ui["bm"]["items_icon"][i] = self createIcon(level.ttt.items[role][i].icon, iconWidth, iconHeight);
		self.ttt.ui["bm"]["items_icon"][i].foreground = true;
		self.ttt.ui["bm"]["items_icon"][i].hidewheninmenu = true;
		self.ttt.ui["bm"]["items_icon"][i].sort = 5;
		self.ttt.ui["bm"]["items_icon"][i] setParent(self.ttt.ui["bm"]["items_bg"][i]);
		// do manual positioning because rects are still weird
		iconOffsetX = int(squareLength / 2 - iconWidth / 2);
		iconOffsetY = int(squareLength / 2 - iconHeight / 2) + 8;
		if (isDefined(item.iconOffsetX)) iconOffsetX += item.iconOffsetX;
		if (isDefined(item.iconOffsetY)) iconOffsetY += item.iconOffsetY;
		self.ttt.ui["bm"]["items_icon"][i] setPoint("TOP LEFT", "TOP LEFT", iconOffsetX, iconOffsetY);

		if (i == 0) // first element
		{
			self.ttt.ui["bm"]["items_bg"][i] setParent(self.ttt.ui["bm"]["bg"]);
			self.ttt.ui["bm"]["items_bg"][i] setPoint("TOP LEFT", "TOP LEFT", PADDING, self.ttt.ui["bm"]["title"].height + PADDING * 3);
		}
		else if (i % COLUMNS == 0) // new row
		{
			self.ttt.ui["bm"]["items_bg"][i] setParent(self.ttt.ui["bm"]["items_bg"][i - COLUMNS]);
			self.ttt.ui["bm"]["items_bg"][i] setPoint("TOP LEFT", "BOTTOM LEFT", 0, PADDING);
		}
		else // continue row
		{
			self.ttt.ui["bm"]["items_bg"][i] setParent(self.ttt.ui["bm"]["items_bg"][i - 1]);
			self.ttt.ui["bm"]["items_bg"][i] setPoint("TOP LEFT", "TOP RIGHT", PADDING, 0);
		}
	}

	self.ttt.ui["bm"]["name"] = self createFontString("objective", 1.0);
	self.ttt.ui["bm"]["name"] setParent(self.ttt.ui["bm"]["items_bg"][columnCount - 1]);
	self.ttt.ui["bm"]["name"] setPoint("TOP LEFT", "TOP RIGHT", PADDING * 2, 6); // shouldn't need vert offset if rects weren't weird
	self.ttt.ui["bm"]["name"].hidewheninmenu = true;
	self.ttt.ui["bm"]["name"].foreground = true;

	self.ttt.ui["bm"]["desc"] = self createFontString("default", 1.0);
	self.ttt.ui["bm"]["desc"] setParent(self.ttt.ui["bm"]["name"]);
	self.ttt.ui["bm"]["desc"] setPoint("TOP LEFT", "BOTTOM LEFT", 0, PADDING);
	self.ttt.ui["bm"]["desc"].hidewheninmenu = true;
	self.ttt.ui["bm"]["desc"].foreground = true;

	self.ttt.ui["bm"]["credits"] = self createFontString("default", 1.2);
	self.ttt.ui["bm"]["credits"] setParent(self.ttt.ui["bm"]["bg"]);
	self.ttt.ui["bm"]["credits"] setPoint("BOTTOM LEFT", "BOTTOM LEFT", PADDING, PADDING * -1);
	self.ttt.ui["bm"]["credits"].hidewheninmenu = true;
	self.ttt.ui["bm"]["credits"].foreground = true;
	self.ttt.ui["bm"]["credits"].label = &"Available Credits: ^3";

	gridWidth = (self.ttt.ui["bm"]["items_bg"][0].width + PADDING) * columnCount;
	gridHeight = (self.ttt.ui["bm"]["items_bg"][0].height + PADDING) * rowCount;

	bgWidth = PADDING + gridWidth + PADDING * 2 + DESC_WIDTH + PADDING;
	bgHeight = (self.ttt.ui["bm"]["title"].height + PADDING * 3) + gridHeight + self.ttt.ui["bm"]["credits"].height + PADDING * 3;

	self.ttt.ui["bm"]["bg"] setDimensions(int(bgWidth), int(bgHeight));

	self updateBuyMenu(role);
}

updateBuyMenu(role, moveDown, moveRight, buySelected)
{
	if (!isDefined(role)) return;
	if (!isDefined(moveDown)) moveDown = 0;
	if (!isDefined(moveRight)) moveRight = 0;
	if (!isDefined(buySelected)) buySelected = false;

	COLUMNS = level.ttt.buyMenu["columns"];
	rowCount = intUp(level.ttt.items[role].size / COLUMNS);
	columnCount = level.ttt.items[role].size;
	if (level.ttt.items[role].size > COLUMNS) columnCount = COLUMNS;

	prevSelectedIndex = self.ttt.items.selectedIndex;

	selectedIndexHoriz = self.ttt.items.selectedIndex % columnCount;
	selectedIndexVert = int(self.ttt.items.selectedIndex / columnCount);

	if (selectedIndexVert + moveDown >= 0 && selectedIndexVert + moveDown < rowCount)
		selectedIndexVert += moveDown;
	if (selectedIndexHoriz + moveRight >= 0 && selectedIndexHoriz + moveRight < columnCount)
		selectedIndexHoriz += moveRight;
	self.ttt.items.selectedIndex = selectedIndexHoriz + selectedIndexVert * columnCount;
	if (self.ttt.items.selectedIndex < 0)
		self.ttt.items.selectedIndex = 0;
	if (self.ttt.items.selectedIndex >= level.ttt.items[role].size)
		self.ttt.items.selectedIndex = level.ttt.items[role].size - 1;

	// Update item texts
	self.ttt.ui["bm"]["name"] setText(level.ttt.items[role][self.ttt.items.selectedIndex].name);
	self.ttt.ui["bm"]["desc"] setText(level.ttt.items[role][self.ttt.items.selectedIndex].description);

	// Update rectangle colors
	foreach (itemBg in self.ttt.ui["bm"]["items_bg"]) itemBg.color = level.ttt.colorsBuyMenu["item_bg"];
	self.ttt.ui["bm"]["items_bg"][self.ttt.items.selectedIndex].color = level.ttt.colorsBuyMenu["item_selected"];

	// Update owned items
	foreach (i, itemIcon in self.ttt.ui["bm"]["items_icon"])
	{
		itemIcon.alpha = 1.0;
		item = level.ttt.items[role][i];
		if (![[item.getIsAvailable]](item) || self.ttt.items.credits <= 0) itemIcon.alpha = 0.25;
	}

	// Update credit count
	self.ttt.ui["bm"]["credits"] setValue(self.ttt.items.credits);

	// Play sounds
	if (buySelected) self playLocalSound("oldschool_pickup");
	else if (prevSelectedIndex != self.ttt.items.selectedIndex) self playLocalSound("mouse_over");
}

destroyBuyMenu()
{
	recursivelyDestroyElements(self.ttt.ui["bm"]);
}

updateBombHuds()
{
	foreach (player in level.players)
	{
		if (isDefined(player.ttt.role) && player.ttt.role == "traitor" && isDefined(player.ttt.ui["hud"]["self"]["role"]))
		{
			player destroyBombHud();
			player displayBombHud();
		}
	}
}

displayBombHud()
{
	if (!isDefined(self.ttt.role) || self.ttt.role != "traitor") return;

	self.ttt.ui["hud"]["self"]["bombs"] = [];

	foreach(i, bombEnt in level.ttt.bombs)
	{
		self.ttt.ui["hud"]["self"]["bombs"][i] = [];

		self.ttt.ui["hud"]["self"]["bombs"][i]["waypoint"] = newClientHudElem(self);
		self.ttt.ui["hud"]["self"]["bombs"][i]["waypoint"] setShader("hud_suitcase_bomb");
		self.ttt.ui["hud"]["self"]["bombs"][i]["waypoint"].color = (1, 0.3, 0.3);
		self.ttt.ui["hud"]["self"]["bombs"][i]["waypoint"].alpha = 0.5;
		self.ttt.ui["hud"]["self"]["bombs"][i]["waypoint"] setWaypoint(true, true);
		self.ttt.ui["hud"]["self"]["bombs"][i]["waypoint"] setTargetEnt(bombEnt);

		self.ttt.ui["hud"]["self"]["bombs"][i]["icon"] = self createIcon("hud_suitcase_bomb", 24, 24);
		self.ttt.ui["hud"]["self"]["bombs"][i]["icon"].color = (1, 0.3, 0.3);
		self.ttt.ui["hud"]["self"]["bombs"][i]["icon"].hidewheninmenu = true;
		self.ttt.ui["hud"]["self"]["bombs"][i]["icon"] setPoint("TOP RIGHT", "TOP RIGHT", -20, 60);
		if (i > 0)
		{
			self.ttt.ui["hud"]["self"]["bombs"][i]["icon"] setParent(self.ttt.ui["hud"]["self"]["bombs"][i - 1]["icon"]);
			self.ttt.ui["hud"]["self"]["bombs"][i]["icon"] setPoint("TOP LEFT", "TOP LEFT", 0, 24 + 12);
		}

		self.ttt.ui["hud"]["self"]["bombs"][i]["text"] = self createFontString("default", 1.5);
		self.ttt.ui["hud"]["self"]["bombs"][i]["text"] setParent(self.ttt.ui["hud"]["self"]["bombs"][i]["icon"]);
		self.ttt.ui["hud"]["self"]["bombs"][i]["text"] setPoint("BOTTOM RIGHT ", "BOTTOM RIGHT", 2, 2);
		self.ttt.ui["hud"]["self"]["bombs"][i]["text"].color = (1, 1, 1);
		self.ttt.ui["hud"]["self"]["bombs"][i]["text"].hidewheninmenu = true;
		self.ttt.ui["hud"]["self"]["bombs"][i]["text"].foreground = true;
		self.ttt.ui["hud"]["self"]["bombs"][i]["text"] setValue(scripts\ttt\items::getBombSecondsRemaining(bombEnt));
	}
}

destroyBombHud()
{
	recursivelyDestroyElements(self.ttt.ui["hud"]["self"]["bombs"]);
}
