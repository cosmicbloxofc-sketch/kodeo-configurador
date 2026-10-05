#!/usr/bin/env bash
# Kodeo — configurador de terminal (macOS / Linux)
# Código aberto: https://github.com/cosmicbloxofc-sketch/kodeo-configurador
#   comando do painel (chave já dentro, vai direto configurar):
#     curl -fsSL https://kodeo.com.br/instalar.sh | KODEO_KEY="ck_…" bash
#   sem a chave (pergunta na tela):
#     curl -fsSL https://kodeo.com.br/instalar.sh | bash
#
# v1.0 (05/10/2026): DE VERDADE. Valida a chave na API antes de gravar, configura
# e desconfigura Claude Code, Claude App e OpenCode nos mesmos lugares que o app de
# computador da Kodeo. KODEO_SEM_REINICIAR=1 pula o reinício do Claude App (testes).
# Compatível com o bash 3.2 do macOS (sem -t fracionário, sem ${v,,}).
set -u
VERSAO="1.0"
BASE="https://api.kodeo.com.br"
MARCA_INI="# >>> kodeo >>>"; MARCA_FIM="# <<< kodeo <<<"

# ── estilo (painel Kodeo: preto/branco, verde só pra sucesso, sem emoji) ─────
E=$'\033'
R="$E[0m"; B="$E[1m"; W="$E[97m"; G="$E[38;2;150;150;150m"; OK="$E[32m"; ERR="$E[31m"; WARN="$E[33m"
rgb() { printf '%s[38;2;%s;%s;%sm' "$E" "$1" "$2" "$3"; }
cursor_off() { printf '%s[?25l' "$E"; }
cursor_on()  { printf '%s[?25h' "$E"; }
limpa_linha() { printf '\r%s[2K' "$E"; }
TTY=/dev/tty; [ -r "$TTY" ] || TTY=/dev/stdin
LINHAS=$(tput lines 2>/dev/null || echo 24); COLS=$(tput cols 2>/dev/null || echo 80)
LARG=$COLS; [ "$LARG" -gt 64 ] && LARG=64
regua() { local i s=""; for ((i=0; i<LARG-4; i++)); do s="${s}─"; done; printf '%s' "$s"; }
tracos() { local i s=""; for ((i=0; i<$1; i++)); do s="${s}─"; done; printf '%s' "$s"; }

restaura() { cursor_on; stty echo 2>/dev/null <"$TTY" || true; printf '%s' "$R"; }
cancela() { restaura; printf '\n\n  %sCancelado.%s Nada foi alterado.\n\n' "$G" "$R"; exit 130; }
trap restaura EXIT
trap cancela INT TERM
pausa() { sleep "$1"; }
digita() { local s="$1" i; for ((i=0; i<${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep 0.008; done; }
tecla() { # lê UMA tecla → ecoa nome: up/down/left/right/enter/space/bs/esc ou o caractere
  local ch seq
  IFS= read -rsn1 ch <"$TTY" || { printf 'eof'; return; }
  case "$ch" in
    $'\x1b') IFS= read -rsn2 -t 1 seq <"$TTY" 2>/dev/null || seq=""
      case "$seq" in '[A') printf 'up';; '[B') printf 'down';; '[D') printf 'left';; '[C') printf 'right';; *) printf 'esc';; esac ;;
    ''|$'\n'|$'\r') printf 'enter';; ' ') printf 'space';; $'\x7f'|$'\b') printf 'bs';; $'\x03') cancela;;
    *) printf '%s' "$ch";;
  esac
}

# ── céu de pixels ────────────────────────────────────────────────────────────
PIXELS=('▪' '▪' '▪' '·' '▘' '▝' '▖' '▗' '■')
estrelas() {
  local n=$(( (COLS*LINHAS)/55 )) i r c t g; [ "$n" -gt 90 ] && n=90
  for ((i=0; i<n; i++)); do
    r=$(( 2 + RANDOM % (LINHAS-4) )); c=$(( 1 + RANDOM % COLS )); t=$(( 55 + RANDOM % 60 )); g="${PIXELS[$((RANDOM % ${#PIXELS[@]}))]}"
    printf '%s[%d;%dH%s%s%s' "$E" "$r" "$c" "$(rgb "$t" "$t" "$t")" "$g" "$R"
  done
}

