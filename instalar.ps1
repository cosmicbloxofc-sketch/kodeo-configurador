# Kodeo — configurador de terminal (Windows)
# Código aberto: https://github.com/cosmicbloxofc-sketch/kodeo-configurador
#   comando do painel (chave já dentro, vai direto configurar):
#     $env:KODEO_KEY="ck_…"; irm https://kodeo.com.br/instalar.ps1 | iex
#   sem a chave (pergunta na tela):
#     irm https://kodeo.com.br/instalar.ps1 | iex
#
# v1.0 (05/10/2026): DE VERDADE. Valida a chave na API antes de gravar, configura
# e desconfigura Claude Code, Claude App e OpenCode nos mesmos lugares que o app de
# computador da Kodeo. KODEO_SEM_REINICIAR=1 pula o reinício do Claude App (testes).
# v1.0.1 (08/10/2026): tudo roda num escopo filho (& { }): Set-StrictMode e
# $ErrorActionPreference ficam só aqui dentro (perfil com Set-StrictMode quebrava o
# .Count) e sair não fecha mais a janela do PowerShell (exit dentro do iex fechava).
& {
Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$VERSAO = '1.0.1'
$BASE = 'https://api.kodeo.com.br'
$WIN = ($env:OS -eq 'Windows_NT')

# ── estilo (painel Kodeo: preto/branco, verde só pra sucesso, sem emoji) ─────
$E = [char]27
$R = "$E[0m"; $B = "$E[1m"; $W = "$E[97m"; $G = "$E[38;2;150;150;150m"; $OK = "$E[32m"; $ERR = "$E[31m"
function Tom($v) { "$E[38;2;$v;$v;$($v)m" }
function Out($s) { [Console]::Write([string]$s) }
function Linha($s) { [Console]::WriteLine([string]$s) }
function LimpaLinha { Out "`r$E[2K" }
function Pausa($ms) { Start-Sleep -Milliseconds $ms }
function Digita($s, $ms = 8) { foreach ($c in $s.ToCharArray()) { Out $c; Pausa $ms } }

try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
if ($env:OS -eq 'Windows_NT') {   # conhost do Windows 10 precisa ligar o modo VT (Windows Terminal já vem ligado)
  try {
    Add-Type -Namespace Kodeo -Name Vt -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int h);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
'@
    $h = [Kodeo.Vt]::GetStdHandle(-11); $m = 0
    if ([Kodeo.Vt]::GetConsoleMode($h, [ref]$m)) { [Kodeo.Vt]::SetConsoleMode($h, $m -bor 4) | Out-Null }
  } catch {}
}
$LINHAS = 24; $COLS = 80
try { $LINHAS = [Console]::WindowHeight; $COLS = [Console]::WindowWidth } catch {}
$LARG = $COLS; if ($LARG -gt 64) { $LARG = 64 }
function Regua { '─' * ($LARG - 4) }
try { [Console]::TreatControlCAsInput = $true } catch {}
function CursorOff { try { [Console]::CursorVisible = $false } catch {} }
function CursorOn  { try { [Console]::CursorVisible = $true } catch {} }
function Restaura { CursorOn; try { [Console]::TreatControlCAsInput = $false } catch {}; Out $R }
function Sair { throw 'kodeo:sair' }   # o try do fim pega; exit aqui fecharia a janela de quem rodou com iex
function Cancela { Restaura; Linha ""; Linha ""; Linha "  $($G)Cancelado.$R Nada foi alterado."; Linha ""; Sair }

# teste automatizado sem terminal: KODEO_TESTE_TECLAS="ck_abc\n{DOWN} \n" (\n = Enter, {UP} {DOWN} {LEFT} {RIGHT} {BS})
$script:TECLAS_TESTE = $null
if ($env:KODEO_TESTE_TECLAS) {
  $fila = [System.Collections.Generic.Queue[object]]::new()
  $txt = $env:KODEO_TESTE_TECLAS
  while ($txt.Length -gt 0) {
    if ($txt.StartsWith('\n')) { $fila.Enqueue('Enter'); $txt = $txt.Substring(2); continue }
    if ($txt -match '^\{(UP|DOWN|LEFT|RIGHT|BS)\}') { $fila.Enqueue($Matches[1]); $txt = $txt.Substring($Matches[0].Length); continue }
    $fila.Enqueue($txt[0]); $txt = $txt.Substring(1)
  }
  $script:TECLAS_TESTE = $fila
}
function Tecla { # devolve: up/down/left/right/enter/space/bs/esc ou o caractere
  if ($script:TECLAS_TESTE) {
    if ($script:TECLAS_TESTE.Count -eq 0) { throw 'teste: acabaram as teclas' }
    $t = $script:TECLAS_TESTE.Dequeue(); Pausa 20
    switch ("$t") { 'Enter' { return 'enter' } 'UP' { return 'up' } 'DOWN' { return 'down' } 'LEFT' { return 'left' } 'RIGHT' { return 'right' } 'BS' { return 'bs' } ' ' { return 'space' } default { return "$t" } }
  }
  $k = [Console]::ReadKey($true)
  if ($k.Key -eq 'C' -and ($k.Modifiers -band [ConsoleModifiers]::Control)) { Cancela }
  switch ($k.Key) {
    'UpArrow' { return 'up' } 'DownArrow' { return 'down' } 'LeftArrow' { return 'left' } 'RightArrow' { return 'right' }
    'Enter' { return 'enter' } 'Spacebar' { return 'space' } 'Backspace' { return 'bs' } 'Escape' { return 'esc' }
  }
  if ($k.KeyChar -and -not [char]::IsControl($k.KeyChar)) { return [string]$k.KeyChar }
  return ''
}

# ── céu de pixels ────────────────────────────────────────────────────────────
$PIXELS = '▪', '▪', '▪', '·', '▘', '▝', '▖', '▗', '■'
function Estrelas {
  $n = [int](($COLS * $LINHAS) / 55); if ($n -gt 90) { $n = 90 }
  for ($i = 0; $i -lt $n; $i++) {
    $r = Get-Random -Minimum 2 -Maximum ([Math]::Max(3, $LINHAS - 2)); $c = Get-Random -Minimum 1 -Maximum ($COLS + 1); $t = Get-Random -Minimum 55 -Maximum 115
    Out ("$E[$r;$($c)H" + (Tom $t) + $PIXELS[(Get-Random -Maximum $PIXELS.Count)] + $R)
  }
}

