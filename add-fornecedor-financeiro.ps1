$arquivo = 'src\app\pages\ReportsPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakforn') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakforn')

$txt = Get-Content $arquivo -Raw

if ($txt -match 'cadastros!fornecedor_id') {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

$c1 = $false; $c2 = $false; $c3 = $false

# 1) Adiciona join de cadastros no select
$de1 = "select('*, cost_centers(codigo,descricao)')"
$para1 = "select('*, cost_centers(codigo,descricao), cadastros!fornecedor_id(nome_razao)')"
if ($txt.Contains($de1)) { $txt = $txt.Replace($de1, $para1); $c1 = $true }

# 2) Adiciona 'Fornecedor' ao cabecalho (logo apos Descricao)
$de2 = "head: [['Vencimento','Descri" + [char]0x00E7 + [char]0x00E3 + "o','Centro de Custo','Valor','Status']],"
$para2 = "head: [['Vencimento','Fornecedor','Descri" + [char]0x00E7 + [char]0x00E3 + "o','Centro de Custo','Valor','Status']],"
if ($txt.Contains($de2)) {
    $txt = $txt.Replace($de2, $para2); $c2 = $true
} else {
    # fallback: tenta casar sem depender dos acentos, via regex
    $rx = "head: \[\['Vencimento','Descri.{1,3}o','Centro de Custo','Valor','Status'\]\],"
    $m = [regex]::Match($txt, $rx)
    if ($m.Success) {
        $novo = $m.Value -replace "'Vencimento',", "'Vencimento','Fornecedor',"
        $txt = $txt.Replace($m.Value, $novo); $c2 = $true
    }
}

# 3) Adiciona o valor do fornecedor no body (apos fmtD(p.due_date),)
$de3 = "body: pagamentos.map((p:any) => [fmtD(p.due_date), p.descricao"
$para3 = "body: pagamentos.map((p:any) => [fmtD(p.due_date), (p.cadastros ? p.cadastros.nome_razao : '-'), p.descricao"
if ($txt.Contains($de3)) { $txt = $txt.Replace($de3, $para3); $c3 = $true }

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('1) Join no select: ' + $c1)
Write-Host ('2) Coluna no cabecalho: ' + $c2)
Write-Host ('3) Valor no corpo: ' + $c3)
Write-Host ''
if ($c1 -and $c2 -and $c3) {
    Write-Host 'OK - coluna Fornecedor adicionada ao relatorio Financeiro Completo.'
} else {
    Write-Host 'ATENCAO: nem tudo foi aplicado. Reverta com:'
    Write-Host ('   Copy-Item ' + $arquivo + '.bakforn ' + $arquivo + ' -Force')
}