# ── planeta em pixel art (24×24, meio-blocos; '@' vira ESC na hora de imprimir) ─
PLANETA=(
'@[1C@[1C@[1C@[1C@[1C@[1C@[1C@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[1C@[1C@[1C@[1C@[1C@[1C@[1C'
'@[1C@[1C@[1C@[1C@[38;2;30;84;172m▄@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;254;255;255m@[48;2;29;80;165m▀@[0m@[38;2;234;238;242m@[48;2;43;112;199m▀@[0m@[38;2;214;218;221m@[48;2;72;138;79m▀@[0m@[38;2;65;125;72m▄@[0m@[1C@[1C@[1C@[1C'
'@[1C@[1C@[38;2;30;84;172m▄@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;90;172;99m▀@[0m@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;29;81;168m▀@[0m@[38;2;28;78;160m@[48;2;81;154;88m▀@[0m@[38;2;196;179;128m@[48;2;74;141;81m▀@[0m@[38;2;69;133;76m@[48;2;67;127;73m▀@[0m@[38;2;89;142;82m@[48;2;59;114;65m▀@[0m@[38;2;79;126;73m@[48;2;52;100;57m▀@[0m@[38;2;116;106;76m▄@[0m@[1C@[1C'
'@[1C@[38;2;90;172;99m▄@[0m@[38;2;49;127;226m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;129;205;118m▀@[0m@[38;2;90;172;99m@[48;2;129;205;118m▀@[0m@[38;2;90;172;99m@[48;2;129;205;118m▀@[0m@[38;2;49;127;226m@[48;2;90;172;99m▀@[0m@[38;2;30;84;172m@[48;2;231;211;151m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;89;170;98m▀@[0m@[38;2;85;162;93m@[48;2;82;156;90m▀@[0m@[38;2;78;149;85m@[48;2;107;170;98m▀@[0m@[38;2;71;135;77m@[48;2;68;130;74m▀@[0m@[38;2;64;122;70m@[48;2;155;142;101m▀@[0m@[38;2;31;80;142m@[48;2;18;50;103m▀@[0m@[38;2;16;46;95m@[48;2;15;43;89m▀@[0m@[38;2;14;39;81m@[48;2;13;37;76m▀@[0m@[38;2;10;30;62m▄@[0m@[1C'
'@[1C@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;129;205;118m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;49;127;226m▀@[0m@[38;2;231;211;151m@[48;2;49;127;226m▀@[0m@[38;2;49;127;226m@[48;2;49;127;226m▀@[0m@[38;2;30;84;172m@[48;2;49;127;226m▀@[0m@[38;2;30;84;172m@[48;2;49;127;226m▀@[0m@[38;2;231;211;151m@[48;2;90;172;99m▀@[0m@[38;2;86;164;94m@[48;2;83;159;91m▀@[0m@[38;2;113;179;104m@[48;2;76;145;83m▀@[0m@[38;2;103;163;94m@[48;2;99;157;91m▀@[0m@[38;2;93;147;85m@[48;2;62;118;68m▀@[0m@[38;2;31;81;145m@[48;2;156;159;162m▀@[0m@[38;2;17;47;97m@[48;2;16;44;91m▀@[0m@[38;2;14;40;84m@[48;2;13;38;78m▀@[0m@[38;2;12;34;70m@[48;2;11;31;64m▀@[0m@[38;2;9;27;57m@[48;2;14;37;67m▀@[0m@[1C'
'@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;231;211;151m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;231;211;151m@[48;2;231;211;151m▀@[0m@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;87;167;96m@[48;2;84;161;93m▀@[0m@[38;2;80;153;88m@[48;2;198;181;129m▀@[0m@[38;2;73;140;80m@[48;2;23;65;134m▀@[0m@[38;2;66;126;72m@[48;2;21;59;121m▀@[0m@[38;2;32;83;148m@[48;2;18;52;107m▀@[0m@[38;2;17;48;99m@[48;2;16;45;94m▀@[0m@[38;2;15;42;86m@[48;2;14;39;80m▀@[0m@[38;2;12;35;72m@[48;2;11;32;67m▀@[0m@[38;2;88;89;91m@[48;2;15;39;70m▀@[0m@[38;2;61;56;40m@[48;2;21;40;23m▀@[0m@[38;2;17;32;18m@[48;2;15;28;16m▀@[0m'
'@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;90;172;99m@[48;2;30;84;172m▀@[0m@[38;2;90;172;99m@[48;2;231;211;151m▀@[0m@[38;2;127;201;116m@[48;2;86;164;94m▀@[0m@[38;2;82;156;89m@[48;2;79;150;86m▀@[0m@[38;2;41;105;187m@[48;2;39;101;180m▀@[0m@[38;2;22;63;129m@[48;2;183;187;190m▀@[0m@[38;2;20;56;115m@[48;2;19;53;110m▀@[0m@[38;2;17;49;102m@[48;2;16;47;96m▀@[0m@[38;2;15;43;88m@[48;2;123;125;127m▀@[0m@[38;2;21;55;98m@[48;2;20;51;91m▀@[0m@[38;2;32;61;35m@[48;2;75;68;49m▀@[0m@[38;2;25;48;27m@[48;2;57;52;37m▀@[0m@[38;2;18;34;20m@[48;2;39;35;25m▀@[0m@[38;2;15;28;16m@[48;2;38;35;25m▀@[0m'
'@[1C@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;83;172m@[48;2;29;81;166m▀@[0m@[38;2;45;116;208m@[48;2;26;74;153m▀@[0m@[38;2;41;107;190m@[48;2;24;68;139m▀@[0m@[38;2;37;97;172m@[48;2;22;61;126m▀@[0m@[38;2;20;57;118m@[48;2;32;83;147m▀@[0m@[38;2;18;51;104m@[48;2;132;121;86m▀@[0m@[38;2;15;44;91m@[48;2;114;104;74m▀@[0m@[38;2;115;117;119m@[48;2;20;53;94m▀@[0m@[38;2;18;47;84m@[48;2;16;43;76m▀@[0m@[38;2;14;37;66m@[48;2;7;22;45m▀@[0m@[38;2;10;27;48m@[48;2;5;15;31m▀@[0m@[38;2;8;21;37m@[48;2;5;14;28m▀@[0m@[1C'
'@[1C@[38;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;29;82;168m▀@[0m@[38;2;28;78;160m@[48;2;27;75;155m▀@[0m@[38;2;25;71;147m@[48;2;24;69;141m▀@[0m@[38;2;23;65;133m@[48;2;22;62;128m▀@[0m@[38;2;21;58;120m@[48;2;20;56;114m▀@[0m@[38;2;56;107;61m@[48;2;29;74;133m▀@[0m@[38;2;49;93;53m@[48;2;46;87;50m▀@[0m@[38;2;42;80;46m@[48;2;99;91;65m▀@[0m@[38;2;89;81;58m@[48;2;17;45;80m▀@[0m@[38;2;15;39;69m@[48;2;13;35;62m▀@[0m@[38;2;6;19;39m@[48;2;5;16;34m▀@[0m@[38;2;5;14;28m@[48;2;5;14;28m▀@[0m@[38;2;5;14;28m▀@[0m@[1C'
'@[1C@[1C@[38;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;49;127;226m▀@[0m@[38;2;30;84;172m@[48;2;90;172;99m▀@[0m@[38;2;30;84;172m@[48;2;89;171;98m▀@[0m@[38;2;242;247;251m@[48;2;82;157;90m▀@[0m@[38;2;26;73;149m@[48;2;75;144;82m▀@[0m@[38;2;23;66;136m@[48;2;68;130;75m▀@[0m@[38;2;21;59;122m@[48;2;156;143;102m▀@[0m@[38;2;19;53;109m@[48;2;18;50;103m▀@[0m@[38;2;16;46;95m@[48;2;15;44;90m▀@[0m@[38;2;122;124;126m@[48;2;13;37;76m▀@[0m@[38;2;19;50;90m@[48;2;94;95;97m▀@[0m@[38;2;15;40;72m@[48;2;8;24;49m▀@[0m@[38;2;12;30;55m@[48;2;10;26;47m▀@[0m@[38;2;42;43;44m@[48;2;38;35;25m▀@[0m@[38;2;42;43;44m▀@[0m@[1C@[1C'
'@[1C@[1C@[1C@[1C@[38;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;231;211;151m@[48;2;255;255;255m▀@[0m@[38;2;90;172;99m@[48;2;255;255;255m▀@[0m@[38;2;129;205;118m@[48;2;255;255;255m▀@[0m@[38;2;124;196;113m@[48;2;238;242;246m▀@[0m@[38;2;114;180;104m@[48;2;218;221;225m▀@[0m@[38;2;104;164;95m@[48;2;198;201;204m▀@[0m@[38;2;65;125;72m@[48;2;178;181;184m▀@[0m@[38;2;58;111;64m@[48;2;158;160;163m▀@[0m@[38;2;28;72;129m@[48;2;137;140;142m▀@[0m@[38;2;14;41;84m@[48;2;117;119;121m▀@[0m@[38;2;12;34;71m@[48;2;97;99;101m▀@[0m@[38;2;86;87;88m@[48;2;77;79;80m▀@[0m@[38;2;7;21;44m@[48;2;57;58;59m▀@[0m@[38;2;8;22;40m▀@[0m@[1C@[1C@[1C@[1C'
'@[1C@[1C@[1C@[1C@[1C@[1C@[1C@[38;2;255;255;255m▀@[0m@[38;2;250;254;255m▀@[0m@[38;2;229;233;237m▀@[0m@[38;2;209;213;216m@[48;2;201;205;208m▀@[0m@[38;2;189;193;196m@[48;2;181;184;187m▀@[0m@[38;2;169;172;175m@[48;2;161;164;166m▀@[0m@[38;2;149;152;154m@[48;2;141;143;146m▀@[0m@[38;2;129;131;134m▀@[0m@[38;2;109;111;113m▀@[0m@[38;2;89;91;92m▀@[0m@[1C@[1C@[1C@[1C@[1C@[1C@[1C'
)
planeta() { # linha, coluna
  local i
  for ((i=0; i<${#PLANETA[@]}; i++)); do printf '%s[%d;%dH%s' "$E" $(($1+i)) "$2" "${PLANETA[$i]//@/$E}"; done
}

# ── moldura de cada tela (cabeçalho + rodapé fixo embaixo) ───────────────────
TOTAL=3; CHAVE_DO_COMANDO=0   # passos: chave, ferramentas, configurar
tela() { # "1/3  Chave"
  local dir="$1" pad
  pad=$((LARG-2-19-${#dir})); [ "$pad" -lt 1 ] && pad=1
  printf '%s[2J%s[H' "$E" "$E"; estrelas
  [ "$COLS" -ge $((LARG+32)) ] && planeta 3 $((LARG+6))
  printf '%s[H\n' "$E"
  printf '  %s%sKODEO%s  %sConfigurador%s%*s%s%s%s\n' "$B" "$W" "$R" "$G" "$R" "$pad" '' "$G" "$dir" "$R"
  printf '  %s%s%s\n\n' "$G" "$(regua)" "$R"
}
dicas() { # "tecla:ação" … → tecla em branco, ação em cinza
  local d s="" sep=""
  for d in "$@"; do s="$s$sep${B}${W}${d%%:*}${R} ${G}${d#*:}${R}"; sep="   "; done
  printf '%s' "$s"
}
rodape() {
  local texto; texto=$(dicas "$@")
  if [ "$LINHAS" -ge 18 ]; then
    printf '%s7' "$E"; printf '%s[%d;1H' "$E" $((LINHAS-2))
    printf '  %s%s%s\n  %s' "$G" "$(regua)" "$R" "$texto"
    printf '%s8' "$E"
  else
    printf '\n  %s%s%s\n  %s\n' "$G" "$(regua)" "$R" "$texto"
  fi
}
caixa_topo()  { printf '  %s╭─ %s %s╮%s\n' "$G" "$1" "$(tracos $((LARG-9-${#1})))" "$R"; }
caixa_linha() { local vis="$2" pad; pad=$((LARG-8-vis)); [ "$pad" -lt 0 ] && pad=0; printf '  %s│%s  %s%*s%s│%s\n' "$G" "$R" "$1" "$pad" '' "$G" "$R"; }
caixa_fundo() { printf '  %s╰%s╯%s\n' "$G" "$(tracos $((LARG-6)))" "$R"; }
SPIN='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
girando() { # texto, ticks de 50 ms → spinner e depois ✓
  local txt="$1" ticks="$2" i=0
  while [ "$i" -lt "$ticks" ]; do limpa_linha; printf '    %s%s%s %s' "$W" "${SPIN:$((i%10)):1}" "$R" "$txt"; sleep 0.05; i=$((i+1)); done
  limpa_linha; printf '    %s✓%s %s\n' "$OK" "$R" "$txt"
}

# ── abertura ─────────────────────────────────────────────────────────────────
LOGO=(
'██╗  ██╗ ██████╗ ██████╗ ███████╗ ██████╗ '
'██║ ██╔╝██╔═══██╗██╔══██╗██╔════╝██╔═══██╗'
'█████╔╝ ██║   ██║██║  ██║█████╗  ██║   ██║'
'██╔═██╗ ██║   ██║██║  ██║██╔══╝  ██║   ██║'
'██║  ██╗╚██████╔╝██████╔╝███████╗╚██████╔╝'
'╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ '
)
abertura() {
  printf '%s[2J%s[H' "$E" "$E"; cursor_off; estrelas
  local tons=(255 236 214 190 165 140) i col=2
  if [ "$COLS" -ge 72 ]; then planeta 2 2; col=30; fi
  for i in "${!LOGO[@]}"; do printf '%s[%d;%dH%s%s%s' "$E" $((4+i)) "$col" "$(rgb "${tons[$i]}" "${tons[$i]}" "${tons[$i]}")" "${LOGO[$i]}" "$R"; pausa 0.055; done
  printf '%s[%d;%dH%s' "$E" 11 "$col" "$G"; digita "Configurador de terminal  ·  api.kodeo.com.br  ·  v$VERSAO"; printf '%s' "$R"
  pausa 1.1
}

# ── passo: chave (pulado quando KODEO_KEY vem no comando) ───────────────────
CHAVE="${KODEO_KEY:-}"
chave_ok() { case "$1" in ck_??????*) return 0;; *) return 1;; esac; }
tela_chave() {
  tela "1/$TOTAL  Chave"
  printf '  Cole a chave do painel (começa com %sck_%s). Ela fica só neste computador.\n' "$W" "$R"
  printf '  %sDica: no painel tem o comando pronto com a chave dentro, que pula esta tela.%s\n\n' "$G" "$R"
  rodape "enter:continuar" "backspace:apagar" "ctrl+c:sair"
  local chave="$CHAVE" k i
  cursor_on
  while :; do
    limpa_linha; printf '  %s❯%s ' "$W" "$R"; for ((i=0; i<${#chave}; i++)); do printf '•'; done
    k=$(tecla)
    case "$k" in
      enter) if ! chave_ok "$chave"; then printf '\n  %s✗%s A chave da Kodeo começa com ck_. Confira e tente de novo.' "$ERR" "$R"; printf '%s[1A' "$E"
             else
               local st; st=$(validar_chave "$chave")
               case "$st" in 200) break;; 401|403) printf '\n  %s✗%s A API recusou essa chave. Confira no painel (kodeo.com.br/app) e cole de novo.' "$ERR" "$R"; printf '%s[1A' "$E";;
                 *) printf '\n  %s!%s Não consegui falar com api.kodeo.com.br (%s). Verifique a internet e tente de novo.' "$WARN" "$R" "$st"; printf '%s[1A' "$E";; esac
             fi ;;
      bs) chave="${chave%?}";;
      space|up|down|left|right|esc|eof) ;;
      *) chave="$chave$k";;
    esac
  done
  cursor_off
  CHAVE="$chave"
  printf '\n'; limpa_linha; printf '  %s✓%s Chave válida\n' "$OK" "$R"
  pausa 0.5
}
validar_chave() { curl -s -m 15 -o /dev/null -w '%{http_code}' -A "kodeo-configurador/$VERSAO" "$BASE/v1/me" -H "x-api-key: $1" 2>/dev/null || printf '000'; }
# chave que veio no comando: valida antes de qualquer coisa
tela_chave_do_comando() {
  tela "1/3  Chave"
  printf '  Chave recebida pelo comando.\n\n'
  local sinal="/tmp/kodeo-cfg-$$" st
  rm -f "$sinal"; ( validar_chave "$CHAVE" >"$sinal.st"; : >"$sinal" ) &
  local i=0; while [ ! -e "$sinal" ]; do limpa_linha; printf '  %s%s%s Verificando a chave em api.kodeo.com.br' "$W" "${SPIN:$((i%10)):1}" "$R"; sleep 0.05; i=$((i+1)); done
  st=$(cat "$sinal.st" 2>/dev/null); rm -f "$sinal" "$sinal.st"; limpa_linha
  case "$st" in
    200) printf '  %s✓%s Chave válida\n' "$OK" "$R"; pausa 0.6; return 0;;
    401|403) printf '  %s✗%s A API recusou a chave do comando. Pegue o comando de novo no painel.\n' "$ERR" "$R"; rodape "enter:sair"; while :; do [ "$(tecla)" = enter ] && break; done; exit 1;;
    *) printf '  %s!%s Não consegui falar com api.kodeo.com.br (%s). Verifique a internet e rode o comando de novo.\n' "$WARN" "$R" "$st"; rodape "enter:sair"; while :; do [ "$(tecla)" = enter ] && break; done; exit 1;;
  esac
}