# ── planeta em pixel art (24×24, meio-blocos; '@' vira ESC na hora de imprimir) ─
$PLANETA = @(
'@[1C@[1C@[1C@[1C@[1C@[1C@[1C@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[38;2;255;255;255m▄@[0m@[1C@[1C@[1C@[1C@[1C@[1C@[1C',
'@[1C@[1C@[1C@[1C@[38;2;30;84;172m▄@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;254;255;255m@[48;2;29;80;165m▀@[0m@[38;2;234;238;242m@[48;2;43;112;199m▀@[0m@[38;2;214;218;221m@[48;2;72;138;79m▀@[0m@[38;2;65;125;72m▄@[0m@[1C@[1C@[1C@[1C',
'@[1C@[1C@[38;2;30;84;172m▄@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;90;172;99m▀@[0m@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;29;81;168m▀@[0m@[38;2;28;78;160m@[48;2;81;154;88m▀@[0m@[38;2;196;179;128m@[48;2;74;141;81m▀@[0m@[38;2;69;133;76m@[48;2;67;127;73m▀@[0m@[38;2;89;142;82m@[48;2;59;114;65m▀@[0m@[38;2;79;126;73m@[48;2;52;100;57m▀@[0m@[38;2;116;106;76m▄@[0m@[1C@[1C',
'@[1C@[38;2;90;172;99m▄@[0m@[38;2;49;127;226m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;129;205;118m▀@[0m@[38;2;90;172;99m@[48;2;129;205;118m▀@[0m@[38;2;90;172;99m@[48;2;129;205;118m▀@[0m@[38;2;49;127;226m@[48;2;90;172;99m▀@[0m@[38;2;30;84;172m@[48;2;231;211;151m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;89;170;98m▀@[0m@[38;2;85;162;93m@[48;2;82;156;90m▀@[0m@[38;2;78;149;85m@[48;2;107;170;98m▀@[0m@[38;2;71;135;77m@[48;2;68;130;74m▀@[0m@[38;2;64;122;70m@[48;2;155;142;101m▀@[0m@[38;2;31;80;142m@[48;2;18;50;103m▀@[0m@[38;2;16;46;95m@[48;2;15;43;89m▀@[0m@[38;2;14;39;81m@[48;2;13;37;76m▀@[0m@[38;2;10;30;62m▄@[0m@[1C',
'@[1C@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;129;205;118m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;129;205;118m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;49;127;226m▀@[0m@[38;2;231;211;151m@[48;2;49;127;226m▀@[0m@[38;2;49;127;226m@[48;2;49;127;226m▀@[0m@[38;2;30;84;172m@[48;2;49;127;226m▀@[0m@[38;2;30;84;172m@[48;2;49;127;226m▀@[0m@[38;2;231;211;151m@[48;2;90;172;99m▀@[0m@[38;2;86;164;94m@[48;2;83;159;91m▀@[0m@[38;2;113;179;104m@[48;2;76;145;83m▀@[0m@[38;2;103;163;94m@[48;2;99;157;91m▀@[0m@[38;2;93;147;85m@[48;2;62;118;68m▀@[0m@[38;2;31;81;145m@[48;2;156;159;162m▀@[0m@[38;2;17;47;97m@[48;2;16;44;91m▀@[0m@[38;2;14;40;84m@[48;2;13;38;78m▀@[0m@[38;2;12;34;70m@[48;2;11;31;64m▀@[0m@[38;2;9;27;57m@[48;2;14;37;67m▀@[0m@[1C',
'@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;231;211;151m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;49;127;226m@[48;2;30;84;172m▀@[0m@[38;2;231;211;151m@[48;2;231;211;151m▀@[0m@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;90;172;99m@[48;2;90;172;99m▀@[0m@[38;2;87;167;96m@[48;2;84;161;93m▀@[0m@[38;2;80;153;88m@[48;2;198;181;129m▀@[0m@[38;2;73;140;80m@[48;2;23;65;134m▀@[0m@[38;2;66;126;72m@[48;2;21;59;121m▀@[0m@[38;2;32;83;148m@[48;2;18;52;107m▀@[0m@[38;2;17;48;99m@[48;2;16;45;94m▀@[0m@[38;2;15;42;86m@[48;2;14;39;80m▀@[0m@[38;2;12;35;72m@[48;2;11;32;67m▀@[0m@[38;2;88;89;91m@[48;2;15;39;70m▀@[0m@[38;2;61;56;40m@[48;2;21;40;23m▀@[0m@[38;2;17;32;18m@[48;2;15;28;16m▀@[0m',
'@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;90;172;99m@[48;2;30;84;172m▀@[0m@[38;2;90;172;99m@[48;2;231;211;151m▀@[0m@[38;2;127;201;116m@[48;2;86;164;94m▀@[0m@[38;2;82;156;89m@[48;2;79;150;86m▀@[0m@[38;2;41;105;187m@[48;2;39;101;180m▀@[0m@[38;2;22;63;129m@[48;2;183;187;190m▀@[0m@[38;2;20;56;115m@[48;2;19;53;110m▀@[0m@[38;2;17;49;102m@[48;2;16;47;96m▀@[0m@[38;2;15;43;88m@[48;2;123;125;127m▀@[0m@[38;2;21;55;98m@[48;2;20;51;91m▀@[0m@[38;2;32;61;35m@[48;2;75;68;49m▀@[0m@[38;2;25;48;27m@[48;2;57;52;37m▀@[0m@[38;2;18;34;20m@[48;2;39;35;25m▀@[0m@[38;2;15;28;16m@[48;2;38;35;25m▀@[0m',
'@[1C@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;83;172m@[48;2;29;81;166m▀@[0m@[38;2;45;116;208m@[48;2;26;74;153m▀@[0m@[38;2;41;107;190m@[48;2;24;68;139m▀@[0m@[38;2;37;97;172m@[48;2;22;61;126m▀@[0m@[38;2;20;57;118m@[48;2;32;83;147m▀@[0m@[38;2;18;51;104m@[48;2;132;121;86m▀@[0m@[38;2;15;44;91m@[48;2;114;104;74m▀@[0m@[38;2;115;117;119m@[48;2;20;53;94m▀@[0m@[38;2;18;47;84m@[48;2;16;43;76m▀@[0m@[38;2;14;37;66m@[48;2;7;22;45m▀@[0m@[38;2;10;27;48m@[48;2;5;15;31m▀@[0m@[38;2;8;21;37m@[48;2;5;14;28m▀@[0m@[1C',
'@[1C@[38;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;255;255;255m@[48;2;255;255;255m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;29;82;168m▀@[0m@[38;2;28;78;160m@[48;2;27;75;155m▀@[0m@[38;2;25;71;147m@[48;2;24;69;141m▀@[0m@[38;2;23;65;133m@[48;2;22;62;128m▀@[0m@[38;2;21;58;120m@[48;2;20;56;114m▀@[0m@[38;2;56;107;61m@[48;2;29;74;133m▀@[0m@[38;2;49;93;53m@[48;2;46;87;50m▀@[0m@[38;2;42;80;46m@[48;2;99;91;65m▀@[0m@[38;2;89;81;58m@[48;2;17;45;80m▀@[0m@[38;2;15;39;69m@[48;2;13;35;62m▀@[0m@[38;2;6;19;39m@[48;2;5;16;34m▀@[0m@[38;2;5;14;28m@[48;2;5;14;28m▀@[0m@[38;2;5;14;28m▀@[0m@[1C',
'@[1C@[1C@[38;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;49;127;226m▀@[0m@[38;2;30;84;172m@[48;2;90;172;99m▀@[0m@[38;2;30;84;172m@[48;2;89;171;98m▀@[0m@[38;2;242;247;251m@[48;2;82;157;90m▀@[0m@[38;2;26;73;149m@[48;2;75;144;82m▀@[0m@[38;2;23;66;136m@[48;2;68;130;75m▀@[0m@[38;2;21;59;122m@[48;2;156;143;102m▀@[0m@[38;2;19;53;109m@[48;2;18;50;103m▀@[0m@[38;2;16;46;95m@[48;2;15;44;90m▀@[0m@[38;2;122;124;126m@[48;2;13;37;76m▀@[0m@[38;2;19;50;90m@[48;2;94;95;97m▀@[0m@[38;2;15;40;72m@[48;2;8;24;49m▀@[0m@[38;2;12;30;55m@[48;2;10;26;47m▀@[0m@[38;2;42;43;44m@[48;2;38;35;25m▀@[0m@[38;2;42;43;44m▀@[0m@[1C@[1C',
'@[1C@[1C@[1C@[1C@[38;2;30;84;172m▀@[0m@[38;2;30;84;172m@[48;2;255;255;255m▀@[0m@[38;2;231;211;151m@[48;2;255;255;255m▀@[0m@[38;2;90;172;99m@[48;2;255;255;255m▀@[0m@[38;2;129;205;118m@[48;2;255;255;255m▀@[0m@[38;2;124;196;113m@[48;2;238;242;246m▀@[0m@[38;2;114;180;104m@[48;2;218;221;225m▀@[0m@[38;2;104;164;95m@[48;2;198;201;204m▀@[0m@[38;2;65;125;72m@[48;2;178;181;184m▀@[0m@[38;2;58;111;64m@[48;2;158;160;163m▀@[0m@[38;2;28;72;129m@[48;2;137;140;142m▀@[0m@[38;2;14;41;84m@[48;2;117;119;121m▀@[0m@[38;2;12;34;71m@[48;2;97;99;101m▀@[0m@[38;2;86;87;88m@[48;2;77;79;80m▀@[0m@[38;2;7;21;44m@[48;2;57;58;59m▀@[0m@[38;2;8;22;40m▀@[0m@[1C@[1C@[1C@[1C',
'@[1C@[1C@[1C@[1C@[1C@[1C@[1C@[38;2;255;255;255m▀@[0m@[38;2;250;254;255m▀@[0m@[38;2;229;233;237m▀@[0m@[38;2;209;213;216m@[48;2;201;205;208m▀@[0m@[38;2;189;193;196m@[48;2;181;184;187m▀@[0m@[38;2;169;172;175m@[48;2;161;164;166m▀@[0m@[38;2;149;152;154m@[48;2;141;143;146m▀@[0m@[38;2;129;131;134m▀@[0m@[38;2;109;111;113m▀@[0m@[38;2;89;91;92m▀@[0m@[1C@[1C@[1C@[1C@[1C@[1C@[1C'
)
function Planeta($linha, $col) { for ($i = 0; $i -lt $PLANETA.Count; $i++) { Out ("$E[$($linha + $i);$($col)H" + $PLANETA[$i].Replace('@', [string]$E)) } }

