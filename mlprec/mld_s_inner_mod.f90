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
! File: mld_inner_mod.f90
!
! Module: mld_inner_mod
!
!  This module defines the interfaces to the real/complex, single/double
!  precision versions of the MLD2P4 routines, except those of the user level,
!  whose interfaces are defined in mld_prec_mod.f90.
!
module mld_s_inner_mod
  use mld_s_prec_type
  use mld_s_move_alloc_mod


  interface mld_mlprec_bld
    subroutine mld_smlprec_bld(a,desc_a,prec,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      use mld_s_prec_type, only : mld_sprec_type
      implicit none
      type(psb_sspmat_type), intent(in), target   :: a
      type(psb_desc_type), intent(in), target     :: desc_a
      type(mld_sprec_type), intent(inout), target :: prec
      integer, intent(out)                        :: info
!!$      character, intent(in),optional             :: upd
    end subroutine mld_smlprec_bld
  end interface mld_mlprec_bld


  interface mld_mlprec_aply
    subroutine mld_smlprec_aply(alpha,p,x,beta,y,desc_data,trans,work,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      use mld_s_prec_type, only : mld_sprec_type
      type(psb_desc_type),intent(in)      :: desc_data
      type(mld_sprec_type), intent(in)  :: p
      real(psb_spk_),intent(in)         :: alpha,beta
      real(psb_spk_),intent(inout)      :: x(:)
      real(psb_spk_),intent(inout)      :: y(:)
      character,intent(in)              :: trans
      real(psb_spk_),target             :: work(:)
      integer, intent(out)              :: info
    end subroutine mld_smlprec_aply
  end interface mld_mlprec_aply


  interface mld_coarse_bld
    subroutine mld_scoarse_bld(a,desc_a,p,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      use mld_s_prec_type, only : mld_sonelev_type
      type(psb_sspmat_type), intent(in)              :: a
      type(psb_desc_type), intent(in)                :: desc_a
      type(mld_sonelev_type), intent(inout), target :: p
      integer, intent(out)                           :: info
    end subroutine mld_scoarse_bld
  end interface mld_coarse_bld

  interface mld_aggrmap_bld
    subroutine mld_saggrmap_bld(aggr_type,theta,a,desc_a,ilaggr,nlaggr,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      integer, intent(in)               :: aggr_type
      real(psb_spk_), intent(in)        :: theta
      type(psb_sspmat_type), intent(in) :: a
      type(psb_desc_type), intent(in)   :: desc_a
      integer, allocatable, intent(out) :: ilaggr(:),nlaggr(:)
      integer, intent(out)              :: info
    end subroutine mld_saggrmap_bld
  end interface mld_aggrmap_bld

  interface  mld_dec_map_bld
    subroutine mld_s_dec_map_bld(theta,a,desc_a,nlaggr,ilaggr,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      type(psb_sspmat_type), intent(in) :: a
      type(psb_desc_type), intent(in)    :: desc_a
      real(psb_spk_), intent(in)         :: theta
      integer, allocatable, intent(out)  :: ilaggr(:),nlaggr(:)
      integer, intent(out)               :: info
    end subroutine mld_s_dec_map_bld
  end interface mld_dec_map_bld

  interface mld_aggrmat_asb
    subroutine mld_saggrmat_asb(a,desc_a,ilaggr,nlaggr,p,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      use mld_s_prec_type, only : mld_sonelev_type
      type(psb_sspmat_type), intent(in)              :: a
      type(psb_desc_type), intent(in)                :: desc_a
      integer, intent(inout)                         :: ilaggr(:), nlaggr(:)
      type(mld_sonelev_type), intent(inout), target :: p
      integer, intent(out)                           :: info
    end subroutine mld_saggrmat_asb
  end interface mld_aggrmat_asb

  interface mld_aggrmat_nosmth_asb
    subroutine mld_saggrmat_nosmth_asb(a,desc_a,ilaggr,nlaggr,p,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      use mld_s_prec_type, only : mld_sonelev_type
      type(psb_sspmat_type), intent(in)              :: a
      type(psb_desc_type), intent(in)                :: desc_a
      integer, intent(inout)                         :: ilaggr(:), nlaggr(:)
      type(mld_sonelev_type), intent(inout), target :: p
      integer, intent(out)                           :: info
    end subroutine mld_saggrmat_nosmth_asb
  end interface mld_aggrmat_nosmth_asb

  interface mld_aggrmat_smth_asb
    subroutine mld_saggrmat_smth_asb(a,desc_a,ilaggr,nlaggr,p,info)
      use psb_base_mod, only : psb_sspmat_type, psb_desc_type, psb_spk_
      use mld_s_prec_type, only : mld_sonelev_type
      type(psb_sspmat_type), intent(in)              :: a
      type(psb_desc_type), intent(in)                :: desc_a
      integer, intent(inout)                         :: ilaggr(:), nlaggr(:)
      type(mld_sonelev_type), intent(inout), target :: p
      integer, intent(out)                           :: info
    end subroutine mld_saggrmat_smth_asb
  end interface mld_aggrmat_smth_asb

end module mld_s_inner_mod