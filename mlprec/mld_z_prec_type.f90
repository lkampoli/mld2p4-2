!!$
!!$ 
!!$                           MLD2P4  version 2.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 3.0)
!!$  
!!$  (C) Copyright 2008,2009,2010
!!$
!!$                      Salvatore Filippone  University of Rome Tor Vergata
!!$                      Alfredo Buttari      CNRS-IRIT, Toulouse
!!$                      Pasqua D'Ambra       ICAR-CNR, Naples
!!$                      Daniela di Serafino  Second University of Naples
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the MLD2P4 group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$
! File: mld_prec_type.f90
!
! Module: mld_prec_type
!
!  This module defines: 
!  - the mld_prec_type data structure containing the preconditioner and related
!    data structures;
!  - integer constants defining the preconditioner;
!  - character constants describing the preconditioner (used by the routines
!    printing out a preconditioner description);
!  - the interfaces to the routines for the management of the preconditioner
!    data structure (see below).
!
!  It contains routines for
!  - converting character constants defining the preconditioner into integer
!    constants; 
!  - checking if the preconditioner is correctly defined;
!  - printing a	description of the preconditioner;
!  - deallocating the preconditioner data structure.  
!

module mld_z_prec_type

  use mld_base_prec_type
  !
  ! Type: mld_Tprec_type.
  !
  !  It is the data type containing all the information about the multilevel
  !  preconditioner (here and in the following 'T' denotes 'd', 's', 'c' and
  !  'z', according to the real/complex, single/double precision version of
  !  MLD2P4). It consists of an array of 'one-level' intermediate data structures
  !  of type mld_Tonelev_type, each containing the information needed to apply
  !  the smoothing and the coarse-space correction at a generic level.
  !
  !  type mld_Tprec_type
  !    type(mld_Tonelev_type), allocatable :: precv(:) 
  !  end type mld_Tprec_type
  ! 
  !  Note that the levels are numbered in increasing order starting from
  !  the finest one and the number of levels is given by size(precv(:)).
  !
  !
  ! Type: mld_Tonelev_type.
  !
  !  It is the data type containing the necessary items for the	current
  !  level (essentially, the base preconditioner, the current-level	matrix
  !  and the restriction and prolongation operators).
  !
  !  type mld_Tonelev_type
  !    type(mld_Tbaseprec_type)       :: prec
  !    integer, allocatable           :: iprcparm(:)
  !    real(psb_Tpk_), allocatable    :: rprcparm(:)
  !    type(psb_Tspmat_type)          :: ac
  !    type(psb_desc_type)            :: desc_ac
  !    type(psb_Tspmat_type), pointer :: base_a    => null()
  !    type(psb_desc_type), pointer   :: base_desc => null()
  !    type(psb_Tlinmap_type)         :: map
  !  end type mld_Tonelev_type
  !
  !  Note that psb_Tpk denotes the kind of the real data type to be chosen
  !  according to single/double precision version of MLD2P4.
  !
  !   prec         -  type(mld_Tbaseprec_type). 
  !                   The current level preconditioner (aka smoother).
  !   iprcparm     -  integer, dimension(:), allocatable.
  !                   The integer parameters defining the multilevel strategy.
  !   rprcparm     -  real(psb_Ypk_), dimension(:), allocatable.
  !                   The real parameters defining the multilevel strategy.
  !   ac           -  The local part of the current-level matrix, built by
  !                   coarsening the previous-level matrix.
  !   desc_ac      -  type(psb_desc_type).
  !                   The communication descriptor associated to the matrix
  !                   stored in ac.
  !   base_a       -  type(psb_zspmat_type), pointer.
  !                   Pointer (really a pointer!) to the local part of the current 
  !                   matrix (so we have a unified treatment of residuals).
  !                   We need this to avoid passing explicitly the current matrix
  !                   to the routine which applies the preconditioner.
  !   base_desc    -  type(psb_desc_type), pointer.
  !                   Pointer to the communication descriptor associated to the
  !                   matrix pointed by base_a.
  !   map          -  Stores the maps (restriction and prolongation) between the
  !                   vector spaces associated to the index spaces of the previous
  !                   and current levels.
  !
  ! 
  ! Type: mld_Tbaseprec_type.
  ! 
  !  It holds the smoother (base preconditioner) at a single level.
  !
  !  type mld_Tbaseprec_type
  !    type(psb_Tspmat_type), allocatable :: av(:)
  !    IntrType(psb_Tpk_), allocatable    :: d(:)
  !    type(psb_desc_type)                :: desc_data
  !    integer, allocatable               :: iprcparm(:)
  !    real(psb_Tpk_), allocatable        :: rprcparm(:)
  !    integer, allocatable               :: perm(:),  invperm(:)
  !  end type mld_sbaseprec_type
  !
  !  Note that IntrType denotes the real or complex data type, and psb_Tpk denotes
  !  the kind of the real or complex type, according to the real/complex, single/double
  !  precision version of MLD2P4.
  !
  !    av         -  type(psb_Tspmat_type), dimension(:), allocatable(:).
  !                  The sparse matrices needed to apply the preconditioner at
  !                  the current level ilev. 
  !      av(mld_l_pr_)     -  The L factor of the ILU factorization of the local
  !                           diagonal block of the current-level matrix A(ilev).
  !      av(mld_u_pr_)     -  The U factor of the ILU factorization of the local
  !                           diagonal block of A(ilev), except its diagonal entries
  !                           (stored in d).
  !      av(mld_ap_nd_)    -  The entries of the local part of A(ilev) outside
  !                           the diagonal block, for block-Jacobi sweeps.
  !   d            -  real/complex(psb_Tpk_), dimension(:), allocatable.
  !                   The diagonal entries of the U factor in the ILU factorization
  !                   of A(ilev).
  !   desc_data    -  type(psb_desc_type).
  !                   The communication descriptor associated to the base preconditioner,
  !                   i.e. to the sparse matrices needed to apply the base preconditioner
  !                   at the current level.
  !   iprcparm     -  integer, dimension(:), allocatable.
  !                   The integer parameters defining the base preconditioner K(ilev)
  !                   (the iprcparm entries and values are specified below).
  !   rprcparm     -  real(psb_Tpk_), dimension(:), allocatable.
  !                   The real parameters defining the base preconditioner K(ilev)
  !                   (the rprcparm entries and values are specified below).
  !   perm         -  integer, dimension(:), allocatable.
  !                   The row and column permutations applied to the local part of
  !                   A(ilev) (defined only if iprcparm(mld_sub_ren_)>0). 
  !   invperm      -  integer, dimension(:), allocatable.
  !                   The inverse of the permutation stored in perm.
  !
  !   Note that when the LU factorization of the (local part of the) matrix A(ilev) is
  !   computed instead of the ILU one, by using UMFPACK, SuperLU or SuperLU_dist, the
  !   corresponding L and U factors are stored in data structures provided by those
  !   packages and pointed by prec%iprcparm(mld_umf_ptr), prec%iprcparm(mld_slu_ptr)
  !   or prec%iprcparm(mld_slud_ptr).
  !

  type mld_z_base_solver_type
  contains
    procedure, pass(sv) :: build => z_base_solver_bld
    procedure, pass(sv) :: apply => z_base_solver_apply
    procedure, pass(sv) :: free  => z_base_solver_free
    procedure, pass(sv) :: seti  => z_base_solver_seti
    procedure, pass(sv) :: setc  => z_base_solver_setc
    procedure, pass(sv) :: setr  => z_base_solver_setr
    generic, public     :: set   => seti, setc, setr
    procedure, pass(sv) :: default => z_base_solver_default
    procedure, pass(sv) :: descr =>   z_base_solver_descr
    procedure, pass(sv) :: sizeof =>  z_base_solver_sizeof
  end type mld_z_base_solver_type

  type  mld_z_base_smoother_type
    class(mld_z_base_solver_type), allocatable :: sv
  contains
    procedure, pass(sm) :: build => z_base_smoother_bld
    procedure, pass(sm) :: apply => z_base_smoother_apply
    procedure, pass(sm) :: free  => z_base_smoother_free
    procedure, pass(sm) :: seti  => z_base_smoother_seti
    procedure, pass(sm) :: setc  => z_base_smoother_setc
    procedure, pass(sm) :: setr  => z_base_smoother_setr
    generic, public     :: set   => seti, setc, setr
    procedure, pass(sm) :: default => z_base_smoother_default
    procedure, pass(sm) :: descr =>   z_base_smoother_descr
    procedure, pass(sm) :: sizeof =>  z_base_smoother_sizeof
  end type mld_z_base_smoother_type

  type, extends(psb_z_base_prec_type)   :: mld_zbaseprec_type
    integer, allocatable                :: iprcparm(:) 
    real(psb_dpk_), allocatable         :: rprcparm(:) 
  end type mld_zbaseprec_type

  type mld_zonelev_type
    class(mld_z_base_smoother_type), allocatable :: sm
    integer                         :: sweeps, sweeps_pre, sweeps_post
    type(mld_zbaseprec_type)        :: prec
    integer, allocatable            :: iprcparm(:) 
    real(psb_dpk_), allocatable     :: rprcparm(:) 
    type(psb_zspmat_type)          :: ac
    type(psb_desc_type)             :: desc_ac
    type(psb_zspmat_type), pointer :: base_a    => null() 
    type(psb_desc_type), pointer    :: base_desc => null() 
    type(psb_zlinmap_type)          :: map
  contains
    procedure, pass(lv) :: seti  => z_base_onelev_seti
    procedure, pass(lv) :: setr  => z_base_onelev_setr
    procedure, pass(lv) :: setc  => z_base_onelev_setc
    generic, public     :: set   => seti, setr, setc
  end type mld_zonelev_type

  type, extends(psb_zprec_type)         :: mld_zprec_type
    integer                             :: ictxt
    type(mld_zonelev_type), allocatable :: precv(:) 
  contains
    procedure, pass(prec)               :: z_apply2v => mld_z_apply2v
    procedure, pass(prec)               :: z_apply1v => mld_z_apply1v
  end type mld_zprec_type

  private :: z_base_solver_bld,  z_base_solver_apply, &
       &  z_base_solver_free,    z_base_solver_seti, &
       &  z_base_solver_setc,    z_base_solver_setr, &
       &  z_base_solver_descr,   z_base_solver_sizeof, &
       &  z_base_solver_default, &
       &  z_base_smoother_bld,   z_base_smoother_apply, &
       &  z_base_smoother_free,  z_base_smoother_seti, &
       &  z_base_smoother_setc,  z_base_smoother_setr,&
       &  z_base_smoother_descr, z_base_smoother_sizeof, &
       &  z_base_smoother_default


  !
  ! Interfaces to routines for checking the definition of the preconditioner,
  ! for printing its description and for deallocating its data structure
  !

  interface mld_precfree
    module procedure mld_zbase_precfree, mld_z_onelev_precfree, mld_zprec_free
  end interface

  interface mld_nullify_baseprec
    module procedure mld_nullify_zbaseprec
  end interface

  interface mld_nullify_onelevprec
    module procedure  mld_nullify_z_onelevprec
  end interface

  interface mld_precdescr
    module procedure mld_zfile_prec_descr
  end interface

  interface mld_sizeof
    module procedure mld_zprec_sizeof, mld_zbaseprec_sizeof, mld_z_onelev_prec_sizeof
  end interface

  interface mld_precaply
    subroutine mld_zprecaply(prec,x,y,desc_data,info,trans,work)
      use psb_sparse_mod, only : psb_zspmat_type, psb_desc_type, psb_dpk_
      import mld_zprec_type
      type(psb_desc_type),intent(in)    :: desc_data
      type(mld_zprec_type), intent(in)  :: prec
      complex(psb_dpk_),intent(in)    :: x(:)
      complex(psb_dpk_),intent(inout) :: y(:)
      integer, intent(out)              :: info
      character(len=1), optional        :: trans
      complex(psb_dpk_),intent(inout), optional, target :: work(:)
    end subroutine mld_zprecaply
    subroutine mld_zprecaply1(prec,x,desc_data,info,trans)
      use psb_sparse_mod, only : psb_zspmat_type, psb_desc_type, psb_dpk_
      import mld_zprec_type
      type(psb_desc_type),intent(in)    :: desc_data
      type(mld_zprec_type), intent(in)  :: prec
      complex(psb_dpk_),intent(inout) :: x(:)
      integer, intent(out)              :: info
      character(len=1), optional        :: trans
    end subroutine mld_zprecaply1
  end interface