# ── moldura de cada tela (cabeçalho + rodapé fixo embaixo) ───────────────────
$script:TOTAL = 3; $script:CHAVE_DO_COMANDO = $false
function Tela($dir) {
  $pad = $LARG - 2 - 19 - $dir.Length; if ($pad -lt 1) { $pad = 1 }
  Out "$E[2J$E[H"; Estrelas
  if ($COLS -ge ($LARG + 32)) { Planeta 3 ($LARG + 6) }
  Out "$E[H"; Linha ""
  Linha ("  $B$($W)KODEO$R  $($G)Configurador$R" + (' ' * $pad) + "$G$dir$R")
  Linha "  $G$(Regua)$R"; Linha ""
}
function Dicas([string[]]$pares) { ($pares | ForEach-Object { $i = $_.IndexOf(':'); "$B$W" + $_.Substring(0, $i) + "$R $G" + $_.Substring($i + 1) + $R }) -join '   ' }
function Rodape([string[]]$pares) {
  $texto = Dicas $pares
  if ($LINHAS -ge 18) { Out "$($E)7"; Out "$E[$($LINHAS - 2);1H"; Out "  $G$(Regua)$R`n  $texto"; Out "$($E)8" }
  else { Linha ""; Linha "  $G$(Regua)$R"; Linha "  $texto" }
}
function CaixaTopo($t) { Linha ("  $G╭─ $t " + ('─' * ($LARG - 9 - $t.Length)) + "╮$R") }
function CaixaLinha($txt, $vis) { $pad = $LARG - 8 - $vis; if ($pad -lt 0) { $pad = 0 }; Linha ("  $G│$R  " + $txt + (' ' * $pad) + "$G│$R") }
function CaixaFundo { Linha ("  $G╰" + ('─' * ($LARG - 6)) + "╯$R") }
$SPIN = '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
function Girando($txt, $ticks) {
  for ($i = 0; $i -lt $ticks; $i++) { LimpaLinha; Out "    $W$($SPIN[$i % 10])$R $txt"; Pausa 50 }
  LimpaLinha; Linha "    $OK✓$R $txt"
}

