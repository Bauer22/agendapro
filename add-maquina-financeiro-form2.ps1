$arquivo = 'src\app\pages\FinancePage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakmaq') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakmaq')

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

# ---- 3) Campo Maquina: inserido ANTES da linha do grid que vem apos o Centro de Custo ----
# Ancora simples: a div do grid de 2 colunas dentro do modal de conta a pagar.
# Para garantir que e a do modal certo, casamos a sequencia unica:
# "descricao}`}))]} />" seguido da quebra e do <div className="grid grid-cols-2 gap-x-2">
$campo = "            <Select label=`"Maquina (opcional)`" value={editing.machine_id||''} onChange={(v:string)=>setEdit((e:any)=>({...e,machine_id:v||null}))} options={[{value:'',label:'Nenhuma'},...machines.map(mq=>({value:mq.id,label:(mq.code?mq.code+' - ':'')+mq.name}))]} />"

# Procura o bloco: fim do Select de Centro de Custo + a div do grid logo abaixo.
# Usamos o padrao do onChange do centro_custo_id como ancora de contexto.
$idxCC = $txt.IndexOf("onChange={(v:string)=>setEdit((e:any)=>({...e,centro_custo_id:v}))}")
if ($idxCC -ge 0) {
    # Acha a proxima ocorrencia de '<div className="grid grid-cols-2 gap-x-2">' depois do centro de custo
    $idxGrid = $txt.IndexOf('<div className="grid grid-cols-2 gap-x-2">', $idxCC)
    if ($idxGrid -ge 0) {
        # Recua ate o inicio da linha do grid
        $inicioLinha = $txt.LastIndexOf($nl, $idxGrid) + 1
        $txt = $txt.Substring(0, $inicioLinha) + $campo + $nl + $txt.Substring($inicioLinha)
        $c3 = $true
    }
}

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('1) Estado machines: ' + $c1)
Write-Host ('2) Carregamento das maquinas: ' + $c2)
Write-Host ('3) Campo Maquina no formulario: ' + $c3)
Write-Host ''
if ($c1 -and $c2 -and $c3) {
    Write-Host 'OK - campo Maquina adicionado ao formulario de conta a pagar.'
} else {
    Write-Host 'ATENCAO: nem tudo aplicado. Reverta com:'
    Write-Host ('   Copy-Item ' + $arquivo + '.bakmaq ' + $arquivo + ' -Force')
}
