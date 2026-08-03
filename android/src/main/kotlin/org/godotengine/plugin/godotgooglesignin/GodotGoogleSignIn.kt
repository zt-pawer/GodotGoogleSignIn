package org.godotengine.plugin.godotgooglesignin

import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.ClearCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class GodotGoogleSignIn(godot: Godot) : GodotPlugin(godot) {

    companion object {
        init {
            System.loadLibrary("GodotGoogleSignIn")
        }
    }

    override fun getPluginName() = "GodotGoogleSignIn"

    override fun getPluginGDExtensionLibrariesPaths() =
        setOf("res://addons/GodotGoogleSignIn/godot_google_sign_in.gdextension")

    override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
        SignalInfo("google_sign_in_success", String::class.java, String::class.java),
        SignalInfo("google_sign_in_failed", String::class.java),
        SignalInfo("google_sign_in_cancelled"),
    )

    private val scope = CoroutineScope(Dispatchers.Main)

    // Web-type OAuth client ID — same value as GameConfig.get_google_server_client_id(),
    // already used for Play Games' request_server_side_access.
    private var serverClientId: String = ""

    @UsedByGodot
    fun configure(clientId: String) {
        serverClientId = clientId
    }

    @UsedByGodot
    fun signIn() {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("google_sign_in_failed", "No activity found")
            return
        }
        if (serverClientId.isEmpty()) {
            emitSignal("google_sign_in_failed", "configure() must be called before signIn()")
            return
        }
        val signInOption = GetSignInWithGoogleOption.Builder(serverClientId).build()
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(signInOption)
            .build()

        scope.launch {
            try {
                val credentialManager = CredentialManager.create(activity)
                val result = credentialManager.getCredential(activity, request)
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(result.credential.data)
                // Credential Manager only yields an ID token — no OAuth access token.
                // Firebase's GoogleAuthProvider credential accepts a null/empty access token.
                emitSignal("google_sign_in_success", googleIdTokenCredential.idToken, "")
            } catch (e: GetCredentialCancellationException) {
                emitSignal("google_sign_in_cancelled")
            } catch (e: GetCredentialException) {
                emitSignal("google_sign_in_failed", e.message ?: e.type)
            }
        }
    }

    @UsedByGodot
    fun signOut() {
        val activity = getActivity() ?: return
        scope.launch {
            try {
                CredentialManager.create(activity).clearCredentialState(ClearCredentialStateRequest())
            } catch (e: ClearCredentialException) {
                // Best-effort sign-out; nothing actionable to surface to GDScript.
            }
        }
    }
}