# ── ferramentas: Claude Code, Claude App, OpenCode (detecção REAL, só leitura) ─
NOMES=("Claude Code" "Claude App" "OpenCode")
IDS=("claude-code" "claude-app" "opencode")
ONDE=("~/.claude/settings.json + ~/.zshrc" "Claude-3p/claude_desktop_config.json" "~/.config/opencode/opencode.json")
CONF=(0 0 0)   # 1 = já configurado pra Kodeo
SEL=(0 0 0)    # 1 = marcado (configurar ou desconfigurar, conforme o estado)
INST=(0 0 0)   # 1 = ferramenta encontrada no computador
detectar() {
  # Claude Code: env no settings.json OU bloco Kodeo no ~/.zshrc (mesmo formato do app de computador)
  if grep -qs "api.kodeo.com.br" "$HOME/.claude/settings.json" 2>/dev/null || grep -qs "^# >>> kodeo >>>" "$HOME/.zshrc" "$HOME/.bashrc" 2>/dev/null; then CONF[0]=1; fi
  command -v claude >/dev/null 2>&1 && INST[0]=1
  # Claude App: pasta Claude-3p com config apontando pra Kodeo
  local cfg="$HOME/Library/Application Support/Claude-3p/claude_desktop_config.json" lib="$HOME/Library/Application Support/Claude-3p/configLibrary"
  [ -f "$HOME/.config/Claude-3p/claude_desktop_config.json" ] && cfg="$HOME/.config/Claude-3p/claude_desktop_config.json"
  if grep -qsi "kodeo" "$cfg" 2>/dev/null || grep -rqsi "api.kodeo.com.br" "$lib" 2>/dev/null; then CONF[1]=1; fi
  { [ -d "/Applications/Claude.app" ] || [ -d "$HOME/Applications/Claude.app" ] || command -v claude-desktop >/dev/null 2>&1; } && INST[1]=1
  # OpenCode: provider "kodeo" no opencode.json
  grep -qs '"kodeo"' "$HOME/.config/opencode/opencode.json" 2>/dev/null && CONF[2]=1
  command -v opencode >/dev/null 2>&1 && INST[2]=1
  local i; for i in 0 1 2; do [ "${CONF[$i]}" -eq 0 ] && SEL[$i]=1; done   # o que falta vem marcado
}
tela_ferramentas() { # devolve 0 = aplicar, 1 = voltar
  tela "2/3  Ferramentas"
  printf '  Marque o que configurar. O que já está configurado pode ser desconfigurado.\n\n'
  local n=${#NOMES[@]} i cur=0 k
  if [ "$CHAVE_DO_COMANDO" -eq 0 ]; then rodape "↑↓:mover" "espaço:marcar" "enter:aplicar" "←:voltar" "ctrl+c:sair"; else rodape "↑↓:mover" "espaço:marcar" "enter:aplicar" "ctrl+c:sair"; fi
  desenha() {
    for ((i=0;i<n;i++)); do
      local pre="  " caixa estado acao nome="${NOMES[$i]}"
      [ "$i" -eq "$cur" ] && pre="${W}❯${R} "
      if [ "${SEL[$i]}" -eq 1 ]; then caixa="${W}[x]${R}"; else caixa="${G}[ ]${R}"; fi
      if [ "${CONF[$i]}" -eq 1 ]; then estado="${OK}configurado${R}"; acao="desconfigurar"; else estado="${G}não configurado${R}"; acao="configurar"; fi
      [ "${INST[$i]}" -eq 0 ] && [ "${CONF[$i]}" -eq 0 ] && estado="${G}não encontrado${R}"
      if [ "${SEL[$i]}" -eq 1 ]; then acao="${W}→ ${acao}${R}"; else acao="${G}  ${acao}${R}"; fi
      limpa_linha; printf '  %s%s %s%s%*s%s%*s%s\n' "$pre" "$caixa" "$W" "$nome" $((13-${#NOMES[$i]})) '' "$estado" $((17-${#estado}+${#G}+${#R}+4)) '' "$acao"
    done
  }
  desenha
  while :; do
    k=$(tecla)
    case "$k" in
      up|k) cur=$(( (cur+n-1) % n ));; down|j) cur=$(( (cur+1) % n ));;
      space) SEL[$cur]=$((1-SEL[$cur]));;
      a|A) for ((i=0;i<n;i++)); do SEL[$i]=1; done;;
      left|b|B) [ "$CHAVE_DO_COMANDO" -eq 0 ] && return 1;;
      enter) local algum=0; for ((i=0;i<n;i++)); do [ "${SEL[$i]}" -eq 1 ] && algum=1; done; [ "$algum" -eq 1 ] && return 0;;
    esac
    printf '%s[%dA' "$E" "$n"; desenha
  done
}

