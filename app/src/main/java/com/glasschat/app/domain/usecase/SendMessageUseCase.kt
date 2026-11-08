package com.glasschat.app.domain.usecase

import com.glasschat.app.domain.model.PendingAttachment
import com.glasschat.app.domain.model.SendMessageRequest
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.MessageRepository
import javax.inject.Inject

/**
 * Validates and persists a message written by either side of the simulated conversation.
 *
 * Rules enforced here (not in the UI, so they cannot be bypassed):
 *  * empty messages without attachments are rejected;
 *  * a message attributed to a contact must reference a participant of that chat;
 *  * a one-to-one chat always attributes contact messages to its single participant.
 */
class SendMessageUseCase @Inject constructor(
    private val messageRepository: MessageRepository,
    private val chatRepository: ChatRepository,
) {

    suspend operator fun invoke(
        chatId: String,
        senderType: SenderType,
        senderContactId: String?,
        text: String,
        replyToMessageId: String? = null,
        attachments: List<PendingAttachment> = emptyList(),
    ): String? {
        val trimmed = text.trim()
        if (trimmed.isEmpty() && attachments.isEmpty()) return null

        val detail = chatRepository.getChatDetailOnce(chatId) ?: return null
        val resolvedContactId = when (senderType) {
            SenderType.ME -> null
            SenderType.CONTACT -> {
                val requested = senderContactId?.takeIf { id ->
                    detail.participants.any { it.contactId == id }
                }
                requested ?: detail.participants.firstOrNull()?.contactId ?: return null
            }
        }

        val messageId: String = messageRepository.sendMessage(
            SendMessageRequest(
                chatId = chatId,
                senderType = senderType,
                senderContactId = resolvedContactId,
                text = trimmed,
                replyToMessageId = replyToMessageId,
                attachments = attachments,
            ),
        )
        return messageId
    }
}
