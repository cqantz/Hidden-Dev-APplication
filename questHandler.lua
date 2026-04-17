local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local Quests = { questMetas = {} }

Quests.__index = Quests

local questInformation = require(script.Parent.Information)

local knitServer = require(game.ServerStorage["Server Libary"].Systems.Core.knitServer)
local generalService = knitServer.GeneralService
local abilityHandler = require(game.ServerStorage["Server Libary"].Systems.Core.Abilities.Handler)

local questAttributes = { "dungeonAbilities" }

function Quests.new(questModel)
	local questObject = setmetatable({}, Quests)
	questObject.Model = questModel
	questModel.HumanoidRootPart.Anchored = true
	questObject.Name = questObject.Model.Name

	questObject.activePeople = {}

	table.insert(Quests.questMetas, questObject)

	local dictionaryOfInformation = questInformation[questModel.Name]

	questObject.levelRequired = dictionaryOfInformation.levelRequired
	questObject.dictionaryOfInformation = dictionaryOfInformation

	questObject.Objectives = {}
	questObject.attachedFunctions = {}

	local idleAnimationObject = Instance.new("Animation")
	idleAnimationObject.Parent = questModel
	idleAnimationObject.Name = "Idle"
	idleAnimationObject.AnimationId = dictionaryOfInformation.Idle

	local questProximityPrompt = script.Quest:Clone()
	questProximityPrompt.Parent = questModel.HumanoidRootPart
	questProximityPrompt.Name = "ProximityPromptQuest"
	questProximityPrompt.ActionText = "Talk to " .. questModel.Name .. "."
	questObject.Prompt = questProximityPrompt

	questObject.questAssets = {}

	local dataSetup = require(ServerStorage["Server Libary"].Systems.Core.Data.dataSetup)

	questProximityPrompt.Triggered:Connect(function(playerTriggered)
		if
			dataSetup.GetData(playerTriggered).Slots[playerTriggered:GetAttribute("Slot")].Quests[questObject.Name]
			== true
		then
			return
		end
		if questObject.activePeople[playerTriggered] == nil then
			questObject.Objectives[playerTriggered] = {}
			questObject.questAssets[playerTriggered] = {}
			questObject.attachedFunctions[playerTriggered] = {}
			for indexOfQuest, _ in pairs(questObject.dictionaryOfInformation.Objectives) do
				questObject.Objectives[playerTriggered][indexOfQuest] = false
			end
			questObject:initiateDialouge(playerTriggered)
		end
	end)

	questModel.Humanoid:LoadAnimation(idleAnimationObject):Play()
end

function Quests:initiateDialouge(player)
	self.activePeople[player] = true
	generalService.Client.GeneralContact:Fire(player, { arg1 = "questClientDialouge", arg2 = self })
	player.Character:SetAttribute("inQuestDialouge", true)
	abilityHandler.stopMovement(player.Character)
end

function Quests:breakDialouge(player)
	local dataSetup = require(ServerStorage["Server Libary"].Systems.Core.Data.dataSetup)

	local playerData = dataSetup.GetData(player)

	local boolOfQuest = playerData.Slots[player:GetAttribute("Slot")].Quests[self.Name]

	generalService.Client.GeneralContact:Fire(
		player,
		{ arg1 = "questClientDialougeBreak", arg2 = self, arg3 = boolOfQuest }
	)
	self.activePeople[player] = nil
	player.Character:SetAttribute("inQuestDialouge", false)
	abilityHandler.startMovement(player.Character)
end

function Quests:acceptQuest(player)
	generalService.Client.GeneralContact:Fire(player, { arg1 = "questClientDialougeBreak", arg2 = self, arg3 = true })
	player.Character:SetAttribute("inQuestDialouge", false)
	abilityHandler.startMovement(player.Character)
	self:startQuest(player)
end

function Quests:breakDialougeCutscene(player)
	generalService.Client.GeneralContact:Fire(player, { arg1 = "questClientDialougeBreak", arg2 = self, arg3 = true })
	player.Character:SetAttribute("inQuestDialouge", false)
	abilityHandler.startMovement(player.Character)
end

