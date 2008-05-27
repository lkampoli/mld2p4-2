!!$ 
!!$ 
!!$                           MLD2P4  version 1.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 2.2)
!!$  
!!$  (C) Copyright 2008
!!$
!!$                      Salvatore Filippone  University of Rome Tor Vergata       
!!$                      Alfredo Buttari      University of Rome Tor Vergata
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
! File: mld_cmlprec_bld.f90
!
! Subroutine: mld_cmlprec_bld
! Version:    complex
!
!  This routine builds the base preconditioner corresponding to the current
!  level of the multilevel preconditioner. The routine first builds the
!  (coarse) matrix associated to the current level from the (fine) matrix
!  associated to the previous level, then builds the related base preconditioner.
!
! 
! Arguments:
!    a       -  type(psb_cspmat_type).
!               The sparse matrix structure containing the local part of the
!               matrix to be preconditioned.
!    desc_a  -  type(psb_desc_type), input.
!               The communication descriptor of a.
!    p       -  type(mld_cbaseprc_type), input/output.
!               The base preconditioner data structure containing the local
!               part of the base preconditioner to be built.
!    info    -  integer, output.
!               Error code.         
!  
subroutine mld_cmlprec_bld(a,desc_a,p,info)

  use psb_base_mod
  use mld_inner_mod, mld_protect_name => mld_cmlprec_bld

  implicit none 

  ! Arguments
  type(psb_cspmat_type), intent(in), target :: a
  type(psb_desc_type), intent(in), target   :: desc_a
  type(mld_cbaseprc_type), intent(inout),target    :: p
  integer, intent(out)                      :: info

  ! Local variables
  type(psb_desc_type)    :: desc_ac
  type(psb_cspmat_type)  :: ac
  character(len=20)      :: name
  integer                :: ictxt, np, me, err_act

  name='mld_cmlprec_bld'
  if (psb_get_errstatus().ne.0) return 
  call psb_erractionsave(err_act)
  info = 0
  ictxt = psb_cd_get_context(desc_a)
  call psb_info(ictxt,me,np)

  if (.not.allocated(p%iprcparm)) then 
    info = 2222
    call psb_errpush(info,name)
    goto 9999
  endif
  call mld_check_def(p%iprcparm(mld_ml_type_),'Multilevel type',&
       &   mld_mult_ml_,is_legal_ml_type)
  call mld_check_def(p%iprcparm(mld_aggr_alg_),'Aggregation',&
       &   mld_dec_aggr_,is_legal_ml_aggr_alg)
  call mld_check_def(p%iprcparm(mld_aggr_kind_),'Smoother',&
       &   mld_smooth_prol_,is_legal_ml_aggr_kind)
  call mld_check_def(p%iprcparm(mld_coarse_mat_),'Coarse matrix',&
       &   mld_distr_mat_,is_legal_ml_coarse_mat)
  call mld_check_def(p%iprcparm(mld_smooth_pos_),'smooth_pos',&
       &   mld_pre_smooth_,is_legal_ml_smooth_pos)


  select case(p%iprcparm(mld_sub_solve_))
  case(mld_ilu_n_,mld_milu_n_)      
    call mld_check_def(p%iprcparm(mld_sub_fill_in_),'Level',0,is_legal_ml_lev)
  case(mld_ilu_t_)                 
    call mld_check_def(p%rprcparm(mld_fact_thrs_),'Eps',szero,is_legal_s_fact_thrs)
  end select
  call mld_check_def(p%rprcparm(mld_aggr_damp_),'Omega',szero,is_legal_s_omega)
  call mld_check_def(p%iprcparm(mld_smooth_sweeps_),'Jacobi sweeps',&
       & 1,is_legal_jac_sweeps)

  !
  !  Build a mapping between the row indices of the fine-level matrix 
  !  and the row indices of the coarse-level matrix, according to a decoupled 
  !  aggregation algorithm. This also defines a tentative prolongator from
  !  the coarse to the fine level.
  ! 
  call mld_aggrmap_bld(p%iprcparm(mld_aggr_alg_),a,desc_a,p%nlaggr,p%mlia,info)
  if(info /= 0) then
    call psb_errpush(4010,name,a_err='mld_aggrmap_bld')
    goto 9999
  end if

  !
  ! Build the coarse-level matrix from the fine level one, starting from 
  ! the mapping defined by mld_aggrmap_bld and applying the aggregation
  ! algorithm specified by p%iprcparm(mld_aggr_kind_)
  !
  call mld_aggrmat_asb(a,desc_a,ac,desc_ac,p,info)
  if(info /= 0) then
    call psb_errpush(4010,name,a_err='mld_aggrmat_asb')
    goto 9999
  end if

  !
  !  Build the 'base preconditioner' corresponding to the coarse level
  !
  call mld_baseprc_bld(ac,desc_ac,p,info)
  if (info /= 0) then
    call psb_errpush(4010,name,a_err='mld_baseprc_bld')
    goto 9999
  end if
  
  !
  ! We have used a separate ac because
  ! 1. we want to reuse the same routines mld_ilu_bld, etc.,
  ! 2. we do NOT want to pass an argument twice to them (p%av(mld_ac_) and p),
  !    as this would violate the Fortran standard.
  ! Hence a separate AC and a TRANSFER function at the end. 
  !
  call psb_sp_transfer(ac,p%av(mld_ac_),info)
  p%base_a => p%av(mld_ac_)
  if (info==0) call psb_cdtransfer(desc_ac,p%desc_ac,info)

  p%map_desc = psb_inter_desc(psb_map_aggr_,desc_a,&
       & p%desc_ac,p%av(mld_sm_pr_t_),p%av(mld_sm_pr_))
  ! The two matrices from p%av() have been copied, may free them.
  if (info == 0) call psb_sp_free(p%av(mld_sm_pr_t_),info)
  if (info == 0) call psb_sp_free(p%av(mld_sm_pr_),info)
  if (info /= 0) then 
    call psb_errpush(4010,name,a_err='psb_cdtransfer')
    goto 9999
  end if
  p%base_desc => p%desc_ac

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act.eq.psb_act_abort_) then
    call psb_error()
    return
  end if
  Return

end subroutine mld_cmlprec_bld