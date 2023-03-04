extends Node


var socket = WebSocketPeer.new()
func _ready():
	socket.handshake_headers = [
		"User-Agent: Mozilla"]
	socket.connect_to_url("wss://websocket-example-colbus.glitch.me/")

var time = 0
func _on_ping_timer_timeout():
	time = Time.get_ticks_msec()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(str(player_num)+"test ping")

var player_num = 1
var last_position
func _input(event):
	var my_player = get_node("Arena/Player"+str(player_num))
	if Input.is_action_pressed("w"): my_player.position.y -= 4
	if Input.is_action_pressed("a"): my_player.position.x -= 4
	if Input.is_action_pressed("s"): my_player.position.y += 4
	if Input.is_action_pressed("d"): my_player.position.x += 4
	# если позиция игрока изменилась, и мы подключены к сокету
	if last_position != my_player.position and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(
			JSON.stringify([player_num, my_player.position.x, my_player.position.y]))
		last_position = my_player.position

func _on_change_player_pressed():
	if player_num == 1: 
		player_num = 2
		$ChangePlayer/Label.text = 'Player 2'
	else: 
		player_num = 1
		$ChangePlayer/Label.text = 'Player 1'

func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	# если сокет открыт
	if state == WebSocketPeer.STATE_OPEN:
		# пока в пуле есть новые пакеты
		while socket.get_available_packet_count():
			# взять последний пакет из пула и преобразовать его в строку
			var packet_str = socket.get_packet().get_string_from_utf8()
			# если это проверка пинга
			if packet_str == str(player_num)+"test ping":
				$Ping.text = "Server ping: "+str(Time.get_ticks_msec()-time)
			# если это данные о другом игроке
			else:
				var packet = JSON.parse_string(packet_str)
				if packet[0] != player_num:
					var friend_player = get_node("Arena/Player"+str(packet[0]))
					friend_player.position = Vector2(packet[1], packet[2])
	# если сокет закрыт
	elif state == WebSocketPeer.STATE_CLOSED:
		print("WebSocket closed")
		# "убиваем" скрипт
		set_process(false)