function Quests:checkCurrentObjective(player)
	local _currentObjective = nil
	for index, Objective in pairs(self.Objectives[player]) do
		if Objective == false then
			_currentObjective = index
			break
		end
	end

	if _currentObjective ~= nil then
		local objectiveObject = self.dictionaryOfInformation.Objectives[_currentObjective]
		return _currentObjective, objectiveObject
	end
	return "Reward"
end

function Quests:delayOfQuest(player, objectiveObject)
	if objectiveObject.quitTime then
		task.delay(objectiveObject.quitTime, function()
			local _keyOfObjective, objectiveObjectNew = self:checkCurrentObjective(player)
			if objectiveObjectNew == objectiveObject then
				local grabCurrentObjective, _ = self:checkCurrentObjective(player)
				if grabCurrentObjective == _keyOfObjective then
					self:Maid(player)
				end
			end
		end)
	end
end

function Quests:startQuest(player)
	generalService.Client.GeneralContact:Fire(player, { arg1 = "disableQuestProximitys", arg2 = self.Prompt })

	local keyOfObjective, objectiveObject = self:checkCurrentObjective(player)
	if not player:FindFirstChild("Quests") then
		local questFolder = Instance.new("Folder")
		questFolder.Parent = player
		questFolder.Name = "Quests"
	end

	self.questAssets[player] = {}

	for _index, stringFound in pairs(questAttributes) do
		if player.Character:GetAttribute(stringFound) then
			player.Character:SetAttribute(stringFound, nil)
		end
	end

	for _, connectedFunctions in pairs(self.attachedFunctions[player]) do
		connectedFunctions:Disconnect()
		connectedFunctions = nil
	end

	local questsFolder = player:WaitForChild("Quests", 4)

	for _, folderInside in pairs(questsFolder:GetChildren()) do
		if folderInside:IsA("Folder") then
			folderInside:Destroy()
		end
	end

	local folderObj = Instance.new("Folder")
	folderObj.Parent = questsFolder
	folderObj.Name = self.Name

	if keyOfObjective == "Value" or keyOfObjective == "Value2" then
		if objectiveObject.stopAbilities ~= nil and objectiveObject.stopAbilities == true then
			abilityHandler.stopAbilities(player.Character, nil, objectiveObject.attribute)
		end

		if objectiveObject.minigame then
			for _, parts in pairs(objectiveObject.locationOfPoint:GetChildren()) do
				if parts:IsA("BasePart") then
					self.attachedFunctions[player][parts] = parts.ProximityPrompt.Triggered:Connect(
						function(playerTriggered)
							if playerTriggered == player then
								generalService.Client.GeneralContact:Fire(player, {
									arg1 = "loadSession",
									arg2 = objectiveObject.minigamestring,
								})
							end
						end
					)
				end
			end
		end

		local _tableOfNumbers = nil
		if objectiveObject.randomObject then
			print(objectiveObject.reachValue)
			for index = 1, objectiveObject.reachValue do
				print(index)
				self:spawnObjectInArea(player)
			end
		elseif objectiveObject.randomLocation then
			self:spawnObjectInArea(player)
		end

		objectiveObject["enableServerFunction"](player, self.Name, generalService)

		local NumbVal = Instance.new("NumberValue")
		NumbVal.Parent = folderObj
		NumbVal.Name = "valueToChange"
		NumbVal.Value = 0

		self.attachedFunctions[player]["numbValChange"] = NumbVal:GetPropertyChangedSignal("Value"):Connect(function()
			generalService.Client.GeneralContact:Fire(player, {
				arg1 = "updateQuestValue",
				arg2 = objectiveObject.nameOfObjective,
				arg3 = NumbVal.Value,
				arg4 = objectiveObject.reachValue,
			})
			if NumbVal.Value >= objectiveObject.reachValue then
				self.Objectives[player][keyOfObjective] = true
				self:startQuest(player)
			end
		end)
	elseif keyOfObjective == "Return" then
		objectiveObject["enableServerFunction"](player, self.Name, generalService, self.Prompt)
		self.attachedFunctions[player]["Return Prompt"] = self.Prompt.Triggered:Connect(function(playerTriggered)
			if player ~= playerTriggered then
				return
			end
			if self.activePeople[player] then
				self.Objectives[player][keyOfObjective] = true
				generalService.Client.GeneralContact:Fire(
					player,
					{ arg1 = "questClientDialougeReturn", arg2 = self, arg3 = true }
				)
				self:startQuest(player)
			end
		end)
	end

	if keyOfObjective == "Reward" then
		folderObj:Destroy()
	else
		self:delayOfQuest(player, objectiveObject)
		generalService.Client.GeneralContact:Fire(player, {
			arg1 = "updateQuestButton",
			arg2 = objectiveObject.nameOfObjective,
			arg3 = self,
			arg4 = keyOfObjective,
			arg5 = objectiveObject.reachValue,
		})
		player.PlayerGui.Interface.Extras.QuestButton.Frame.Visible = true
	end
