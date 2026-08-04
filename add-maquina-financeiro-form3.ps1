$arquivo = 'src\app\pages\FinancePage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakmaq3') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakmaq3')

$txt = Get-Content $arquivo -Raw

if ($txt -match 'const \[machines') {
    Write-Host 'Ja aplicado antes (machines existe). Nada alterado.'
    exit 0
}

$c1 = $false; $c2 = $false; $c3 = $false
$nl = [Environment]::NewLine

# ---- 1) Estado machines ----
$de1 = "  const [centers, setCenters]   = useState<any[]>([])"
$para1 = $de1 + $nl + "  const [machines, setMachines] = useState<any[]>([])"
if ($txt.Contains($de1)) { $txt = $txt.Replace($de1, $para1); $c1 = $true }

# ---- 2) Carregar maquinas no load (aba bills) ----
$de2 = "        supabase.from('cadastros').select('id,nome_razao,nome_fantasia').eq('is_fornecedor',true).eq('status',true),"
$para2 = $de2 + $nl + "        supabase.from('machines').select('id,code,name').order('name'),"
if ($txt.Contains($de2)) {
    $txt = $txt.Replace($de2, $para2)
    $deSet = "      setBills(b.data||[]); setCenters(c.data||[]); setSuppliers(s.data||[])"
    $paraSet = "      setBills(b.data||[]); setCenters(c.data||[]); setSuppliers(s.data||[]); setMachines(m.data||[])"
    if ($txt.Contains($deSet)) { $txt = $txt.Replace($deSet, $paraSet) }
    $mDes = [regex]::Match($txt, "const \[b, c, s\] = await Promise\.all\(\[")
    if ($mDes.Success) { $txt = $txt.Replace($mDes.Value, "const [b, c, s, m] = await Promise.all([") }
    $c2 = $true
}

# ---- 3) Campo Maquina: inserido logo APOS a linha do options do Centro de Custo do FORMULARIO ----
# Ancora EXATA (linha 323), unica no arquivo:
$ancora3 = "              options={[{value:'',label:'Nenhum'},...centers.map(c=>({value:c.id,label:``${c.codigo} - ${c.descricao}``}))]} />"

# Como a crase e complicada, montamos a ancora via caracteres:
$cr = [char]0x60  # crase `
$ancora3 = "              options={[{value:'',label:'Nenhum'},...centers.map(c=>({value:c.id,label:" + $cr + "`${c.codigo} - `${c.descricao}" + $cr + "}))]} />"

# Campo maquina (sem crase no label - concatenacao simples)
$campo = "            <Select label=`"Maquina (opcional)`" value={editing.machine_id||''} onChange={(v:string)=>setEdit((e:any)=>({...e,machine_id:v||null}))} options={[{value:'',label:'Nenhuma'},...machines.map(mq=>({value:mq.id,label:(mq.code?mq.code+' - ':'')+mq.name}))]} />"

if ($txt.Contains($ancora3)) {
    $txt = $txt.Replace($ancora3, $ancora3 + $nl + $campo)
    $c3 = $true
} else {
    # Fallback: usa regex tolerante ao conteudo entre crases
    $rx = "options=\{\[\{value:'',label:'Nenhum'\},\.\.\.centers\.map\(c=>\(\{value:c\.id,label:" + [char]0x60 + "[^" + [char]0x60 + "]*" + [char]0x60 + "\}\)\)\]\} />"
    $m = [regex]::Match($txt, $rx)
    if ($m.Success) {
        $txt = $txt.Replace($m.Value, $m.Value + $nl + $campo)
        $c3 = $true
    }
}

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('1) Estado machines: ' + $c1)
Write-Host ('2) Carregamento das maquinas: ' + $c2)
Write-Host ('3) Campo Maquina no formulario: ' + $c3)
Write-Host ''
if ($c1 -and $c2 -and $c3) {
    Write-Host 'OK - campo Maquina adicionado.'
} else {
    Write-Host 'ATENCAO: nem tudo aplicado. Reverta com:'
    Write-Host ('   Copy-Item ' + $arquivo + '.bakmaq3 ' + $arquivo + ' -Force')
}
