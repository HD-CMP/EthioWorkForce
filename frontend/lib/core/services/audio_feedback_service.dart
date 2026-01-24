import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

class AudioFeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();

  AudioFeedbackService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('am-ET');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> playAttendanceSuccess(String workerName, {bool speakAmharic = true}) async {
    try {
      try {
        await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      } catch (audioError) {
        _logger.w('Audio file not available, using voice only: $audioError');
      }
      
      if (speakAmharic) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.speak('ተመዝግቧል');
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      _logger.i('Attendance success feedback played for $workerName');
    } catch (e) {
      _logger.e('Failed to play success feedback: $e');
    }
  }

  Future<void> playAttendanceError({bool speakAmharic = true}) async {
    try {
      try {
        await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      } catch (audioError) {
        _logger.w('Audio file not available, using voice only: $audioError');
      }
      
      if (speakAmharic) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.speak('ስህተት');
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      _logger.i('Attendance error feedback played');
    } catch (e) {
      _logger.e('Failed to play error feedback: $e');
    }
  }

  Future<void> playAlreadyRegistered({bool speakAmharic = true}) async {
    try {
      try {
        await _audioPlayer.play(AssetSource('sounds/warning.mp3'));
      } catch (audioError) {
        _logger.w('Audio file not available, using voice only: $audioError');
      }
      
      if (speakAmharic) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.speak('ቀደም ብሎ ተመዝግቧል');
        await Future.delayed(const Duration(milliseconds: 1200));
      }
      
      _logger.i('Already registered feedback played');
    } catch (e) {
      _logger.e('Failed to play warning feedback: $e');
    }
  }

  Future<void> speakCustomMessage(String message, {String language = 'am-ET'}) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.speak(message);
      _logger.i('Custom message spoken: $message');
    } catch (e) {
      _logger.e('Failed to speak custom message: $e');
    }
  }

  Future<void> playWorkerGreeting(String workerName, {bool speakAmharic = true}) async {
    try {
      if (speakAmharic) {
        await _flutterTts.speak('እንኳን ደህና መጡ $workerName');
        _logger.i('Greeting played for $workerName');
      }
    } catch (e) {
      _logger.e('Failed to play greeting: $e');
    }
  }

  Future<void> playCheckInConfirmation(String workerName, {bool speakAmharic = true}) async {
    try {
      try {
        await _audioPlayer.play(AssetSource('sounds/check_in.mp3'));
      } catch (audioError) {
        _logger.w('Audio file not available, using voice only: $audioError');
      }
      
      if (speakAmharic) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.speak('መግቢያ ተመዝግቧል');
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      _logger.i('Check-in confirmation played for $workerName');
    } catch (e) {
      _logger.e('Failed to play check-in confirmation: $e');
    }
  }

  Future<void> playCheckOutConfirmation(String workerName, {bool speakAmharic = true}) async {
    try {
      try {
        await _audioPlayer.play(AssetSource('sounds/check_out.mp3'));
      } catch (audioError) {
        _logger.w('Audio file not available, using voice only: $audioError');
      }
      
      if (speakAmharic) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.speak('መውጫ ተመዝግቧል');
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      _logger.i('Check-out confirmation played for $workerName');
    } catch (e) {
      _logger.e('Failed to play check-out confirmation: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
