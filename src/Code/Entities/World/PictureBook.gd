extends CanvasLayer

@export var book_title := "月族图书馆藏书 · 残缺的绘本"
@export var pages: Array[String] = [
	"画册前半部分，日族与月族会一起出现。有人在白昼下耕作，有人在长夜中寻找水源；他们交换食物与水，一起商议决策、休闲娱乐。他们的脸上挂着笑容。",
	"可最后几页，画面出现了奇怪的变化，有些人物的表情被改成了悲伤，原本空着的手上被添上了刀剑、长矛，画面的角落也被画上了武器。",
	"最后一页，原本画的是在广场上一起庆祝节日的集会，但现在每个人的表情都被改了，全都是悲伤的表情。"
]
@export var page_monologues: Array[String] = []
@export var close_monologues: Array[String] = [
	"这些月族人……有和我一样的耳朵和尾巴……",
	"他们曾经毫无嫌隙地生活在一起。后来究竟发生了什么事情……"
]

@onready var _root: Control = $Root
@onready var _page_text: Label = $Root/Book/Pages/PageText
@onready var _page_number: Label = $Root/Book/Pages/Navigation/PageNumber
@onready var _previous: Button = $Root/Book/Pages/Navigation/Previous
@onready var _next: Button = $Root/Book/Pages/Navigation/Next
@onready var _close: Button = $Root/Book/Pages/Close
@onready var _interactable: InteractableComponent = get_parent()

var _page_index := 0
var _read_pages: Dictionary = {}
var _waiting_for_dialog := false

func _ready() -> void:
	_root.hide()
	$Root/Book/Pages/Title.text = book_title
	_interactable.Interacted.connect(_open)
	_previous.pressed.connect(_change_page.bind(-1))
	_next.pressed.connect(_change_page.bind(1))
	_close.pressed.connect(_close_book)

func _open(_interactor: Node2D) -> void:
	_page_index = 0
	_read_pages.clear()
	_update_page()
	_root.show()
	_interactable.enable_interaction = false
	_interactable._lock_players()
	_read_current_page()

func _change_page(direction: int) -> void:
	if _waiting_for_dialog:
		return
	_page_index = clampi(_page_index + direction, 0, pages.size() - 1)
	_update_page()
	_read_current_page()

func _update_page() -> void:
	_page_text.text = pages[_page_index]
	_page_number.text = "%d / %d" % [_page_index + 1, pages.size()]
	_previous.disabled = _page_index == 0
	_next.disabled = _page_index == pages.size() - 1

func _read_current_page() -> void:
	if _read_pages.has(_page_index):
		return
	_read_pages[_page_index] = true
	if _page_index < page_monologues.size() and not page_monologues[_page_index].is_empty():
		var current_page := _page_index
		await RenderingServer.frame_post_draw
		if _root.visible and _page_index == current_page:
			_show_monologues([page_monologues[current_page]], false)

func _close_book() -> void:
	if _waiting_for_dialog:
		return
	_root.hide()
	if close_monologues.is_empty():
		_on_monologue_finished(true)
	else:
		_show_monologues(close_monologues, true)

func _show_monologues(lines: Array[String], closing: bool) -> void:
	if closing:
		_root.hide()
	_waiting_for_dialog = true
	var dialog_box: Node = _interactable._dialog_box
	if dialog_box != null:
		dialog_box.Finished.connect(_on_monologue_finished.bind(closing), CONNECT_ONE_SHOT)
	for line in lines:
		SignalBus.DialogBox.emit(&"独白", line)
	if dialog_box == null:
		_on_monologue_finished(closing)

func _on_monologue_finished(closing: bool) -> void:
	_waiting_for_dialog = false
	if closing:
		_interactable._unlock_players()
		_interactable.enable_interaction = true
	else:
		_interactable._lock_players()
		_root.show()

func _input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_close_book()