# ── ferramenta de JSON (node, senão python3 real — no macOS o python3 sem CLT abre um aviso) ──
JSON_TOOL=""
if command -v node >/dev/null 2>&1; then JSON_TOOL=node
elif command -v python3 >/dev/null 2>&1 && { [ "$(uname -s)" != Darwin ] || xcode-select -p >/dev/null 2>&1; }; then JSON_TOOL=python3; fi
# json_edit ARQUIVO OPERACAO — lê o JSON (ou {}), aplica a operação e grava de forma atômica. Chave e valores vão por ambiente.
json_edit() {
  local arq="$1" op="$2" dir; dir=$(dirname "$arq"); mkdir -p "$dir"
  if [ "$JSON_TOOL" = node ]; then
    KODEO_ARQ="$arq" KODEO_OP="$op" KODEO_CHAVE="$CHAVE" KODEO_BASE="$BASE" node -e '
const fs=require("fs"),f=process.env.KODEO_ARQ,op=process.env.KODEO_OP,chave=process.env.KODEO_CHAVE,base=process.env.KODEO_BASE;
let txt="";try{txt=fs.readFileSync(f,"utf8")}catch{}
let j={};if(txt.trim()){try{j=JSON.parse(txt)}catch{console.error("corrompido");process.exit(2)}}
if(!j||typeof j!=="object"||Array.isArray(j)){console.error("nao-objeto");process.exit(2)}
const ENV={ANTHROPIC_BASE_URL:base,ANTHROPIC_AUTH_TOKEN:chave,ANTHROPIC_MODEL:"grok-4.7",ANTHROPIC_SMALL_FAST_MODEL:"minimax-m2.7",ANTHROPIC_DEFAULT_OPUS_MODEL:"claude-opus-5.5",ANTHROPIC_DEFAULT_SONNET_MODEL:"grok-4.7",ANTHROPIC_DEFAULT_HAIKU_MODEL:"minimax-m2.7",CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY:"1"};
const MODELOS={"grok-4.7":{name:"Grok 4.7 (Kodeo)",limit:{context:256000,output:32000}},"claude-opus-5":{name:"Claude Opus 5 (Kodeo)",limit:{context:200000,output:32000}},"claude-opus-5.5":{name:"Claude Opus 5.5 (Kodeo)",limit:{context:200000,output:32000}},"gpt-6-sol":{name:"GPT-6 Sol (Kodeo)",limit:{context:400000,output:32000}},"gpt-6-astra":{name:"GPT-6 Astra (Kodeo)",limit:{context:400000,output:32000}},"minimax-m2.7":{name:"MiniMax M2.7 (Kodeo)",limit:{context:200000,output:32000}},"glm-5.3-flash":{name:"GLM 5.3 Flash (Kodeo)",limit:{context:200000,output:32000}},"deepseek-v4-flash":{name:"DeepSeek V4 Flash (Kodeo)",limit:{context:200000,output:32000}}};
if(op==="claude-code-add"){j.env=(j.env&&typeof j.env==="object"&&!Array.isArray(j.env))?j.env:{};Object.assign(j.env,ENV)}
else if(op==="claude-code-del"){if(j.env&&typeof j.env==="object"){for(const k of Object.keys(ENV))delete j.env[k];if(!Object.keys(j.env).length)delete j.env}}
else if(op==="opencode-add"){j.provider=(j.provider&&typeof j.provider==="object"&&!Array.isArray(j.provider))?j.provider:{};j.provider.kodeo={name:"Kodeo",npm:"@ai-sdk/anthropic",options:{apiKey:"{file:"+process.env.KODEO_KEYFILE+"}",baseURL:base+"/v1"},models:MODELOS};if(typeof j.model==="string"&&!j.model.startsWith("kodeo/"))process.stdout.write(j.model);j.model="kodeo/grok-4.7"}
else if(op==="opencode-del"){if(j.provider&&typeof j.provider==="object")delete j.provider.kodeo;if(typeof j.model==="string"&&j.model.startsWith("kodeo/")){const ant=process.env.KODEO_MODELO_ANTERIOR||"";if(ant)j.model=ant;else delete j.model}}
else if(op==="set-3p"){j.deploymentMode="3p"}else if(op==="set-1p"){j.deploymentMode="1p"}else if(op==="devtools"){j.allowDevTools=true}
const tmp=f+".kodeo-tmp";fs.writeFileSync(tmp,JSON.stringify(j,null,2)+"\n");fs.renameSync(tmp,f);'
  else
    KODEO_ARQ="$arq" KODEO_OP="$op" KODEO_CHAVE="$CHAVE" KODEO_BASE="$BASE" python3 - <<'PYEOF'
import json,os
f=os.environ["KODEO_ARQ"];op=os.environ["KODEO_OP"];chave=os.environ["KODEO_CHAVE"];base=os.environ["KODEO_BASE"]
txt=""
try: txt=open(f,encoding="utf-8").read()
except FileNotFoundError: pass
j={}
if txt.strip():
    try: j=json.loads(txt)
    except Exception: print("corrompido"); raise SystemExit(2)
if not isinstance(j,dict): raise SystemExit(2)
ENV={"ANTHROPIC_BASE_URL":base,"ANTHROPIC_AUTH_TOKEN":chave,"ANTHROPIC_MODEL":"grok-4.7","ANTHROPIC_SMALL_FAST_MODEL":"minimax-m2.7","ANTHROPIC_DEFAULT_OPUS_MODEL":"claude-opus-5.5","ANTHROPIC_DEFAULT_SONNET_MODEL":"grok-4.7","ANTHROPIC_DEFAULT_HAIKU_MODEL":"minimax-m2.7","CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY":"1"}
M=lambda n,c: {"name":n,"limit":{"context":c,"output":32000}}
MODELOS={"grok-4.7":M("Grok 4.7 (Kodeo)",256000),"claude-opus-5":M("Claude Opus 5 (Kodeo)",200000),"claude-opus-5.5":M("Claude Opus 5.5 (Kodeo)",200000),"gpt-6-sol":M("GPT-6 Sol (Kodeo)",400000),"gpt-6-astra":M("GPT-6 Astra (Kodeo)",400000),"minimax-m2.7":M("MiniMax M2.7 (Kodeo)",200000),"glm-5.3-flash":M("GLM 5.3 Flash (Kodeo)",200000),"deepseek-v4-flash":M("DeepSeek V4 Flash (Kodeo)",200000)}
if op=="claude-code-add":
    env=j.get("env") if isinstance(j.get("env"),dict) else {}; env.update(ENV); j["env"]=env
elif op=="claude-code-del":
    if isinstance(j.get("env"),dict):
        for k in ENV: j["env"].pop(k,None)
        if not j["env"]: del j["env"]
elif op=="opencode-add":
    prov=j.get("provider") if isinstance(j.get("provider"),dict) else {}
    prov["kodeo"]={"name":"Kodeo","npm":"@ai-sdk/anthropic","options":{"apiKey":"{file:"+os.environ.get("KODEO_KEYFILE","")+"}","baseURL":base+"/v1"},"models":MODELOS}; j["provider"]=prov
    if isinstance(j.get("model"),str) and not j["model"].startswith("kodeo/"): print(j["model"],end="")
    j["model"]="kodeo/grok-4.7"
elif op=="opencode-del":
    if isinstance(j.get("provider"),dict): j["provider"].pop("kodeo",None)
    if isinstance(j.get("model"),str) and j["model"].startswith("kodeo/"):
        ant=os.environ.get("KODEO_MODELO_ANTERIOR","")
        if ant: j["model"]=ant
        else: del j["model"]
elif op=="set-3p": j["deploymentMode"]="3p"
elif op=="set-1p": j["deploymentMode"]="1p"
elif op=="devtools": j["allowDevTools"]=True
tmp=f+".kodeo-tmp"; open(tmp,"w",encoding="utf-8").write(json.dumps(j,indent=2,ensure_ascii=False)+"\n"); os.replace(tmp,f)
PYEOF
  fi
}
passo() { # texto, comando… → spinner enquanto roda; ✓ ou ✗ com a mensagem de erro
  local txt="$1"; shift
  local sinal="/tmp/kodeo-cfg-$$-$RANDOM" i=0 rc
  rm -f "$sinal"; ( "$@" >"$sinal.out" 2>&1; echo $? >"$sinal.rc"; : >"$sinal" ) &
  while [ ! -e "$sinal" ]; do limpa_linha; printf '    %s%s%s %s' "$W" "${SPIN:$((i%10)):1}" "$R" "$txt"; sleep 0.05; i=$((i+1)); done
  rc=$(cat "$sinal.rc" 2>/dev/null || echo 1); limpa_linha
  if [ "$rc" = 0 ]; then printf '    %s✓%s %s\n' "$OK" "$R" "$txt"; else printf '    %s✗%s %s %s(%s)%s\n' "$ERR" "$R" "$txt" "$G" "$(head -c 120 "$sinal.out" 2>/dev/null | tr '\n' ' ')" "$R"; FALHAS=$((FALHAS+1)); fi
  rm -f "$sinal" "$sinal.out" "$sinal.rc"
  sleep 0.15
}
FALHAS=0
RC_FILES() { local f; for f in "$HOME/.zshrc" "$HOME/.bashrc"; do [ -f "$f" ] && printf '%s\n' "$f"; done; [ -f "$HOME/.zshrc" ] || printf '%s\n' "$HOME/.zshrc"; }
rc_remover_bloco() { # tira o bloco entre as marcas (se existir)
  local f="$1"; [ -f "$f" ] || return 0
  awk -v a="$MARCA_INI" -v b="$MARCA_FIM" '$0==a{dentro=1;next} $0==b{dentro=0;next} !dentro' "$f" >"$f.kodeo-tmp" && mv "$f.kodeo-tmp" "$f"
}
rc_escrever_bloco() {
  local f="$1"; rc_remover_bloco "$f"
  printf '%s\nexport ANTHROPIC_BASE_URL="%s"\nexport ANTHROPIC_AUTH_TOKEN="%s"\n%s\n' "$MARCA_INI" "$BASE" "$CHAVE" "$MARCA_FIM" >>"$f"
}
teste_conexao() { local st; st=$(curl -s -m 20 -o /dev/null -w '%{http_code}' "$BASE/v1/models" -H "x-api-key: $CHAVE"); [ "$st" = 200 ] || { echo "api respondeu $st"; return 1; }; }