contains
  !
  ! Function returning the size of the mld_prec_type data structure
  !

  function mld_zprec_sizeof(prec) result(val)
    implicit none 
    type(mld_zprec_type), intent(in) :: prec
    integer(psb_long_int_k_) :: val
    integer             :: i
    val = 0
    val = val + psb_sizeof_int
    if (allocated(prec%precv)) then 
      do i=1, size(prec%precv)
        val = val + mld_sizeof(prec%precv(i))
      end do
    end if
  end function mld_zprec_sizeof

  function mld_zbaseprec_sizeof(prec) result(val)
    implicit none 
    type(mld_zbaseprec_type), intent(in) :: prec
    integer(psb_long_int_k_) :: val
    integer             :: i
    
    val = 0
    if (allocated(prec%iprcparm)) then 
      val = val + psb_sizeof_int * size(prec%iprcparm)
      if (prec%iprcparm(mld_prec_status_) == mld_prec_built_) then 
        select case(prec%iprcparm(mld_sub_solve_)) 
        case(mld_ilu_n_,mld_ilu_t_)
          ! do nothing
        case(mld_slu_)
        case(mld_umf_)
        case(mld_sludist_)
        case default
        end select
        
      end if
    end if
    if (allocated(prec%rprcparm)) val = val + psb_sizeof_dp * size(prec%rprcparm)