# ── abertura ─────────────────────────────────────────────────────────────────
$LOGO = @(
'██╗  ██╗ ██████╗ ██████╗ ███████╗ ██████╗ ',
'██║ ██╔╝██╔═══██╗██╔══██╗██╔════╝██╔═══██╗',
'█████╔╝ ██║   ██║██║  ██║█████╗  ██║   ██║',
'██╔═██╗ ██║   ██║██║  ██║██╔══╝  ██║   ██║',
'██║  ██╗╚██████╔╝██████╔╝███████╗╚██████╔╝',
'╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ '
)
function Abertura {
  Out "$E[2J$E[H"; CursorOff; Estrelas
  $tons = 255, 236, 214, 190, 165, 140; $col = 2
  if ($COLS -ge 72) { Planeta 2 2; $col = 30 }
  for ($i = 0; $i -lt $LOGO.Count; $i++) { Out ("$E[$(4 + $i);$($col)H" + (Tom $tons[$i]) + $LOGO[$i] + $R); Pausa 55 }
  Out "$E[11;$($col)H$G"; Digita "Configurador de terminal  ·  api.kodeo.com.br  ·  v$VERSAO"; Out $R
  Pausa 1100
}

# ── passo: chave (pulado quando KODEO_KEY vem no comando) ───────────────────
$script:CHAVE = if ($env:KODEO_KEY) { $env:KODEO_KEY.Trim() } else { '' }
function ChaveOk($c) { $c -match '^ck_.{6,}' }
function TelaChave {
  Tela '1/3  Chave'
  Linha "  Cole a chave do painel (começa com $($W)ck_$R). Ela fica só neste computador."
  Linha "  $($G)Dica: no painel tem o comando pronto com a chave dentro, que pula esta tela.$R"; Linha ""
  Rodape 'enter:continuar', 'backspace:apagar', 'ctrl+c:sair'
  $chave = $script:CHAVE
  CursorOn
  while ($true) {
    LimpaLinha; Out ("  $W❯$R " + ('•' * $chave.Length))
    $k = Tecla
    if ($k -eq 'enter') {
      if (-not (ChaveOk $chave)) { Out "`n  $ERR✗$R A chave da Kodeo começa com ck_. Confira e tente de novo."; Out "$E[1A" }
      else {
        $st = ValidarChave $chave
        if ($st -eq 200) { break }
        elseif ($st -in 401, 403) { Out "`n  $ERR✗$R A API recusou essa chave. Confira no painel (kodeo.com.br/app) e cole de novo."; Out "$E[1A" }
        else { Out "`n  $($G)!$R Não consegui falar com api.kodeo.com.br ($st). Verifique a internet e tente de novo."; Out "$E[1A" }
      }
    }
    elseif ($k -eq 'bs') { if ($chave.Length -gt 0) { $chave = $chave.Substring(0, $chave.Length - 1) } }
    elseif ($k -in 'space', 'up', 'down', 'left', 'right', 'esc', '') { }
    else { $chave += $k }
  }
  CursorOff
  $script:CHAVE = $chave
  Linha ""; LimpaLinha; Linha "  $OK✓$R Chave válida"
  Pausa 500
}
function ValidarChave($c) {
  try { $r = Invoke-WebRequest -Uri "$BASE/v1/me" -Headers @{ 'x-api-key' = $c; 'User-Agent' = "kodeo-configurador/$VERSAO" } -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop; return [int]$r.StatusCode }
  catch { try { return [int]$_.Exception.Response.StatusCode } catch { return 0 } }
}
function TelaChaveDoComando {
  Tela '1/3  Chave'
  Linha '  Chave recebida pelo comando.'; Linha ""
  for ($i = 0; $i -lt 8; $i++) { LimpaLinha; Out "  $W$($SPIN[$i % 10])$R Verificando a chave em api.kodeo.com.br"; Pausa 50 }
  $st = ValidarChave $script:CHAVE
  LimpaLinha
  if ($st -eq 200) { Linha "  $OK✓$R Chave válida"; Pausa 600; return }
  if ($st -in 401, 403) { Linha "  $ERR✗$R A API recusou a chave do comando. Pegue o comando de novo no painel." } else { Linha "  $($G)!$R Não consegui falar com api.kodeo.com.br ($st). Verifique a internet e rode o comando de novo." }
  Rodape 'enter:sair'; while ($true) { if ((Tecla) -eq 'enter') { break } }; Sair
}