# Claude Code: env no ~/.claude/settings.json (vale pro Claude Code e pra extensão do VS Code) + bloco no rc do shell
aplicar_claude_code() {
  [ -n "$JSON_TOOL" ] || { printf '    %s✗%s Preciso do Node.js (ou Python) pra editar o settings.json. Instale o Node e rode de novo.\n' "$ERR" "$R"; FALHAS=$((FALHAS+1)); return; }
  passo "env no ~/.claude/settings.json (ANTHROPIC_BASE_URL + chave + modelos)" json_edit "$HOME/.claude/settings.json" claude-code-add
  local f; for f in $(RC_FILES); do passo "Bloco Kodeo em ${f/#$HOME/~}" rc_escrever_bloco "$f"; done
  passo "Teste de conexão (api.kodeo.com.br/v1/models)" teste_conexao
}
remover_claude_code() {
  if [ -n "$JSON_TOOL" ] && [ -f "$HOME/.claude/settings.json" ]; then passo "Tirar o env da Kodeo do ~/.claude/settings.json" json_edit "$HOME/.claude/settings.json" claude-code-del; fi
  local f; for f in "$HOME/.zshrc" "$HOME/.bashrc"; do [ -f "$f" ] && grep -qs "^$MARCA_INI" "$f" && passo "Remover o bloco Kodeo de ${f/#$HOME/~}" rc_remover_bloco "$f"; done
  true
}

