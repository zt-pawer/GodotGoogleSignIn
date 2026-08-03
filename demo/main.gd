extends Node

var _google_signin: Object

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var sign_in_btn: Button = $VBoxContainer/HBoxContainer/SignIn
@onready var sign_out_btn: Button = $VBoxContainer/HBoxContainer/SignOut

# Replace with your own OAuth client IDs from Firebase Console / Google Cloud Console.
const IOS_CLIENT_ID := "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com"
const ANDROID_SERVER_CLIENT_ID := "YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com"

func _ready() -> void:
	# Android's v2 GodotPlugin loader exposes Kotlin plugins as an Engine
	# singleton; the Swift/SwiftGodotRuntime side registers a ClassDB class
	# instead, so the two platforms need different lookup calls.
	if OS.get_name() == "Android":
		if Engine.has_singleton("GodotGoogleSignIn"):
			_google_signin = Engine.get_singleton("GodotGoogleSignIn")
	elif ClassDB.class_exists("GodotGoogleSignIn"):
		_google_signin = ClassDB.instantiate("GodotGoogleSignIn")

	if _google_signin:
		_google_signin.google_sign_in_success.connect(_on_google_sign_in_success)
		_google_signin.google_sign_in_failed.connect(_on_google_sign_in_failed)
		_google_signin.google_sign_in_cancelled.connect(_on_google_sign_in_cancelled)
		var client_id := ANDROID_SERVER_CLIENT_ID if OS.get_name() == "Android" else IOS_CLIENT_ID
		_google_signin.configure(client_id)
		status_label.text = "GodotGoogleSignIn Initialized"
	else:
		status_label.text = "GodotGoogleSignIn not found"
		sign_in_btn.disabled = true
		sign_out_btn.disabled = true

func _on_sign_in_pressed() -> void:
	if _google_signin:
		status_label.text = "Signing in..."
		_google_signin.signIn()

func _on_sign_out_pressed() -> void:
	if _google_signin:
		_google_signin.signOut()
		status_label.text = "Signed out"

func _on_google_sign_in_success(id_token: String, access_token: String) -> void:
	status_label.text = "Success. idToken: %s..." % id_token.substr(0, 12)

func _on_google_sign_in_failed(error_message: String) -> void:
	status_label.text = "Failed: " + error_message

func _on_google_sign_in_cancelled() -> void:
	status_label.text = "Cancelled"
