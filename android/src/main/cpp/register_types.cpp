#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

// All real logic lives in the Kotlin GodotPlugin (android/src/main/kotlin),
// reached via Engine.get_singleton("GodotGoogleSignIn") exactly like iOS/macOS.
// This shim only satisfies the v2 GDExtension-Android-plugin loader's
// requirement for a valid native binary.

void initialize_godot_google_sign_in_module(ModuleInitializationLevel p_level) {
}

void uninitialize_godot_google_sign_in_module(ModuleInitializationLevel p_level) {
}

extern "C" {
GDExtensionBool GDE_EXPORT godot_google_sign_in_start(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_godot_google_sign_in_module);
	init_obj.register_terminator(uninitialize_godot_google_sign_in_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