# ── ferramentas: Claude Code, Claude App, OpenCode (detecção REAL, só leitura) ─
$NOMES = 'Claude Code', 'Claude App', 'OpenCode', 'Codex'
$IDS   = 'claude-code', 'claude-app', 'opencode', 'codex'
$script:CONF = @($false, $false, $false, $false)
$script:SEL  = @($false, $false, $false, $false)
$script:INST = @($false, $false, $false, $false)
function TemTexto($arq, $padrao) { try { (Test-Path $arq) -and ((Get-Content -Raw $arq -ErrorAction Stop) -match $padrao) } catch { $false } }
function Detectar {
  $home_ = $env:USERPROFILE; if (-not $home_) { $home_ = $HOME }
  # Claude Code: env no settings.json OU variável de usuário apontando pra Kodeo
  $envUser = ''; try { $envUser = [string][Environment]::GetEnvironmentVariable('ANTHROPIC_BASE_URL', 'User') } catch {}
  $script:CONF[0] = (TemTexto (Join-Path $home_ '.claude\settings.json') 'api\.kodeo\.com\.br') -or ($envUser -match 'kodeo')
  $script:INST[0] = [bool](Get-Command claude -ErrorAction SilentlyContinue)
  # Claude App: pasta Claude-3p com config apontando pra Kodeo
  $base3p = if ($env:APPDATA) { Join-Path $env:APPDATA 'Claude-3p' } else { Join-Path $home_ 'Library/Application Support/Claude-3p' }
  $lib = Join-Path $base3p 'configLibrary'
  $achouLib = $false; try { if (Test-Path $lib) { $achouLib = [bool](Get-ChildItem $lib -Recurse -File -ErrorAction SilentlyContinue | Where-Object { (Get-Content -Raw $_.FullName -ErrorAction SilentlyContinue) -match 'api\.kodeo\.com\.br' } | Select-Object -First 1) } } catch {}
  $script:CONF[1] = (TemTexto (Join-Path $base3p 'claude_desktop_config.json') '(?i)kodeo') -or $achouLib
  $script:INST[1] = (($env:LOCALAPPDATA) -and (Test-Path (Join-Path $env:LOCALAPPDATA 'AnthropicClaude'))) -or (Test-Path '/Applications/Claude.app')
  # OpenCode: provider "kodeo" no opencode.json
  $script:CONF[2] = TemTexto (Join-Path $home_ '.config\opencode\opencode.json') '"kodeo"'
  $script:INST[2] = [bool](Get-Command opencode -ErrorAction SilentlyContinue)
  # Codex: provider kodeo no config.toml (CODEX_HOME ou ~\.codex)
  $script:CONF[3] = TemTexto (CxCfg) 'model_providers\.kodeo'
  $script:INST[3] = [bool](Get-Command codex -ErrorAction SilentlyContinue)
  for ($i = 0; $i -lt 4; $i++) { $script:SEL[$i] = -not $script:CONF[$i] }   # o que falta vem marcado
}
function TelaFerramentas { # $true = aplicar, $false = voltar
  Tela '2/3  Ferramentas'
  Linha '  Marque o que configurar. O que já está configurado pode ser desconfigurado.'; Linha ""
  $n = $NOMES.Count; $cur = 0
  if (-not $script:CHAVE_DO_COMANDO) { Rodape '↑↓:mover', 'espaço:marcar', 'enter:aplicar', '←:voltar', 'ctrl+c:sair' } else { Rodape '↑↓:mover', 'espaço:marcar', 'enter:aplicar', 'ctrl+c:sair' }
  function Desenha {
    for ($i = 0; $i -lt $n; $i++) {
      $pre = '  '; if ($i -eq $cur) { $pre = "$W❯$R " }
      $caixa = if ($script:SEL[$i]) { "$W[x]$R" } else { "$G[ ]$R" }
      if ($script:CONF[$i]) { $estado = "$($OK)configurado$R"; $estadoLen = 11; $acao = 'desconfigurar' } else { $estado = "$($G)não configurado$R"; $estadoLen = 15; $acao = 'configurar' }
      if (-not $script:INST[$i] -and -not $script:CONF[$i]) { $estado = "$($G)não encontrado$R"; $estadoLen = 14 }
      $acaoTxt = if ($script:SEL[$i]) { "$W→ $acao$R" } else { "$G  $acao$R" }
      LimpaLinha; Linha ("  $pre$caixa $W" + $NOMES[$i].PadRight(13) + $estado + (' ' * (21 - $estadoLen)) + $acaoTxt)
    }
  }
  Desenha
  while ($true) {
    $k = Tecla
    switch ($k) {
      { $_ -in 'up', 'k' }   { $cur = ($cur + $n - 1) % $n }
      { $_ -in 'down', 'j' } { $cur = ($cur + 1) % $n }
      'space' { $script:SEL[$cur] = -not $script:SEL[$cur] }
      { $_ -in 'a', 'A' } { for ($i = 0; $i -lt $n; $i++) { $script:SEL[$i] = $true } }
      { $_ -in 'left', 'b', 'B' } { if (-not $script:CHAVE_DO_COMANDO) { return $false } }
      'enter' { if (@($script:SEL | Where-Object { $_ }).Count -gt 0) { return $true } }
    }
    Out "$E[$($n)A"; Desenha
  }
}