!!$    if (allocated(prec%d))        val = val + psb_sizeof_sp * size(prec%d)
!!$    if (allocated(prec%perm))     val = val + psb_sizeof_int * size(prec%perm)
!!$    if (allocated(prec%invperm))  val = val + psb_sizeof_int * size(prec%invperm)
!!$                                  val = val + psb_sizeof(prec%desc_data)
!!$    if (allocated(prec%av))  then 
!!$      do i=1,size(prec%av)
!!$        val = val + psb_sizeof(prec%av(i))
!!$      end do
!!$    end if


  end function mld_zbaseprec_sizeof

  function mld_z_onelev_prec_sizeof(prec) result(val)
    implicit none 
    type(mld_zonelev_type), intent(in) :: prec
    integer(psb_long_int_k_) :: val
    integer             :: i
    
    val = mld_sizeof(prec%prec)
    if (allocated(prec%iprcparm)) &
         &  val = val + psb_sizeof_int * size(prec%iprcparm)
!!$    if (allocated(prec%ilaggr)) &
!!$         &  val = val + psb_sizeof_int * size(prec%ilaggr)
!!$    if (allocated(prec%nlaggr)) &
!!$         &  val = val + psb_sizeof_int * size(prec%nlaggr)
    if (allocated(prec%rprcparm)) val = val + psb_sizeof_dp * size(prec%rprcparm)
    val = val + psb_sizeof(prec%desc_ac)
    val = val + psb_sizeof(prec%ac)
    val = val + psb_sizeof(prec%map) 
    if (allocated(prec%sm))  val = val + prec%sm%sizeof()
  end function mld_z_onelev_prec_sizeof

  !
  ! Subroutine: mld_file_prec_descr
  ! Version: real
  !
  !  This routine prints a description of the preconditioner to the standard 
  !  output or to a file. It must be called after the preconditioner has been
  !  built by mld_precbld.
  !
  ! Arguments:
  !  p       -  type(mld_Tprec_type), input.
  !             The preconditioner data structure to be printed out.
  !  info    -  integer, output.
  !             error code.
  !  iout    -  integer, input, optional.
  !             The id of the file where the preconditioner description
  !             will be printed. If iout is not present, then the standard
  !             output is condidered.
  !
  subroutine mld_zfile_prec_descr(p,info,iout)
    implicit none 
    ! Arguments
    type(mld_zprec_type), intent(in) :: p
    integer, intent(out)             :: info
    integer, intent(in), optional    :: iout

    ! Local variables
    integer      :: ilev, nlev
    integer      :: ictxt, me, np
    character(len=20), parameter :: name='mld_file_prec_descr'
    integer :: iout_

    info = psb_success_
    if (present(iout)) then 
      iout_ = iout
    else
      iout_ = 6 
    end if
    if (iout_ < 0) iout_ = 6 

    ictxt = p%ictxt
    
    if (allocated(p%precv)) then
