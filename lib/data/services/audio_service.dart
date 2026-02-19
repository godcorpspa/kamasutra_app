import 'package:flutter/services.dart';
import 'preferences_service.dart';

/// Servizio audio per effetti sonori nell'app.
///
/// Utilizza i suoni di sistema di Flutter per fornire feedback audio
/// durante i giochi e le interazioni. Rispetta l'impostazione
/// "Effetti sonori" nelle preferenze utente.
class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  bool _enabled = true;

  /// Inizializza il servizio leggendo la preferenza corrente.
  void initialize() {
    _enabled = PreferencesService.instance.areSoundEffectsEnabled;
  }

  /// Abilita o disabilita gli effetti sonori.
  void setEnabled(bool value) {
    _enabled = value;
  }

  bool get isEnabled => _enabled;

  /// Suono di click generico (tap su bottone, selezione).
  void playClick() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Suono di attivazione toggle.
  void playToggleOn() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  /// Suono di completamento / successo.
  void playSuccess() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  /// Suono di alert / attenzione.
  void playAlert() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  /// Suono per tiro dado / spin ruota.
  void playGameAction() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  /// Suono per carta pescata / nuova sfida.
  void playCardDraw() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Suono per vittoria / traguardo raggiunto.
  void playVictory() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  }

  /// Suono per navigazione tra schermate.
  void playNavigation() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
  }
}
