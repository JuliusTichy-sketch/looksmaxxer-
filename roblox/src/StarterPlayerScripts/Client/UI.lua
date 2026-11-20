--[[
	UI – kleine Helfer, um Oberflächen per Code zu bauen.
	Farben und Schriften des Spiels sind hier festgelegt.
]]

local UI = {}

UI.C = {
	bg = Color3.fromRGB(26, 11, 46),
	panel = Color3.fromRGB(45, 18, 78),
	panel2 = Color3.fromRGB(64, 28, 108),
	dark = Color3.fromRGB(15, 5, 28),
	pink = Color3.fromRGB(255, 79, 216),
	purple = Color3.fromRGB(155, 92, 255),
	cyan = Color3.fromRGB(62, 242, 255),
	gold = Color3.fromRGB(255, 209, 102),
	orange = Color3.fromRGB(255, 159, 67),
	green = Color3.fromRGB(78, 240, 160),
	money = Color3.fromRGB(124, 252, 154),
	red = Color3.fromRGB(255, 93, 115),
	text = Color3.new(1, 1, 1),
	muted = Color3.fromRGB(199, 181, 220),
	grey = Color3.fromRGB(90, 80, 110),
}

-- Instanz mit Eigenschaften und Kindern erstellen
function UI.new(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(inst, radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = inst })
end

function UI.stroke(inst, color, thickness, transparency)
	return UI.new("UIStroke", {
		Color = color or Color3.new(1, 1, 1), Thickness = thickness or 1.5,
		Transparency = transparency or 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst,
	})
end

function UI.gradient(inst, c1, c2, rotation)
	return UI.new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 0, Parent = inst })
end

function UI.padding(inst, px)
	return UI.new("UIPadding", {
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px), Parent = inst,
	})
end

function UI.list(inst, horizontal, padding, hAlign, vAlign)
	return UI.new("UIListLayout", {
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		Parent = inst,
	})
end

-- Textfeld (passt die Schriftgröße automatisch an)
function UI.text(parent, text, props)
	props = props or {}
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Text = text or "",
		RichText = true,
		TextScaled = true,
		Font = props.Font or Enum.Font.FredokaOne,
		TextColor3 = props.Color or UI.C.text,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		TextWrapped = true,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Name = props.Name or "Label",
		Parent = parent,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = math.min(props.MaxText or 26, 100), MinTextSize = props.MinText or 8, Parent = l })
	return l
end

-- Knopf
function UI.button(parent, text, color, onClick, props)
	props = props or {}
	local b = UI.new("TextButton", {
		Size = props.Size or UDim2.new(0, 120, 0, 40),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = color or UI.C.purple,
		AutoButtonColor = true,
		Text = text or "",
		RichText = true,
		TextScaled = true,
		Font = props.Font or Enum.Font.FredokaOne,
		TextColor3 = props.TextColor or UI.C.text,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Name = props.Name or "Button",
		Parent = parent,
	})
	UI.corner(b, props.Radius or 10)
	UI.new("UITextSizeConstraint", { MaxTextSize = math.min(props.MaxText or 22, 100), MinTextSize = 8, Parent = b })
	UI.padding(b, props.Pad or 4)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Panel (Hintergrund-Kasten)
function UI.panel(parent, props)
	props = props or {}
	local f = UI.new("Frame", {
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = props.Color or UI.C.panel,
		BackgroundTransparency = props.Transparency or 0,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Name = props.Name or "Panel",
		Parent = parent,
	})
	UI.corner(f, props.Radius or 14)
	return f
end

-- Scrollbare Liste
function UI.scroll(parent, props)
	props = props or {}
	local s = UI.new("ScrollingFrame", {
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UI.C.pink,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = props.Horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		ScrollingDirection = props.Horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
		Name = props.Name or "Scroll",
		Parent = parent,
	})
	return s
end

-- Farbe als Hex-Text für RichText
function UI.hex(c)
	return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

function UI.clear(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

return UI
