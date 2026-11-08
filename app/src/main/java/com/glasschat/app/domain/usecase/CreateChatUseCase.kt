package com.glasschat.app.domain.usecase

import com.glasschat.app.domain.model.ChatTemplates
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.model.CreateChatRequest
import com.glasschat.app.domain.model.SendMessageRequest
import com.glasschat.app.domain.model.SenderType
import com.glasschat.app.domain.repository.ChatRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.MessageRepository
import javax.inject.Inject

/**
 * Creates a conversation entirely on-device: optional new contacts, the chat row, its
 * participants and (optionally) template messages. Nothing here depends on a remote user.
 */
class CreateChatUseCase @Inject constructor(
    private val chatRepository: ChatRepository,
    private val contactRepository: ContactRepository,
    private val messageRepository: MessageRepository,
) {

    /**
     * @param newContacts contacts to create before the chat is assembled.
     * @return the id of the created chat.
     */
    suspend operator fun invoke(
        title: String,
        type: ChatType,
        existingContactIds: List<String> = emptyList(),
        newContacts: List<ContactDraft> = emptyList(),
        templateId: String? = null,
    ): String {
        val createdIds = newContacts.map { draft -> contactRepository.createContact(draft) }
        val participantIds = (existingContactIds + createdIds).distinct()
        require(participantIds.isNotEmpty()) { "A chat needs at least one contact" }

        val fallbackTitle = if (type == ChatType.GROUP) {
            "New group"
        } else {
            contactRepository.getContact(participantIds.first())?.name ?: "New chat"
        }

        val chatId = chatRepository.createChat(
            CreateChatRequest(
                title = title.trim().ifBlank { fallbackTitle },
                type = type,
                participantContactIds = participantIds,
                templateId = templateId,
            ),
        )

        val template = ChatTemplates.byId(templateId)
        if (template.seeds.isNotEmpty()) {
            val now = System.currentTimeMillis()
            val otherId = participantIds.first()
            template.seeds.forEach { seed ->
                messageRepository.sendMessage(
                    SendMessageRequest(
                        chatId = chatId,
                        senderType = if (seed.fromMe) SenderType.ME else SenderType.CONTACT,
                        senderContactId = if (seed.fromMe) null else otherId,
                        text = seed.text,
                        createdAt = now - seed.minutesAgo * 60_000L,
                    ),
                )
            }
            // Anything the other person "wrote" starts out unread, exactly like a real
            // inbox would, so the simulated unread badge has something to show.
            chatRepository.markUnread(chatId)
        }

        return chatId
    }
}