# ── JSON: lê (ou {}), mescla, grava sem BOM e de forma atômica ──────────────
function LerJson($arq) {
  if (-not (Test-Path $arq)) { return [pscustomobject]@{} }
  $txt = Get-Content -Raw -Encoding UTF8 $arq
  if (-not $txt -or -not $txt.Trim()) { return [pscustomobject]@{} }
  try { $j = $txt | ConvertFrom-Json } catch { throw "arquivo corrompido: $arq (nada foi alterado)" }
  if ($j -isnot [pscustomobject]) { throw "não é um objeto JSON: $arq" }
  $j
}
function GravarJson($arq, $obj) {
  $dir = Split-Path $arq; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  $txt = ($obj | ConvertTo-Json -Depth 64) + "`n"
  $tmp = "$arq.kodeo-tmp"; [IO.File]::WriteAllText($tmp, $txt, [Text.UTF8Encoding]::new($false)); Move-Item -Force $tmp $arq
}
function Definir($obj, $nome, $valor) { if ($obj.PSObject.Properties[$nome]) { $obj.$nome = $valor } else { $obj | Add-Member -NotePropertyName $nome -NotePropertyValue $valor } }
function Tirar($obj, $nome) { if ($obj.PSObject.Properties[$nome]) { $obj.PSObject.Properties.Remove($nome) } }
function Casa { if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME } }
$script:FALHAS = 0
function Passo($txt, [scriptblock]$acao) {
  for ($i = 0; $i -lt 6; $i++) { LimpaLinha; Out "    $W$($SPIN[$i % 10])$R $txt"; Pausa 40 }
  try { & $acao | Out-Null; LimpaLinha; Linha "    $OK✓$R $txt" }
  catch { LimpaLinha; Linha "    $ERR✗$R $txt $G($([string]$_.Exception.Message).Substring(0, [Math]::Min(120, ([string]$_.Exception.Message).Length)))$R"; $script:FALHAS++ }
  Pausa 150
}
$ENV_KODEO = [ordered]@{ ANTHROPIC_BASE_URL = $BASE; ANTHROPIC_AUTH_TOKEN = ''; ANTHROPIC_MODEL = 'grok-4.7'; ANTHROPIC_SMALL_FAST_MODEL = 'minimax-m2.7'; ANTHROPIC_DEFAULT_OPUS_MODEL = 'claude-opus-5.5'; ANTHROPIC_DEFAULT_SONNET_MODEL = 'grok-4.7'; ANTHROPIC_DEFAULT_HAIKU_MODEL = 'minimax-m2.7'; CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = '1' }
function ModelosKodeo {
  $m = [ordered]@{}
  foreach ($x in @(@('grok-4.7','Grok 4.7',256000), @('claude-opus-5','Claude Opus 5',200000), @('claude-opus-5.5','Claude Opus 5.5',200000), @('gpt-6-sol','GPT-6 Sol',400000), @('gpt-6-astra','GPT-6 Astra',400000), @('minimax-m2.7','MiniMax M2.7',200000), @('glm-5.3-flash','GLM 5.3 Flash',200000), @('deepseek-v4-flash','DeepSeek V4 Flash',200000))) {
    $m[$x[0]] = [pscustomobject]@{ name = "$($x[1]) (Kodeo)"; limit = [pscustomobject]@{ context = $x[2]; output = 32000 } }
  }
  [pscustomobject]$m
}

# Claude Code: env no ~\.claude\settings.json (Claude Code e extensão do VS Code) + variáveis do usuário (Windows)
$CC_CFG = Join-Path (Casa) '.claude\settings.json'
function AplicarClaudeCode {
  Passo 'env no ~\.claude\settings.json (ANTHROPIC_BASE_URL + chave + modelos)' {
    $j = LerJson $CC_CFG
    $env_ = if ($j.PSObject.Properties['env'] -and $j.env -is [pscustomobject]) { $j.env } else { [pscustomobject]@{} }
    foreach ($k in $ENV_KODEO.Keys) { $v = if ($k -eq 'ANTHROPIC_AUTH_TOKEN') { $script:CHAVE } else { $ENV_KODEO[$k] }; Definir $env_ $k $v }
    Definir $j 'env' $env_; GravarJson $CC_CFG $j
  }
  if ($WIN) { Passo 'Variáveis de ambiente do usuário (ANTHROPIC_BASE_URL + chave + KODEO_API_KEY)' { [Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', $BASE, 'User'); [Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', $script:CHAVE, 'User'); [Environment]::SetEnvironmentVariable('KODEO_API_KEY', $script:CHAVE, 'User') } }
  Passo 'Teste de conexão (api.kodeo.com.br/v1/models)' { $r = Invoke-WebRequest -Uri "$BASE/v1/models" -Headers @{ 'x-api-key' = $script:CHAVE } -TimeoutSec 20 -UseBasicParsing -ErrorAction Stop; if ([int]$r.StatusCode -ne 200) { throw "api respondeu $($r.StatusCode)" } }
}
function RemoverClaudeCode {
  if (Test-Path $CC_CFG) { Passo 'Tirar o env da Kodeo do ~\.claude\settings.json' { $j = LerJson $CC_CFG; if ($j.PSObject.Properties['env'] -and $j.env -is [pscustomobject]) { foreach ($k in $ENV_KODEO.Keys) { Tirar $j.env $k }; if (-not @($j.env.PSObject.Properties).Count) { Tirar $j 'env' } }; GravarJson $CC_CFG $j } }
  if ($WIN) { Passo 'Limpar as variáveis de ambiente do usuário' { [Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', $null, 'User'); [Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', $null, 'User'); if (-not ($script:CONF[3] -and -not $script:SEL[3])) { [Environment]::SetEnvironmentVariable('KODEO_API_KEY', $null, 'User') } } }
}