end

function Quests:rewardPlayer(player)
	self:finishQuest(player)
	player.PlayerGui.Interface.Extras.QuestButton.Frame.Visible = false
	local dataSetup = require(ServerStorage["Server Libary"].Systems.Core.Data.dataSetup)

	local data = dataSetup.GetData(player).Slots[player:GetAttribute("Slot")]
	generalService.Client.GeneralContact:Fire(player, { arg1 = "enableQuestProximitys", arg2 = data })
end

function Quests:spawnNpc(player)
	if not self.activePeople[player] then
		return
	end
	local _currentObjective = self:checkCurrentObjective(player)
	if _currentObjective ~= nil then
		local function getRandomPositionInArea(areaCenter, areaSize)
			local halfX = areaSize.X / 2
			local halfZ = areaSize.Z / 2

			local randomX = areaCenter.X + math.random(-halfX * 100, halfX * 100) / 100
			local randomZ = areaCenter.Z + math.random(-halfZ * 100, halfZ * 100) / 100

			local rayOrigin = Vector3.new(randomX, areaCenter.Y + areaSize.Y / 2, randomZ)
			local rayDirection = Vector3.new(0, -1000, 0)

			local result = workspace:Raycast(rayOrigin, rayDirection)

			local randomY
			if result then
				randomY = result.Position.Y
			else
				randomY = areaCenter.Y
				warn("Raycast hit nothing, falling back to areaCenter.Y")
			end

			return Vector3.new(randomX, randomY, randomZ)
		end

		local objectiveInformation = self.dictionaryOfInformation.Objectives[_currentObjective]
		local Handler = require(ServerStorage["Server Libary"].Systems.Core.NPCS.Handler)

		local tableOfAssets = self.questAssets[player]
		tableOfAssets.NPC = {}

		if objectiveInformation.NPC == true then
			for _ = 1, objectiveInformation.reachValue do
				local npcModel = nil

				if objectiveInformation.variationInModels then
					npcModel =
						game.ReplicatedStorage["Replicated Libary"].Assets.Characters[objectiveInformation.valueName]
							:FindFirstChild(tostring(math.random(1, objectiveInformation.variationInModels)))
							:Clone()
					npcModel.Parent = game.Workspace.Alive
					npcModel.Name = objectiveInformation.valueName
				else
					npcModel =
						game.ReplicatedStorage["Replicated Libary"].Assets.Characters[objectiveInformation.valueName].Regular:Clone()
					npcModel.Parent = game.Workspace.Alive
					npcModel.Name = objectiveInformation.valueName
				end

				if objectiveInformation.npcCutscene then
					local instance = Instance.new("StringValue")
					instance.Name = "Cutscene"
					instance.Value = player.Name
					instance.Parent = npcModel
				end

				if objectiveInformation.inLocation == true then
					local npcPosition =
						getRandomPositionInArea(objectiveInformation.locationOfPoint.Position, Vector3.new(60, 60, 60))
					if npcPosition then
						npcModel:PivotTo(CFrame.new(npcPosition) * CFrame.new(0, 3, 0))
					end
					local NPC = Handler.new(npcModel.Name, npcModel, true)
					NPC.Model:SetAttribute("temporaryNPC", true)
					if not objectiveInformation.npcCutscene or objectiveInformation.npcCutscene == nil then
						NPC:attackPlayer(player, 20)
					end
					table.insert(tableOfAssets.NPC, NPC)
				else
					npcModel:PivotTo(objectiveInformation.locationOfPoint.CFrame)
					local NPC = Handler.new(npcModel.Name, npcModel, true)
					NPC.Model:SetAttribute("temporaryNPC", true)
					if not objectiveInformation.npcCutscene or objectiveInformation.npcCutscene == nil then
						NPC:attackPlayer(player, 20)
					end
					table.insert(tableOfAssets.NPC, NPC)
				end
			end

			if objectiveInformation.npcCutscene then
				local _currentObjectiveNew, _dictionary = self:checkCurrentObjective(player)
				print("fire cutscene")
				generalService.Client.GeneralContact:Fire(player, {
					arg1 = "questCutscene",
					arg2 = self,
					arg3 = _currentObjectiveNew,
					arg4 = objectiveInformation.valueName,
				})
			end
			self.Objectives[player][_currentObjective] = true
		end
	end
