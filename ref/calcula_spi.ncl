; Implementado por Eduardo Machado
; 2015

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

  dirIn=getenv("DIRIN")
  dirOut=getenv("DIROUT")
  fileIn=getenv("FILEIN")
  prefixo=getenv("PREFIXO")
  nMesesSpi=stringtointeger(getenv("N_MESES_SPI"))

  f      = addfile(dirIn+fileIn, "r")
  prc    = flt2dble(f->cxc)
  pmsg   = prc@_FillValue

  printVarSummary(prc)
  printMinMax(prc,0)

  dimprc = dimsizes(prc)
  mlon   = dimprc(0)
  nlat   = dimprc(1)
  ntim   = dimprc(2)

  spi    = dim_spi_n(prc, nMesesSpi, False, 0)
  asciiwrite(dirOut+prefixo+"_"+nMesesSpi+".txt", spi)
  spi@long_name = "SPI"
  spi@units = "run="+nMesesSpi
  copy_VarCoords(prc, spi)