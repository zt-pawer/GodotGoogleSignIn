import SwiftGodotRuntime

private func makeGodotGoogleSignInTypes() -> [ExtensionInitializationLevel: [Object.Type]] {
    do {
        return try [
            GodotGoogleSignIn.self,
        ].prepareForRegistration()
    } catch {
        fatalError("Failed to prepare GodotGoogleSignIn registrations: \(error)")
    }
}

private let godotGoogleSignInTypes = makeGodotGoogleSignInTypes()

public let godotGoogleSignInMinimumInitializationLevel = minimumInitializationLevel(
    for: godotGoogleSignInTypes
)

public func godotGoogleSignInInitialize(level: ExtensionInitializationLevel) {
    godotGoogleSignInTypes[level]?.forEach(register)
}

public func godotGoogleSignInDeinitialize(level: ExtensionInitializationLevel) {
    godotGoogleSignInTypes[level]?.reversed().forEach(unregister)
}

@_cdecl("godot_google_sign_in_start")
public func godotGoogleSignInStart(interface: OpaquePointer?, library: OpaquePointer?, extension: OpaquePointer?) -> UInt8 {
    guard let interface, let library, let `extension` else {
        print("Error: Not all parameters were initialized.")
        return 0
    }
    initializeSwiftModule(
        interface,
        library,
        `extension`,
        initHook: godotGoogleSignInInitialize,
        deInitHook: godotGoogleSignInDeinitialize,
        minimumInitializationLevel: godotGoogleSignInMinimumInitializationLevel
    )
    return 1
}