end

function Quests:spawnObjectInArea(player)
	local keyOfObjective, objectiveObject = self:checkCurrentObjective(player)

	if objectiveObject.inLocation == true then
		local function getRandomPositionInArea(areaCenter, areaSize)
			local halfX = areaSize.X / 2
			local halfZ = areaSize.Z / 2

			local randomX = areaCenter.X + math.random(math.floor(-halfX * 100), math.floor(halfX * 100)) / 100
			local randomZ = areaCenter.Z + math.random(math.floor(-halfZ * 100), math.floor(halfZ * 100)) / 100

			local rayOrigin = Vector3.new(randomX, areaCenter.Y + areaSize.Y / 2, randomZ)
			local rayDirection = Vector3.new(0, -1000, 0)

			local result = workspace:Raycast(rayOrigin, rayDirection)

			local randomY
			if result then
				randomY = result.Position.Y
			else
				randomY = areaCenter.Y
				warn("Raycast hit nothing, falling back to areaCenter.Y")
			end

			return Vector3.new(randomX, randomY, randomZ)
		end

		local Asset = objectiveObject.randomObject:Clone()
		Asset.Parent = game.Workspace.Quests.questObjects

		local randomposition =
			getRandomPositionInArea(objectiveObject.locationOfPoint.Position, objectiveObject.locationOfPoint.Size)

		if objectiveObject.objectOffset then
			Asset:SetPrimaryPartCFrame(CFrame.new(randomposition) * objectiveObject.objectOffset)
		else
			Asset:SetPrimaryPartCFrame(CFrame.new(randomposition))
		end

		table.insert(self.questAssets[player], Asset)

		if objectiveObject.Prompt == true then
			local Prompt = Asset.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
			if Prompt then
				Prompt:SetAttribute("PlayerAssigned", player.Name)
				generalService.Client.GeneralContact:FireAll({ arg1 = "disableProximityPrompt" })
				Prompt.ActionText = objectiveObject.objectText
				self.attachedFunctions[player]["objectivePromptPickUp"] = Prompt.Triggered:Connect(
					function(playerTriggered)
						if playerTriggered == player then
							if player:FindFirstChild("Quests") then
								if player.Quests:FindFirstChild(self.Name) then
									player.Quests[self.Name].valueToChange.Value += 1
									Asset:Destroy()
								end
							end
						end
					end
				)
			end
		end
	elseif objectiveObject.randomLocation == true then
		local folderOfRandomPositions = game.Workspace.Quests.questInformation.Value[self.Name]
		if folderOfRandomPositions then
			local maxIndexOfFolder = #folderOfRandomPositions:GetChildren()

			local _tableOfNumbers = {}

			for _ = 1, objectiveObject.reachValue do
				local randomNumber = math.random(1, maxIndexOfFolder)
				repeat
					task.wait()
					randomNumber = math.random(1, maxIndexOfFolder)
				until _tableOfNumbers[randomNumber] == nil

				_tableOfNumbers[randomNumber] = true

				local Part = folderOfRandomPositions:FindFirstChild(randomNumber)

				objectiveObject.enableServerFunction(player, self.Name, generalService, Part)

				table.insert(self.questAssets[player], Part)
				if objectiveObject.Prompt == true then
					local Prompt = script.Quest:Clone()
					Prompt.Parent = Part
					Prompt:SetAttribute("PlayerAssigned", player.Name)
					Prompt.ObjectText = ""
					Prompt.ActionText = objectiveObject.objectText
					table.insert(self.questAssets[player], Prompt)
					self.attachedFunctions[player]["objectivePromptPickUp" .. tostring(randomNumber)] = Prompt.Triggered:Connect(
						function(playerTriggered)
							if playerTriggered == player then
								if player:FindFirstChild("Quests") then
									if player.Quests:FindFirstChild(self.Name) then
										player.Quests[self.Name].valueToChange.Value += 1
										Prompt:Destroy()
										objectiveObject.proximityCustomServer({
											Character = player.Character,
											arg1 = Part,
											arg3 = self.Name,
											arg4 = generalService,
										})
									end
								end
							end
						end
					)
				end
				task.wait()
			end

			generalService.Client.GeneralContact:FireAll({ arg1 = "disableProximityPrompt" })

			return _tableOfNumbers
		end
	end
