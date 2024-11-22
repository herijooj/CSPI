#!/bin/bash

# Programa para padronizar arquivos ctl, 
# garantindo que vão funcionar no programa 'compose'


#arquivo de entrada
IN_FILE=$1
unset IN_PLACE

if [ "$1" = '-i' ]
then
    IN_FILE=$2
    IN_PLACE=1
elif [ "$2" = '-i' ]
then
    IN_PLACE=1
elif [ "$2" ]
then
    exec > "$2"
fi

if [ ! -s "$IN_FILE" ]
then
    echo -e "Uso:\n\t$0 entrada.ctl\t\tPara saída no terminal"
    echo -e "\t$0 entrada.ctl saida.ctl\tPara redirecionar saída para arquivo 'saida.ctl'."
    echo -e "\t$0 entrada.ctl -i\t\tPara modificar o próprio arquivo."
    exit 1
fi >&2

if [ "$IN_PLACE" ]
then
    # cria arquivo temporario em /tmp
    TMP="$(mktemp "${TMPDIR:-/tmp/}$(basename $0).XXXXXXX")"
    # se sair mesmo que o script seja interrompido, apaga o arquivo temporario
    trap 'rm -f "$TMP"' EXIT

    exec > "$TMP"
fi


# imprime as linhas na ordem certa
# garantindo que todos os campos estão presentes
grep "$IN_FILE" -i -e "dset"          || { >&2 echo "ERRO: dset não está presente"; exit 1; }
grep "$IN_FILE" -i -e "title"         || echo
grep "$IN_FILE" -i -e "undef"         || { >&2 echo "ERRO: undef não está presente"; exit 1; }
grep "$IN_FILE" -i -e "xdef.*linear"  || { >&2 echo "ERRO: xdef precisa estar presente e ser do tipo \"linear\""; exit 1; }
grep "$IN_FILE" -i -e "ydef.*linear"  || { >&2 echo "ERRO: ydef precisa estar presente e ser do tipo \"linear\""; exit 1; }
grep "$IN_FILE" -i -e "zdef"          || { >&2 echo "ERRO: zdef não está presente"; exit 1; }

# colocando as strings da linha tdef em um vetor
TDEF=($(grep -i "tdef" "$IN_FILE"))

# testa se a data não está vazia
test "${TDEF[*]}" || { >&2 echo "ERRO: tdef não está presente"; exit 1; }

# imprime os 3 primeiros campos
echo -n "${TDEF[@]:0:3}"

# padroniza a data
# dia
echo -n " 01"
# data com letras em minusculo | corta mes com 3 letras e ano com 4 digitos

DATE_STR=$(echo "${TDEF[3],,}" | grep -oE "[a-z]{3}[0-9]{4}")
echo -n "$DATE_STR"

test "$DATE_STR" || {

    # se o ultimo grep falhou
    # corta mes com 3 letras e ano com 2 digitos
    DATE_STR=$(echo -n "${TDEF[3],,}" | grep -oE "[a-z]{3}[0-9]{2}")
    
    test "$DATE_STR" || { >&2 echo "ERRO: data do campo tdef não pode ser lido"; exit 1; }
    
    # transforma o ano em 4 digitos
    # "2 digits implies a year between 1950 and 2049" (http://cola.gmu.edu/grads/gadoc/descriptorfile.html#TDEF)
    if [ "${DATE_STR:3}" -lt 50 ]
    then
        echo -n ${DATE_STR:0:3}20${DATE_STR:3}
    else
        echo -n ${DATE_STR:0:3}19${DATE_STR:3}
    fi
}

# imprime o 4 (último) campo de tdef
if [ "${TDEF[4],,}" = "1440mn" ]
then
    TDEF[4]="1dy"
fi
echo " ${TDEF[4]}"

# linhas entre "vars" e "endvars" {imprime}
sed -n '/^vars/,/^endvars/{p}' "$IN_FILE"

if [ $IN_PLACE ]
then
    mv "$TMP" "$IN_FILE"
fi

exit 0
