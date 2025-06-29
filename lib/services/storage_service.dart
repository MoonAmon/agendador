import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sinal_agendado.dart';

// Serviço para armazenamento local dos sinais
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _sinaisKey = 'sinais_agendados';

  // Salvar lista de sinais
  Future<void> salvarSinais(List<SinalAgendado> sinais) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sinaisJson = sinais.map((sinal) => sinal.toJson()).toList();
      final sinaisString = jsonEncode(sinaisJson);
      await prefs.setString(_sinaisKey, sinaisString);
    } catch (e) {
      print('Erro ao salvar sinais: $e');
    }
  }

  // Carregar lista de sinais
  Future<List<SinalAgendado>> carregarSinais() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sinaisString = prefs.getString(_sinaisKey);

      if (sinaisString == null || sinaisString.isEmpty) {
        return [];
      }

      final sinaisJson = jsonDecode(sinaisString) as List;
      return sinaisJson.map((json) => SinalAgendado.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar sinais: $e');
      return [];
    }
  }

  // Salvar um sinal específico
  Future<void> salvarSinal(
    SinalAgendado sinal,
    List<SinalAgendado> sinaisExistentes,
  ) async {
    final index = sinaisExistentes.indexWhere((s) => s.id == sinal.id);

    if (index >= 0) {
      sinaisExistentes[index] = sinal;
    } else {
      sinaisExistentes.add(sinal);
    }

    await salvarSinais(sinaisExistentes);
  }

  // Remover um sinal
  Future<void> removerSinal(
    String sinalId,
    List<SinalAgendado> sinaisExistentes,
  ) async {
    sinaisExistentes.removeWhere((sinal) => sinal.id == sinalId);
    await salvarSinais(sinaisExistentes);
  }

  // Limpar todos os sinais
  Future<void> limparTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sinaisKey);
    } catch (e) {
      print('Erro ao limpar sinais: $e');
    }
  }

  // Salvar configurações gerais
  Future<void> salvarConfiguracao(String chave, dynamic valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (valor is String) {
        await prefs.setString(chave, valor);
      } else if (valor is int) {
        await prefs.setInt(chave, valor);
      } else if (valor is double) {
        await prefs.setDouble(chave, valor);
      } else if (valor is bool) {
        await prefs.setBool(chave, valor);
      }
    } catch (e) {
      print('Erro ao salvar configuração: $e');
    }
  }

  // Carregar configuração
  Future<T?> carregarConfiguracao<T>(String chave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.get(chave) as T?;
    } catch (e) {
      print('Erro ao carregar configuração: $e');
      return null;
    }
  }
}
