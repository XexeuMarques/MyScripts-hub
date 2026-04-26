# Hub de Scripts Inteligentes 🚀 (KDE Plasma & Arch Linux)

Bem-vindo ao **Hub de Scripts Inteligentes**, uma arquitetura de linha de comando (CLI) modular criada especialmente para gerenciar, instalar e integrar miniapplicativos baseados em bash no seu ecossistema Arch Linux com front-end voltado à usabilidade extrema.

## Módulos Incluídos Atualmente

### 📦 Organizador de Pastas (Organizer)
Um motor CLI fortíssimo para varrer bagunças do sistema.
- **Tipagem baseada em Regras (Config em Cascata):** Define subpastas baseadas em extensões e/ou tipo de `MIME` Unix. Ele "adivinha" e manda pra pasta correta num fallback (Ex: fotos sem extensão vão parar e 'Imagens'). Usa um arquivo central `~/.config/.organizador.conf` que pode ser sobrescrito por regras locais da pasta.
- **Integração Plena (KDE Dolphin):** Menu ao clicar sobre pastas com Botão Direito > (🌟 Padrão ou ⚙️Avançado) invocando um popup UI no KDE (kdialog) ou processando via terminal (konsole).
- **Sem conflitos, Sem medos:** Detecção via SHA256 de Duplicados movendo para `Duplicados/`. Nunca move configurações nativas de `node_modules` nem arquivos ocultos (`.*`). Cria o arquivo espelho ao gitignore: `.organizadorignore`.
- **Prevenção Visual (Dry-run):** Suporta `-n` simulando como ficaria a hierarquia de pastas. Modos paramétricos de achate (Flatten) ou Relativos (Preserve Tree) durante escaneamento recursivo (`-r`).

### 📦 Ebook & Media Converter
Conversor unificado rápido de uso diário.
- **Integração Nativa:** Atua diretamente no *Menu de Contexto* (clique direito) do KDE Dolphin para que seja natural e prático.
- **Vídeos e Áudios:** Habilidade de extrair música de vídeos ou recodar `.mkv` para `.mp4` usando a robustez do `ffmpeg`.
- **Ebooks:** Facilita a leitura convertendo de `PDF`, `MOBI` para `EPUB` (ou vice-versa) através de binding silencioso do *calibre*.
- **Flexível:** Configuração em `~/.config/.media_converter.conf` para ditar se sobrescreve os originais, ou apaga os originais, mantendo o controle 100% com o usuário.

---

## 🛠 Como usar

1. **Rodar Hub CLI:**
   Abra seu terminal favorito:
   ```bash
   ./menu.sh
   # (Nesse Menu Interativo, com Cores ANSI, você Instala/Desinstala/Executa as ferramentas).
   ```

2. **Como Organizar uma pasta fora do Dolphin:**
   ```bash
   # CLI Avançado:
   organizer -r --flatten --dry-run /home/xexeu/Downloads/
   # Ou para interface visual nativa do desktop:
   organizer --advanced-gui /home/xexeu/Downloads/
   ```

3. **Gerenciar Configurações Pessoais de Pastas:**
   Edite o seu arquivo em `~/.config/.organizador.conf` do jeito que desejar. Adicione classes customizadas como `[Projetos_Web]="html css js"`. Pastas serão construídas por demanda para essa tag. 

---

## 📝 TODOs & Possíveis Implementações

Aqui trago uma lista de ideias já planejadas (ou sugeridas) de como ampliar futuramente este Hub CLI e o Organizer:

### Para o Organizer:
- [ ] **Módulo Undo (Desfazer):** Guardar um index `.json` nos Logs (na tabela `~/.local/share/meus-scripts/logs/`) mapeando toda localização original da última movimentação de arquivos, gerando a opção `organizer --undo` pro caso de o flatten não ser do gosto do usuário.
- [ ] **Agendamento em Fundo (Cron/Systemd):** Adicionar à UI de Instalação a configuração de uma rotina em Daemon para varrer uma vez por dia as pastas de `Downloads`, sem intervenção do usuário.
- [ ] **Notificações Push (notify-send):** Ao concluir grandes moves de `organizer`, criar bolhas no tray do KDE informando "500 Arquivos Organizados na pasta".
- [ ] **Remoção Segura de Duplicados:** Já que agora enviamos tudo idêntico para `Duplicados/`, poderíamos adicionar na Advanced GUI um check: `Deletar Arquivos Duplicados após confirmar que são Idênticos`.

- [ ] **Arch Linux Automated Baseline Settings:** Um script salvador via rsync configurado pra rodar a cada boot ou mensalmente, salvando a sua config `.dotfiles`, lista oficial do `pacman` e customizações do Plasma Shell subindo via SSH/Restic no seu Backup seguro.
- [ ] **Git-Multi-Push / AutoSync:** Script que escaneia várias pastas de códigos sua para gerar Auto-Commits e Pushes das mudanças triviais via cronjob.