# Claude App: Claude-3p\configLibrary + deploymentMode 3p + reinício (igual ao app de computador)
function Pasta3p { if ($env:APPDATA) { Join-Path $env:APPDATA 'Claude-3p' } else { Join-Path (Casa) 'Library/Application Support/Claude-3p' } }
function AppRemoverConfigSilencioso($lib) {
  $meta = Join-Path $lib '_meta.json'; if (-not (Test-Path $meta)) { return }
  try { $m = Get-Content -Raw $meta | ConvertFrom-Json } catch { return }
  $nosso = $false; foreach ($e in @($m.entries)) { if ($e.name -eq 'Kodeo') { $nosso = $true } }
  if ($nosso) { if ($m.appliedId) { Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $lib "$($m.appliedId).json") }; Remove-Item -Force $meta }
}
function AppReiniciar {
  if ($env:KODEO_SEM_REINICIAR -eq '1' -or -not $WIN) { return }
  $p = Get-Process -Name Claude -ErrorAction SilentlyContinue
  if ($p) {
    $exe = $p[0].Path; $p | Stop-Process -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 2500
    if (-not $exe) { $exe = Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe' }
    if (Test-Path $exe) { Start-Process $exe | Out-Null }
  }
}
function AplicarClaudeApp {
  Passo 'Config Kodeo em Claude-3p\configLibrary' {
    $dir = Pasta3p; $lib = Join-Path $dir 'configLibrary'; New-Item -ItemType Directory -Force $lib | Out-Null
    AppRemoverConfigSilencioso $lib
    $id = [guid]::NewGuid().ToString().ToLower()
    GravarJson (Join-Path $lib "$id.json") ([pscustomobject]@{ inferenceProvider = 'gateway'; inferenceCredentialKind = 'static'; inferenceGatewayBaseUrl = $BASE; inferenceGatewayApiKey = $script:CHAVE })
    GravarJson (Join-Path $lib '_meta.json') ([pscustomobject]@{ appliedId = $id; entries = @([pscustomobject]@{ id = $id; name = 'Kodeo' }) })
  }
  Passo 'deploymentMode = 3p' { $a = Join-Path (Pasta3p) 'claude_desktop_config.json'; $j = LerJson $a; Definir $j 'deploymentMode' '3p'; GravarJson $a $j }
  Passo 'Modo desenvolvedor (allowDevTools)' { $a = Join-Path (Pasta3p) 'developer_settings.json'; $j = LerJson $a; Definir $j 'allowDevTools' $true; GravarJson $a $j }
  Passo 'Reiniciar o Claude (se estiver aberto)' { AppReiniciar }
}
function RemoverClaudeApp {
  Passo 'Remover a config Kodeo do configLibrary' { AppRemoverConfigSilencioso (Join-Path (Pasta3p) 'configLibrary') }
  $a = Join-Path (Pasta3p) 'claude_desktop_config.json'
  if (Test-Path $a) { Passo 'deploymentMode = 1p' { $j = LerJson $a; Definir $j 'deploymentMode' '1p'; GravarJson $a $j } }
  Passo 'Reiniciar o Claude (se estiver aberto)' { AppReiniciar }
}

# OpenCode: provider kodeo no ~\.config\opencode\opencode.json (chave num arquivo só nosso) + modelo padrão grok-4.7
$OC_CFG = Join-Path (Casa) '.config\opencode\opencode.json'; $OC_KEY = Join-Path (Casa) '.config\opencode\kodeo-api-key'; $OC_BK = Join-Path (Casa) '.config\kodeo\opencode-model-anterior'
function AplicarOpenCode {
  Passo 'Chave em ~\.config\opencode\kodeo-api-key' { New-Item -ItemType Directory -Force (Split-Path $OC_KEY) | Out-Null; [IO.File]::WriteAllText($OC_KEY, $script:CHAVE, [Text.UTF8Encoding]::new($false)); if ($WIN) { icacls $OC_KEY /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null } }
  Passo 'Provedor kodeo com os 8 modelos em ~\.config\opencode\opencode.json' {
    $j = LerJson $OC_CFG
    $prov = if ($j.PSObject.Properties['provider'] -and $j.provider -is [pscustomobject]) { $j.provider } else { [pscustomobject]@{} }
    $arqChave = ($OC_KEY -replace '\\', '/')
    Definir $prov 'kodeo' ([pscustomobject]@{ name = 'Kodeo'; npm = '@ai-sdk/anthropic'; options = [pscustomobject]@{ apiKey = "{file:$arqChave}"; baseURL = "$BASE/v1" }; models = (ModelosKodeo) })
    Definir $j 'provider' $prov
    if ($j.PSObject.Properties['model'] -and $j.model -is [string] -and -not $j.model.StartsWith('kodeo/')) { New-Item -ItemType Directory -Force (Split-Path $OC_BK) | Out-Null; [IO.File]::WriteAllText($OC_BK, $j.model, [Text.UTF8Encoding]::new($false)) }
    Definir $j 'model' 'kodeo/grok-4.7'; GravarJson $OC_CFG $j
  }
  Passo 'Modelo padrão: kodeo/grok-4.7' { }
}
function RemoverOpenCode {
  if (Test-Path $OC_CFG) {
    Passo 'Remover o provedor kodeo do opencode.json (e devolver o modelo anterior)' {
      $j = LerJson $OC_CFG
      if ($j.PSObject.Properties['provider'] -and $j.provider -is [pscustomobject]) { Tirar $j.provider 'kodeo' }
      if ($j.PSObject.Properties['model'] -and "$($j.model)".StartsWith('kodeo/')) { if (Test-Path $OC_BK) { $j.model = (Get-Content -Raw $OC_BK).Trim() } else { Tirar $j 'model' } }
      GravarJson $OC_CFG $j
      Remove-Item -Force -ErrorAction SilentlyContinue $OC_KEY, $OC_BK
    }
  } else { Remove-Item -Force -ErrorAction SilentlyContinue $OC_KEY, $OC_BK }
}
# Codex: provider kodeo em config.toml (CODEX_HOME ou ~\.codex), wire_api responses, chave pela variável KODEO_API_KEY
$CX_MODELO = 'claude-opus-5'
function CxDir { if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path (Casa) '.codex' } }
function CxCfg { Join-Path (CxDir) 'config.toml' }
$CX_BK = Join-Path (Casa) '.config\kodeo\codex-config.toml.anterior'
function CxBlocoTopo { "# >>> kodeo >>>`nmodel = `"$CX_MODELO`"`nmodel_provider = `"kodeo`"`n# <<< kodeo <<<`n" }
function CxBlocoProvider { "# >>> kodeo provider >>>`n[model_providers.kodeo]`nname = `"Kodeo`"`nbase_url = `"$BASE/v1`"`nwire_api = `"responses`"`nenv_key = `"KODEO_API_KEY`"`n# <<< kodeo provider <<<`n" }
function CxSemBlocos($txt) {
  $out = @(); $dentro = $false
  foreach ($l in ($txt -split "`r?`n")) {
    if ($l -match '^# >>> kodeo( provider)? >>>$') { $dentro = $true; continue }
    if ($l -match '^# <<< kodeo( provider)? <<<$') { $dentro = $false; continue }
    if (-not $dentro) { $out += $l }
  }
  ($out -join "`n")
}
function CxEscrever {
  $cfg = CxCfg; $dir = CxDir; New-Item -ItemType Directory -Force $dir | Out-Null
  if (-not (Test-Path $cfg)) { [IO.File]::WriteAllText($cfg, (CxBlocoTopo) + "`n" + (CxBlocoProvider), [Text.UTF8Encoding]::new($false)); return }
  if (-not (Test-Path $CX_BK)) { New-Item -ItemType Directory -Force (Split-Path $CX_BK) | Out-Null; Copy-Item $cfg $CX_BK }
  $resto = CxSemBlocos (Get-Content -Raw -Encoding UTF8 $cfg)
  # chaves de topo só valem antes da primeira [tabela]: nosso topo vai primeiro; model/model_provider antigos saem (ficam no backup)
  $linhas = $resto -split "`n"; $cabeca = @(); $cauda = @(); $viuTabela = $false
  foreach ($l in $linhas) { if (-not $viuTabela -and $l -match '^\[') { $viuTabela = $true }; if ($viuTabela) { $cauda += $l } elseif ($l -notmatch '^\s*(model|model_provider)\s*=') { $cabeca += $l } }
  $novo = (CxBlocoTopo) + (($cabeca -join "`n").TrimEnd()) + "`n" + (($cauda -join "`n").TrimEnd()) + "`n`n" + (CxBlocoProvider)
  $tmp = "$cfg.kodeo-tmp"; [IO.File]::WriteAllText($tmp, $novo, [Text.UTF8Encoding]::new($false)); Move-Item -Force $tmp $cfg
}
function CxRemover {
  $cfg = CxCfg; if (-not (Test-Path $cfg)) { return }
  if (Test-Path $CX_BK) { Move-Item -Force $CX_BK $cfg; return }
  $txt = Get-Content -Raw -Encoding UTF8 $cfg; if ($txt -notmatch '# >>> kodeo') { return }
  $resto = CxSemBlocos $txt
  if (-not $resto.Trim()) { Remove-Item -Force $cfg } else { [IO.File]::WriteAllText($cfg, $resto.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false)) }
}
function AplicarCodex {
  Passo "Provedor kodeo em ~\.codex\config.toml (wire_api responses, modelo $CX_MODELO)" { CxEscrever }
  if ($WIN) { Passo 'KODEO_API_KEY nas variáveis do usuário (o Codex lê a chave do ambiente)' { [Environment]::SetEnvironmentVariable('KODEO_API_KEY', $script:CHAVE, 'User') } }
  Passo 'Teste de conexão (api.kodeo.com.br/v1/responses)' { $r = Invoke-WebRequest -Uri "$BASE/v1/responses" -Method Post -Headers @{ 'Authorization' = "Bearer $($script:CHAVE)" } -ContentType 'application/json' -Body (@{ model = $CX_MODELO; input = 'Responda só: ok'; max_output_tokens = 20; store = $false } | ConvertTo-Json) -TimeoutSec 60 -UseBasicParsing -ErrorAction Stop; if ([int]$r.StatusCode -ne 200) { throw "api respondeu $($r.StatusCode)" } }
}
function RemoverCodex {
  Passo 'Devolver o ~\.codex\config.toml como estava (ou remover o provedor kodeo)' { CxRemover }
  if ($WIN -and -not ($script:CONF[0] -and -not $script:SEL[0])) { Passo 'Limpar KODEO_API_KEY das variáveis do usuário' { [Environment]::SetEnvironmentVariable('KODEO_API_KEY', $null, 'User') } }
}
function Mascara { $c = $script:CHAVE; $c.Substring(0, [Math]::Min(9, $c.Length)) + '…' + $c.Substring([Math]::Max(0, $c.Length - 4)) }
function TelaConfigurar {
  Tela '3/3  Configurar'
  Rodape 'aguarde:aplicando'
  $feitas = @(); $removidas = @()
  for ($i = 0; $i -lt $NOMES.Count; $i++) {
    if (-not $script:SEL[$i]) { continue }
    if ($script:CONF[$i]) {
      Linha "  $B$W$($NOMES[$i])$R  $($G)desconfigurar$R"
      switch ($IDS[$i]) { 'claude-code' { RemoverClaudeCode } 'claude-app' { RemoverClaudeApp } 'opencode' { RemoverOpenCode } 'codex' { RemoverCodex } }
      $removidas += $NOMES[$i]
    } else {
      Linha "  $B$W$($NOMES[$i])$R  $($G)configurar$R"
      switch ($IDS[$i]) { 'claude-code' { AplicarClaudeCode } 'claude-app' { AplicarClaudeApp } 'opencode' { AplicarOpenCode } 'codex' { AplicarCodex } }
      $feitas += $NOMES[$i]
    }
    Linha ""
  }
  $m = Mascara; $l = $feitas -join ', '; $l2 = $removidas -join ', '
  CaixaTopo 'Pronto'
  CaixaLinha '' 0
  CaixaLinha "$($G)Chave          $R$m" (15 + $m.Length)
  if ($l)  { CaixaLinha "$($G)Configuradas   $R$l" (15 + $l.Length) }
  if ($l2) { CaixaLinha "$($G)Desconfiguradas $R$l2" (16 + $l2.Length) }
  CaixaLinha '' 0
  if ($script:FALHAS -gt 0) { CaixaLinha "$($ERR)$($script:FALHAS) passo(s) falharam$R — veja acima e rode de novo." (40 + "$($script:FALHAS)".Length) }
  elseif ($l) { CaixaLinha 'Abra um terminal novo e use a ferramenta normalmente.' 53 } else { CaixaLinha 'Tudo removido. Nada da Kodeo ficou no computador.' 50 }
  CaixaFundo
  Rodape 'enter:sair'
  while ($true) { $k = Tecla; if ($k -in 'enter', 'q', 'Q') { break } }
  Out "$E[$LINHAS;1H`n"
}

try {
  Abertura
  Detectar
  if (ChaveOk $script:CHAVE) { $script:CHAVE_DO_COMANDO = $true; TelaChaveDoComando }
  while ($true) {
    if (-not $script:CHAVE_DO_COMANDO) { TelaChave }
    if (TelaFerramentas) { break }
  }
  TelaConfigurar
} catch {
  if ("$_" -ne 'kodeo:sair') { throw }
} finally {
  Restaura
}
}
