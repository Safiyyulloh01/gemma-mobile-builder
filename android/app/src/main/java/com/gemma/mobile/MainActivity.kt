package com.gemma.mobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                GemmaApp()
            }
        }
    }
}

@Composable
fun GemmaApp(viewModel: ChatViewModel = viewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        // Header
        Text(
            text = "Gemma Mobile",
            style = MaterialTheme.typography.headlineMedium
        )
        Spacer(Modifier.height(8.dp))

        // Chat messages
        LazyColumn(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(uiState.messages) { msg ->
                Surface(
                    shape = MaterialTheme.shapes.medium,
                    color = if (msg.isUser)
                        MaterialTheme.colorScheme.primaryContainer
                    else
                        MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Text(
                        text = msg.text,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }

            if (uiState.isLoading) {
                item {
                    Text("Generating...", style = MaterialTheme.typography.bodySmall)
                }
            }
        }

        Spacer(Modifier.height(8.dp))

        // Input
        Row(modifier = Modifier.fillMaxWidth()) {
            OutlinedTextField(
                value = uiState.input,
                onValueChange = viewModel::onInputChanged,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Ask Gemma...") },
                singleLine = true
            )
            Spacer(Modifier.width(8.dp))
            Button(
                onClick = { viewModel.sendMessage() },
                enabled = uiState.input.isNotBlank() && !uiState.isLoading
            ) {
                Text("Send")
            }
        }
    }
}
