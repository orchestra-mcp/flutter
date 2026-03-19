/// Service for interacting with foundation AI models.
///
/// All methods return mock data. Replace with real API calls when the
/// orchestrator bridge is wired up.
class FoundationModelsService {
  const FoundationModelsService();

  /// Returns the list of all available foundation models.
  Future<List<FoundationModel>> listModels() async {
    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockModels;
  }

  /// Returns a single model by [id], or `null` if not found.
  Future<FoundationModel?> getModel(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      return _mockModels.firstWhere((m) => m.id == id);
    } on StateError {
      return null;
    }
  }

  /// Sends a [prompt] to the model identified by [modelId] and returns
  /// the completion text.
  Future<ModelResponse> promptModel({
    required String modelId,
    required String prompt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return ModelResponse(
      modelId: modelId,
      prompt: prompt,
      completion:
          'This is a mock response from model "$modelId" for prompt: "$prompt".\n\n'
          'In a real implementation this would call the orchestrator bridge '
          'which routes to the correct AI provider.',
      tokensUsed: 42,
      latencyMs: 600,
    );
  }

  // ── Mock data ───────────────────────────────────────────────────────────

  static const _mockModels = [
    FoundationModel(
      id: 'claude-opus-4',
      name: 'Claude Opus 4',
      provider: 'Anthropic',
      contextWindow: 200000,
      capabilities: ['text', 'code', 'analysis', 'vision'],
    ),
    FoundationModel(
      id: 'claude-sonnet-4',
      name: 'Claude Sonnet 4',
      provider: 'Anthropic',
      contextWindow: 200000,
      capabilities: ['text', 'code', 'analysis', 'vision'],
    ),
    FoundationModel(
      id: 'gpt-4o',
      name: 'GPT-4o',
      provider: 'OpenAI',
      contextWindow: 128000,
      capabilities: ['text', 'code', 'vision', 'audio'],
    ),
    FoundationModel(
      id: 'gemini-2.5-pro',
      name: 'Gemini 2.5 Pro',
      provider: 'Google',
      contextWindow: 1000000,
      capabilities: ['text', 'code', 'vision'],
    ),
    FoundationModel(
      id: 'llama-3.3-70b',
      name: 'Llama 3.3 70B',
      provider: 'Meta (via Ollama)',
      contextWindow: 128000,
      capabilities: ['text', 'code'],
    ),
  ];
}

/// A foundation model descriptor.
class FoundationModel {
  const FoundationModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.contextWindow,
    required this.capabilities,
  });

  final String id;
  final String name;
  final String provider;
  final int contextWindow;
  final List<String> capabilities;

  @override
  String toString() => 'FoundationModel($id, $name, $provider)';
}

/// Response from prompting a model.
class ModelResponse {
  const ModelResponse({
    required this.modelId,
    required this.prompt,
    required this.completion,
    required this.tokensUsed,
    required this.latencyMs,
  });

  final String modelId;
  final String prompt;
  final String completion;
  final int tokensUsed;
  final int latencyMs;
}
