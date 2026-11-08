package com.glasschat.app.data.repository

import com.glasschat.app.data.local.db.dao.ChatDao
import com.glasschat.app.data.local.db.dao.ChatParticipantDao
import com.glasschat.app.data.local.db.dao.ContactDao
import com.glasschat.app.data.local.db.entity.ContactEntity
import com.glasschat.app.data.mapper.toDomain
import com.glasschat.app.di.IoDispatcher
import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.util.newId
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ContactRepositoryImpl @Inject constructor(
    private val contactDao: ContactDao,
    private val participantDao: ChatParticipantDao,
    private val chatDao: ChatDao,
    @IoDispatcher private val io: CoroutineDispatcher,
) : ContactRepository {

    override fun observeContacts(): Flow<List<Contact>> =
        contactDao.observeAll().map { contacts -> contacts.map { it.toDomain() } }

    override fun observeContact(contactId: String): Flow<Contact?> =
        contactDao.observeById(contactId).map { it?.toDomain() }

    override suspend fun getContact(contactId: String): Contact? =
        withContext(io) { contactDao.getById(contactId)?.toDomain() }

    override suspend fun countContacts(): Int = withContext(io) { contactDao.count() }

    override suspend fun createContact(draft: ContactDraft): String = withContext(io) {
        val id = newId()
        contactDao.insert(draft.toEntity(id))
        id
    }

    override suspend fun updateContact(contactId: String, draft: ContactDraft) = withContext(io) {
        val existing = contactDao.getById(contactId) ?: return@withContext
        contactDao.update(
            existing.copy(
                name = draft.name.trim().ifBlank { existing.name },
                avatarUri = draft.avatarUri,
                accentColor = draft.accentColor,
                bio = draft.bio.trim(),
                phoneLabel = draft.phoneLabel.trim(),
                notes = draft.notes.trim(),
            ),
        )
        Unit
    }

    /**
     * Deleting a contact also removes their chat memberships (FK cascade). Any chat left
     * with nobody in it cannot be written to from the "other" side, so it is removed too.
     */
    override suspend fun deleteContact(contactId: String) = withContext(io) {
        val affectedChats = participantDao.getAll().filter { it.contactId == contactId }.map { it.chatId }
        contactDao.deleteById(contactId)
        affectedChats.distinct().forEach { chatId ->
            if (participantDao.getContactIds(chatId).isEmpty()) chatDao.deleteById(chatId)
        }
        Unit
    }

    override suspend fun setFavorite(contactId: String, favorite: Boolean) = withContext(io) {
        contactDao.setFavorite(contactId, favorite)
    }

    override suspend fun setBlocked(contactId: String, blocked: Boolean) = withContext(io) {
        contactDao.setBlocked(contactId, blocked)
    }

    private fun ContactDraft.toEntity(id: String): ContactEntity = ContactEntity(
        id = id,
        name = name.trim().ifBlank { "New contact" },
        avatarUri = avatarUri,
        accentColor = accentColor,
        bio = bio.trim(),
        phoneLabel = phoneLabel.trim(),
        notes = notes.trim(),
        isFavorite = false,
        isBlocked = false,
        createdAt = System.currentTimeMillis(),
    )
}
