# Configurador de terminal da Kodeo

Este é o script que o painel da Kodeo manda você colar no terminal. Ele está aqui, aberto, para você
ler exatamente o que ele faz antes de rodar.

## O comando

| Sistema | Comando |
|---|---|
| macOS / Linux | `curl -fsSL https://kodeo.com.br/instalar.sh \| KODEO_KEY="ck_…" bash` |
| Windows (PowerShell) | `$env:KODEO_KEY="ck_…"; irm https://kodeo.com.br/instalar.ps1 \| iex` |

A chave vem no comando que o painel gera para você. Sem ela, o script pergunta a chave na tela.
Os arquivos em `kodeo.com.br` são cópias exatas de `instalar.sh` e `instalar.ps1` deste repositório.

## O que ele faz

1. Valida a chave em `https://api.kodeo.com.br/v1/me`. Se a chave for recusada ou não houver internet,
   ele avisa e não altera nada.
2. Mostra o estado de quatro ferramentas no seu computador e deixa você marcar o que quer:
   - **Claude Code**: grava as variáveis `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN` e os modelos padrão
     no bloco `env` de `~/.claude/settings.json`, e um bloco marcado `# >>> kodeo >>>` no `~/.zshrc` ou
     `~/.bashrc`. No Windows, variáveis de ambiente do usuário.
   - **Claude App** (aplicativo de computador): cria uma configuração "Kodeo" em `Claude-3p/configLibrary`,
     liga `deploymentMode: "3p"` e `allowDevTools`, e reinicia o Claude se ele estiver aberto.
   - **OpenCode**: adiciona o provedor `kodeo` com os modelos da Kodeo em `~/.config/opencode/opencode.json`,
     guarda a chave em `~/.config/opencode/kodeo-api-key` (permissão só do dono) e deixa `kodeo/grok-4.7`
     como modelo padrão. O modelo que você usava antes fica salvo em `~/.config/kodeo/opencode-model-anterior`.
   - **Codex** (CLI da OpenAI): adiciona o provedor `kodeo` em `~/.codex/config.toml` (`base_url`
     `https://api.kodeo.com.br/v1`, `wire_api = "responses"`, chave pela variável de ambiente `KODEO_API_KEY`,
     que o script exporta no seu `.zshrc`/`.bashrc` ou nas variáveis do usuário no Windows) e deixa
     `claude-opus-5` como modelo padrão. Se já existia um `config.toml`, ele fica guardado em
     `~/.config/kodeo/codex-config.toml.anterior` e volta ao desconfigurar.
3. Mostra um resumo do que foi feito.

Tudo é **mesclado**: o resto dos seus arquivos é preservado. A gravação é atômica, e um arquivo JSON
corrompido faz o passo parar sem tocar nele.

## Como desfazer

Rode o mesmo comando de novo. O que já está configurado aparece como `configurado`; marque e ele
**desconfigura**: tira só as chaves da Kodeo do `settings.json` (o bloco `env` some se ficar vazio), remove o
bloco do `.zshrc`, apaga a configuração "Kodeo" do Claude App e volta o `deploymentMode` para `1p`, remove o
provedor `kodeo` do OpenCode e devolve o seu modelo anterior, e devolve o `config.toml` do Codex como estava.

## O que ele não faz

- Não manda nada para a internet além das chamadas de validação e teste à API da Kodeo (`/v1/me`, `/v1/models`
  e `/v1/responses` com um "ok"), todas com a sua própria chave.
- Não instala programas, não pede senha, não mexe em outros arquivos.
- Não guarda a chave em lugar nenhum além dos arquivos de configuração das ferramentas que você marcou.

## Requisitos

- macOS ou Linux: `bash` e `curl` (já vêm no sistema). Para editar os arquivos JSON ele usa o Node.js ou,
  se não houver, o Python 3; sem os dois ele avisa e pede para instalar o Node.
- Windows: PowerShell 5.1 ou mais novo (já vem no Windows 10 e 11).

## Variáveis de ambiente

- `KODEO_KEY`: a chave; com ela a pergunta da chave é pulada.
- `KODEO_SEM_REINICIAR=1`: não reinicia o Claude App (usado em testes).

Licença MIT.