!!$      ictxt = psb_cd_get_context(p%precv(1)%prec%desc_data)
      
      call psb_info(ictxt,me,np)
      
      !
      ! The preconditioner description is printed by processor psb_root_.
      ! This agrees with the fact that all the parameters defining the
      ! preconditioner have the same values on all the procs (this is
      ! ensured by mld_precbld).
      !
      if (me == psb_root_) then
        
        write(iout_,*) 
        write(iout_,'(a)') 'Preconditioner description'
        nlev = size(p%precv)
        if (nlev >= 1) then
          !
          ! Print description of base preconditioner
          !
          if (nlev > 1) then
            write(iout_,*) 'Multilevel Schwarz'
            write(iout_,*) 
            write(iout_,*) 'Base preconditioner (smoother) details'
          endif
          call p%precv(1)%sm%descr(info,iout=iout_)
        end if

        if (nlev > 1) then

          !
          ! Print multilevel details
          !
          write(iout_,*) 
          write(iout_,*) 'Multilevel details'

          do ilev = 2, nlev 
            if (.not.allocated(p%precv(ilev)%iprcparm)) then 
              info = 3111
              write(iout_,*) ' ',name,&
                   & ': error: inconsistent MLPREC part, should call MLD_PRECINIT'
              return
            endif
          end do

          write(iout_,*) ' Number of levels: ',nlev

          !
          ! Currently, all the preconditioner parameters must have
          ! the same value at levels
          ! 2,...,nlev-1, hence only the values at level 2 are printed
          !

          ilev=2
          call mld_ml_alg_descr(iout_,ilev,p%precv(ilev)%iprcparm, info,&
               & dprcparm=p%precv(ilev)%rprcparm)

          !
          ! Coarse matrices are different at levels 2,...,nlev-1, hence related
          ! info is printed separately
          !
          write(iout_,*) 
          do ilev = 2, nlev-1
            call mld_ml_level_descr(iout_,ilev,p%precv(ilev)%iprcparm,&
                 & p%precv(ilev)%map%naggr,info,&
                 & dprcparm=p%precv(ilev)%rprcparm)
            call p%precv(ilev)%sm%descr(info,iout=iout_)
          
          end do

          !
          ! Print coarsest level details
          !

          ilev = nlev
          write(iout_,*) 
          call mld_ml_new_coarse_descr(iout_,ilev,&
               & p%precv(ilev)%iprcparm,&
               & p%precv(ilev)%map%naggr,info,&
               & dprcparm=p%precv(ilev)%rprcparm)
          call p%precv(ilev)%sm%descr(info,iout=iout_)
        end if
        
      endif
      write(iout_,*) 
    else
      write(iout_,*) trim(name), &
           & ': Error: no base preconditioner available, something is wrong!'
      info = -2
      return
    endif

  end subroutine mld_zfile_prec_descr

  !
  ! Subroutines: mld_Tbase_precfree, mld_T_onelev_precfree, mld_Tprec_free
  ! Version: real/complex
  !
  !  These routines deallocate the mld_Tbaseprec_type, mld_Tonelev_type and
  !  mld_Tprec_type data structures.
  !
  ! Arguments:
  !  p       -  type(mld_Tbaseprec_type/mld_Tonelev_type/mld_Tprec_type), input.
  !             The data structure to be deallocated.
  !  info    -  integer, output.
  !             error code.
  !
  subroutine mld_zbase_precfree(p,info)
    implicit none 
    type(mld_zbaseprec_type), intent(inout) :: p
    integer, intent(out)                :: info
    integer :: i

    info = psb_success_

    ! Actually we might just deallocate the top level array, except 
    ! for the inner UMFPACK or SLU stuff

