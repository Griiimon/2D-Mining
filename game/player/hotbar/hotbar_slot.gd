extends PanelContainer
class_name HotbarSlot

@onready var selection: TextureRect = $Selection
@onready var texture_rect: TextureRect = $TextureRect
@onready var amount_label: Label = $MarginContainer/Amount

var selected: bool= false: set= set_selected


func set_item(inv_item: InventoryItem):
	if not inv_item.item:
		texture_rect.texture= null
		amount_label.hide()
	else:
		texture_rect.texture= inv_item.item.texture
		if inv_item.item.can_stack:
			amount_label.text= str(inv_item.amount)
			amount_label.show()
		else:
			amount_label.hide()


func set_selected(b: bool):
	selected= b
	selection.visible= selected
