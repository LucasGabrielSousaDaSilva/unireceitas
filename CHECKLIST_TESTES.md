# 📝 Checklist de Configuração e Testes - UniReceitas

## 🔧 Configuração Inicial

### Dependências
- [ ] Executar `flutter pub get` para instalar dependências
- [ ] Verificar se todas as 9 dependências foram instaladas corretamente
- [ ] Testar build: `flutter build apk --debug` (Android) ou `flutter build ios` (iOS)

### Git & Versionamento
- [ ] Inicializar repositório Git
- [ ] Fazer commit inicial com todos os arquivos
- [ ] Criar branch de desenvolvimento: `git checkout -b develop`

---

## 🎯 Configuração de Serviços Externos

### 1. Supabase ✅
- [ ] Criar conta em [supabase.com](https://supabase.com)
- [ ] Criar novo projeto
- [ ] Copiar URL do projeto
- [ ] Copiar anon key
- [ ] Preencher `lib/config/supabase_config.dart`
- [ ] Executar SQL para criar tabelas (ver `SETUP_SUPABASE.md`)
- [ ] Configurar RLS (Row-Level Security)
- [ ] Testar conexão simples

**Verificação:**
```bash
# Verificar se Supabase está respondendo
curl -H "apikey: YOUR_KEY" https://YOUR_URL/rest/v1/usuarios
```

### 2. Google Generative AI (Gemini) ✅
- [ ] Acessar [Google AI Studio](https://makersuite.google.com/app/apikey)
- [ ] Criar API Key
- [ ] Copiar para `lib/services/ai_service.dart`
- [ ] Testar com prompt simples

**Teste:**
```dart
final aiService = AIService();
await aiService.inicializar();
final resultado = await aiService.sugerirReceitas(['arroz', 'feijão']);
print(resultado);
```

### 3. USDA FoodData Central (Nutrição) ✅
- [ ] Acessar [fdc.nal.usda.gov](https://fdc.nal.usda.gov/api-key-signup)
- [ ] Cadastrar/fazer login
- [ ] Obter API Key
- [ ] Copiar para `lib/services/nutrition_service.dart`
- [ ] Testar busca de alimento

**Teste:**
```dart
final nutritionService = NutritionService();
final info = await nutritionService.buscarAlimento('frango');
print(info?.obterFormatado());
```

### 4. Google Calendar API ✅
- [ ] Acessar [Google Cloud Console](https://console.cloud.google.com)
- [ ] Criar novo projeto
- [ ] Ativar "Google Calendar API"
- [ ] Criar credenciais OAuth2
- [ ] Configurar consentimento OAuth
- [ ] Fazer download do credentials.json
- [ ] Integrar fluxo de autenticação OAuth

**Verificação:**
```dart
// Testar integração após OAuth
await calendarService.criarLembreteCompras(
  titulo: 'Test',
  itens: ['item1'],
  dataLembrete: DateTime.now().add(Duration(days: 1)),
);
```

---

## 🧪 Testes por Camada

### Camada de Models ✅
- [ ] Usuario model valida corretamente
- [ ] Receita model com todos os campos
- [ ] Serialização/Desserialização funciona

### Camada de Services ✅

#### AuthService
- [ ] `cadastrarUsuario` funciona
- [ ] `buscarUsuarioPorCredenciais` retorna usuário correto
- [ ] `atualizarUsuario` modifica dados
- [ ] `emailJaExiste` detecta duplicatas

#### ReceitaService
- [ ] CRUD completo funciona
- [ ] Busca por ingredientes funciona
- [ ] Filtro de acesso (privada/pública) funciona
- [ ] Marcação de favoritos funciona

#### SupabaseService
- [ ] Conexão com Supabase estabelecida
- [ ] Criar usuário remoto funciona
- [ ] Sincronizar receitas funciona
- [ ] Autenticação OAuth2 funciona

#### ImageService
- [ ] Capturar foto com câmera funciona
- [ ] Selecionar da galeria funciona
- [ ] Validação de tamanho funciona
- [ ] Múltiplas imagens funcionam

#### AIService
- [ ] Inicialização com API Key funciona
- [ ] Sugestão de receita retorna texto válido
- [ ] Informação nutricional funciona
- [ ] Dicas de cozinha funcionam

#### NutritionService
- [ ] OpenFoodFacts retorna dados
- [ ] USDA retorna dados
- [ ] Cálculo de macronutrientes correto
- [ ] Cache funciona

#### CalendarService
- [ ] Autenticação OAuth2 funciona
- [ ] Criar evento funciona
- [ ] Listar eventos funciona
- [ ] Deletar evento funciona

#### SessionService
- [ ] Session inicia corretamente
- [ ] Tempo de expiração funciona
- [ ] Atividade prorroga sessão
- [ ] Logout limpa dados

#### BiometricService
- [ ] Detecta biometria disponível
- [ ] Autentica com biometria
- [ ] Retorna tipo correto (Face/Fingerprint/Iris)

#### ValidationService
- [ ] Email valida corretamente
- [ ] Senha valida força
- [ ] Nome não aceita muito curto
- [ ] Campos obrigatórios são detectados

### Camada de Providers (Controllers) ✅

#### AuthProvider
- [ ] Inicializar funciona
- [ ] Cadastro notifica listeners
- [ ] Login atualiza estado
- [ ] Logout limpa dados

#### ReceitaProvider
- [ ] Carregamento funciona
- [ ] Adicionar receita notifica
- [ ] Editar receita atualiza
- [ ] Deletar receita remove

#### SessionProvider
- [ ] Inicializar funciona
- [ ] Sessão valida após tempo
- [ ] Biometria habilitável
- [ ] Tempo até expiração atualiza

#### ImageProvider
- [ ] Capturar foto funciona
- [ ] Remover imagem funciona
- [ ] Total de imagens atualiza
- [ ] Limpar todas funciona

#### AIProvider
- [ ] Sugerir receita funciona
- [ ] Dicas de cozinha funcionam
- [ ] Variações funcionam
- [ ] Erro é capturado

#### NutritionProvider
- [ ] Buscar alimento funciona
- [ ] Total de nutrientes calcula
- [ ] Cache funciona
- [ ] Erro é tratado

#### CalendarProvider
- [ ] Criar lembrete funciona
- [ ] Agendar para fim de semana funciona
- [ ] Listar lembretes funciona
- [ ] Remover lembrete funciona

#### BiometricProtectionProvider
- [ ] Habilitar proteção funciona
- [ ] Proteger receita funciona
- [ ] Validar acesso funciona
- [ ] Desabilitar funciona

### Camada de Database ✅
- [ ] SQLite cria tabelas
- [ ] Inserir usuario funciona
- [ ] Buscar receitas funciona
- [ ] Atualizar dados funciona
- [ ] Deletar registros funciona

### SyncService (Integração) ✅
- [ ] Detecta conexão online/offline
- [ ] Sincroniza quando online
- [ ] Salva localmente quando offline
- [ ] Não perde dados

---

## 📱 Testes de Interface (Screens)

### Login Screen
- [ ] [ ] Email input funciona
- [ ] [ ] Senha input funciona
- [ ] [ ] Validação funciona
- [ ] [ ] Erro é exibido
- [ ] [ ] Loading spinner aparece
- [ ] [ ] Botão desabilita durante login

### Home Screen
- [ ] [ ] Lista de receitas carrega
- [ ] [ ] Busca funciona
- [ ] [ ] Filtros funcionam
- [ ] [ ] Acesso a detalhes funciona

### Cadastro de Receita
- [ ] [ ] Câmera captura foto
- [ ] [ ] Galeria seleciona imagem
- [ ] [ ] Ingredientes validam
- [ ] [ ] Modo preparo valida
- [ ] [ ] Acesso (privada/pública) muda
- [ ] [ ] Salva receita

### Detalhes de Receita
- [ ] [ ] Informações exibem corretamente
- [ ] [ ] Biometria protege acesso (se marcada)
- [ ] [ ] Botões de ação funcionam
- [ ] [ ] Compartilhar funciona

### Tela de IA (Sugerir Receita)
- [ ] [ ] Input de ingredientes funciona
- [ ] [ ] Botão enviar funciona
- [ ] [ ] Loading spinner aparece
- [ ] [ ] Resultado exibe
- [ ] [ ] Erro é mostrado

### Tela de Nutrição
- [ ] [ ] Busca de alimento funciona
- [ ] [ ] Resultado exibe nutrientes
- [ ] [ ] Cálculo de macros funciona
- [ ] [ ] Cache funciona

### Tela de Calendário
- [ ] [ ] Criar lembrete funciona
- [ ] [ ] Agendar fim de semana funciona
- [ ] [ ] Listar lembretes funciona
- [ ] [ ] Editar lembrete funciona

### Perfil de Usuário
- [ ] [ ] Exibe dados corretos
- [ ] [ ] Edita dados
- [ ] [ ] Biometria toggle funciona
- [ ] [ ] Logout funciona

---

## 🔐 Testes de Segurança

### Autenticação
- [ ] Senha incorreta nega acesso
- [ ] Email não registrado nega acesso
- [ ] Sessão expira após tempo
- [ ] Logout remove dados

### Biometria
- [ ] Falha biométrica nega acesso
- [ ] Sucesso biométrico libera acesso
- [ ] Proteção só funciona se habilitada

### Validação
- [ ] Email inválido é rejeitado
- [ ] Senha fraca é advertida
- [ ] Campos vazios são rejeitados
- [ ] XSS é prevenido

### Supabase RLS
- [ ] Usuário não pode ver dados de outro
- [ ] Receitas privadas são protegidas
- [ ] Receitas públicas são visíveis
- [ ] DELETE é controlado

---

## 🌐 Testes de Conectividade

### Offline-First
- [ ] App funciona sem internet
- [ ] Dados salvam localmente
- [ ] Sincronizam quando volta online
- [ ] Sem perda de dados

### APIs
- [ ] Timeout é tratado (10s)
- [ ] Erro HTTP é capturado
- [ ] Retry funciona (se implementado)
- [ ] Cache usado offline

---

## ✅ Checklist Final de Produção

### Código
- [ ] Sem console.log/debugPrint desnecessários
- [ ] Sem código comentado desnecessário
- [ ] Sem imports não usados
- [ ] Lint checks passando

### Performance
- [ ] App não congela
- [ ] Memória usada é razoável
- [ ] Imagens são otimizadas
- [ ] Paginação implementada

### UX
- [ ] Mensagens de erro claras
- [ ] Loading indicadores em operações demoradas
- [ ] Sucesso é confirmado visualmente
- [ ] Navegação é intuitiva

### Documentação
- [ ] README.md atualizado
- [ ] Comentários no código importante
- [ ] APIs documentadas
- [ ] Setup instructions claras

### Build & Release
- [ ] `flutter clean` não quebra nada
- [ ] Build APK funciona
- [ ] Build iOS funciona
- [ ] Versão incrementada

---

## 📊 Relatório de Testes

**Data**: _______________  
**Testador**: _______________

### Status Geral
- [ ] ✅ Todos os testes passaram
- [ ] ⚠️ Alguns testes com aviso
- [ ] ❌ Testes falharam

### Testes Passados: ___ / ___
### Testes Falhados: ___ / ___

### Problemas Encontrados:

1. _________________________________
2. _________________________________
3. _________________________________

### Observações:

_____________________________________________
_____________________________________________
_____________________________________________

---

## 🔄 Próximo Ciclo de Testes

- [ ] Revisar problemas encontrados
- [ ] Implementar correções
- [ ] Reexecutar testes falhados
- [ ] Testar integrações novamente
- [ ] Documentar mudanças
- [ ] Commit com mensagem descritiva

---

**Assinado em**: _______________

