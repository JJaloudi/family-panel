local Family = {}

function Family:Init()
	self.Scale = 1
	self.Offset = {x = 0, y = 0}
	self.Bounds = {x = 1000, y = 1000}
	self.Velocity = {x = 0, y = 0}
	self:MakePopup()

	self.CapturedPress = false
	self.lastCheck = CurTime()
	self.Items = {}
	
	self:SetTitle("")
end

function Family:OnMousePressed(key)
	if (key == (MOUSE_RIGHT || MOUSE_MIDDLE)) then
		self.CapturedPress = {x = gui.MouseX(), y = gui.MouseY()}
	end
end

function Family:OnMouseReleased(key)
	if (key == (MOUSE_RIGHT || MOUSE_MIDDLE)) then
		self.captureReleased = true
	end
end

function Family:Think()
	local xSpeed, ySpeed = 0.0, 0.0
	local xDist, yDist = 0.0, 0.0
	if (CurTime() - self.lastCheck > 0.1 && self.CapturedPress) then
		local currentPosition = {x = gui.MouseX(), y = gui.MouseY()}
		xDist, yDist = self.CapturedPress.x - currentPosition.x, self.CapturedPress.y - currentPosition.y
		xSpeed, ySpeed = (xDist * 10), (yDist * 10)
		
		self.CapturedPress = currentPosition
		
		if (!self.captureReleased) then
			self.Offset.x, self.Offset.y = (self.Offset.x - xDist), (self.Offset.y - yDist)
			self.Velocity = {x = 0, y = 0}
		else
			
		
			if (math.abs(xSpeed) > 10) then
				self.Velocity.x = self.Velocity.x - xSpeed
			end
			if (math.abs(ySpeed) > 10) then
				self.Velocity.y = self.Velocity.y - ySpeed
			end
			
			self.captureReleased = false
			self.CapturedPress = false
		end
	end
	
	if (!self.CapturedPress) then
		if (math.abs(self.Velocity.x) > 0 || math.abs(self.Velocity.y) > 0) then		
			self.Velocity.x = math.Approach(self.Velocity.x, 0, 0.5)
			self.Velocity.y = math.Approach(self.Velocity.y, 0, 0.5)
			
			if (self.Velocity.x - self.Velocity.y <= 30 && ((self.Velocity.x > 0 && self.Velocity.y > 0) || (self.Velocity.x < 0 && self.Velocity.y < 0))) then
				local avg = (self.Velocity.x + self.Velocity.y) / 2
				self.Velocity.x = avg
				self.Velocity.y = avg
			end
			
			self.Offset.x = self.Offset.x + self.Velocity.x
			self.Offset.y = self.Offset.y + self.Velocity.y
		end
	end
	
	if(input.IsKeyDown(KEY_MINUS)) then
		self.Scale = self.Scale - 0.01
	end
	
	if(input.IsKeyDown(KEY_EQUAL)) then
		self.Scale = self.Scale + 0.01
	end
	
	self.Scale = math.Clamp(self.Scale, 0.25, 1) 
end

local bg = Material("backgrounds/tree_bg.png")
function Family:Paint(w, h)
	local xs, ys = w * 1.25, h * 1.25

	surface.SetDrawColor(color_white)
	surface.SetMaterial(bg)
	surface.DrawTexturedRect((w/2 - xs/2) - (math.Clamp(self.Offset.x * self.Scale, -w/2, w/2)/4), (h/2 - ys/2) - (math.Clamp(self.Offset.y * self.Scale, -h/2, h/2)/4), xs, ys)
	
	local x, y = draw.SimpleText("Velocity: x: "..-self.Velocity.x.." y: "..self.Velocity.y, "Default", 5, 5, color_black)
	x, y = draw.SimpleText("Offset: x: "..-self.Offset.x.." y: "..self.Offset.y, "Default", 5, y + 5, color_black)
	draw.SimpleText("Zoom: " .. self.Scale * 100 .. "%", "Default", 5, y*2 + 5, color_black)
end

function Family:AddItem(item)
	item:SetParent(self)
	item.Tree = self
	
	self.Items[#self.Items + 1] = item
	
	local xp, yp = item:GetPos()
	item.savedData = {
		size = {
			x = item:GetWide(),
			y = item:GetTall()
		},
		pos = {
			x = xp,
			y = yp
		}
	}

	local oldpress = item.OnMousePressed
	function item:OnMousePressed(key)		
		if (key == (MOUSE_RIGHT || MOUSE_MIDDLE)) then
			self.Tree.CapturedPress = {x = gui.MouseX(), y = gui.MouseY()}
		else
			oldpress(self, key)
		end
	end
	
	local oldrelease = item.OnMouseReleased
	function item:OnMouseReleased(key)
		if (key == (MOUSE_RIGHT || MOUSE_MIDDLE)) then
			self.Tree.captureReleased = true
		else
			oldrelease(self, key)
		end
	end
	
	local oldthink = item.Think
	function item:Think()
		local tree = self.Tree
		local data = self.savedData
		oldthink(self)
		
		if (!self.ignoreScale) then
			self:SetSize(data.size.x * tree.Scale, data.size.y * tree.Scale)
		end
		
		self:SetPos(
			tree:GetWide()/2 + (data.pos.x + tree.Offset.x) * tree.Scale, 
			tree:GetTall()/2 + (data.pos.y + tree.Offset.y) * tree.Scale
		)
	end
end
vgui.Register("FamilyView", Family, "DFrame")
