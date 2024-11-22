! Implementado por Eduardo Machado
! 2015

program converte
	implicit none
	real, allocatable :: input(:)
	integer :: nx, ny, nt, i
	character (len = 100) :: arqIn, arqOut, dirIn, dirOut

	character *512 :: buffer
	call getarg (1, arqIn)
	call getarg (2, arqOut)
	call getarg (3, dirIn)
	call getarg (4, dirOut)
	call getarg (5, buffer)
	read (buffer, *) nx
	call getarg (6, buffer)
	read (buffer, *) ny
	call getarg (7, buffer)
	read (buffer, *) nt
	allocate (input(nx*ny*nt))

	open (1, file=trim(dirIn)//'/'//trim(arqIn), form= 'formatted', status= 'old')
	read(1, *) (input(i), i=1, nx*ny*nt)
	close (1)
	open (2, file=trim(dirOut)//'/'//trim(arqOut), form= 'unformatted', status= 'replace', access='direct', recl=(nx*ny*nt*4))
	write (2, rec=1) (input(i), i=1, (nx*ny*nt))
	close (2)
end program converte