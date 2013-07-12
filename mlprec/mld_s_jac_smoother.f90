!!$
!!$ 
!!$                           MLD2P4  version 2.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 3.0)
!!$  
!!$  (C) Copyright 2008,2009,2010,2012,2013
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
!
!
!
!
!
!
module mld_s_jac_smoother

  use mld_s_base_smoother_mod

  type, extends(mld_s_base_smoother_type) :: mld_s_jac_smoother_type
    ! The local solver component is inherited from the
    ! parent type. 
    !    class(mld_s_base_solver_type), allocatable :: sv
    !    
    type(psb_sspmat_type) :: nd
    integer(psb_ipk_)               :: nnz_nd_tot
  contains
    procedure, pass(sm) :: build   => mld_s_jac_smoother_bld
    procedure, pass(sm) :: clone   => mld_s_jac_smoother_clone
    procedure, pass(sm) :: apply_v => mld_s_jac_smoother_apply_vect
    procedure, pass(sm) :: apply_a => mld_s_jac_smoother_apply
    procedure, pass(sm) :: free    => s_jac_smoother_free
    procedure, pass(sm) :: descr   => s_jac_smoother_descr
    procedure, pass(sm) :: sizeof  => s_jac_smoother_sizeof
    procedure, pass(sm) :: get_nzeros => s_jac_smoother_get_nzeros
    procedure, nopass   :: get_fmt    => s_jac_smoother_get_fmt
  end type mld_s_jac_smoother_type


  private :: s_jac_smoother_free,   s_jac_smoother_descr, &
       & s_jac_smoother_sizeof,  s_jac_smoother_get_nzeros, &
       & s_jac_smoother_get_fmt


  interface 
    subroutine mld_s_jac_smoother_apply_vect(alpha,sm,x,beta,y,desc_data,trans,sweeps,work,info)
      import :: psb_desc_type, mld_s_jac_smoother_type, psb_s_vect_type, psb_spk_, &
           & psb_sspmat_type, psb_s_base_sparse_mat, psb_s_base_vect_type, psb_ipk_
       
      type(psb_desc_type), intent(in)                 :: desc_data
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      type(psb_s_vect_type),intent(inout)           :: x
      type(psb_s_vect_type),intent(inout)           :: y
      real(psb_spk_),intent(in)                      :: alpha,beta
      character(len=1),intent(in)                     :: trans
      integer(psb_ipk_), intent(in)                   :: sweeps
      real(psb_spk_),target, intent(inout)           :: work(:)
      integer(psb_ipk_), intent(out)                  :: info
    end subroutine mld_s_jac_smoother_apply_vect
  end interface
  
  interface 
    subroutine mld_s_jac_smoother_apply(alpha,sm,x,beta,y,desc_data,trans,sweeps,work,info)
      import :: psb_desc_type, mld_s_jac_smoother_type, psb_s_vect_type, psb_spk_, &
           & psb_sspmat_type, psb_s_base_sparse_mat, psb_s_base_vect_type, psb_ipk_
      type(psb_desc_type), intent(in)      :: desc_data
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      real(psb_spk_),intent(inout)         :: x(:)
      real(psb_spk_),intent(inout)         :: y(:)
      real(psb_spk_),intent(in)            :: alpha,beta
      character(len=1),intent(in)           :: trans
      integer(psb_ipk_), intent(in)         :: sweeps
      real(psb_spk_),target, intent(inout) :: work(:)
      integer(psb_ipk_), intent(out)        :: info
    end subroutine mld_s_jac_smoother_apply
  end interface
  
  interface 
    subroutine mld_s_jac_smoother_bld(a,desc_a,sm,upd,info,amold,vmold)
      import :: psb_desc_type, mld_s_jac_smoother_type, psb_s_vect_type, psb_spk_, &
           & psb_sspmat_type, psb_s_base_sparse_mat, psb_s_base_vect_type, psb_ipk_
      type(psb_sspmat_type), intent(in), target         :: a
      Type(psb_desc_type), Intent(in)                     :: desc_a 
      class(mld_s_jac_smoother_type), intent(inout)     :: sm
      character, intent(in)                               :: upd
      integer(psb_ipk_), intent(out)                      :: info
      class(psb_s_base_sparse_mat), intent(in), optional :: amold
      class(psb_s_base_vect_type), intent(in), optional  :: vmold
    end subroutine mld_s_jac_smoother_bld
  end interface
  
  interface 
    subroutine mld_s_jac_smoother_clone(sm,smout,info)
      import :: mld_s_jac_smoother_type, psb_spk_, &
           & mld_s_base_smoother_type, psb_ipk_
      class(mld_s_jac_smoother_type), intent(inout)               :: sm
      class(mld_s_base_smoother_type), allocatable, intent(inout) :: smout
      integer(psb_ipk_), intent(out)                :: info
    end subroutine mld_s_jac_smoother_clone
  end interface
  
