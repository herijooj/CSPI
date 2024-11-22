#!/bin/bash

# Script feito por Lucas Lopes para cortar dados em latitude, longitude, período e grade

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem cor

# Função de ajuda
function ajuda() {
    echo -e "${YELLOW}Uso: $0 -i INPUT -o EXTENSÃO [-t ANO_INI-ANO_FIM] [-g GRADE] [-s CORTE_ESPACIAL] [-c]${NC}"
    echo
    echo -e "${YELLOW}Opções:${NC}"
    echo -e "${YELLOW}  -i INPUT             Arquivo de entrada (obrigatório)${NC}"
    echo -e "${YELLOW}  -o EXTENSÃO          Extensão do arquivo de saída: nc ou ctl (obrigatório)${NC}"
    echo -e "${YELLOW}  -t ANO_INI-ANO_FIM   Período de tempo (opcional)${NC}"
    echo -e "${YELLOW}  -g GRADE             Grade para remapeamento (opcional)${NC}"
    echo -e "${YELLOW}  -s CORTE_ESPACIAL    Corte espacial: as, polos ou omitido (opcional)${NC}"
    echo -e "${YELLOW}  -c                   Indica que o arquivo é de chuva e deve ser processado com 'divdpm' (opcional)${NC}"
    echo
    echo -e "${YELLOW}Exemplos:${NC}"
    echo -e "${YELLOW}  $0 -i dados.ctl -o nc -t 1950-2020 -g r144x72 -s as -c${NC}"
    echo -e "${YELLOW}  $0 -i dados.nc -o ctl -g r144x72${NC}"
    echo -e "${YELLOW}  $0 -i dados.nc -o nc -t 2000-2010${NC}"
    echo -e "${YELLOW}Grades:${NC}"
    echo -e "${YELLOW}  r720x360 : 720x360 (0.5x0.5)${NC}"
    echo -e "${YELLOW}  r360x180 : 360x180 (1x1)${NC}"
    echo -e "${YELLOW}  r144x72  : 144x72  (2.5x2.5)${NC}"
    echo -e "${YELLOW}  r72x36   : 72x36   (5x5)${NC}"
    exit 1
}

# Inicializa as variáveis com valores padrão
INPUT=""
EXTENSAO_SAIDA=""
PERIODO=""
GRADE=""
CORTE_ESPACIAL=""
PROCESSAR_CHUVA=0

# Processa os argumentos usando getopts
while getopts "i:o:t:g:s:hc" opt; do
    case $opt in
        i)
            INPUT="$OPTARG"
            ;;
        o)
            EXTENSAO_SAIDA="$OPTARG"
            ;;
        t)
            PERIODO="$OPTARG"
            ;;
        g)
            GRADE="$OPTARG"
            ;;
        s)
            CORTE_ESPACIAL="$OPTARG"
            ;;
        c)
            PROCESSAR_CHUVA=1
            ;;
        h | *)
            ajuda
            ;;
    esac
done

# Verificações das entradas:

# Verifica se os argumentos obrigatórios foram fornecidos
if [ -z "$INPUT" ] || [ -z "$EXTENSAO_SAIDA" ]; then
    echo -e "${RED}Erro: Os argumentos -i e -o são obrigatórios.${NC}"
    ajuda
fi

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Arquivo $INPUT inválido.${NC}\n"
    exit 1
fi

if [[ "$EXTENSAO_SAIDA" != "nc" && "$EXTENSAO_SAIDA" != "ctl" ]]; then
    echo -e "${RED}Extensão para o arquivo de saída inválida. Extensões permitidas: nc e ctl${NC}\n"
    exit 1
fi

if [ -n "$CORTE_ESPACIAL" ]; then
    if [[ "$CORTE_ESPACIAL" != "as" && "$CORTE_ESPACIAL" != "polos" ]]; then
        echo -e "${RED}Opção de corte espacial inválida. Opções válidas: as, polos ou omitido${NC}\n"
        exit 1
    fi
fi

if [ -n "$PERIODO" ]; then
    if [[ ! "$PERIODO" =~ ^[0-9]{4}-[0-9]{4}$ ]]; then
        echo -e "${RED}Período de tempo inválido. Use o formato ANO_INI-ANO_FIM${NC}\n"
        exit 1
    fi
    ANO_I=$(echo "$PERIODO" | cut -d'-' -f1)
    ANO_F=$(echo "$PERIODO" | cut -d'-' -f2)
fi

