#!/bin/bash

# Implementado por Eduardo Machado
# 2015

if [[ $# != 2 ]]; then																				# Caso não sejam colocados todos os parâmetros ou
	echo "" 																										# sejam colocados parâmetros demais, o script não
	echo "ERRO! Parametros errados! Utilize:"										# roda e imprime na tela essa mensagem de ERRO
	echo "calcula_spi [ARQ_CTL_ENTRADA] [N_MESES_SPI]"
	echo ""
	echo ""
else
	CTL_IN=$1
	N_MESES_SPI=$2
	PREFIXO=$(basename ${CTL_IN} .ctl)
	NX=$(cat ${CTL_IN} | grep xdef | tr  "\t" " " | tr -s " " | cut -d" " -f2)
	NY=$(cat ${CTL_IN} | grep ydef | tr  "\t" " " | tr -s " " | cut -d" " -f2)
	NT=$(cat ${CTL_IN} | grep tdef | tr  "\t" " " | tr -s " " | cut -d" " -f2)

	cd $(dirname ${CTL_IN})
	pwd > temp
	DIR_IN=$(cat temp)
	rm temp
	cd -

	DIR_OUT=${DIR_IN}/saida_${PREFIXO}
	CTL_IN=$(basename ${CTL_IN})


	if [[ ! -e ${DIR_OUT} ]]; then
		mkdir ${DIR_OUT}
	fi

	cdo -f nc import_binary ${DIR_IN}/${CTL_IN} ${DIR_IN}/${PREFIXO}.nc

	/geral/programas/calcula_SPI/src/aux_param.cshrc "${DIR_IN}/" "${DIR_OUT}/" "${PREFIXO}.nc" "${PREFIXO}" "${N_MESES_SPI}"
	/geral/programas/calcula_SPI/bin/converte_txt_bin ${PREFIXO}_${N_MESES_SPI}.txt ${PREFIXO}_spi${N_MESES_SPI}.bin ${DIR_OUT} ${DIR_OUT} ${NX} ${NY} ${NT}

	ARQ_BIN_IN="$(cat ${DIR_IN}/${CTL_IN} | grep dset | tr -s " " | cut -d"^" -f2)"
	ARQ_BIN_OUT="${PREFIXO}_spi${N_MESES_SPI}.bin"
	CTL_OUT="${PREFIXO}_spi${N_MESES_SPI}.ctl"

	cp ${DIR_IN}/${CTL_IN} $DIR_OUT/$CTL_OUT
	sed  -i "s#$(basename $ARQ_BIN_IN .bin)#$(basename $ARQ_BIN_OUT .bin)#g;" ${DIR_OUT}/${CTL_OUT}
	sed  -i "s#cxc#spi#g;" ${DIR_OUT}/${CTL_OUT}

	rm ${DIR_OUT}/${PREFIXO}_${N_MESES_SPI}.txt
	rm ${DIR_IN}/${PREFIXO}.nc
fi
