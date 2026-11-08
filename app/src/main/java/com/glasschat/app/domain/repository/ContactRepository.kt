package com.glasschat.app.domain.repository

import com.glasschat.app.domain.model.Contact
import com.glasschat.app.domain.model.ContactDraft
import kotlinx.coroutines.flow.Flow

interface ContactRepository {
    fun observeContacts(): Flow<List<Contact>>
    fun observeContact(contactId: String): Flow<Contact?>
    suspend fun getContact(contactId: String): Contact?
    suspend fun countContacts(): Int

    /** @return the newly generated contact id. */
    suspend fun createContact(draft: ContactDraft): String
    suspend fun updateContact(contactId: String, draft: ContactDraft)
    suspend fun deleteContact(contactId: String)
    suspend fun setFavorite(contactId: String, favorite: Boolean)
    suspend fun setBlocked(contactId: String, blocked: Boolean)
}