################################## PARÂMETROS ##################################

# Diretório do arquivo de entrada
DIR_IN=$(dirname "$(realpath "$INPUT")")

if [ ! -d "$DIR_IN" ]; then
    echo -e "${RED}Diretório $DIR_IN inexistente!${NC}\n"
    exit 1
fi

BASE_NAME=$(basename "$INPUT")
PREFIXO="${BASE_NAME%.*}"
EXTENSAO="${BASE_NAME##*.}"

if [[ "$EXTENSAO" != "nc" && "$EXTENSAO" != "ctl" ]]; then
    echo -e "${RED}Extensão $EXTENSAO inválida. Extensões permitidas: .nc e .ctl${NC}\n"
    exit 1
fi

# Especificar quais transformações serão feitas
AJUSTAR_CALENDARIO=1
SINCRONIZAR_DATA=1
APAGAR_TMP=1 # Se ativado, apaga os arquivos intermediários

################################## PROCESSAMENTO ##################################

# Converte o arquivo ctl para nc se necessário
if [[ "$EXTENSAO" == "ctl" ]]; then
    echo -e "${GREEN}Convertendo arquivo para .nc${NC}"
    echo cdo -f nc import_binary "$INPUT" "tmp_${PREFIXO}.nc"
    cdo -f nc import_binary "$INPUT" "tmp_${PREFIXO}.nc"
    echo -e "${GREEN}OK!${NC}\n"
    OUTPUT="tmp_${PREFIXO}.nc"
else
    OUTPUT="$INPUT"
fi

if [[ $AJUSTAR_CALENDARIO -eq 1 ]]; then
    echo -e "${GREEN}Ajustando o calendário${NC}"
    echo cdo -O -setcalendar,standard -setmissval,-7777.7 "$OUTPUT" "tmp_${PREFIXO}_calendar.nc"
    cdo -O -setcalendar,standard -setmissval,-7777.7 "$OUTPUT" "tmp_${PREFIXO}_calendar.nc"
    echo -e "${GREEN}OK!${NC}\n"
    OUTPUT="tmp_${PREFIXO}_calendar.nc"
fi 

# Processa com divdpm se a flag estiver ativada
if [ "$PROCESSAR_CHUVA" -eq 1 ]; then
    echo -e "${GREEN}Processando o arquivo com a função divdpm${NC}"
    echo cdo -O divdpm "$OUTPUT" "tmp_${PREFIXO}_divdpm.nc"
    cdo -O divdpm "$OUTPUT" "tmp_${PREFIXO}_divdpm.nc"
    echo -e "${GREEN}OK!${NC}\n"
    OUTPUT="tmp_${PREFIXO}_divdpm.nc"
fi

if [[ $SINCRONIZAR_DATA -eq 1 && -n "$PERIODO" ]]; then
    echo -e "${GREEN}Sincronizando Data${NC}"
    echo cdo -O settaxis,"${ANO_I}-01-01,00:00:00,1month" "$OUTPUT" "tmp_${PREFIXO}_sync.nc"
    cdo -O settaxis,"${ANO_I}-01-01,00:00:00,1month" "$OUTPUT" "tmp_${PREFIXO}_sync.nc"
    echo -e "${GREEN}OK!${NC}\n"
    OUTPUT="tmp_${PREFIXO}_sync.nc"
fi 

if [ -n "$GRADE" ]; then
    echo -e "${GREEN}Cortando para a grade $GRADE!${NC}"
    echo cdo remapbil,"$GRADE" "$OUTPUT" "tmp_${PREFIXO}_grade.nc"
    cdo remapbil,"$GRADE" "$OUTPUT" "tmp_${PREFIXO}_grade.nc"
    echo -e "${GREEN}OK!${NC}\n"
    OUTPUT="tmp_${PREFIXO}_grade.nc"
fi

# Corte espacial
if [ -n "$CORTE_ESPACIAL" ]; then
    if [ "$CORTE_ESPACIAL" = "as" ]; then
        echo -e "${GREEN}Cortando latitude e longitude para América do Sul!${NC}"
        echo cdo -O -sellonlatbox,-82.50,-32.50,-56.25,16.25 "$OUTPUT" "tmp_${PREFIXO}_as.nc"
        cdo -O -sellonlatbox,-82.50,-32.50,-56.25,16.25 "$OUTPUT" "tmp_${PREFIXO}_as.nc"
        echo -e "${GREEN}OK!${NC}\n"
        OUTPUT="tmp_${PREFIXO}_as.nc"
    elif [ "$CORTE_ESPACIAL" = "polos" ]; then
        echo -e "${GREEN}Cortando latitude e longitude dos polos!${NC}"
        echo cdo -O -sellonlatbox,0,360,-58.75,58.75 "$OUTPUT" "tmp_${PREFIXO}_polos.nc"
        cdo -O -sellonlatbox,0,360,-58.75,58.75 "$OUTPUT" "tmp_${PREFIXO}_polos.nc"
        echo -e "${GREEN}OK!${NC}\n"
        OUTPUT="tmp_${PREFIXO}_polos.nc"
    fi