end

function Quests:finishQuest(player)
	local dataSetup = require(ServerStorage["Server Libary"].Systems.Core.Data.dataSetup)
	local rewardsTable = self.dictionaryOfInformation.Reward
	for _, rewardDictionary in pairs(rewardsTable) do
		if rewardDictionary.Value == "COINS" then
			dataSetup.UpdateTokens(player, rewardDictionary.valueRewarded, player:GetAttribute("Slot"))
		elseif rewardDictionary.Value == "XP" then
			dataSetup.updateXP(player, rewardDictionary.valueRewarded, player:GetAttribute("Slot"))
		end
	end
	local playerData = dataSetup.GetData(player)
	if player.Name ~= "Cenvaria" then
		playerData.Slots[player:GetAttribute("Slot")].Quests[self.Name] = true
	end
	playerData.Slots[player:GetAttribute("Slot")]["Quest Timestamps"][self.Name] = DateTime.now().UnixTimestamp
end

function Quests:Maid(player, cancel)
	local dataSetup = require(ServerStorage["Server Libary"].Systems.Core.Data.dataSetup)

	local questInstance = self

	local keyOfObjective, objectiveObject = self:checkCurrentObjective(player)

	if keyOfObjective ~= "Reward" then
		if objectiveObject.disableServerFunction then
			objectiveObject.disableServerFunction(player, self.Name, generalService, self)
		end
	end

	local playerData = dataSetup.GetData(player)

	generalService.Client.GeneralContact:Fire(player, { arg1 = "updateQuestUIS", arg2 = playerData })

	if questInstance.questAssets[player] then
		if questInstance.questAssets[player].NPC then
			for _key, npcInstance in pairs(questInstance.questAssets[player].NPC) do
				npcInstance:Destroy(cancel)
			end
		end
		for _, itemInside in pairs(questInstance.questAssets[player]) do
			local typeInside = typeof(itemInside)
			if typeInside == "Instance" then
				if itemInside:IsA("Model") or itemInside:IsA("ProximityPrompt") then
					itemInside:Destroy()
				end
			end
		end
		questInstance.questAssets[player] = nil
	end
	if questInstance.attachedFunctions[player] then
		for _, connectedFunctions in pairs(questInstance.attachedFunctions[player]) do
			connectedFunctions:Disconnect()
			connectedFunctions = nil
		end
		questInstance.attachedFunctions[player] = nil
	end
	if questInstance.Objectives[player] then
		questInstance.Objectives[player] = nil
	end
	questInstance.activePeople[player] = nil

	if cancel then
		player.PlayerGui.Interface.Extras.QuestButton.Frame.Visible = false
	end
end

function Quests.grabQuest(player)
	for _, meta in pairs(Quests.questMetas) do
		if meta.activePeople[player] then
			return meta
		end
	end
	return nil
end

local folderOfQuests = workspace:WaitForChild("Quests")

for _, modelInQuests in pairs(folderOfQuests:GetChildren()) do
	if modelInQuests:IsA("Model") then
		Quests.new(modelInQuests)
	end
end

return Quests
