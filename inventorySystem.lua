local module = {}

local tools = require(script.toolsAvaliable)

local uis = game:GetService("UserInputService")

-- translates numbers to words for keybind handling

local Word2Number = {
	["Zero"]=0,
	["One"]=1,
	["Two"]=2,
	["Three"]=3,
	["Four"]=4,
	["Five"]=5,
	["Six"]=6,
	["Seven"]=7,
	["Eight"]=8,
	["Nine"]=9,
	["Ten"]=10,
	["Eleven"]=11,
	["twelve"]=12,
	["thirteen"]=13,
	["fourteen"]=14,
	["fifteen"]=15,
	["sixteen"]=16,
	["seventeen"]=17,
	["eighteen"]=18,
	["nineteen"]=19,
	["twenty"]=20,
	["twenty-one"]=21,
	["twenty-two"]=22,
	["twenty-three"]=23,
	["twenty-four"]=24,
	["twenty-five"]=25,
	["twenty-six"]=26,
	["twenty-seven"]=27,
	["twenty-eight"]=28,
	["twenty-nine"]=29,
	["thirty"]=30,
	["thirty-one"]=31,
	["thirty-two" ]=32,
	["thirty-three" ]=33,
	["thirty-four"]=34,
	["thirty-five"]=35,
	["thirty-six"]=36,
	["thirty-seven"]=37,
	["thirty-eight"]=38,
	["thirty-nine"]=39,
	["forty"]=40,
	["forty-one"]=41,
	["forty-two"]=42,
	["forty-three"]=43,
	["forty-four"]=44,
	["forty-five"]=45,
	["forty-six"]=46,
	["forty-seven"]=47,
	["forty-eight"]=48,
	["forty-nine"]=49,
	["fifty"]=50,
}

module.canEquip = true

module.currentlySelected = "Unequip"

module.toolInformation = {}

module.buttonConnections = {}

local lp = game.Players.LocalPlayer

--clears information related to tools

module.clearInformation = function()
	for i,v in pairs(module.buttonConnections) do
		v:Disconnect()
		module.buttonConnections[i] = nil
	end
	if module.toolInformation[game.Players.LocalPlayer] then
		module.toolInformation[game.Players.LocalPlayer] = nil
	end
end

module.insertInformation = function(stringf,player)
	local info = tools[stringf]
	if module.toolInformation[player] == nil then
		module.toolInformation[player] = {}
	end
	module.toolInformation[player][stringf] = {
		
		Uses = info.Uses
	}
end

--inserts tools needed with ui buttons attached