# Claude App: Claude-3p/configLibrary + deploymentMode 3p + reinício (igual ao app de computador)
pasta_3p() {
  local d; d=$(ps ax -ww -o command 2>/dev/null | grep 'Claude.app/Contents/' | grep -v grep | grep -o -- '--user-data-dir=[^ ]*' | head -1 | sed 's/^--user-data-dir=//')
  case "$d" in "$HOME"/*) ;; *) d="";; esac
  if [ -n "$d" ]; then case "$(basename "$d")" in Claude) printf '%s/Claude-3p' "$(dirname "$d")";; *) printf '%s' "$d";; esac
  elif [ "$(uname -s)" = Darwin ]; then printf '%s/Library/Application Support/Claude-3p' "$HOME"; else printf '%s/.config/Claude-3p' "$HOME"; fi
}
app_escrever_config() {
  local dir; dir=$(pasta_3p); local lib="$dir/configLibrary"; mkdir -p "$lib" || return 1
  local id; id=$( (uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null) | tr 'A-Z' 'a-z'); [ -n "$id" ] || return 1
  # tira um config nosso anterior
  app_remover_config_silencioso "$lib"
  printf '{\n  "inferenceProvider": "gateway",\n  "inferenceCredentialKind": "static",\n  "inferenceGatewayBaseUrl": "%s",\n  "inferenceGatewayApiKey": "%s"\n}\n' "$BASE" "$CHAVE" >"$lib/$id.json.kodeo-tmp" && mv "$lib/$id.json.kodeo-tmp" "$lib/$id.json" || return 1
  printf '{\n  "appliedId": "%s",\n  "entries": [{ "id": "%s", "name": "Kodeo" }]\n}\n' "$id" "$id" >"$lib/_meta.json.kodeo-tmp" && mv "$lib/_meta.json.kodeo-tmp" "$lib/_meta.json"
}
app_remover_config_silencioso() { # só mexe se o config aplicado for o nosso
  local lib="$1" meta="$1/_meta.json" id
  [ -f "$meta" ] || return 0
  grep -q '"name": *"Kodeo"' "$meta" || return 0
  id=$(grep -o '"appliedId": *"[^"]*"' "$meta" | sed 's/.*: *"//; s/"$//'); [ -n "$id" ] && rm -f "$lib/$id.json"; rm -f "$meta"
}
app_remover_config() { app_remover_config_silencioso "$(pasta_3p)/configLibrary"; }
app_modo() { json_edit "$(pasta_3p)/claude_desktop_config.json" "$1"; }
app_devtools() { json_edit "$(pasta_3p)/developer_settings.json" devtools; }
app_reiniciar() {
  [ "${KODEO_SEM_REINICIAR:-0}" = 1 ] && return 0
  if pgrep -f '/Applications/Claude.app' >/dev/null 2>&1; then
    osascript -e 'tell application "Claude" to quit' >/dev/null 2>&1; sleep 2.5
    pgrep -f '/Applications/Claude.app' >/dev/null 2>&1 && pkill -f '/Applications/Claude.app'; sleep 0.5
    open -a Claude 2>/dev/null || true
  fi
}
aplicar_claude_app() {
  [ -n "$JSON_TOOL" ] || { printf '    %s✗%s Preciso do Node.js (ou Python) pra editar a configuração do Claude. Instale o Node e rode de novo.\n' "$ERR" "$R"; FALHAS=$((FALHAS+1)); return; }
  passo "Config Kodeo em Claude-3p/configLibrary" app_escrever_config
  passo "deploymentMode = 3p" app_modo set-3p
  passo "Modo desenvolvedor (allowDevTools)" app_devtools
  passo "Reiniciar o Claude (se estiver aberto)" app_reiniciar
}
remover_claude_app() {
  passo "Remover a config Kodeo do configLibrary" app_remover_config
  [ -n "$JSON_TOOL" ] && [ -f "$(pasta_3p)/claude_desktop_config.json" ] && passo "deploymentMode = 1p" app_modo set-1p
  passo "Reiniciar o Claude (se estiver aberto)" app_reiniciar
}

# OpenCode: provider kodeo no ~/.config/opencode/opencode.json (chave num arquivo só nosso, 600) + modelo padrão grok-4.7
OC_CFG="$HOME/.config/opencode/opencode.json"; OC_KEY="$HOME/.config/opencode/kodeo-api-key"; OC_BK="$HOME/.config/kodeo/opencode-model-anterior"
oc_chave() { mkdir -p "$(dirname "$OC_KEY")" && (umask 077; printf '%s' "$CHAVE" >"$OC_KEY"); }
oc_provider() { local ant; ant=$(KODEO_KEYFILE="$OC_KEY" json_edit "$OC_CFG" opencode-add) || return 1; if [ -n "$ant" ]; then mkdir -p "$(dirname "$OC_BK")"; printf '%s' "$ant" >"$OC_BK"; fi; }
oc_remover() { local ant=""; [ -f "$OC_BK" ] && ant=$(cat "$OC_BK"); KODEO_MODELO_ANTERIOR="$ant" json_edit "$OC_CFG" opencode-del && rm -f "$OC_KEY" "$OC_BK"; }
aplicar_opencode() {
  [ -n "$JSON_TOOL" ] || { printf '    %s✗%s Preciso do Node.js (ou Python) pra editar o opencode.json. Instale o Node e rode de novo.\n' "$ERR" "$R"; FALHAS=$((FALHAS+1)); return; }
  passo "Chave em ~/.config/opencode/kodeo-api-key (só você lê)" oc_chave
  passo "Provedor kodeo com os 8 modelos em ~/.config/opencode/opencode.json" oc_provider
  passo "Modelo padrão: kodeo/grok-4.7" true
}
remover_opencode() {
  if [ -n "$JSON_TOOL" ] && [ -f "$OC_CFG" ]; then passo "Remover o provedor kodeo do opencode.json (e devolver o modelo anterior)" oc_remover; else rm -f "$OC_KEY" "$OC_BK"; fi
  true
}
FEITAS=(); REMOVIDAS=()
tela_configurar() {
  tela "3/3  Configurar"
  rodape "aguarde:aplicando"
  local i
  for ((i=0;i<${#NOMES[@]};i++)); do
    [ "${SEL[$i]}" -eq 1 ] || continue
    if [ "${CONF[$i]}" -eq 1 ]; then
      printf '  %s%s%s  %sdesconfigurar%s\n' "$B$W" "${NOMES[$i]}" "$R" "$G" "$R"
      case "${IDS[$i]}" in claude-code) remover_claude_code;; claude-app) remover_claude_app;; opencode) remover_opencode;; esac
      REMOVIDAS+=("${NOMES[$i]}")
    else
      printf '  %s%s%s  %sconfigurar%s\n' "$B$W" "${NOMES[$i]}" "$R" "$G" "$R"
      case "${IDS[$i]}" in claude-code) aplicar_claude_code;; claude-app) aplicar_claude_app;; opencode) aplicar_opencode;; esac
      FEITAS+=("${NOMES[$i]}")
    fi
    printf '\n'
  done
  local mascara="${CHAVE:0:9}…${CHAVE: -4}" lista="" lista2="" x
  for x in "${FEITAS[@]+"${FEITAS[@]}"}"; do lista="$lista${lista:+, }$x"; done
  for x in "${REMOVIDAS[@]+"${REMOVIDAS[@]}"}"; do lista2="$lista2${lista2:+, }$x"; done
  caixa_topo "Pronto"
  caixa_linha "" 0
  caixa_linha "${G}Chave          $R$mascara" $((15+${#mascara}))
  [ -n "$lista" ]  && caixa_linha "${G}Configuradas   $R$lista" $((15+${#lista}))
  [ -n "$lista2" ] && caixa_linha "${G}Desconfiguradas $R$lista2" $((16+${#lista2}))
  caixa_linha "" 0
  if [ "$FALHAS" -gt 0 ]; then caixa_linha "${ERR}${FALHAS} passo(s) falharam$R — veja acima e rode de novo." $((${#FALHAS}+40))
  elif [ -n "$lista" ]; then caixa_linha "Abra um terminal novo e use a ferramenta normalmente." 53; else caixa_linha "Tudo removido. Nada da Kodeo ficou no computador." 50; fi
  caixa_fundo
  rodape "enter:sair"
  while :; do k=$(tecla); case "$k" in enter|q|Q|eof) break;; esac; done
  printf '%s[%d;1H\n' "$E" "$LINHAS"
}

abertura
stty -echo 2>/dev/null <"$TTY" || true
detectar
if chave_ok "$CHAVE"; then CHAVE_DO_COMANDO=1; tela_chave_do_comando; fi
while :; do
  [ "$CHAVE_DO_COMANDO" -eq 0 ] && tela_chave
  if tela_ferramentas; then break; fi      # ← volta pra chave (só quando ela foi digitada)
done
tela_configurar
