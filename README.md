# 🍳 UniReceitas - Aplicativo de Receitas Inteligente

Um aplicativo Flutter completo para descobrir, criar e gerenciar receitas com inteligência artificial, integração com calendário e informações nutricionais.

## ✨ Características Principais

### 🏗️ Arquitetura MVCS
- **Model**: Estrutura de dados (Usuario, Receita)
- **View**: Telas e widgets do Flutter
- **Controller**: Providers para gerenciamento de estado
- **Service**: Lógica de negócio isolada e reutilizável

### 🔐 Autenticação Robusta
- Cadastro e login de usuários
- Gerenciamento de sessões com expiração automática
- Validação forte de senhas

### 🤖 Inteligência Artificial
- Sugestão de receitas baseado em ingredientes
- Informações nutricionais com IA
- Variações criativas de receitas
- Dicas de cozinha personalizadas

### 🔄 Sincronização de Dados
- SQLite para persistência local
- Supabase para banco de dados remoto
- Sincronização offline-first
- Sem perda de dados

### 📸 Recurso de Câmera
- Capturar fotos de ingredientes
- Selecionar imagens da galeria
- Gerenciamento de múltiplas imagens
- Validação de tamanho e formato

### 📊 Informações Nutricionais
- Busca em OpenFoodFacts e USDA
- Cálculo de macronutrientes
- Informações por porção
- Histórico de buscas

### 📅 Integração com Calendário
- Agendar lembretes de compras
- Sincronizar com Google Calendar
- Notificações automáticas
- Agendamento para fim de semana


## 🚀 Quick Start

### Pré-requisitos
- Flutter 3.11.0+
- Dart 3.11.0+
- Android Studio / Xcode
- Git

### 1. Clonar Repositório
```bash
git clone https://github.com/usuario/unireceitas.git
cd unireceitas
```

### 2. Instalar Dependências
```bash
flutter pub get
```

### 3. Configurar Variáveis de Ambiente

