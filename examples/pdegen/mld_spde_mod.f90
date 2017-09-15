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
module mld_s_pde_mod
contains
  !
  ! functions parametrizing the differential equation 
  !  
  function b1(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) :: b1
    real(psb_spk_), intent(in) :: x,y,z
    b1=szero
  end function b1
  function b2(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) ::  b2
    real(psb_spk_), intent(in) :: x,y,z
    b2=szero
  end function b2
  function b3(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) ::  b3
    real(psb_spk_), intent(in) :: x,y,z      
    b3=szero
  end function b3
  function c(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) ::  c
    real(psb_spk_), intent(in) :: x,y,z      
    c=szero
  end function c
  function a1(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) ::  a1   
    real(psb_spk_), intent(in) :: x,y,z
    a1=sone
  end function a1
  function a2(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) ::  a2
    real(psb_spk_), intent(in) :: x,y,z
    a2=sone
  end function a2
  function a3(x,y,z)
    use psb_base_mod, only : psb_spk_, sone
    real(psb_spk_) ::  a3
    real(psb_spk_), intent(in) :: x,y,z
    a3=sone
  end function a3
  function g(x,y,z)
    use psb_base_mod, only : psb_spk_, sone, szero
    real(psb_spk_) ::  g
    real(psb_spk_), intent(in) :: x,y,z
    g = szero
    if (x == sone) then
      g = sone
    else if (x == szero) then 
      g = exp(y**2-z**2)
    end if
  end function g
end module mld_s_pde_mod
