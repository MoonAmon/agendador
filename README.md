# Agendador de Sinais

Um aplicativo Flutter para Android que permite agendar sinais/alarmes para tocar música em horários específicos por uma duração determinada pelo usuário.

## ✅ Funcionalidades Garantidas

### 1. **Execução em Segundo Plano**

- ✅ **SIM** - O aplicativo tocará os sinais mesmo quando estiver em segundo plano
- ✅ **SIM** - Funciona mesmo com o app minimizado
- ⚠️ **LIMITADO** - Pode ser restrito pelo sistema após horas de inatividade
- ✅ **SIM** - Utiliza notificações locais e SchedulerService para garantir execução

### 2. **Persistência de Dados**

- ✅ **SIM** - Os sinais ficam salvos mesmo que o celular desligue
- ✅ **SIM** - Dados são salvos localmente no dispositivo
- ✅ **SIM** - Sistema de backup automático para evitar perda de dados
- ✅ **SIM** - Sinais são restaurados automaticamente ao reiniciar o app

### 3. **Funcionalidades Principais**

- ✅ **Agendar Sinais**: Crie alarmes para horários específicos
- ✅ **Duração Personalizável**: Defina por quanto tempo a música deve tocar (em segundos)
- ✅ **Repetição**: Configure sinais para repetir em dias específicos da semana
- ✅ **Múltiplos Sons**: Use sons pré-definidos ou selecione arquivos personalizados
- ✅ **Gerenciamento**: Ativar/desativar, editar ou excluir sinais
- ✅ **Execução Automática**: Toca automaticamente no horário, sem depender de notificações
- ✅ **Fila de Execução**: Múltiplos sinais no mesmo horário tocam em sequência
- ✅ **Interface Simplificada**: Apenas horário e dias da semana, sem seleção de data

## Tecnologias Utilizadas

- **Flutter/Dart**: Framework principal
- **Provider**: Gerenciamento de estado
- **flutter_local_notifications**: Notificações locais
- **audioplayers**: Reprodução de áudio
- **shared_preferences**: Armazenamento local
- **timezone**: Manipulação de fusos horários
- **permission_handler**: Gerenciamento de permissões

## Estrutura do Projeto

```
lib/
├── main.dart                    # Ponto de entrada da aplicação
├── models/
│   └── sinal_agendado.dart     # Modelo de dados dos sinais
├── providers/
│   └── sinais_provider.dart    # Gerenciamento de estado
├── services/
│   ├── notification_service.dart # Serviço de notificações
│   ├── audio_service.dart       # Serviço de áudio
│   └── storage_service.dart     # Serviço de armazenamento
├── screens/
│   ├── home_screen.dart         # Tela principal
│   └── adicionar_sinal_screen.dart # Tela de criação/edição
└── widgets/
    └── sinal_card.dart          # Widget do card de sinal
```

## Instalação e Execução

### Pré-requisitos

- Flutter SDK (versão 3.32.5 ou superior)
- Android SDK
- Device Android ou Emulador

### Passos para executar

1. **Instale as dependências**:

   ```bash
   flutter pub get
   ```

2. **Execute o aplicativo**:
   ```bash
   flutter run
   ```

### Build para produção

Para gerar um APK:

```bash
flutter build apk --release
```

## Como Usar

### 1. Adicionar um Novo Sinal

- Toque no botão "+" na tela principal
- Preencha o nome do sinal
- Selecione data e hora
- Escolha a duração (1-60 minutos)
- Selecione o som desejado
- Configure repetição se necessário
- Toque em "SALVAR"

### 2. Gerenciar Sinais

- **Ativar/Desativar**: Use o switch no card do sinal
- **Editar**: Toque no menu (⋮) e selecione "Editar"
- **Excluir**: Toque no menu (⋮) e selecione "Excluir"
- **Tocar Agora**: Toque no botão de play para testar

## Sons Disponíveis

O app inclui os seguintes sons pré-definidos:

- Alarme Padrão
- Canto dos Pássaros
- Sino Suave
- Sons da Natureza
- Melodia de Piano

_Nota: No projeto atual, os arquivos de áudio são placeholders. Em um projeto real, você deve substituí-los por arquivos de áudio reais (.mp3, .wav, etc.)_

**Desenvolvido com ❤️ usando Flutter**