!!$    if (allocated(p%d)) then 
!!$      deallocate(p%d,stat=info)
!!$    end if
!!$
!!$    if (allocated(p%av))  then 
!!$      do i=1,size(p%av) 
!!$        call p%av(i)%free()
!!$        if (info /= psb_success_) then 
!!$          ! Actually, we don't care here about this.
!!$          ! Just let it go.
!!$          ! return
!!$        end if
!!$      enddo
!!$      deallocate(p%av,stat=info)
!!$    end if
!!$
!!$    
    if (allocated(p%rprcparm)) then 
      deallocate(p%rprcparm,stat=info)
    end if

!!$    if (allocated(p%perm)) then 
!!$      deallocate(p%perm,stat=info)
!!$    endif
!!$
!!$    if (allocated(p%invperm)) then 
!!$      deallocate(p%invperm,stat=info)
!!$    endif

    if (allocated(p%iprcparm)) then 
      if (p%iprcparm(mld_prec_status_) == mld_prec_built_) then       
        if (p%iprcparm(mld_sub_solve_) == mld_slu_) then 
          call mld_zslu_free(p%iprcparm(mld_slu_ptr_),info)
        end if
      end if
      deallocate(p%iprcparm,stat=info)
    end if
    call mld_nullify_baseprec(p)
  end subroutine mld_zbase_precfree

  subroutine mld_z_onelev_precfree(p,info)
    use psb_sparse_mod
    implicit none 

    type(mld_zonelev_type), intent(inout) :: p
    integer, intent(out)                :: info
    integer :: i

    info = psb_success_

    ! Actually we might just deallocate the top level array, except 
    ! for the inner UMFPACK or SLU stuff
    call mld_precfree(p%prec,info)
    
    call p%ac%free()
    if (psb_is_ok_desc(p%desc_ac)) &
         & call psb_cdfree(p%desc_ac,info)
    
    if (allocated(p%rprcparm)) then 
      deallocate(p%rprcparm,stat=info)
    end if
    ! This is a pointer to something else, must not free it here. 
    nullify(p%base_a) 
    ! This is a pointer to something else, must not free it here. 
    nullify(p%base_desc) 

    !
    ! free explicitly map???
    ! For now thanks to allocatable semantics
    ! works anyway. 
    !

    call mld_nullify_onelevprec(p)
  end subroutine mld_z_onelev_precfree

  subroutine mld_nullify_zbaseprec(p)
    implicit none 

    type(mld_zbaseprec_type), intent(inout) :: p


  end subroutine mld_nullify_zbaseprec

  subroutine mld_nullify_z_onelevprec(p)
    implicit none 

    type(mld_zonelev_type), intent(inout) :: p

    nullify(p%base_a) 
    nullify(p%base_desc) 

  end subroutine mld_nullify_z_onelevprec

  subroutine mld_zprec_free(p,info)
  
    use psb_sparse_mod
    
    implicit none
    
    ! Arguments
    type(mld_zprec_type), intent(inout) :: p
    integer, intent(out)                :: info
    
    ! Local variables
    integer             :: me,err_act,i
    character(len=20)   :: name
    
    if(psb_get_errstatus().ne.0) return 
    info=psb_success_
    name = 'mld_zprecfree'
    call psb_erractionsave(err_act)
    
    me=-1
    
    if (allocated(p%precv)) then 
      do i=1,size(p%precv) 
        call mld_precfree(p%precv(i),info)
      end do
      deallocate(p%precv)
    end if
    call psb_erractionrestore(err_act)
    return
    
