package com.glasschat.app.flow

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodes
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.glasschat.app.MainActivity
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.repository.BackupRepository
import com.glasschat.app.domain.repository.SettingsRepository
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.FixMethodOrder
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.MethodSorters
import javax.inject.Inject

/**
 * End-to-end UI coverage for the core authoring loop: create a contact, create a chat,
 * write as "Me", flip the composer to the other participant, search the chat list and open
 * the attachment chooser.
 *
 * The tests share one database and run in name order; each one creates the data it needs.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class GlassChatFlowTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val compose = createAndroidComposeRule<MainActivity>()

    @Inject
    lateinit var settingsRepository: SettingsRepository

    @Inject
    lateinit var backupRepository: BackupRepository

    @Before
    fun setUp() {
        hiltRule.inject()
        runBlocking {
            backupRepository.deleteAllData()
            settingsRepository.setOnboardingComplete(true)
            settingsRepository.setProfile(
                displayName = "Me",
                about = "Testing GlassChat",
                avatarUri = null,
                accent = 0xFF8C7CFF,
            )
        }
        // Recreate so the nav host picks up the "onboarding finished" start destination.
        compose.activityRule.scenario.recreate()
        compose.waitForIdle()
    }

    private fun openTab(label: String) {
        compose.onNodeWithTag("tab_$label").performClick()
        compose.waitForIdle()
    }

    @Inject
    lateinit var contactRepository: com.glasschat.app.domain.repository.ContactRepository

    private fun seedContact(name: String) = runBlocking {
        contactRepository.createContact(
            ContactDraft(name = name, accentColor = 0xFF4FE3D5, bio = "Seeded for tests"),
        )
    }

    @Test
    fun a_createContactThroughEditor() {
        openTab("Contacts")
        compose.onNodeWithContentDescription("Add contact").performClick()
        compose.waitForIdle()

        compose.onAllNodes(hasSetTextAction()).onFirst().performTextInput("Riley Park")
        compose.onAllNodesWithText("Save").onFirst().performClick()
        compose.waitForIdle()

        compose.onAllNodesWithText("Riley Park").onFirst().assertIsDisplayed()
    }

    @Test
    fun b_createChatAndSendAsMe() {
        seedContact("Jules Hart")
        openTab("Chats")
        compose.onNodeWithContentDescription("Start a new chat").performClick()
        compose.waitForIdle()

        compose.onNodeWithText("Jules Hart").performClick()
        compose.onAllNodesWithText("Create chat").onFirst().performClick()
        compose.waitForIdle()

        compose.onNodeWithContentDescription("Message field").performTextInput("First line from me")
        compose.onNodeWithContentDescription("Send message").performClick()
        compose.waitForIdle()

        compose.onAllNodesWithText("First line from me").onFirst().assertIsDisplayed()
    }

    @Test
    fun c_switchSenderAndSend() {
        seedContact("Nadia Fox")
        openTab("Chats")
        compose.onNodeWithContentDescription("Start a new chat").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Nadia Fox").performClick()
        compose.onAllNodesWithText("Create chat").onFirst().performClick()
        compose.waitForIdle()

        compose.onNodeWithContentDescription("Message field").performTextInput("Written as me")
        compose.onNodeWithContentDescription("Send message").performClick()
        compose.waitForIdle()

        // The composer segmented control labels the contact with their first name.
        compose.onAllNodes(hasClickAction() and androidx.compose.ui.test.hasText("Nadia")).onFirst()
            .performClick()
        compose.waitForIdle()

        compose.onNodeWithContentDescription("Message field").performTextInput("Written as Nadia")
        compose.onNodeWithContentDescription("Send message").performClick()
        compose.waitForIdle()

        compose.onAllNodesWithText("Written as Nadia").onFirst().assertIsDisplayed()
        compose.onAllNodesWithText("Written as me").onFirst().assertIsDisplayed()
    }

    @Test
    fun d_attachmentChooserOpensPhotoOption() {
        seedContact("Owen Pike")
        openTab("Chats")
        compose.onNodeWithContentDescription("Start a new chat").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Owen Pike").performClick()
        compose.onAllNodesWithText("Create chat").onFirst().performClick()
        compose.waitForIdle()

        compose.onNodeWithContentDescription("Attach a file").performClick()
        compose.waitForIdle()

        // The sheet is the app's own UI; the system Photo Picker itself is not scripted here.
        assertTrue(
            compose.onAllNodesWithText("Photo").fetchSemanticsNodes().isNotEmpty(),
        )
    }

    @Test
    fun e_searchChatsFiltersTheList() {
        seedContact("Pia Verne")
        openTab("Chats")
        compose.onNodeWithContentDescription("Start a new chat").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Pia Verne").performClick()
        compose.onAllNodesWithText("Create chat").onFirst().performClick()
        compose.waitForIdle()

        compose.onNodeWithContentDescription("Go back").performClick()
        compose.waitForIdle()

        compose.onAllNodes(hasSetTextAction()).onFirst().performTextInput("zzzz-no-match")
        compose.waitForIdle()
        assertTrue(
            compose.onAllNodes(hasClickAction() and androidx.compose.ui.test.hasText("Pia")).fetchSemanticsNodes().isEmpty(),
        )

        compose.onAllNodes(hasSetTextAction()).onFirst().performTextInput("Pia")
        compose.waitForIdle()
        assertTrue(
            compose.onAllNodes(hasClickAction() and androidx.compose.ui.test.hasText("Pia")).fetchSemanticsNodes().isNotEmpty(),
        )
    }
}
