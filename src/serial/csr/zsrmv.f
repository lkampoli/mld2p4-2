***********************************************************************
*    ZSRMV modified for SPARKER                                       *
*                                                                     *
*    FUNCTION: Driver for routines performing one of the sparse       *
*              matrix vector operations                               *
*                                                                     *
*                   y = alpha*op(A)*x + beta*y                        *
*                                                                     *
*              where op(A) is one of:                                 *
*                                                                     *
*                  op(A) = A or op(A) = A'  or                        *
*                  op(A) = conjug(A') or                              *
*                  op(A) = lower or upper part of A                   *
*                                                                     *
*              alpha and beta are scalars.                            *
*              The data structure of the matrix is related            *
*              to the scalar computer.                                *
*              This is an internal routine called by:                 *
*              ZCSRMM                                                 *
*                                                                     *
*    ENTRY-POINT = ZSRMV                                              *
*                                                                     *
*                                                                     *
*    INPUT =                                                          *
*                                                                     *
*                                                                     *
*      SYMBOLIC NAME: TRANS                                           *
*      POSITION:      PARAMETER NO 1.                                 *
*      ATTRIBUTES:    CHARACTER*1                                     *
*      VALUES:        'N' 'T' 'C' 'L' 'M' 'U' 'V'                     *
*      DESCRIPTION:   Specifies the form of op(A) to be used in the   *
*                     matrix vector multiplications as follows:       *
*                                                                     *
*                     TRANS = 'N'       ,  op( A ) = A.               *
*                                                                     *
*                     TRANS = 'T'       ,  op( A ) = A'.              *
*                                                                     *
*                     TRANS = 'C'       ,  OP( A ) = conjug(A')       *
*                                                                     *
*                     TRANS = 'L' or 'U',  op( A ) = lower or         *
*                             upper part of A                         *
*                                                                     *
*                     TRANS = 'M' or 'V',  op( A ) = lower or         *
*                             upper part of conjugate of A            *
*                                                                     *
*      SYMBOLIC NAME: DIAG                                            *
*      POSITION:      PARAMETER NO 2.                                 *
*      ATTRIBUTES:    CHARACTER*1                                     *
*      VALUES:        'N' 'U'                                         *
*      DESCRIPTION:                                                   *
*                     Specifies whether or not the matrix A has       *
*                     unit diagonal as follows:                       *
*                                                                     *
*                     DIAG = 'N'  A is not assumed                    *
*                            to have unit diagonal                    *
*                                                                     *
*                     DIAG = 'U'  A is assumed                        *
*                            to have unit diagonal.                   *
*                                                                     *
*                     WARNING: it is the caller's responsibility      *
*                     to ensure that if the matrix has unit           *
*                     diagonal, there are no elements of the          *
*                     diagonal are stored in the arrays AS and JA.    *
*                                                                     *
*       SYMBOLIC NAME: M                                              *
*       POSITION:      PARAMETER NO 3.                                *
*       ATTRIBUTES:    INTEGER*4.                                     *
*       VALUES:        M >= 0                                         *
*       DESCRIPTION:   Number of rows of the matrix op(A).            *
*                                                                     *
*       SYMBOLIC NAME: N                                              *
*       POSITION:      PARAMETER NO 4.                                *
*       ATTRIBUTES:    INTEGER*4.                                     *
*       VALUES:        N >= 0                                         *
*       DESCRIPTION:   Number of columns of the matrix op(A)          *
*                                                                     *
*       SYMBOLIC NAME: ALPHA                                          *
*       POSITION:      PARAMETER NO 5.                                *
*       ATTRIBUTES:    COMPLEX*16.                                    *
*       VALUES:        any.                                           *
*       DESCRIPTION:   Specifies the scalar alpha.                    *
*                                                                     *
*                                                                     *
*       SYMBOLIC NAME: AS                                             *
*       POSITION:      PARAMETER NO 6.                                *
*       ATTRIBUTES:    COMPLEX*16: ARRAY(IA(M+1)-1)                   *
*       VALUES:        ANY                                            *
*       DESCRIPTION:   Array containing the non zero coefficients of  *
*                      the sparse matrix op(A).                       *
*                                                                     *
*       SYMBOLIC NAME: JA                                             *
*       POSITION:      PARAMETER NO 7.                                *
*       ATTRIBUTES:    INTEGER*4: ARRAY(IA(M+1)-1)                    *
*       VALUES:        0 < JA(I) <= M                                 *
*       DESCRIPTION:   Array containing the column number of the      *
*                      nonzero coefficients stored in array AS.       *
*                                                                     *
*       SYMBOLIC NAME: IA                                             *
*       POSITION:      PARAMETER NO 8.                                *
*       ATTRIBUTES:    INTEGER*4: ARRAY(*)                            *
*       VALUES:        IA(I) > 0                                      *
*       DESCRIPTION:   Contains the pointers for the beginning of     *
*                      each rows.                                     *
*                                                                     *
*                                                                     *
*       SYMBOLIC NAME: X                                              *
*       POSITION:      PARAMETER NO 9.                                *
*       ATTRIBUTES:    COMPLEX*16 ARRAY(N)                            *
*                      (or ARRAY(M) when op(A) = A')                  *
*       VALUES:        any.                                           *
*       DESCRIPTION:   Contains the values of the vector to be        *
*                      multiplied by the matrix A.                    *
*                                                                     *
*       SYMBOLIC NAME: BETA                                           *
*       POSITION:      PARAMETER NO 10.                               *
*       ATTRIBUTES:    COMPLEX*16.                                    *
*       VALUES:        any.                                           *
*       DESCRIPTION:   Specifies the scalar beta.                     *
*                                                                     *
*       SYMBOLIC NAME: Y                                              *
*       POSITION:      PARAMETER NO 11.                               *
*       ATTRIBUTES:    COMPLEX*16 ARRAY(M)                            *
*                      (or ARRAY(N) when op(A) = A')                  *
*       VALUES:        any.                                           *
*       DESCRIPTION:   Contains the values of the vector to be        *
*                      updated by the matrix-vector multiplication.   *
*                                                                     *
*       SYMBOLIC NAME: WORK                                           *
*       POSITION:      PARAMETER NO 12.                               *
*       ATTRIBUTES:    COMPLEX*16 ARRAY(M)                            *
*                      (or ARRAY(N) when op(A) = A')                  *
*       VALUES:        any.                                           *
*       DESCRIPTION:   Work area available to the program. It is used *
*                      only when TRANS = 'T'.                         *
*                                                                     *
*  OUTPUT =                                                           *
*                                                                     *
*                                                                     *
*       SYMBOLIC NAME: Y                                              *
*       POSITION:      PARAMETER NO 11.                               *
*       ATTRIBUTES:    COMPLEX*16 ARRAY(M)                            *
*                      (or ARRAY(N) when op(A) = A')                  *
*       VALUES:        any.                                           *
*       DESCRIPTION:   Contains the values of the vector              *
*                      updated by the matrix-vector multiplication.   *
*                                                                     *
*                                                                     *
***********************************************************************
C
      SUBROUTINE ZSRMV (TRANS,DIAG,M,N,ALPHA,AS,JA,IA,X,BETA,Y,WORK)
C     .. Parameters ..
      COMPLEX*16 ONE, ZERO
      PARAMETER (ONE=(1.0D0, 0.0D0), ZERO=(0.0D0, 0.0D0))
C     .. Scalar Arguments ..
      COMPLEX*16 ALPHA, BETA
      INTEGER    M, N
      CHARACTER  DIAG, TRANS
C     .. Array Arguments ..
      COMPLEX*16 AS(*), WORK(*), X(*), Y(*)
      INTEGER    IA(*), JA(*)
C     .. Local Scalars ..
      COMPLEX*16 ACC
      INTEGER    I, J, K, NCOLA, NROWA,DUM
      LOGICAL    SYM, TRA, COTRA, UNI
C     .. Executable Statements ..
C
      UNI = DIAG.EQ.'U'
C
C     .. Not simmetric matrix
      TRA = TRANS.EQ.'T'
      COTRA = TRANS.EQ.'C'

C     .. Symmetric matrix upper or lower 
      SYM = (TRANS.EQ.'L').OR.(TRANS.EQ.'U').OR.
     +      (TRANS.EQ.'M').OR.(TRANS.EQ.'V')
C
      IF (.NOT.(TRA.OR.COTRA)) THEN
         NROWA = M
         NCOLA = N
      ELSE
         NROWA = N
         NCOLA = M
      END IF    !(....(CO)TRA)

      IF (ALPHA.EQ.ZERO) THEN
         IF (BETA.EQ.ZERO) THEN
            DO I = 1, M
               Y(I) = ZERO
            ENDDO
         ELSE
            DO 20 I = 1, M
               Y(I) = BETA*Y(I)
 20         CONTINUE
         ENDIF
         RETURN
      END IF

C
      IF (SYM) THEN
         IF (UNI) THEN
C
C              ......Symmetric with unitary diagonal.......
C              ....OK!!
C              To be optimized
            
            IF (BETA.NE.ZERO) THEN
               DO 40 I = 1, M
C
C                 Product for diagonal elements
C
                  Y(I) = BETA*Y(I) + ALPHA*X(I)
 40            CONTINUE
            ELSE
               DO I = 1, M
                  Y(I) = ALPHA*X(I)
               ENDDO
            ENDIF

C              Product for other elements
            IF ((TRANS.EQ.'L').OR.(TRANS.EQ.'U')) THEN
               DO 80 I = 1, M
                  ACC = ZERO
                  DO 60 J = IA(I), IA(I+1) - 1
                     K = JA(J)
                     Y(K) = Y(K) + ALPHA*AS(J)*X(I)
                     ACC = ACC + AS(J)*X(K)
 60               CONTINUE
                  Y(I) = Y(I) + ALPHA*ACC
 80            CONTINUE
            ELSE   ! Perform computations on conjug(A)
               DO 82 I = 1, M
                  ACC = ZERO
                  DO 81 J = IA(I), IA(I+1) - 1
                     K = JA(J)
                     Y(K) = Y(K) + ALPHA * CONJG(AS(J)) * X(I)
                     ACC = ACC + CONJG(AS(J)) * X(K)
 81               CONTINUE
                  Y(I) = Y(I) + ALPHA*ACC
 82            CONTINUE
            ENDIF
C
         ELSE IF ( .NOT. UNI) THEN
C
C            Check if matrix is lower or upper
C
            IF ((TRANS.EQ.'L').OR.(TRANS.EQ.'M')) THEN
C
C               LOWER CASE: diagonal element is the last element of row
C               ....OK!

               IF (BETA.NE.ZERO) THEN
                  DO 100 I = 1, M
                     Y(I) = BETA*Y(I)
 100              CONTINUE
               ELSE
                  DO I = 1, M
                     Y(I) = ZERO
                  ENDDO
               ENDIF

               IF  (TRANS.EQ.'L') THEN
                  DO 140 I = 1, M
                     ACC = ZERO
                     DO 120 J = IA(I), IA(I+1) - 1 ! it was -2
                        K = JA(J)
C   
C                    To be optimized
C   
                        IF (K.NE.I) THEN    !for symmetric element 
                           Y(K) = Y(K) + ALPHA*AS(J)*X(I)
                        ENDIF
                        ACC = ACC + AS(J)*X(K)
 120                 CONTINUE

                     Y(I) = Y(I) + ALPHA*ACC 
 140              CONTINUE
               ELSE   ! Perform computations on conjug(A)
                  DO 142 I = 1, M
                     ACC = ZERO
                     DO 141 J = IA(I), IA(I+1) - 1 ! it was -2
                        K = JA(J)
C   
C                    To be optimized
C   
                        IF (K.NE.I) THEN    !for symmetric element 
                           Y(K) = Y(K) + ALPHA * CONJG(AS(J)) * X(I)
                        ENDIF
                        ACC = ACC + CONJG(AS(J)) * X(K)
 141                 CONTINUE
                     Y(I) = Y(I) + ALPHA * ACC 
 142              CONTINUE

               ENDIF

            ELSE   ! ....Trans<>L, M
C
C              UPPER CASE
C              ....OK!!
C
               IF (BETA.NE.ZERO) THEN
                  DO 160 I = 1, M
                     Y(I) = BETA*Y(I)
 160              CONTINUE
               ELSE
                  DO I = 1, M
                     Y(I) = ZERO
                  ENDDO
               ENDIF
               IF (TRANS.EQ.'U') THEN
                  DO 200 I = 1, M
                     ACC = ZERO
                     DO 180 J = IA(I) , IA(I+1) - 1 ! removed +1
                        K = JA(J)
C   
C                    To be optimized
C   
                        IF(K.NE.I) THEN
                           Y(K) = Y(K) + ALPHA*AS(J)*X(I)
                        ENDIF
                        ACC = ACC + AS(J)*X(K)
  180                CONTINUE
                     Y(I) = Y(I) + ALPHA*ACC
  200             CONTINUE
               ELSE  ! Perform computations on conjug(A)
                  DO 202 I = 1, M
                     ACC = ZERO
                     DO 201 J = IA(I) , IA(I+1) - 1 ! removed +1
                        K = JA(J)
C   
C                    To be optimized
C   
                        IF(K.NE.I) THEN
                           Y(K) = Y(K) + ALPHA * CONJG(AS(J)) * X(I)
                        ENDIF
                        ACC = ACC + CONJG(AS(J)) * X(K)
 201                 CONTINUE
                     Y(I) = Y(I) + ALPHA*ACC
 202              CONTINUE
               ENDIF
            END IF   ! ......TRANS=='L'
         END IF      ! ......Not UNI
C
      ELSE IF ((.NOT.TRA).AND.(.NOT.COTRA)) THEN    !......NOT SYM

         IF ( .NOT. UNI) THEN      
C
C          .......General Not Unit, No Traspose
C

            IF (BETA.NE.ZERO) THEN
               DO 240 I = 1, M
                  ACC = ZERO
                  DO 220 J = IA(I), IA(I+1) - 1
                     ACC = ACC + AS(J)*X(JA(J))
 220              CONTINUE
                  Y(I) = ALPHA*ACC + BETA*Y(I)
 240           CONTINUE
            ELSE
               DO I = 1, M
                  ACC = ZERO
                  DO J = IA(I), IA(I+1) - 1
                     ACC = ACC + AS(J)*X(JA(J))
                  ENDDO
                  Y(I) = ALPHA*ACC
               ENDDO
            ENDIF
C
         ELSE IF (UNI) THEN
C
            IF (BETA.NE.ZERO) THEN
               DO 280 I = 1, M
                  ACC = ZERO
                  DO 260 J = IA(I), IA(I+1) - 1
                     ACC = ACC + AS(J)*X(JA(J))
 260              CONTINUE
                  Y(I) = ALPHA*(ACC+X(I)) + BETA*Y(I)
 280           CONTINUE
            ELSE        !(BETA.EQ.ZERO)
               DO I = 1, M
                  ACC = ZERO
                  DO J = IA(I), IA(I+1) - 1
                     ACC = ACC + AS(J)*X(JA(J))
                  ENDDO
                  Y(I) = ALPHA*(ACC+X(I))
               ENDDO
            ENDIF
         END IF   !....End Testing on UNI
C
      ELSE IF (TRA) THEN   !....Else on SYM (swapped M and N)
C
         IF ( .NOT. UNI) THEN
C
            IF (BETA.NE.ZERO) THEN
               DO 300 I = 1, M
                  Y(I) = BETA*Y(I)
 300           CONTINUE
            ELSE        !(BETA.EQ.ZERO)
               DO I = 1, M
                  Y(I) = ZERO
               ENDDO
            ENDIF
C
         ELSE IF (UNI) THEN
C

            IF (BETA.NE.ZERO) THEN
               DO 320 I = 1, M
                  Y(I) = BETA*Y(I) + ALPHA*X(I)
 320           CONTINUE
            ELSE                !(BETA.EQ.ZERO)
               DO I = 1, M
                  Y(I) = ALPHA*X(I)
               ENDDO
            ENDIF

C
         END IF    !....UNI
C
         IF (ALPHA.EQ.ONE) THEN
C
            DO 360 I = 1, N
               DO 340 J = IA(I), IA(I+1) - 1
                  K = JA(J)
                  Y(K) = Y(K) + AS(J)*X(I)
  340          CONTINUE
  360       CONTINUE
C
         ELSE IF (ALPHA.EQ.-ONE) THEN
C
            DO 400 I = 1, n
               DO 380 J = IA(I), IA(I+1) - 1
                  K = JA(J)
                  Y(K) = Y(K) - AS(J)*X(I)
  380          CONTINUE
  400       CONTINUE
C
         ELSE           !.....Else on TRA
C
C           This work array is used for efficiency
C
            DO 420 I = 1, N
               WORK(I) = ALPHA*X(I)
  420       CONTINUE
C
            DO 460 I = 1, n
               DO 440 J = IA(I), IA(I+1) - 1
                  K = JA(J)
                  Y(K) = Y(K) + AS(J)*WORK(I)
  440          CONTINUE
  460       CONTINUE
C
         END IF     !.....End testing on ALPHA

      ELSE IF (COTRA) THEN   !....Else on SYM (swapped M and N)
C
         IF ( .NOT. UNI) THEN
C
            IF (BETA.NE.ZERO) THEN
               DO 500 I = 1, M
                  Y(I) = BETA*Y(I)
 500           CONTINUE
            ELSE        !(BETA.EQ.ZERO)
               DO I = 1, M
                  Y(I) = ZERO
               ENDDO
            ENDIF
C
         ELSE IF (UNI) THEN
C

            IF (BETA.NE.ZERO) THEN
               DO 520 I = 1, M
                  Y(I) = BETA*Y(I) + ALPHA*X(I)
 520           CONTINUE
            ELSE                !(BETA.EQ.ZERO)
               DO I = 1, M
                  Y(I) = ALPHA*X(I)
               ENDDO
            ENDIF

C
         END IF    !....UNI
C
         IF (ALPHA.EQ.ONE) THEN
C
            DO 560 I = 1, N
               DO 540 J = IA(I), IA(I+1) - 1
                  K = JA(J)
                  Y(K) = Y(K) + CONJG(AS(J))*X(I)
  540          CONTINUE
  560       CONTINUE
C
         ELSE IF (ALPHA.EQ.-ONE) THEN
C
            DO 600 I = 1, n
               DO 580 J = IA(I), IA(I+1) - 1
                  K = JA(J)
                  Y(K) = Y(K) - CONJG(AS(J))*X(I)
  580          CONTINUE
  600       CONTINUE
C
         ELSE           !.....Else on TRA
C
C           This work array is used for efficiency
C
            DO 620 I = 1, N
               WORK(I) = ALPHA*X(I)
  620       CONTINUE
C
            DO 660 I = 1, n
               DO 640 J = IA(I), IA(I+1) - 1
                  K = JA(J)
                  Y(K) = Y(K) + CONJG(AS(J))*WORK(I)
  640          CONTINUE
  660       CONTINUE
C
         END IF     !.....End testing on ALPHA

      END IF        !.....End testing on SYM      
C
      RETURN
C
C     END OF ZSRMV
C
      END
     