#### Supabase
1. Crie uma conta em [supabase.com](https://supabase.com)
2. Copie `supabaseUrl` e `supabaseKey`
3. Atualize `lib/config/supabase_config.dart`

Veja [SETUP_SUPABASE.md](./SETUP_SUPABASE.md) para instruções detalhadas.

#### Google Generative AI (Gemini)
1. Obtenha API Key em [makersuite.google.com](https://makersuite.google.com/app/apikey)
2. Atualize `lib/services/ai_service.dart`

#### USDA FoodData (Nutrição)
1. Cadastre-se em [fdc.nal.usda.gov](https://fdc.nal.usda.gov/api-key-signup)
2. Obtenha API Key
3. Atualize `lib/services/nutrition_service.dart`

### 4. Executar Aplicativo
```bash
# iOS
flutter run --device-id=ios

# Android
flutter run --device-id=android

# Web (opcional)
flutter run -d chrome
```

---

## 📚 Documentação

### Guias de Configuração
- [SETUP_SUPABASE.md](./SETUP_SUPABASE.md) - Configuração do Supabase
- [IMPLEMENTACAO_COMPLETA.md](./IMPLEMENTACAO_COMPLETA.md) - Documentação completa
- [CHECKLIST_TESTES.md](./CHECKLIST_TESTES.md) - Checklist de testes

### Estrutura do Projeto
```
lib/
├── services/          # Lógica de negócio
├── providers/         # Gerenciamento de estado
├── screens/           # Telas da aplicação
├── models/            # Estrutura de dados
├── database/          # Persistência local
├── config/            # Configurações
├── widgets/           # Componentes reutilizáveis
└── utils/             # Utilidades
```

---

## 🛠️ Tecnologias Utilizadas

### Frontend
- **Flutter** 3.11.0+ - Framework UI
- **Provider** 6.1.2 - Gerenciamento de estado
- **Image Picker** 1.1.2 - Câmera/Galeria

### Backend & Cloud
- **Supabase** - PostgreSQL + Auth + APIs
- **Google Generative AI** - IA para receitas
- **Google Calendar API** - Lembretes
- **OpenFoodFacts** - Informações nutricionais
- **USDA FoodData** - Dados de alimentos

### Persistência
- **SQLite** - Banco local via sqflite
- **Supabase** - Sincronização remota

### Segurança
- **Supabase Auth** - Autenticação

---

## 📖 Como Usar

### 1. Cadastro e Login
```dart
// Cadastrar novo usuário
final erro = await authProvider.cadastrarUsuario(
  nome: 'João Silva',
  email: 'joao@example.com',
  senha: 'senha123',
);

// Login
final erro = await authProvider.login(
  email: 'joao@example.com',
  senha: 'senha123',
);
```

### 2. Sugerir Receitas com IA
```dart
await aiProvider.sugerirReceitas(['frango', 'arroz', 'tomate']);
// Retorna sugestão de receita pronta
```

### 3. Capturar Ingredientes
```dart
// Câmera
await imageProvider.capturarFoto();

// Galeria
await imageProvider.selecionarDaGaleria();
```

### 4. Buscar Informações Nutricionais
```dart
final alimento = await nutritionProvider.buscarAlimento('frango');
// Retorna kcal, proteína, carboidratos, gordura, fibra
```

### 5. Agendar Lembretes
```dart
await calendarProvider.agendarLembreteFinDeSemana(
  titulo: 'Compras da Semana',
  itens: ['frango', 'arroz', 'feijão'],
);
```


## 🧪 Testes

### Executar Testes
```bash
# Todos os testes
flutter test

# Teste específico
flutter test test/services/validation_service_test.dart

# Com cobertura
flutter test --coverage
```

### Checklist de Testes
Veja [CHECKLIST_TESTES.md](./CHECKLIST_TESTES.md) para lista completa de testes.

---

## 🔧 Desenvolvimento

### Build para Produção
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Análise de Código
```bash
# Lint
flutter analyze

# Formatter
dart format lib/

# Fix automático
dart fix --apply
```

---

## 🐛 Troubleshooting

### "Supabase não está configurado"
✅ Verifique `lib/config/supabase_config.dart`

### "API Key inválida"
✅ Confirme que copiou a chave completa sem espaços

### "Dados não sincronizam"
✅ Verifique conexão de internet
✅ Verifique políticas RLS no Supabase

---

## 📦 Instalação (App Stores)

### Android
Disponível em [Google Play Store](https://play.google.com)

### iOS
Disponível em [Apple App Store](https://www.apple.com/app-store/)

---

## 🤝 Contribuindo

1. Faça fork do projeto
2. Crie uma branch: `git checkout -b feature/NovaFeature`
3. Commit suas mudanças: `git commit -m 'Adiciona NovaFeature'`
4. Push para a branch: `git push origin feature/NovaFeature`
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para detalhes.

---

## 👨‍💼 Autor

**Seu Nome**
- GitHub: [@usuario](https://github.com/usuario)
- Email: seu.email@example.com

---

## 🙏 Agradecimentos

- Flutter Team pela excelente documentação
- Supabase por facilitar o backend
- Google por APIs incríveis
- Comunidade Flutter por suporte

---

## 📞 Suporte

Encontrou um bug? Abra uma [Issue](https://github.com/usuario/unireceitas/issues)

Tem uma sugestão? Abra uma [Discussion](https://github.com/usuario/unireceitas/discussions)

---

## 📊 Roadmap

- [ ] Autenticação social (Google, GitHub)
- [ ] Compartilhamento de receitas via redes sociais
- [ ] Community de usuários
- [ ] Recomendações personalizadas
- [ ] Modo offline completo
- [ ] Múltiplos idiomas
- [ ] App Widget
- [ ] Integração Alexa/Google Assistant

---

**Desenvolvido com ❤️ usando Flutter**

Última atualização: Maio 2026
