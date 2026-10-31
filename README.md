# Quem é a máquina? · starter do workshop

Humanos e o Gemini respondem a mesma pergunta. Cada jogador recebe 4 cartas
(3 humanas, 1 máquina) e aponta a IA. Hoje **você escreve a máquina**.

O app já vem pronto: entrada, lobby, cartas animadas, placar, telão. O backend
(Firestore + Functions) é do organizador e já está no ar. Você faz três coisas:

> ⚠️ **Não rode `flutterfire configure`.** O `firebase_options.dart` já aponta
> para o projeto do jogo. Se rodar, seu app sai do jogo.

## 1. TODO 1 · `app/lib/services/impostor_service.dart`

Implemente `generate()` com **Firebase AI Logic** (`package:firebase_ai`):

1. Crie o modelo `impostorModel` com `GenerationConfig` pedindo
   `responseMimeType: 'application/json'` e o `impostorSchema`
   (de `package:shared/impostor_prompt.dart`).
2. Monte o prompt com `buildImpostorPrompt(...)`. É o **mesmo** código que o
   servidor usa para gerar os impostores de verdade.
3. Leia o JSON `{ "answer": "..." }` da resposta e valide.
4. Corte em 140 caracteres (`maxAnswerChars`).

Teste na aba **Lab** do app: escreva um estilo e aperte **Testar**.

## 2. O prompt

Ainda no Lab, itere no estilo até as 3 respostas parecerem de gente. Dica: o
prompt bom restringe (tamanho, gíria, erro de digitação, pontuação). Quando
gostar, **Usar no jogo**. A partir daí os impostores do jogo podem sair do seu
prompt, e se ele enganar muita gente, você leva o Dash de pelúcia.

## 3. Deploy no seu projeto

```bash
cd app
firebase use --add        # escolha o SEU projeto (impostor-seunome)
./deploy.sh               # flutter build web + firebase deploy --only hosting
```

Copie a URL que aparecer (`https://impostor-seunome.web.app`), abra o app
publicado, vá no **Lab** e cole em **Registrar no telão**.

## Rodando

```bash
cd app
flutter pub get
flutter run -d chrome
```
