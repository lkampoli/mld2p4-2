/*
 * 
 *                            MLD2P4  version 1.1
 *   MultiLevel Domain Decomposition Parallel Preconditioners Package
 *              based on PSBLAS (Parallel Sparse BLAS version 2.3.1)
 *   
 *   (C) Copyright 2008,2009
 * 
 *                       Salvatore Filippone  University of Rome Tor Vergata
 *                       Alfredo Buttari      CNRS-IRIT, Toulouse
 *                       Pasqua D'Ambra       ICAR-CNR, Naples
 *                       Daniela di Serafino  Second University of Naples
 * 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *    1. Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions, and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *    3. The name of the MLD2P4 group or the names of its contributors may
 *       not be used to endorse or promote products derived from this
 *       software without specific written permission.
 * 
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 * 
 *
 * File: mld_umf_interface.c
 *
 * Functions: mld_sumf_fact_, mld_sumf_solve_, mld_umf_free_.
 *
 * This file is an interface to the UMFPACK routines for sparse factorization and
 * solve. It was obtained by adapting umfpack_di_demo under the original UMFPACK
 * copyright terms reproduced below.
 * 
 */

/*		=====================
UMFPACK Version 4.4 (Jan. 28, 2005), Copyright (c) 2005 by Timothy A.
Davis.  All Rights Reserved.

UMFPACK License:

    Your use or distribution of UMFPACK or any modified version of
    UMFPACK implies that you agree to this License.

    THIS MATERIAL IS PROVIDED AS IS, WITH ABSOLUTELY NO WARRANTY
    EXPRESSED OR IMPLIED.  ANY USE IS AT YOUR OWN RISK.

    Permission is hereby granted to use or copy this program, provided
    that the Copyright, this License, and the Availability of the original
    version is retained on all copies.  User documentation of any code that
    uses UMFPACK or any modified version of UMFPACK code must cite the
    Copyright, this License, the Availability note, and "Used by permission."
    Permission to modify the code and to distribute modified code is granted,
    provided the Copyright, this License, and the Availability note are
    retained, and a notice that the code was modified is included.  This
    software was developed with support from the National Science Foundation,
    and is provided to you free of charge.

Availability:

    http://www.cise.ufl.edu/research/sparse/umfpack

*/



#ifdef  LowerUndescore
#define mld_sumf_fact_   mld_sumf_fact_
#define mld_sumf_solve_  mld_sumf_solve_
#define mld_sumf_free_   mld_sumf_free_
#endif
#ifdef  LowerDoubleUndescore
#define mld_sumf_fact_   mld_sumf_fact__
#define mld_sumf_solve_  mld_sumf_solve__
#define mld_sumf_free_   mld_sumf_free__
#endif
#ifdef  LowerCase
#define mld_sumf_fact_   mld_sumf_fact
#define mld_sumf_solve_  mld_sumf_solve
#define mld_sumf_free_   mld_sumf_free
#endif
#ifdef  UpperUndescore
#define mld_sumf_fact_   MLD_SUMF_FACT_
#define mld_sumf_solve_  MLD_SUMF_SOLVE_
#define mld_sumf_free_   MLD_SUMF_FREE_
#endif
#ifdef  UpperFloatUndescore
#define mld_sumf_fact_   MLD_SUMF_FACT__
#define mld_sumf_solve_  MLD_SUMF_SOLVE__
#define mld_sumf_free_   MLD_SUMF_FREE__
#endif
#ifdef  UpperCase
#define mld_sumf_fact_   MLD_SUMF_FACT
#define mld_sumf_solve_  MLD_SUMF_SOLVE
#define mld_sumf_free_   MLD_SUMF_FREE
#endif


#include <stdio.h>
/* Currently no single precision version in UMFPACK */
#ifdef Have_UMF_		 
#undef Have_UMF_
#endif

#ifdef Have_UMF_		 
#include "umfpack.h"
#endif

#ifdef Ptr64Bits
typedef long long fptr; 
#else
typedef int fptr;  /* 32-bit by default */
#endif

void
mld_sumf_fact_(int *n, int *nnz,
                 float *values, int *rowind, int *colptr,
#ifdef Have_UMF_		 
		 fptr *symptr, 
		 fptr *numptr, 
		 
#else 
		 void *symptr,
		 void *numptr,
#endif
		 int *info)

{
 
#ifdef Have_UMF_
  float Info [UMFPACK_INFO], Control [UMFPACK_CONTROL];
  void *Symbolic, *Numeric ;
  int i;
  
  
  umfpack_di_defaults(Control);
  
  for (i = 0; i <= *n;  ++i) --colptr[i];
  for (i = 0; i < *nnz; ++i) --rowind[i];
  *info = umfpack_di_symbolic (*n, *n, colptr, rowind, values, &Symbolic,
				Control, Info);
  
    
  if ( *info == UMFPACK_OK ) {
    *info = 0;
  } else {
    printf("umfpack_di_symbolic() error returns INFO= %d\n", *info);
    *info = -11;
    *numptr = (fptr) NULL; 
    return;
  }
    
  *symptr = (fptr) Symbolic; 
  
  *info = umfpack_di_numeric (colptr, rowind, values, Symbolic, &Numeric,
				Control, Info) ;
  
    
  if ( *info == UMFPACK_OK ) {
    *info = 0;
    *numptr = (fptr) Numeric; 
  } else {
    printf("umfpack_di_numeric() error returns INFO= %d\n", *info);
    *info = -12;
    *numptr = (fptr) NULL; 
  }
    
  for (i = 0; i <= *n;  ++i) ++colptr[i];
  for (i = 0; i < *nnz; ++i) ++rowind[i];
#else
    fprintf(stderr," UMF Not available for single precision.\n");
    *info=-1;
#endif    
}


void
mld_sumf_solve_(int *itrans, int *n,  
                 float *x,  float *b, int *ldb,
#ifdef Have_UMF_		 
		 fptr *numptr, 
		 
#else 
		 void *numptr,
#endif
		 int *info)

{
#ifdef Have_UMF_ 
  float Info [UMFPACK_INFO], Control [UMFPACK_CONTROL];
  void *Symbolic, *Numeric ;
  int i,trans;
  
  
  umfpack_di_defaults(Control);
  Control[UMFPACK_IRSTEP]=0;


  if (*itrans == 0) {
    trans = UMFPACK_A;
  } else if (*itrans ==1) {
    trans = UMFPACK_At;
  } else {
    trans = UMFPACK_A;
  }

  *info = umfpack_di_solve(trans,NULL,NULL,NULL,
			   x,b,(void *) *numptr,Control,Info);
  
#else
    fprintf(stderr," UMF Not available for single precision.\n");
    *info=-1;
#endif
    
}


void
mld_sumf_free_(
#ifdef Have_UMF_		 
		 fptr *symptr, 
		 fptr *numptr, 
		 
#else 
		 void *symptr,
		 void *numptr,
#endif
		 int *info)

{
#ifdef Have_UMF_ 
  void *Symbolic, *Numeric ;
  Symbolic = (void *) *symptr;
  Numeric  = (void *) *numptr;
  
  umfpack_di_free_numeric(&Numeric);
  umfpack_di_free_symbolic(&Symbolic);
  *info=0;
#else
    fprintf(stderr," UMF Not available for single precision.\n");
    *info=-1;
#endif
}


