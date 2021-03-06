!   
!   
!                             MLD2P4  version 2.1
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.5)
!    
!    (C) Copyright 2008, 2010, 2012, 2015, 2017 
!  
!        Salvatore Filippone    Cranfield University, UK
!        Pasqua D'Ambra         IAC-CNR, Naples, IT
!        Daniela di Serafino    University of Campania "L. Vanvitelli", Caserta, IT
!   
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!      1. Redistributions of source code must retain the above copyright
!         notice, this list of conditions and the following disclaimer.
!      2. Redistributions in binary form must reproduce the above copyright
!         notice, this list of conditions, and the following disclaimer in the
!         documentation and/or other materials provided with the distribution.
!      3. The name of the MLD2P4 group or the names of its contributors may
!         not be used to endorse or promote products derived from this
!         software without specific written permission.
!   
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!    POSSIBILITY OF SUCH DAMAGE.
!   
!  
! File: mld_sexample_ml.f90
!
! This sample program solves a linear system obtained by discretizing a
! PDE with Dirichlet BCs. The solver is CG, coupled with one of the 
! following multi-level preconditioner, as explained in Section 5.1 of
! the MLD2P4 User's and Reference Guide:
!
! - choice = 1, the default multi-level preconditioner solver, i.e., 
! V-cycle with basic smoothed aggregation, 1 hybrid forward/backward
! GS sweep as pre/post-smoother and UMFPACK as coarsest-level
! solver (Sec. 5.1, Fig. 2)
!
! - choice = 2, a V-cycle preconditioner with 1 block-Jacobi sweep
! (with ILU(0) on the blocks) as pre- and post-smoother, and 8 block-Jacobi
! sweeps (with ILU(0) on the blocks) as coarsest-level solver (Sec. 5.1, Fig. 3)
!
! - choice = 3, a W-cycle preconditioner with 2 hybrid forward/backward
! GS sweeps as pre/post-smoother, a distributed coarsest matrix,
! and MUMPS as coarsest-level solver (Sec. 5.1, Fig. 4)
!
! The PDE is a general second order equation in 3d
!
!   a1 dd(u)  a2 dd(u)    a3 dd(u)    b1 d(u)   b2 d(u)  b3 d(u)  
! -   ------ -  ------ -  ------ +  -----  +  ------  +  ------ + c u = f
!      dxdx     dydy       dzdz        dx       dy         dz   
!
! with Dirichlet boundary conditions
!   u = g 
!
!  on the unit cube  0<=x,y,z<=1.
!
!
! Note that if b1=b2=b3=c=0., the PDE is the  Laplace equation.
!
! In this sample program the index space of the discretized
! computational domain is first numbered sequentially in a standard way, 
! then the corresponding vector is distributed according to a BLOCK
! data distribution.
!
program mld_sexample_ml
  use psb_base_mod
  use mld_prec_mod
  use psb_krylov_mod
  use psb_util_mod
  use data_input
  use mld_s_pde_mod
  implicit none

  ! input parameters

  ! sparse matrices
  type(psb_sspmat_type) :: A

  ! sparse matrices descriptor
  type(psb_desc_type):: desc_A

  ! preconditioner
  type(mld_sprec_type)  :: P

  ! right-hand side, solution and residual vectors
  type(psb_s_vect_type) :: x, b, r

  ! solver and preconditioner parameters
  real(psb_spk_)   :: tol, err
  integer          :: itmax, iter, istop
  integer          :: nlev

  ! parallel environment parameters
  integer            :: ictxt, iam, np

  ! other variables
  integer            :: choice       
  integer            :: i,info,j
  integer(psb_long_int_k_) :: amatsize, precsize, descsize
  integer            :: idim, ierr, ircode
  real(psb_spk_)     :: resmx, resmxp
  real(psb_dpk_)     :: t1, t2, tprec
  character(len=5)   :: afmt='CSR'
  character(len=20)  :: name, kmethod

  ! initialize the parallel environment

  call psb_init(ictxt)
  call psb_info(ictxt,iam,np)

  if (iam < 0) then 
    ! This should not happen, but just in case
    call psb_exit(ictxt)
    stop
  endif

  name='mld_sexample_ml'
  if(psb_get_errstatus() /= 0) goto 9999
  info=psb_success_
  call psb_set_errverbosity(2)
  !
  ! Hello world
  !
  if (iam == psb_root_) then 
    write(*,*) 'Welcome to MLD2P4 version: ',mld_version_string_
    write(*,*) 'This is the ',trim(name),' sample program'
  end if

  ! get parameters

  call get_parms(ictxt,choice,idim,itmax,tol)

  !  allocate and fill in the coefficient matrix, rhs and initial guess

  call psb_barrier(ictxt)
  t1 = psb_wtime()
  call mld_gen_pde3d(ictxt,idim,a,b,x,desc_a,afmt,&
       & a1,a2,a3,b1,b2,b3,c,g,info)  
  call psb_barrier(ictxt)
  t2 = psb_wtime() - t1
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    call psb_errpush(info,name)
    goto 9999
  end if

  if (iam == psb_root_) write(*,'("Overall matrix creation time : ",es12.5)')t2
  if (iam == psb_root_) write(*,'(" ")')

  select case(choice)

 case(1)

    ! initialize the default multi-level preconditioner, i.e. V-cycle
    ! with basic smoothed aggregation, 1 hybrid forward/backward
    ! GS sweep as pre/post-smoother and UMFPACK as coarsest-level
    ! solver

    call P%init('ML',info)
    kmethod = 'CG'

  case(2)

    ! initialize a V-cycle preconditioner with 1 block-Jacobi sweep (with
    ! ILU(0) on the blocks) as pre- and post-smoother, and 8  block-Jacobi
    ! sweeps (with ILU(0) on the blocks) as coarsest-level solver

    call P%init('ML',info)
    call P%set('SMOOTHER_TYPE','BJAC',info)
    call P%set('COARSE_SOLVE','BJAC',info)
    call P%set('COARSE_SWEEPS',8,info)
    kmethod = 'CG'

  case(3)

   ! initialize a W-cycle preconditioner with 2 hybrid forward/backward
   ! GS sweeps as pre/post-smoother, a distributed coarsest
   ! matrix, and MUMPS as coarsest-level solver

    call P%init('ML',info)
    call P%set('ML_CYCLE','WCYCLE',info)
    call P%set('SMOOTHER_SWEEPS',2,info)
    call P%set('COARSE_SOLVE','MUMPS',info)
    call P%set('COARSE_MAT','DIST',info)
    kmethod = 'CG'

  end select

  call psb_barrier(ictxt)
  t1 = psb_wtime()

  ! build the preconditioner
  call P%hierarchy_build(A,desc_A,info)
  call P%smoothers_build(A,desc_A,info)

  tprec = psb_wtime()-t1
  call psb_amx(ictxt, tprec)

  if (info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,a_err='mld_precbld')
    goto 9999
  end if

  ! set the solver parameters and the initial guess

  call psb_geall(x,desc_A,info)
  call x%zero()
  call psb_geasb(x,desc_A,info)

  ! solve Ax=b with preconditioned Krylov method

  call psb_barrier(ictxt)
  t1 = psb_wtime()

  call psb_krylov(kmethod,A,P,b,x,tol,desc_A,info,itmax,iter,err,itrace=1,istop=2)

  t2 = psb_wtime() - t1
  call psb_amx(ictxt,t2)

  call psb_geall(r,desc_A,info)
  call r%zero()
  call psb_geasb(r,desc_A,info)
  call psb_geaxpby(sone,b,szero,r,desc_A,info)
  call psb_spmm(-sone,A,x,sone,r,desc_A,info)
  resmx  = psb_genrm2(r,desc_A,info)
  resmxp = psb_geamax(r,desc_A,info)

  amatsize = a%sizeof()
  descsize = desc_a%sizeof()
  precsize = p%sizeof()
  call psb_sum(ictxt,amatsize)
  call psb_sum(ictxt,descsize)
  call psb_sum(ictxt,precsize)

  call P%descr(info)

  if (iam == psb_root_) then
    write(*,'(" ")')
    write(*,'("Matrix from PDE example")')
    write(*,'("Computed solution on ",i8," processors")')np
    write(*,'("Krylov method             : ",a)') kmethod
    write(*,'("Iterations to convergence : ",i6)')iter
    write(*,'("Error estimate on exit    : ",es12.5)')err
    write(*,'("Time to build prec.       : ",es12.5)')tprec
    write(*,'("Time to solve system      : ",es12.5)')t2
    write(*,'("Time per iteration        : ",es12.5)')t2/(iter)
    write(*,'("Total time                : ",es12.5)')t2+tprec
    write(*,'("Residual 2-norm           : ",es12.5)')resmx
    write(*,'("Residual inf-norm         : ",es12.5)')resmxp
    write(*,'("Total memory occupation for A      : ",i12)')amatsize
    write(*,'("Total memory occupation for DESC_A : ",i12)')descsize
    write(*,'("Total memory occupation for PREC   : ",i12)')precsize
  end if

  call psb_gefree(b, desc_A,info)
  call psb_gefree(x, desc_A,info)
  call psb_spfree(A, desc_A,info)
  call P%free(info)
  call psb_cdfree(desc_A,info)
  call psb_exit(ictxt)
  stop

9999 continue
  call psb_error(ictxt)

contains
  !
  ! get parameters from standard input
  !
  subroutine get_parms(ictxt,choice,idim,itmax,tol)

    use psb_base_mod
    implicit none

    integer             :: choice, idim, ictxt, itmax
    real(psb_spk_)      :: tol
    integer             :: iam, np

    call psb_info(ictxt,iam,np)

    if (iam == psb_root_) then
      ! read input parameters
      call read_data(choice,5)
      call read_data(idim,5)
      call read_data(itmax,5)
      call read_data(tol,5)
    end if

    call psb_bcast(ictxt,choice)
    call psb_bcast(ictxt,idim)
    call psb_bcast(ictxt,itmax)
    call psb_bcast(ictxt,tol)

  end subroutine get_parms

end program mld_sexample_ml
