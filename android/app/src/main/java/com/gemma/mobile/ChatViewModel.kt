package com.gemma.mobile

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class Message(val text: String, val isUser: Boolean)

data class UiState(
    val messages: List<Message> = emptyList(),
    val input: String = "",
    val isLoading: Boolean = false,
    val isModelLoaded: Boolean = false
)

class ChatViewModel : androidx.lifecycle.ViewModel() {
    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val inferenceEngine = InferenceEngine()

    fun onInputChanged(text: String) {
        _uiState.value = _uiState.value.copy(input = text)
    }

    fun sendMessage() {
        val text = _uiState.value.input.trim()
        if (text.isBlank()) return

        _uiState.value = _uiState.value.copy(
            messages = _uiState.value.messages + Message(text, true),
            input = "",
            isLoading = true
        )

        // Run inference on background thread
        kotlinx.coroutines.MainScope().launch {
            try {
                val response = inferenceEngine.generate(text)
                _uiState.value = _uiState.value.copy(
                    messages = _uiState.value.messages + Message(response, false),
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    messages = _uiState.value.messages + Message("Error: ${e.message}", false),
                    isLoading = false
                )
            }
        }
    }
}

fun kotlinx.coroutines.MainScope(): kotlinx.coroutines.CoroutineScope {
    return kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main + kotlinx.coroutines.SupervisorJob())
}
