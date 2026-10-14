extends Node

class_name UCIEngine

# Provide functionality for interactions with a Chess Engine
# Also, find the installed exe files rather than needing UI entry by user

var engine # Path3D of installed Chess Engine in the engine directory

var engine_process
var engine_pid: int = 0
var stdio: FileAccess
var stderr: FileAccess
var reader_thread := Thread.new()
var reader_running: bool

signal done

func _ready():
	# Get the base path of the application files
	var cmd = "pwd"
	var params = []
	if OS.get_name() == "Windows":
		cmd = "cmd.exe"
		params = ["/c", "cd"]
	elif OS.get_name() == "Linux":
		engine = "stockfish"
		return
		
	var output = []
	var _exit_code = OS.execute(cmd, params, output)
	var path = output[0].strip_edges() # Remove cstring null termination char
	# Allow for running in dev mode, so back peddle from src folder
	var src_pos = path.find("src")
	if src_pos > -1:
		path = path.substr(0, src_pos - 1)
	
	# Form paths to the executables
	# Use forward slash for all platforms
	engine = path + "/engine/"

	# Get the first file found in the engine folder for the Chess Engine to use
	var dir = DirAccess.open(engine)
	if dir != null:
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		engine += dir.get_next()

func _reader_loop() -> void:
	while reader_running:
		if stdio == null or not stdio.is_open():
			break

		var line := stdio.get_line()

		if not reader_running:
			break

		if line.is_empty():
			continue

		call_deferred(
			"_handle_engine_line",
			line
		)

func _handle_engine_line(line: String) -> void:
	$Timer.stop()
	# Dont print verbose lines
	if !line.begins_with("info depth"):
		print("UCI: ", line)
	emit_signal("done", true, line)

func start_engine():
	var err = ""
	# Check for existence of the exe files
	#var file = FileAccess.new()
	if !FileAccess.file_exists(engine) and OS.get_name() == "Windows":
		err = "Missing engine at: " + engine
	else:
		engine_process = OS.execute_with_pipe(engine, [], false)
		
		if engine_process.is_empty():
			err = "Unable to start chess engine"
		
		engine_pid = int(engine_process.get("pid"))
		stdio = engine_process.get("stdio") as FileAccess
		stderr = engine_process.get("stderr") as FileAccess
		
		reader_running = true
		reader_thread.start(_reader_loop)
		
		if engine_pid < 400: # PIDs are likely above this value and error codes below it
			err = "Unable to start chess engine with error code: " + str(engine_pid)
			engine_pid = 0
	return { "started": err == "", "error": err }

func stop_engine() -> void:
	reader_running = false

	if stdio != null and stdio.is_open():
		stdio.store_string("quit\n")
		stdio.flush()

	if reader_thread.is_started():
		reader_thread.wait_to_finish()

	if engine_pid > 0 and OS.is_process_running(engine_pid):
		OS.kill(engine_pid)

	stdio = null
	stderr = null
	engine_pid = -1
	engine_process.clear()

func send_command(pkt: String):
	print("Sent command: ", pkt)
	stdio.store_string(pkt + "\n")
	stdio.flush()
	$Timer.start()

func _on_Timer_timeout():
	stop_engine()
	emit_signal("done", false, "")

func _on_Engine_tree_exited():
	stop_engine()