contains


  subroutine s_jac_smoother_free(sm,info)


    Implicit None

    ! Arguments
    class(mld_s_jac_smoother_type), intent(inout) :: sm
    integer(psb_ipk_), intent(out)                  :: info
    integer(psb_ipk_) :: err_act
    character(len=20)  :: name='s_jac_smoother_free'

    call psb_erractionsave(err_act)
    info = psb_success_

    
    
    if (allocated(sm%sv)) then 
      call sm%sv%free(info)
      if (info == psb_success_) deallocate(sm%sv,stat=info)
      if (info /= psb_success_) then 
        info = psb_err_alloc_dealloc_
        call psb_errpush(info,name)
        goto 9999 
      end if
    end if
    call sm%nd%free()

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine s_jac_smoother_free

  subroutine s_jac_smoother_descr(sm,info,iout,coarse)

    Implicit None

    ! Arguments
    class(mld_s_jac_smoother_type), intent(in) :: sm
    integer(psb_ipk_), intent(out)               :: info
    integer(psb_ipk_), intent(in), optional      :: iout
    logical, intent(in), optional              :: coarse

    ! Local variables
    integer(psb_ipk_)      :: err_act
    character(len=20), parameter :: name='mld_s_jac_smoother_descr'
    integer(psb_ipk_)      :: iout_
    logical      :: coarse_

    call psb_erractionsave(err_act)
    info = psb_success_
    if (present(coarse)) then 
      coarse_ = coarse
    else
      coarse_ = .false.
    end if
    if (present(iout)) then 
      iout_ = iout 
    else
      iout_ = 6
    endif
    
    if (.not.coarse_) then
      write(iout_,*) '  Block Jacobi smoother '
      write(iout_,*) '  Local solver:'
    end if
    if (allocated(sm%sv)) then 
      call sm%sv%descr(info,iout_,coarse=coarse)
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
  end subroutine s_jac_smoother_descr

  function s_jac_smoother_sizeof(sm) result(val)

    implicit none 
    ! Arguments
    class(mld_s_jac_smoother_type), intent(in) :: sm
    integer(psb_long_int_k_) :: val
    integer(psb_ipk_)        :: i

    val = psb_sizeof_int 
    if (allocated(sm%sv)) val = val + sm%sv%sizeof()
    val = val + sm%nd%sizeof()

    return
  end function s_jac_smoother_sizeof

  function s_jac_smoother_get_nzeros(sm) result(val)

    implicit none 
    ! Arguments
    class(mld_s_jac_smoother_type), intent(in) :: sm
    integer(psb_long_int_k_) :: val
    integer(psb_ipk_)        :: i

    val = 0
    if (allocated(sm%sv)) val = val + sm%sv%get_nzeros()
    val = val + sm%nd%get_nzeros()

    return
  end function s_jac_smoother_get_nzeros

  function s_jac_smoother_get_fmt() result(val)
    implicit none 
    character(len=32)  :: val

    val = "Jacobi smoother"
  end function s_jac_smoother_get_fmt

end module mld_s_jac_smoother
