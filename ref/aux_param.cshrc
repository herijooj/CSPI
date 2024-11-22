#!/bin/csh

# Implementado por Eduardo Machado
# 2015

setenv DIRIN "$1"
setenv DIROUT "$2"
setenv FILEIN "$3"
setenv PREFIXO "$4"
setenv N_MESES_SPI $5

ncl /geral/programas/calcula_SPI/src/calcula_spi.ncl
