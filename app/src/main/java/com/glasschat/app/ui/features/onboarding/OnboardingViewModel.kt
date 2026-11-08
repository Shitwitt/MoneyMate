package com.glasschat.app.ui.features.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.model.SendMessageRequest
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.model.ThemeMode
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MessageRepository
import com.glasschat.app.domain.repository.SettingsRepository
import com.glasschat.app.domain.usecase.CreateChatUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class OnboardingUiState(
    val step: Int = 0,
    val displayName: String = "Me",
    val accent: Long = 0xFF8C7CFF,
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val includeSamples: Boolean = true,
    val isFinishing: Boolean = false,
) {
    companion object {
        const val STEP_COUNT = 3
    }
}

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val contactRepository: ContactRepository,
    private val chatRepository: ChatRepository,
    private val messageRepository: MessageRepository,
    private val createChatUseCase: CreateChatUseCase,
) : ViewModel() {

    private val _uiState = MutableStateFlow(OnboardingUiState())
    val uiState: StateFlow<OnboardingUiState> = _uiState.asStateFlow()

    fun next() = _uiState.update { it.copy(step = (it.step + 1).coerceAtMost(OnboardingUiState.STEP_COUNT - 1)) }

    fun back() = _uiState.update { it.copy(step = (it.step - 1).coerceAtLeast(0)) }

    fun setName(value: String) = _uiState.update { it.copy(displayName = value.take(30)) }
    fun setAccent(color: Long) = _uiState.update { it.copy(accent = color) }
    fun setTheme(mode: ThemeMode) = _uiState.update { it.copy(themeMode = mode) }
    fun setIncludeSamples(value: Boolean) = _uiState.update { it.copy(includeSamples = value) }

    fun finish(onComplete: () -> Unit) {
        val state = _uiState.value
        if (state.isFinishing) return
        _uiState.update { it.copy(isFinishing = true) }
        viewModelScope.launch {
            settingsRepository.setProfile(
                displayName = state.displayName.ifBlank { "Me" },
                about = "Offline and on purpose.",
                avatarUri = null,
                accent = state.accent,
            )
            settingsRepository.setAccent(state.accent)
            settingsRepository.setThemeMode(state.themeMode)
            if (state.includeSamples && contactRepository.countContacts() == 0) {
                seedSamples()
            }
            settingsRepository.setOnboardingComplete(true)
            onComplete()
        }
    }

    /**
     * Optional starter content. It behaves exactly like user-created data: both sides are
     * authored locally, and every chat/message can be deleted.
     */
    private suspend fun seedSamples() {
        val maya = contactRepository.createContact(
            ContactDraft(
                name = "Maya Chen",
                accentColor = 0xFF4FE3D5,
                bio = "Night owl. Keeps a film camera in her bag.",
                phoneLabel = "mobile",
            ),
        )
        val chatId = createChatUseCase(
            title = "Maya Chen",
            type = ChatType.ONE_TO_ONE,
            existingContactIds = listOf(maya),
        )
        val now = System.currentTimeMillis()
        val script = listOf(
            Triple(SenderType.CONTACT, "Morning! Did the new glass theme land?", 46L),
            Triple(SenderType.ME, "Just finished it. Every panel is frosted now.", 44L),
            Triple(SenderType.CONTACT, "Send a screenshot when you can ✨", 39L),
            Triple(SenderType.ME, "Tonight. Coffee first ☕", 12L),
        )
        script.forEach { (speaker, text, minutesAgo) ->
            messageRepository.sendMessage(
                SendMessageRequest(
                    chatId = chatId,
                    senderType = speaker,
                    senderContactId = if (speaker == SenderType.CONTACT) maya else null,
                    text = text,
                    createdAt = now - minutesAgo * 60_000L,
                ),
            )
        }
        chatRepository.markUnread(chatId)

        val theo = contactRepository.createContact(
            ContactDraft(
                name = "Theo Avery",
                accentColor = 0xFFFFC46B,
                bio = "Designs posters, hoards typefaces.",
            ),
        )
        val groupId = createChatUseCase(
            title = "Studio trio",
            type = ChatType.GROUP,
            existingContactIds = listOf(maya, theo),
        )
        val groupScript = listOf(
            Triple(SenderType.CONTACT, "Who has the print-ready files?", 320L),
            Triple(SenderType.ME, "Uploaded them to the shared folder.", 315L),
            Triple(SenderType.CONTACT, "Perfect — reviewing after lunch.", 300L),
        )
        groupScript.forEach { (speaker, text, minutesAgo) ->
            messageRepository.sendMessage(
                SendMessageRequest(
                    chatId = groupId,
                    senderType = speaker,
                    senderContactId = if (speaker == SenderType.CONTACT) theo else null,
                    text = text,
                    createdAt = now - minutesAgo * 60_000L,
                ),
            )
        }
        chatRepository.markUnread(groupId)
    }
}
