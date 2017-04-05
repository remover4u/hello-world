CREATE OR REPLACE FORCE VIEW BCMS."기간별제품현황"
(
   ITEM_CODE, ITEM_NAME,"기본가","병원가",
   "현 정상재고", "현 보류재고", "현 반품재고", "현 재고합계",
   "검색시작일","검색종료일", "현재일"
    ,"기간별정상입고", "기간별수동입고", "기간별반품입고", "기간별취소입고", "기간별입고합계"
    ,"기간별일반출고", "기간별셈플","기간별출고합계"
    ,"기간별반품"
    ,"기간별반품폐기", "기간별정상폐기", "기간별폐기합계"
   )
   AS
   SELECT 
    A.ITEM_CODE, A.ITEM_NAME, A.STD_UNIT_PRICE, A.HOSPITAL_PRICE,
    B.NORMAL_STOCK, B.HOLD_STOCK, B.RET_STOCK, B.TOTAL_STOCK,
    '&&FROM_DATE', '&&TOTO_DATE',
    Z.CURRENT_DATE,
    C. N_INPUT, C.M_INPUT, C.R_INPUT, C.C_INPUT, C.T_INPUT
    ,(D.PRODUCT_OUT_QTY  -  D.RET_OUT_QTY), D.RET_OUT_QTY, D.PRODUCT_OUT_QTY   
    ,E.RET_OUT_QTY
    ,F.RET_DISPOSE_QTY, F.NOR_DISPOSE_QTY, F.DISPOSE_TOTAL
    FROM
      /* 시스템 기본정보 */
      (
       SELECT TO_DATE(SYSDATE,'YYYY-MM-DD') CURRENT_DATE
       FROM DUAL
       ) Z,
      /* 제품 기본정보 */
      (
      SELECT ITEM_CODE, ITEM_NAME, STD_UNIT_PRICE, HOSPITAL_PRICE
      FROM T_ITEM
      WHERE ITEM_CODE = '&&TARGET_ITEM_CODE'
      )A,
      /*현재고현황 */
      (  
       SELECT /* T_STO_ITEM STO_LOC_ID : C: 출하2층 D :출하1층  S:보류 G:반품 */
        ITEM_CODE, 
       SUM( 
               CASE
                  WHEN SUBSTR (STO_LOC_ID, 0, 1) = 'C' OR
                       SUBSTR (STO_LOC_ID, 0, 1) = 'D' 
                  THEN
                     T_STO_ITEM.STOCK_QTY
                  ELSE
                     0
               END
               )  AS NORMAL_STOCK,
       SUM(
               CASE
                  WHEN SUBSTR (STO_LOC_ID, 0, 1) = 'S'  
                  THEN
                     T_STO_ITEM.STOCK_QTY
                  ELSE
                     0
               END
               ) AS  HOLD_STOCK,        
       SUM(
               CASE
                  WHEN SUBSTR (STO_LOC_ID, 0, 1) = 'G'  
                  THEN
                      T_STO_ITEM.STOCK_QTY
                  ELSE
                     0
               END
               ) AS RET_STOCK,        
       SUM( T_STO_ITEM.STOCK_QTY )   
                 AS TOTAL_STOCK
       FROM T_STO_ITEM 
       WHERE T_STO_ITEM.ITEM_CODE = '&&TARGET_ITEM_CODE'
       GROUP BY T_STO_ITEM.ITEM_CODE
       ORDER BY T_STO_ITEM.ITEM_CODE
      )B,
      /*기간별입고현황 */
       (
      SELECT  /* T_IN_WORK IN_TYPE - PI : 생산입고 RI: 반품입고, TI:  수동입고, CI: 취소입고 */
                 A.ITEM_CODE,
      SUM(
          CASE
              WHEN B.IN_TYPE = 'PI'
              THEN
                   B.IN_QTY
                   ELSE
                   0
                   END) N_INPUT,
      SUM(
          CASE
              WHEN B.IN_TYPE = 'TI'
              THEN
                   B.IN_QTY
                   ELSE
                   0
                   END) M_INPUT,
      SUM(
          CASE
              WHEN B.IN_TYPE = 'RI'
              THEN
                   B.IN_QTY
                   ELSE
                   0
                   END) R_INPUT,
      SUM(
          CASE
              WHEN B.IN_TYPE = 'CI'
              THEN
                   B.IN_QTY
                   ELSE
                   0
                   END) C_INPUT,   
      SUM(
              B.IN_QTY
               )  T_INPUT
                          
      FROM
           T_IN_WORK B, T_ITEM A                                                               
      WHERE
        B.COMP_DATE >=
                               TO_DATE ('&&FROM_DATE', 'YYYY/MM/DD')
       AND
        B.COMP_DATE <=
                               TO_DATE ('&&TOTO_DATE', 'YYYY/MM/DD')
       AND 
       B.ITEM_CODE = '&&TARGET_ITEM_CODE' AND
       A. ITEM_CODE = '&&TARGET_ITEM_CODE'
       GROUP BY A.ITEM_CODE
       ORDER BY A.ITEM_CODE
    ) C,
          /*기간별출고현황 */
          (  SELECT A.ITEM_CODE,
                    SUM(
                           CASE
                                  WHEN B.SUPPLY_FORM  = '7'
                                  THEN
                                  A.OUT_EXP_QTY
                                  ELSE
                                  0
                                  END) RET_OUT_QTY,
                    SUM (A.OUT_EXP_QTY) PRODUCT_OUT_QTY
               FROM T_OUT_EXP_ITEM A 
                        INNER JOIN  
                        T_OUT_EXP B
                        ON  A.OUT_CHIT_NO = B.OUT_CHIT_NO
              WHERE   
                           A.ITEM_CODE = '&&TARGET_ITEM_CODE'
                    AND A.OUT_EXP_ITEM_ST = 'C'
                    AND B.OUT_EXP_DAY >=
                           TO_DATE ('&&FROM_DATE', 'YYYY/MM/DD')
                    AND B.OUT_EXP_DAY <=
                           TO_DATE ('&&TOTO_DATE', 'YYYY/MM/DD')
           GROUP BY  A.ITEM_CODE
           ORDER BY  A.ITEM_CODE 
           ) D,
           (
             SELECT SUM(
                                 A.RET_QTY) RET_OUT_QTY
             FROM T_RET_HIST_SERIAL A 
                       INNER JOIN  
                      T_RET_INFO B
                      ON A.RET_INFO_NO = B.RET_INFO_NO
           WHERE     
                     A.ITEM_CODE = '&&TARGET_ITEM_CODE'
              AND       B.MAN_CFRM_DATE >=
                           TO_DATE ('&&FROM_DATE', 'YYYY/MM/DD')
                    AND B.MAN_CFRM_DATE <=
                           TO_DATE ('&&TOTO_DATE', 'YYYY/MM/DD')
            GROUP BY A.ITEM_CODE
            ORDER BY A.ITEM_CODE
            ) E
           (SELECT R.RETURN_DISPOSE_QTY RET_DISPOSE_QTY,
                   N.NORMAL_DISPOSE_QTY NOR_DISPOSE_QTY,
                  (R.RETURN_DISPOSE_QTY + N.NORMAL_DISPOSE_QTY)   AS DISPOSE_TOTAL
            FROM  ( 
                   SELECT ITEM_CODE, ITEM_NAME, RETURN_DISPOSE_QTY
                   FROM   (SELECT B.ITEM_CODE,
                                  C.ITEM_NAME,
                             SUM (
                                  D.RET_QTY) OVER (PARTITION BY B.ITEM_CODE ORDER BY B.ITEM_CODE) AS RETURN_DISPOSE_QTY,
                                  F.ITEM_CODE AS OMIT_ITEM_CODE
                           FROM   
                                  T_RET_INFO A 
                                  INNER JOIN T_RET_HIST B
                                        ON B.RET_INFO_NO = A.RET_INFO_NO
                                  INNER JOIN T_ITEM C
                                        ON C.ITEM_CODE = B.ITEM_CODE
                                  INNER JOIN T_RET_HIST_SERIAL D
                                        ON D.RET_HIST_NO = B.RET_HIST_NO
                                  LEFT OUTER JOIN T_REQ_OMIT_ITEM F
                                        ON B.ITEM_CODE = F.ITEM_CODE
                           WHERE  A.DISPOSE_DATE >=
                                        TO_DATE ('&&FROM_DATE', 'YYYY/MM/DD')
                                    AND A.DISPOSE_DATE <=
                                        TO_DATE ('&&TOTO_DATE', 'YYYY/MM/DD')
                                    AND B.ITEM_CODE = '&&TARGET_ITEM_CODE' /* 전체 코드 확인 시  라인 주석 처리 */
                                    AND A.DISPOS_CFRM_YN = 'P'
                                    AND A.RET_INFO_ST <> 'D')
                   WHERE OMIT_ITEM_CODE IS NULL
                   GROUP BY ITEM_CODE, ITEM_NAME, RETURN_DISPOSE_QTY) R,
                   
                  (
                   SELECT ITEM_CODE, ITEM_NAME, NORMAL_DISPOSE_QTY
                   FROM   (SELECT A.ITEM_CODE,
                                    C.ITEM_NAME,
                                    SUM (
                                       B.DISPOS_QTY)
                                    OVER (PARTITION BY B.ITEM_CODE
                                          ORDER BY B.ITEM_CODE)
                                       AS NORMAL_DISPOSE_QTY
                               FROM T_OUT_WORK A
                                    LEFT OUTER JOIN T_DISPOS_SERIAL B
                                       ON B.DISPOS_INFO_NO = A.RET_HIST_NO
                                          AND B.DISPOS_INFO_DATE =
                                                 TRUNC (A.COMP_DATE)
                                    INNER JOIN T_ITEM C
                                       ON C.ITEM_CODE = A.ITEM_CODE
                                    INNER JOIN T_IN_WORK D
                                       ON A.IN_WORK_ID = D.IN_WORK_ID
                              WHERE A.PROC_IN_DATE >=
                                       TO_DATE ('&&FROM_DATE', 'YYYY/MM/DD')
                                    AND A.PROC_IN_DATE <=
                                           TO_DATE ('&&TOTO_DATE', 'YYYY/MM/DD')
                                    AND B.ITEM_CODE = '&&TARGET_ITEM_CODE'
                                    AND A.OUT_TYPE = 'KO'
                                    AND A.OUT_REA_CODE = 'A'
                                    AND A.OUT_WORK_ST = 'C'
                                    AND A.RET_HIST_NO IS NOT NULL)
                   GROUP BY ITEM_CODE, ITEM_NAME, NORMAL_DISPOSE_QTY) N) F
          
   WITH READ ONLY;

   