9999 continue
    call psb_erractionrestore(err_act)
    if (err_act.eq.psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine mld_zprec_free


  subroutine z_base_smoother_apply(alpha,sm,x,beta,y,desc_data,trans,sweeps,work,info)
    use psb_sparse_mod
    type(psb_desc_type), intent(in)             :: desc_data
    class(mld_z_base_smoother_type), intent(in) :: sm
    complex(psb_dpk_),intent(in)                :: x(:)
    complex(psb_dpk_),intent(inout)             :: y(:)
    complex(psb_dpk_),intent(in)                :: alpha,beta
    character(len=1),intent(in)                 :: trans
    integer, intent(in)                         :: sweeps
    complex(psb_dpk_),target, intent(inout)     :: work(:)
    integer, intent(out)                        :: info
    
    Integer           :: err_act
    character(len=20) :: name='d_base_smoother_apply'

    call psb_erractionsave(err_act)
    info = psb_success_
    if (allocated(sm%sv)) then 
      call sm%sv%apply(alpha,x,beta,y,desc_data,trans,work,info)
    else
      info = 1121
    endif
    if (info /= psb_success_) then 
      call psb_errpush(info,name)
      goto 9999 
    end if

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine z_base_smoother_apply

  subroutine z_base_smoother_seti(sm,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_smoother_type), intent(inout) :: sm 
    integer, intent(in)                            :: what 
    integer, intent(in)                            :: val
    integer, intent(out)                           :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_smoother_seti'

    call psb_erractionsave(err_act)
    info = psb_success_

    if (allocated(sm%sv)) then 
      call sm%sv%set(what,val,info)
    end if
    if (info /= psb_success_) goto 9999
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_smoother_seti

  subroutine z_base_smoother_setc(sm,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_smoother_type), intent(inout) :: sm 
    integer, intent(in)                            :: what 
    character(len=*), intent(in)                   :: val
    integer, intent(out)                           :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_smoother_setc'

    call psb_erractionsave(err_act)

    info = psb_success_

    if (allocated(sm%sv)) then 
      call sm%sv%set(what,val,info)
    end if
    if (info /= psb_success_) goto 9999

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_smoother_setc
  
  subroutine z_base_smoother_setr(sm,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_smoother_type), intent(inout) :: sm 
    integer, intent(in)                            :: what 
    real(psb_dpk_), intent(in)                     :: val
    integer, intent(out)                           :: info
    Integer :: err_act
    character(len=20)  :: name='d_base_smoother_setr'

    call psb_erractionsave(err_act)


    info = psb_success_

    if (allocated(sm%sv)) then 
      call sm%sv%set(what,val,info)
    end if
    if (info /= psb_success_) goto 9999

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_smoother_setr

  subroutine z_base_smoother_bld(a,desc_a,sm,upd,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    type(psb_zspmat_type), intent(in), target     :: a
    Type(psb_desc_type), Intent(in)                :: desc_a 
    class(mld_z_base_smoother_type), intent(inout) :: sm 
    character, intent(in)                          :: upd
    integer, intent(out)                           :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_smoother_bld'

    call psb_erractionsave(err_act)

    info = psb_success_
    if (allocated(sm%sv)) then 
      call sm%sv%build(a,desc_a,upd,info)
    else
      info = 1121
      call psb_errpush(info,name)
    endif
    if (info /= psb_success_) goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_smoother_bld


  subroutine z_base_smoother_free(sm,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_smoother_type), intent(inout) :: sm
    integer, intent(out)                           :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_smoother_free'

    call psb_erractionsave(err_act)
    info = psb_success_
    
    if (allocated(sm%sv)) then 
      call sm%sv%free(info)
    end if
    if (info == psb_success_) deallocate(sm%sv,stat=info) 
    if (info /= psb_success_) then 
      info = psb_err_alloc_dealloc_
      call psb_errpush(info,name)
      goto 9999
    end if
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_smoother_free

  subroutine z_base_smoother_descr(sm,info,iout)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_smoother_type), intent(in) :: sm
    integer, intent(out)                        :: info
    integer, intent(in), optional               :: iout

    ! Local variables
    integer      :: err_act
    integer      :: ictxt, me, np
    character(len=20), parameter :: name='mld_z_base_smoother_descr'
    integer :: iout_


    call psb_erractionsave(err_act)
    info = psb_success_

    if (present(iout)) then 
      iout_ = iout
    else 
      iout_ = 6
    end if

    write(iout_,*) 'Base smoother with local solver'
    if (allocated(sm%sv)) then 
      call sm%sv%descr(info,iout)
      if (info /= psb_success_) then 
        info = psb_err_from_subroutine_ 
        call psb_errpush(info,name,a_err='Local solver')
        goto 9999
      end if
    end if
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_smoother_descr

  function z_base_smoother_sizeof(sm) result(val)
    implicit none 
    ! Arguments
    class(mld_z_base_smoother_type), intent(in) :: sm
    integer(psb_long_int_k_)                    :: val
    integer             :: i
    
    val = 0
    if (allocated(sm%sv)) then 
      val = sm%sv%sizeof()
    end if

    return
  end function z_base_smoother_sizeof

  subroutine z_base_smoother_default(sm) 
    implicit none 
    ! Arguments
    class(mld_z_base_smoother_type), intent(inout) :: sm
    ! Do nothing for base version

    return
  end subroutine z_base_smoother_default



  subroutine z_base_solver_apply(alpha,sv,x,beta,y,desc_data,trans,work,info)
    use psb_sparse_mod
    type(psb_desc_type), intent(in)           :: desc_data
    class(mld_z_base_solver_type), intent(in) :: sv
    complex(psb_dpk_),intent(in)              :: x(:)
    complex(psb_dpk_),intent(inout)           :: y(:)
    complex(psb_dpk_),intent(in)              :: alpha,beta
    character(len=1),intent(in)               :: trans
    complex(psb_dpk_),target, intent(inout)   :: work(:)
    integer, intent(out)                      :: info
    
    Integer :: err_act
    character(len=20)  :: name='d_base_solver_apply'

    call psb_erractionsave(err_act)
    
    info = 700
    call psb_errpush(info,name)
    goto 9999 
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine z_base_solver_apply

  subroutine z_base_solver_bld(a,desc_a,sv,upd,info,b)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    type(psb_zspmat_type), intent(in), target   :: a
    Type(psb_desc_type), Intent(in)              :: desc_a 
    class(mld_z_base_solver_type), intent(inout) :: sv
    character, intent(in)                        :: upd
    integer, intent(out)                         :: info
    type(psb_zspmat_type), intent(in), target, optional  :: b
    Integer :: err_act
    character(len=20)  :: name='d_base_solver_bld'

    call psb_erractionsave(err_act)

    info = 700
    call psb_errpush(info,name)
    goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_solver_bld


  subroutine z_base_solver_seti(sv,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_solver_type), intent(inout) :: sv 
    integer, intent(in)                          :: what 
    integer, intent(in)                          :: val
    integer, intent(out)                         :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_solver_seti'

    call psb_erractionsave(err_act)

    info = 700
    call psb_errpush(info,name)
    goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_solver_seti

  subroutine z_base_solver_setc(sv,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_solver_type), intent(inout) :: sv
    integer, intent(in)                          :: what 
    character(len=*), intent(in)                 :: val
    integer, intent(out)                         :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_solver_setc'

    call psb_erractionsave(err_act)

    info = 700
    call psb_errpush(info,name)
    goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_solver_setc
  
  subroutine z_base_solver_setr(sv,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_solver_type), intent(inout) :: sv 
    integer, intent(in)                          :: what 
    real(psb_dpk_), intent(in)                   :: val
    integer, intent(out)                         :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_solver_setr'

    call psb_erractionsave(err_act)

    info = 700
    call psb_errpush(info,name)
    goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_solver_setr

  subroutine z_base_solver_free(sv,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_solver_type), intent(inout) :: sv
    integer, intent(out)                         :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_solver_free'

    call psb_erractionsave(err_act)

    info = 700
    call psb_errpush(info,name)
    goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_solver_free

  subroutine z_base_solver_descr(sv,info,iout)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_z_base_solver_type), intent(in) :: sv
    integer, intent(out)                      :: info
    integer, intent(in), optional             :: iout

    ! Local variables
    integer      :: err_act
    integer      :: ictxt, me, np
    character(len=20), parameter :: name='mld_z_base_solver_descr'
    integer      :: iout_


    call psb_erractionsave(err_act)

    info = 700
    call psb_errpush(info,name)
    goto 9999 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_solver_descr

  function z_base_solver_sizeof(sv) result(val)
    implicit none 
    ! Arguments
    class(mld_z_base_solver_type), intent(in) :: sv
    integer(psb_long_int_k_)                  :: val
    integer             :: i
    val = 0

    return
  end function z_base_solver_sizeof

  subroutine z_base_solver_default(sv) 
    implicit none 
    ! Arguments
    class(mld_z_base_solver_type), intent(inout) :: sv
    ! Do nothing for base version

    return
  end subroutine z_base_solver_default


  subroutine mld_z_apply2v(prec,x,y,desc_data,info,trans,work)
    use psb_sparse_mod
    type(psb_desc_type),intent(in)    :: desc_data
    class(mld_zprec_type), intent(in)  :: prec
    complex(psb_dpk_),intent(in)    :: x(:)
    complex(psb_dpk_),intent(inout) :: y(:)
    integer, intent(out)              :: info
    character(len=1), optional        :: trans
    complex(psb_dpk_),intent(inout), optional, target :: work(:)
    Integer :: err_act
    character(len=20)  :: name='z_prec_apply'

    call psb_erractionsave(err_act)

    select type(prec) 
    type is (mld_zprec_type)
      call mld_precaply(prec,x,y,desc_data,info,trans,work)
    class default
      info = 700
      call psb_errpush(info,name)
      goto 9999 
    end select

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return

  end subroutine mld_z_apply2v

  subroutine mld_z_apply1v(prec,x,desc_data,info,trans)
    use psb_sparse_mod
    type(psb_desc_type),intent(in)    :: desc_data
    class(mld_zprec_type), intent(in)  :: prec
    complex(psb_dpk_),intent(inout) :: x(:)
    integer, intent(out)              :: info
    character(len=1), optional        :: trans
    Integer :: err_act
    character(len=20)  :: name='z_prec_apply'

    call psb_erractionsave(err_act)

    select type(prec) 
    type is (mld_zprec_type)
      call mld_precaply(prec,x,desc_data,info,trans)
    class default
      info = 700
      call psb_errpush(info,name)
      goto 9999 
    end select

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return

  end subroutine mld_z_apply1v

  subroutine z_base_onelev_seti(lv,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_zonelev_type), intent(inout) :: lv 
    integer, intent(in)                          :: what 
    integer, intent(in)                          :: val
    integer, intent(out)                         :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_onelev_seti'

    call psb_erractionsave(err_act)
    info = psb_success_

    select case (what) 
    case (mld_smoother_sweeps_)
      lv%sweeps      = val
      lv%sweeps_pre  = val
      lv%sweeps_post = val
    case (mld_smoother_sweeps_pre_)
      lv%sweeps_pre  = val
    case (mld_smoother_sweeps_post_)
      lv%sweeps_post = val
    case default
      if (allocated(lv%sm)) then 
        call lv%sm%set(what,val,info)
      end if
      if (info /= psb_success_) goto 9999
    end select
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_onelev_seti

  subroutine z_base_onelev_setc(lv,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_zonelev_type), intent(inout) :: lv 
    integer, intent(in)                            :: what 
    character(len=*), intent(in)                   :: val
    integer, intent(out)                           :: info
    Integer           :: err_act
    character(len=20) :: name='d_base_onelev_setc'

    call psb_erractionsave(err_act)

    info = psb_success_

    if (allocated(lv%sm)) then 
      call lv%sm%set(what,val,info)
    end if
    if (info /= psb_success_) goto 9999

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_onelev_setc

  subroutine z_base_onelev_setr(lv,what,val,info)

    use psb_sparse_mod

    Implicit None

    ! Arguments
    class(mld_zonelev_type), intent(inout) :: lv 
    integer, intent(in)                            :: what 
    real(psb_dpk_), intent(in)                     :: val
    integer, intent(out)                           :: info
    Integer :: err_act
    character(len=20)  :: name='z_base_onelev_setr'

    call psb_erractionsave(err_act)


    info = psb_success_

    if (allocated(lv%sm)) then 
      call lv%sm%set(what,val,info)
    end if
    if (info /= psb_success_) goto 9999

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine z_base_onelev_setr

  
end module mld_z_prec_type