module.insertTools = function()
	local Player = game.Players.LocalPlayer
	local PlayerUI = Player:WaitForChild("PlayerGui")
	local Inventory = PlayerUI:WaitForChild("Inventory")
	local Frame = Inventory.Frame.Frame
	local num = 0
	local Selection = PlayerUI:WaitForChild("Selection UIS")
	local inventoryButton = Selection["Selection UI"]:WaitForChild("ImageButton")
	inventoryButton.MouseEnter:Connect(function()
		script.Sounds["ui hover"]:Play()
		game:GetService("TweenService"):Create(inventoryButton,TweenInfo.new(.5,Enum.EasingStyle.Linear),{Size = UDim2.new(0.977, 0,0.457, 0)}):Play()
	end)
	inventoryButton.MouseLeave:Connect(function()
		game:GetService("TweenService"):Create(inventoryButton,TweenInfo.new(.5,Enum.EasingStyle.Linear),{Size = UDim2.new(0.841, 0,0.405, 0)}):Play()
	end)
	inventoryButton.MouseButton1Down:Connect(function()
		script.Sounds["ui click"]:Play()
		if Inventory.Enabled == false then
			Inventory.Enabled = true
		else
			Inventory.Enabled = false
		end
	end)
	for i,v in pairs(Frame:GetChildren()) do
		if v:IsA("ImageButton") then
			v:Destroy()
		end
	end
	for i,v in pairs(tools) do
		num = num + 1
		local Template = script.Interface.Template.ImageButton:Clone()
		Template.Parent = Frame
		Template.Name = i
		for b,c in pairs(Word2Number) do
			if c == num then
				Template.Keybind.Text = c
			end
		end
		Template.Description.Text = i
		local Icon = v.Icon:Clone()
		Icon.Parent = Template
		Icon.AnchorPoint = Vector2.new(0.5,0.5)
		Icon.Size = UDim2.fromScale(1,1)
		Icon.Position = UDim2.new(0.5,0,0.5,0)
		script.connectionEvent:FireServer("Add Information", Template.Name)
		Template.MouseButton1Down:Connect(function()
			if module.currentlySelected == Template.Name then
				module.selectTool("Unequip")
			else
				module.selectTool(Template.Name)
			end
		end)
	end
	uis.InputBegan:Connect(function(p1,p2)
		if p2 then return end
		for i,v in pairs(Frame:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "Keybind" then
				local realkeybind = nil
				for b,c in pairs(Word2Number) do
					if tostring(c) == v.Text then
						realkeybind = b
					end
				end
				if p1.KeyCode == Enum.KeyCode[realkeybind] then
					if module.currentlySelected == v.Parent.Name then
						module.selectTool("Unequip")
					else
						module.selectTool(v.Parent.Name)
					end
				end
			end
		end
	end)
	local mouse = Player:GetMouse()
	mouse.Button1Down:Connect(function()
		if module.currentlySelected ~= "Unequip" then
			script.connectionEvent:FireServer("Use Tool",module.currentlySelected,mouse)
		else
			script.connectionEvent:FireServer("Use Tool","Unequip")
		end
	end)
	script.connectionEvent.OnClientEvent:Connect(function(arg,arg2,arg3)
		if arg == "Remove Tool" then
			module.removeTool(arg2,arg3)
			module.selectTool("Unequip")
		elseif arg == "Insert Tools" then
			for i,v in pairs(tools) do
				module.addTool(i)
			end
			
		end
	end)
end

--this inserts the template for the ui and the icon along with it

module.addTool = function(stringForTool)
	local Player = game.Players.LocalPlayer
	local PlayerUI = Player:WaitForChild("PlayerGui")
	local Inventory = PlayerUI:WaitForChild("Inventory")
	local Frame = Inventory.Frame.Frame
	local children = Frame:GetChildren()
	local Template = script.Interface.Template.ImageButton:Clone()
	Template.Parent = Frame
	Template.Name = stringForTool
	for b,c in pairs(Word2Number) do
		if c == #children + 1 then
			Template.Keybind.Text = b
		end
	end
	Template.Description.Text = stringForTool
	local Icon = script.Interface.Icons:FindFirstChild(stringForTool)
	Icon.Parent = Template
	Icon.AnchorPoint = Vector2.new(0.5,0.5)
	Icon.Size = UDim2.fromScale(1,1)
	Icon.Position = UDim2.new(0.5,0,0.5,0)
	script.connectionEvent:FireServer("Add Information", stringForTool)
	Template.MouseButton1Down:Connect(function()
		if module.currentlySelected == Template.Name then
			module.selectTool("Unequip")
		else
			module.selectTool(Template.Name)
		end
	end)
end

--this is for when people select tools, to equip them

module.selectTool = function(stringforTool)
	if module.canEquip == false then return end
	local Player = game.Players.LocalPlayer
	local Player = game.Players.LocalPlayer
	local PlayerUI = Player:WaitForChild("PlayerGui")
	local Inventory = PlayerUI:WaitForChild("Inventory")
	local Frame = Inventory.Frame.Frame
	script.Sounds["ui click"]:Play()
	module.currentlySelected = stringforTool
	for i,v in pairs(Frame:GetChildren()) do
		if v:IsA("ImageButton") then
			if v.Name ~= stringforTool then
				game:GetService("TweenService"):Create(v,TweenInfo.new(.5,Enum.EasingStyle.Linear),{Size = UDim2.new(0.165, 0,0.838, 0)}):Play()
			else
				game:GetService("TweenService"):Create(v.Glow,TweenInfo.new(.2,Enum.EasingStyle.Linear),{BackgroundTransparency = 0}):Play()
				task.delay(.2,function()
					game:GetService("TweenService"):Create(v.Glow,TweenInfo.new(.2,Enum.EasingStyle.Linear),{BackgroundTransparency = 1}):Play()
				end)
				game:GetService("TweenService"):Create(v,TweenInfo.new(.5,Enum.EasingStyle.Linear),{Size = UDim2.new(0.181, 0,0.919, 0)}):Play()
			end
		end
	end
	script.connectionEvent:FireServer("Equip Tool",stringforTool)
end

--this is for when they are equipped to handle visual data

module.equipTool = function(toolString,Character)
	for i,v in pairs(Character:GetChildren()) do
		if v:IsA("Model") then
			if v.Name == "Tool" then
				v:Destroy()
			end
		end
	end
	for i,v in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
		if v.Name == "Tool Holding" then
			v:Stop()
		end
	end
	if toolString ~= "Unequip" then
		local Model = script.Tools:FindFirstChild(toolString):Clone()
		Model.Name = "Tool"
		local info = tools[toolString]
		Model.Parent = Character
		if info.Hand == "Right" then
			Model:SetPrimaryPartCFrame(Character.RightHand.CFrame * info.Offset ) 
			local Weld = Instance.new("WeldConstraint",Model.PrimaryPart)
			Weld.Part0 = Character.RightHand
			Weld.Part1 = Model.PrimaryPart
		elseif info.Hand == "Left" then
			Model:SetPrimaryPartCFrame(Character.LeftHand.CFrame * info.Offset ) 
			local Weld = Instance.new("WeldConstraint",Model.PrimaryPart)
			Weld.Part0 = Character.LeftHand
			Weld.Part1 = Model.PrimaryPart
		end
		if info.HoldingAnimation ~= "None" then
			local Animation = Character.Humanoid:LoadAnimation(info.HoldingAnimation)
			Animation:Play()
			Animation.Name = "Tool Holding"
		end
	end
end

module.removeTool = function(stringforTool,Player)
	local PlayerUI = Player:WaitForChild("PlayerGui")
	local Inventory = PlayerUI:WaitForChild("Inventory")
	local Frame = Inventory.Frame.Frame
	if Frame:FindFirstChild(stringforTool) then
		local Tool = Frame:FindFirstChild(stringforTool)
		if Tool then
			Tool:Destroy()
		end
	end
end

--this function is for the tools functionality, for example the salt creates a sigil beneath them made from salt to be used in a ritual, and candles are placed within a template of the model.

module.useTool = function(stringforTool, Player, Character, mouse)
	if stringforTool == "Unequip" then return end
	local info = tools[stringforTool]
	local playerInfo = module.toolInformation[Player]
	if playerInfo then
		if playerInfo[stringforTool].Uses <= info.Uses then
			module.canEquip = false
			playerInfo[stringforTool].Uses = playerInfo[stringforTool].Uses - 1
			if stringforTool == "Salt" then
				local Tool = Character:FindFirstChild("Tool")
				if Tool then
					if info.TriggerAnimation ~= "None" then
						Character.Humanoid:LoadAnimation(info.TriggerAnimation):Play()
					end
					for i,v in pairs(Tool:GetDescendants()) do
						if v:IsA("ParticleEmitter") then
							v.Enabled = true
							task.delay(1.33,function()
								v.Enabled = false
							end)
						end
					end
					local sound = script.Sounds["salt shaker"]:Clone()
					sound.Parent = Character.Head
					sound:Play()
					task.delay(1.33,function()
						game:GetService("TweenService"):Create(sound,TweenInfo.new(.5,Enum.EasingStyle.Linear),{Volume = 0}):Play()
						task.wait(.5)
						sound:Destroy()
					end)
					task.wait(1.33)
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = Character:GetDescendants()
					local objhit = workspace:Raycast(Character.PrimaryPart.Position,Vector3.new(0,-10000,0),params)
					if objhit then
						local Sigil = game.ServerStorage.Freya.Objects["Freya Ritual Circle"]:Clone()
						Sigil.Parent = workspace
						Sigil:SetPrimaryPartCFrame(CFrame.new(objhit.Position))
						Sigil.Name = Player.Name.." Ritual Circle"
						for i,v in pairs(Sigil:GetChildren()) do
							if v:IsA("BasePart") then
								if v.Transparency == 0 then
									v.Transparency = 1
									game:GetService("TweenService"):Create(v,TweenInfo.new(.5,Enum.EasingStyle.Linear),{Transparency = 0}):Play()
								end
							end
						end
					end
					if playerInfo[stringforTool].Uses <1 then
						script.connectionEvent:FireClient(Player,"Remove Tool",stringforTool,Player)
					end
				end
			elseif stringforTool == "Candle" then
				local p1 = Character.HumanoidRootPart.Position - Vector3.new(20,20,20)
				local p2 = Character.HumanoidRootPart.Position + Vector3.new(20,20,20)
				local ig = {Character}
				local region = Region3.new(p1,p2)
				local row = workspace:FindPartsInRegion3WithIgnoreList(region,ig,10000)
				for i,v in pairs(row) do
					if v:IsA("BasePart") and v.Name == "Ritual Circle" and v.Parent.Name == Player.Name.." Ritual Circle" then
						v.Parent:SetAttribute("Candles",v.Parent:GetAttribute("Candles")+1)
						local model = v.Parent
						local candle = model:GetAttribute("Candles")
						local sound = script.Sounds.thud:Clone()
						sound.Parent = model.PrimaryPart
						sound:Play()
						if candle == 1 then
							model["Candle 2.003"].Transparency = 0
						elseif candle == 2 then
							model["Candle 3.001"].Transparency = 0
						end
					end
				end
				if playerInfo[stringforTool].Uses <1 then
					script.connectionEvent:FireClient(Player,"Remove Tool",stringforTool,Player)
				end
			end
		end
	end
end

return module