fi 

if [ -n "$PERIODO" ]; then
    echo -e "${GREEN}Cortando para o período $ANO_I-$ANO_F${NC}"
    echo cdo -selyear,"${ANO_I}/${ANO_F}" "$OUTPUT" "tmp_${PREFIXO}_${ANO_I}-${ANO_F}.nc"
    cdo -selyear,"${ANO_I}/${ANO_F}" "$OUTPUT" "tmp_${PREFIXO}_${ANO_I}-${ANO_F}.nc"
    echo -e "${GREEN}OK!${NC}\n" 
    OUTPUT="tmp_${PREFIXO}_${ANO_I}-${ANO_F}.nc"
fi

# Monta o nome base do arquivo final com base nas opções fornecidas
FINAL_OUTPUT_BASE="${PREFIXO}"

if [ -n "$PERIODO" ]; then
    FINAL_OUTPUT_BASE="${FINAL_OUTPUT_BASE}_${ANO_I}-${ANO_F}"
fi

if [ -n "$GRADE" ]; then
    FINAL_OUTPUT_BASE="${FINAL_OUTPUT_BASE}_${GRADE}"
fi

if [ -n "$CORTE_ESPACIAL" ]; then
    FINAL_OUTPUT_BASE="${FINAL_OUTPUT_BASE}_${CORTE_ESPACIAL}"
fi

if [ "$PROCESSAR_CHUVA" -eq 1 ]; then
    FINAL_OUTPUT_BASE="${FINAL_OUTPUT_BASE}_chuva"
fi

# Se a extensão de saída for 'nc'
if [[ "$EXTENSAO_SAIDA" == "nc" ]]; then
    FINAL_OUTPUT="${FINAL_OUTPUT_BASE}.nc"
    # Renomeia o OUTPUT para o nome final
    echo mv "$OUTPUT" "$FINAL_OUTPUT"
    mv "$OUTPUT" "$FINAL_OUTPUT"
    OUTPUT="$FINAL_OUTPUT"
fi

# Se a extensão de saída for 'ctl'
if [[ "$EXTENSAO_SAIDA" == "ctl" ]]; then
    FINAL_NC="${FINAL_OUTPUT_BASE}.nc"
    FINAL_OUTPUT="${FINAL_OUTPUT_BASE}.ctl"
    # Renomeia o OUTPUT para o nome final com extensão .nc
    echo mv "$OUTPUT" "$FINAL_NC"
    mv "$OUTPUT" "$FINAL_NC"
    # Converte o arquivo .nc para .ctl
    echo -e "${GREEN}Convertendo formato .nc para .ctl${NC}" 
    /geral/programas/converte_nc_bin/converte_dados_nc_to_bin.sh "${FINAL_NC}" "${FINAL_OUTPUT_BASE}" > converte.log 
    echo -e "${GREEN}OK!${NC}\n"
    OUTPUT="$FINAL_OUTPUT"
fi

# Apagar arquivos intermediários se necessário
if [ "$APAGAR_TMP" -eq 1 ]; then
    echo -e "${GREEN}Apagando arquivos intermediários!${NC}"
    echo rm tmp_"${PREFIXO}"*
    rm tmp_"${PREFIXO}"*
    if [[ "$EXTENSAO_SAIDA" == "ctl" ]]; then 
        rm "${FINAL_NC}"
    fi
    rm converte.log 2>/dev/null
    echo -e "${GREEN}OK!${NC}\n"
fi 

echo -e "${GREEN}Arquivo de saída: $OUTPUT${NC}"
echo -e "${GREEN}Arquivo modificado conforme parâmetros!${NC}"

# --------------------------------------------------
# X está variando   Lon = -82.5 a -32.5   X = 1 a 21
# Y está variando   Lat = -56.25 a 16.25   Y = 1 a 30
# --------------------------------------------------
