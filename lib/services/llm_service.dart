import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  String? _modelPath;
  bool _isInitialized = false;
  bool _isLoading = false;
  
  // Model configuration
  static const String modelFileName = 'SmolLM2-360M-Instruct-Q4_K_M.gguf';
  static const String modelUrl = 'https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF/resolve/main/SmolLM2-360M-Instruct-Q4_K_M.gguf';
  
  // Inference parameters (optimized for mobile)
  static const int contextSize = 2048; // Good for <8GB RAM devices
  static const int maxTokens = 512;
  static const double temperature = 0.7;
  static const double topP = 0.9;
  static const int numGpuLayers = 99; // Use GPU if available
  static const double frequencyPenalty = 0.0; // Don't use below 1.1
  static const double presencePenalty = 1.1; // Prevents token repetition
  
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  
  /// Initialize the LLM service and load the model
  Future<void> initialize({
    VoidCallback? onProgress,
    Function(String)? onError,
  }) async {
    if (_isInitialized || _isLoading) return;
    
    try {
      _isLoading = true;
      
      // Get the model path
      _modelPath = await _getModelPath();
      
      // Check if model exists, download if needed
      final modelFile = File(_modelPath!);
      if (!await modelFile.exists()) {
        if (kDebugMode) {
          print('Model not found, downloading from HuggingFace...');
        }
        await _downloadModel(onProgress: onProgress);
      }
      
      // Verify model exists after download
      if (!await modelFile.exists()) {
        throw Exception('Model file not found after download');
      }
      
      _isInitialized = true;
      _isLoading = false;
      
      if (kDebugMode) {
        print('LLM Service initialized with model at: $_modelPath');
      }
    } catch (e) {
      _isLoading = false;
      final errorMsg = 'Failed to initialize LLM: $e';
      if (kDebugMode) {
        print(errorMsg);
      }
      onError?.call(errorMsg);
      rethrow;
    }
  }
  
  /// Get the path where the model should be stored
  Future<String> _getModelPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String modelDir = '${appDocDir.path}/models';
    
    // Create models directory if it doesn't exist
    final Directory modelsDirectory = Directory(modelDir);
    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(recursive: true);
    }
    
    return '$modelDir/$modelFileName';
  }
  
  /// Download the model from HuggingFace
  Future<void> _downloadModel({VoidCallback? onProgress}) async {
    try {
      if (kDebugMode) {
        print('Starting model download from: $modelUrl');
      }
      
      final response = await http.get(Uri.parse(modelUrl));
      
      if (response.statusCode == 200) {
        final file = File(_modelPath!);
        await file.writeAsBytes(response.bodyBytes);
        
        if (kDebugMode) {
          print('Model downloaded successfully');
        }
        onProgress?.call();
      } else {
        throw Exception('Failed to download model: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading model: $e');
    }
  }
  
  /// Generate a response for the given messages using fllama
  Stream<String> generateResponse({
    required List<Message> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async* {
    if (!_isInitialized || _modelPath == null) {
      throw Exception('LLM Service not initialized');
    }
    
    // Check if model file exists
    final modelFile = File(_modelPath!);
    if (!await modelFile.exists()) {
      throw Exception('Model file not found');
    }
    
    // Create OpenAI-style request for fllama
    final request = OpenAiRequest(
      modelPath: _modelPath!,
      messages: messages,
      maxTokens: maxTokens ?? LLMService.maxTokens,
      temperature: temperature ?? LLMService.temperature,
      topP: topP ?? LLMService.topP,
      contextSize: contextSize,
      numGpuLayers: numGpuLayers,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      // Note: stopStrings may not be available in all fllama versions
    );
    
    final completer = StreamController<String>();
    String fullResponse = '';
    bool hasError = false;
    
    try {
      // Use fllama's chat API with streaming callback
      // Callback signature: (String response, String responseJson, bool done)
      fllamaChat(
        request,
        (String response, String responseJson, bool done) {
          if (!done && !hasError) {
            // Extract new tokens from the response
            String newToken = '';
            if (response.length > fullResponse.length) {
              newToken = response.substring(fullResponse.length);
              fullResponse = response;
              if (!completer.isClosed) {
                completer.add(newToken);
              }
            }
          } else if (done && !hasError) {
            // Completion done
            if (!completer.isClosed) {
              completer.close();
            }
          }
        },
      );
      
      yield* completer.stream;
    } catch (e) {
      hasError = true;
      if (kDebugMode) {
        print('Error generating response: $e');
      }
      if (!completer.isClosed) {
        completer.addError(e);
        completer.close();
      }
      rethrow;
    }
  }
  
  /// Simple chat completion for testing
  Future<String> complete(String prompt) async {
    final messages = [
      Message(Role.system, 'You are SmolLM2-360M, a helpful AI assistant running on-device.'),
      Message(Role.user, prompt),
    ];
    
    final responseStream = generateResponse(messages: messages);
    final response = await responseStream.join();
    return response;
  }
  
  /// Clean up resources
  void dispose() {
    _isInitialized = false;
    _modelPath = null;
  }
  
  /// Get model info
  Map<String, dynamic> getModelInfo() {
    return {
      'name': 'SmolLM2-360M',
      'parameters': '360M',
      'quantization': 'Q4_K_M',
      'contextSize': contextSize,
      'fileSize': '~271MB',
      'isInitialized': _isInitialized,
      'modelPath': _modelPath,
    };
  }
  
  /// Get additional model capabilities (optional)
  Future<Map<String, String>> getModelCapabilities() async {
    if (!_isInitialized || _modelPath == null) {
      return {};
    }
    
    try {
      // Get model-specific tokens and templates if available
      final capabilities = <String, String>{};
      
      // These methods might be available in fllama
      // Uncomment if they exist in your version
      // capabilities['chatTemplate'] = await fllamaChatTemplateGet();
      // capabilities['eosToken'] = await fllamaEosTokenGet();
      // capabilities['bosToken'] = await fllamaBosTokenGet();
      
      return capabilities;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting model capabilities: $e');
      }
      return {};
    }
  }
}