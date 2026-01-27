SELECT USER
FROM DUAL;
--==>> SCOTT


CREATE SEQUENCE ST_SEQ
INCREMENT BY 1
START WITH 114
NOCACHE;
--==>> Sequence ST_SEQ이(가) 생성되었습니다.

-- 프로시저 생성
-- 프로시저명: PRC_ST_C
-- STUD테이블에 INSERT - 최종관리자만 가능 (이름, 주민번호)
-- 주민번호 유니크 예외 처리할지?
CREATE OR REPLACE PROCEDURE PRC_ST_C
( P_ST_NAME   IN  STUD.ST_NAME%TYPE
, P_ST_SSN    IN  STUD.ST_SSN%TYPE
)
IS
    V_SEQ   NUMBER;
BEGIN

    SELECT ST_SEQ.NEXTVAL INTO V_SEQ
    FROM DUAL;
    INSERT INTO STUD(ST_ID, ST_PW, ST_NAME, ST_SSN)
    VALUES('ST'||V_SEQ, SUBSTR(P_ST_SSN,8),P_ST_NAME,P_ST_SSN);
        
END;


-- 프로시저 생성
-- 프로시저명: PRC_ST_U
-- STUD테이블에 UPDATE - 관리자만 가능 (학생아이디, 이름, 주민번호, 비밀번호)
CREATE OR REPLACE PROCEDURE PRC_ST_U
( P_ST_ID   IN  STUD.ST_ID%TYPE
, P_ST_NAME IN  STUD.ST_NAME%TYPE
, P_ST_SSN  IN  STUD.ST_SSN%TYPE
, P_ST_PW   IN  STUD.ST_PW%TYPE
)
IS
    V_ST_CNT            NUMBER;
    USER_DEFINE_ERROR1  EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO V_ST_CNT
    FROM STUD
    WHERE ST_ID = P_ST_ID;
    
    IF (V_ST_CNT = 0) THEN
        RAISE USER_DEFINE_ERROR1;
    END IF;

    UPDATE STUD
    SET ST_NAME = NVL(P_ST_NAME, ST_NAME), ST_SSN = NVL(P_ST_SSN, ST_SSN), ST_PW = NVL(P_ST_PW, ST_PW)
    WHERE ST_ID = P_ST_ID;
    
    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN    
            RAISE_APPLICATION_ERROR(-20001, '데이터가 존재하지 않습니다.');
END;



-- 프로시저 생성
-- 프로시저명: PRC_ST_D
-- STUD테이블에 DELETE - 관리자만 가능 (학생아이디) 
-- 학생이 수강신청이나 성적에 없을 때만 삭제 가능
CREATE OR REPLACE PROCEDURE PRC_ST_D
(P_ST_ID IN STUD.ST_ID%TYPE)
IS
    USER_DEFINE_ERROR1   EXCEPTION;
    USER_DEFINE_ERROR2   EXCEPTION;
    V_EN_CNT            NUMBER;
    V_ST_CNT            NUMBER;
BEGIN
    
    SELECT COUNT(*) INTO V_ST_CNT
    FROM STUD
    WHERE ST_ID = P_ST_ID;
    
    IF (V_ST_CNT = 0) THEN
        RAISE USER_DEFINE_ERROR1;
    END IF;
    
    SELECT COUNT(*)  INTO V_EN_CNT
    FROM ENROLLMENT
    WHERE ST_ID = P_ST_ID;
    
    IF (V_EN_CNT > 0 ) THEN
        RAISE USER_DEFINE_ERROR2;
    ELSE
        DELETE
        FROM STUD
        WHERE ST_ID = P_ST_ID;
    END IF;
    
    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN    
            RAISE_APPLICATION_ERROR(-20001, '데이터가 존재하지 않습니다.');
            ROLLBACK;
        WHEN USER_DEFINE_ERROR2 THEN
            RAISE_APPLICATION_ERROR(-20002, '삭제 불가능합니다.');
            ROLLBACK;
END;
















CREATE SEQUENCE GR_SEQ
INCREMENT BY 1
START WITH 3
NOCACHE;
--==>> Sequence GR_SEQ이(가) 생성되었습니다.


-- 프로시저 생성
-- 프로시저명: PRC_GR_C
-- GRADE 테이블에 INSERT - 관리자, 교수자만 가능 (로그인아이디, 수강신청코드, 개설과목코드, 출결점수, 필기점수, 실기점수)
-- 교수자가 본인 과목에 한해서만 생성가능
-- 중도탈락 학생 제외
-- 수강신청의 수강신청코드가 중도탈락 중도탈락 테이블에 존재할 경우 탈락 일자를 확인
-- 탈락일자가 개설과목의 종료일시보다 빠른경우는 생성불가
CREATE OR REPLACE PROCEDURE PRC_GR_C_PF
(P_LOGIN_ID    IN  PROF.PF_ID%TYPE
)
IS
    V_LOGIN_ID  CHAR(2);
    V_DUP_CNT   NUMBER;
    
    USER_DEFINE_ERROR1  EXCEPTION;
BEGIN
    V_LOGIN_ID := SUBSTR(P_LOGIN_ID,1,2);
    
    IF (V_LOGIN_ID = 'PF') THEN
         -- 중도탈락자가 아니면서 교수자의 과목인 컬럼들 
        FOR REC IN ( SELECT OS.OS_CODE, ER.ER_CODE, OS.OS_EDATE
                     FROM OPEN_SUB OS JOIN ENROLLMENT ER
                        ON ER.OC_CODE = OS.OC_CODE
                     WHERE OS.PF_ID = P_LOGIN_ID
                        AND NOT EXISTS( SELECT 1
                                        FROM DROP_OUT DO 
                                        WHERE DO.ER_CODE = ER.ER_CODE
                                          AND DO.DO_DATE <= OS.OS_EDATE)
                                       ) LOOP

            -- 중복 생성 방지
            -- ER_CODE, OS_CODE가 동일한게 있다면 생성방지
            SELECT COUNT(*) INTO V_DUP_CNT
            FROM GRADE
            WHERE ER_CODE = REC.ER_CODE AND OS_CODE = REC.OS_CODE;
            
            IF(V_DUP_CNT > 0) THEN
                CONTINUE;
            END IF;

            -- 데이터 삽입
            INSERT INTO GRADE(GR_CODE, ER_CODE, OS_CODE)
            VALUES('GR'||LPAD(GR_SEQ.NEXTVAL, 3, '0'), REC.ER_CODE, REC.OS_CODE);

        END LOOP;
    ELSE
        RAISE USER_DEFINE_ERROR1;
    END IF;
    
    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN
            RAISE_APPLICATION_ERROR(-20004, '권한이 없습니다.');
END;


---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE PRC_GR_C_AD
( P_LOGIN_ID    IN  ADMIN.AD_ID%TYPE
, P_ER_CODE     IN  GRADE.ER_CODE%TYPE
, P_OS_CODE     IN  GRADE.OS_CODE%TYPE
, P_ATT_SCORE   IN  GRADE.ATT_SCORE%TYPE
, P_WRT_SCORE   IN  GRADE.WRT_SCORE%TYPE
, P_PRC_SCORE   IN  GRADE.PRC_SCORE%TYPE
)
IS
    V_LOGIN_ID          CHAR(2);
    V_OS_CNT            NUMBER;
    V_ER_CNT            NUMBER;
    V_DO_CNT            NUMBER;
    V_DUP_CNT           NUMBER;
    V_DO_DATE           DATE;
    V_OS_EDATE          DATE;
    V_OC_CODE           ENROLLMENT.OC_CODE%TYPE;
    V_FLAG              BOOLEAN:= FALSE;
    
    USER_DEFINE_ERROR1  EXCEPTION;
    USER_DEFINE_ERROR2  EXCEPTION;
    USER_DEFINE_ERROR3  EXCEPTION;
    USER_DEFINE_ERROR4  EXCEPTION;
    USER_DEFINE_ERROR5  EXCEPTION;
BEGIN
     V_LOGIN_ID := SUBSTR(P_LOGIN_ID,1,2);
    
    IF (V_LOGIN_ID = 'AD') THEN
         -- 성적테이블에 중복데이터 존재 시 예외처리
        SELECT COUNT(*) INTO V_DUP_CNT
        FROM GRADE
        WHERE ER_CODE = P_ER_CODE AND OS_CODE = P_OS_CODE;
        
        IF(V_DUP_CNT > 0) THEN
            RAISE USER_DEFINE_ERROR3;
        END IF;
        
        
        -- P_OS_CODE와 P_ER_CODE가 실제로 서로 관계가 있는지 확인
        -- 개설과목코드 수강신청코드
        -- 수강신청테이블에 파라미터수강신청코드와 같은 수강신청코드에서 개설과정을 가져오고
        -- 그 개설과정코드가 개설과목에 들어있는 것 중에 파라미터로 받은 개설과목코드가 있는지 확인
        
        -- 데이터 없을 때 예외처리 
        SELECT COUNT(*)  INTO V_ER_CNT
        FROM ENROLLMENT
        WHERE ER_CODE = P_ER_CODE;
        
        SELECT COUNT(*) INTO V_OS_CNT
        FROM OPEN_SUB
        WHERE OS_CODE = P_OS_CODE;
        
        IF (V_OS_CNT = 0 OR V_ER_CNT = 0) THEN
            RAISE USER_DEFINE_ERROR1;
        END IF;
        
        
        -- 수강신청테이블에서 파라미터로 받은 ER_CODE와 같은 행에서 OC_CODE 불러오기
        SELECT OC_CODE  INTO V_OC_CODE
        FROM ENROLLMENT
        WHERE ER_CODE = P_ER_CODE;
   
        -- 개설과목코드들
        FOR R_OS_CODE IN ( SELECT OS_CODE 
                           FROM OPEN_SUB
                           WHERE OC_CODE = V_OC_CODE
                          ) LOOP
            -- 개설과목코드와 파라미터개설과목코드가 같은 게 하나라도 있으면 TRUE 
            IF R_OS_CODE.OS_CODE = P_OS_CODE    THEN
                V_FLAG := TRUE;
                EXIT;
            END IF;   
        END LOOP;
        
        -- 개설과목코드에 파라미터개설과목코드가 같은게 없다면 예외처리
        IF NOT V_FLAG THEN
            RAISE USER_DEFINE_ERROR5;
        END IF;
        
          -- 중도탈락 학생 예외처리           
                SELECT OS_EDATE INTO V_OS_EDATE
                FROM OPEN_SUB
                WHERE OS_CODE = P_OS_CODE;
                
                SELECT COUNT(*) INTO V_DO_CNT
                FROM DROP_OUT
                WHERE ER_CODE = P_ER_CODE;
                
                IF(V_DO_CNT > 0) THEN
                    SELECT DO_DATE  INTO V_DO_DATE
                    FROM DROP_OUT
                    WHERE ER_CODE = P_ER_CODE;
                    IF (V_DO_DATE <= V_OS_EDATE) THEN
                        RAISE USER_DEFINE_ERROR4;
                    ELSE
                        INSERT INTO GRADE(GR_CODE, ER_CODE, OS_CODE, ATT_SCORE, WRT_SCORE, PRC_SCORE)
                        VALUES('GR'||LPAD(GR_SEQ.NEXTVAL, 3, '0'), P_ER_CODE, P_OS_CODE, P_ATT_SCORE, P_WRT_SCORE, P_PRC_SCORE);
                    END IF;
                ELSE
                    INSERT INTO GRADE(GR_CODE, ER_CODE, OS_CODE, ATT_SCORE, WRT_SCORE, PRC_SCORE)
                    VALUES('GR'||LPAD(GR_SEQ.NEXTVAL, 3, '0'), P_ER_CODE, P_OS_CODE, P_ATT_SCORE, P_WRT_SCORE, P_PRC_SCORE);
                END IF; 
    ELSE
        RAISE USER_DEFINE_ERROR2;
    END IF;
    
    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN
            RAISE_APPLICATION_ERROR(-20003, '데이터가 존재하지 않습니다.');
        WHEN USER_DEFINE_ERROR2 THEN
            RAISE_APPLICATION_ERROR(-20004, '권한이 없습니다.');
        WHEN USER_DEFINE_ERROR3 THEN
            RAISE_APPLICATION_ERROR(-20005, '유효하지 않은 파라미터입니다.');
        WHEN USER_DEFINE_ERROR4 THEN
            RAISE_APPLICATION_ERROR(-20006, '중도탈락한 학생입니다.');
        WHEN USER_DEFINE_ERROR5 THEN
            RAISE_APPLICATION_ERROR(-20007, '유효한 개설과목이 존재하지 않습니다.');
END;




/*
CREATE OR REPLACE PROCEDURE PRC_GR_C
( P_LOGIN_ID    IN  ADMIN.AD_ID%TYPE
, P_ER_CODE     IN  GRADE.ER_CODE%TYPE
, P_OS_CODE     IN  GRADE.OS_CODE%TYPE
, P_ATT_SCORE   IN  GRADE.ATT_SCORE%TYPE
, P_WRT_SCORE   IN  GRADE.WRT_SCORE%TYPE
, P_PRC_SCORE   IN  GRADE.PRC_SCORE%TYPE
)
IS
    V_LOGIN_ID          CHAR(2);
    V_OS_CNT            NUMBER;
    V_ER_CNT            NUMBER;
    V_DO_CNT            NUMBER;
    V_DUP_CNT           NUMBER;
    V_DO_DATE           DATE;
    V_OS_EDATE          DATE;
    V_OC_CODE           ENROLLMENT.OC_CODE%TYPE;
    V_FLAG              BOOLEAN:= FALSE;
    
    USER_DEFINE_ERROR1  EXCEPTION;
    USER_DEFINE_ERROR2  EXCEPTION;
    USER_DEFINE_ERROR3  EXCEPTION;
    USER_DEFINE_ERROR4  EXCEPTION;
    USER_DEFINE_ERROR5  EXCEPTION;
BEGIN
    V_LOGIN_ID := SUBSTR(P_LOGIN_ID,1,2);
    
    --● 교수자 계정일 때
    IF(V_LOGIN_ID = 'PF') THEN

        -- 중도탈락자가 아니면서 교수자의 과목인 컬럼들 
        FOR REC IN ( SELECT OS.OS_CODE, ER.ER_CODE, OS.OS_EDATE
                     FROM OPEN_SUB OS JOIN ENROLLMENT ER
                        ON ER.OC_CODE = OS.OC_CODE
                     WHERE OS.PF_ID = P_LOGIN_ID
                        AND NOT EXISTS( SELECT 1
                                        FROM DROP_OUT DO 
                                        WHERE DO.ER_CODE = ER.ER_CODE
                                          AND DO.DO_DATE <= OS.OS_EDATE)
                                       ) LOOP

            -- 중복 생성 방지
            -- ER_CODE, OS_CODE가 동일한게 있다면 생성방지
            SELECT COUNT(*) INTO V_DUP_CNT
            FROM GRADE
            WHERE ER_CODE = REC.ER_CODE AND OS_CODE = REC.OS_CODE;
            
            IF(V_DUP_CNT > 0) THEN
                CONTINUE;
            END IF;

            -- 데이터 삽입
            INSERT INTO GRADE(GR_CODE, ER_CODE, OS_CODE, ATT_SCORE, WRT_SCORE, PRC_SCORE)
            VALUES('GR'||LPAD(GR_SEQ.NEXTVAL, 3, '0'), REC.ER_CODE, REC.OS_CODE, P_ATT_SCORE, P_WRT_SCORE, P_PRC_SCORE);

        END LOOP;

    --● 관리자계정일 때
    ELSIF(V_LOGIN_ID = 'AD') THEN
        
        -- 성적테이블에 중복데이터 존재 시 예외처리
        SELECT COUNT(*) INTO V_DUP_CNT
        FROM GRADE
        WHERE ER_CODE = P_ER_CODE AND OS_CODE = P_OS_CODE;
        
        IF(V_DUP_CNT > 0) THEN
            RAISE USER_DEFINE_ERROR3;
        END IF;
        
        
        -- P_OS_CODE와 P_ER_CODE가 실제로 서로 관계가 있는지 확인
        -- 개설과목코드 수강신청코드
        -- 수강신청테이블에 파라미터수강신청코드와 같은 수강신청코드에서 개설과정을 가져오고
        -- 그 개설과정코드가 개설과목에 들어있는 것 중에 파라미터로 받은 개설과목코드가 있는지 확인
        
        -- 데이터 없을 때 예외처리 
        SELECT COUNT(*)  INTO V_ER_CNT
        FROM ENROLLMENT
        WHERE ER_CODE = P_ER_CODE;
        
        SELECT COUNT(*) INTO V_OS_CNT
        FROM OPEN_SUB
        WHERE OS_CODE = P_OS_CODE;
        
        IF (V_OS_CNT = 0 OR V_ER_CNT = 0) THEN
            RAISE USER_DEFINE_ERROR1;
        END IF;
        
        
        -- 수강신청테이블에서 파라미터로 받은 ER_CODE와 같은 행에서 OC_CODE 불러오기
        SELECT OC_CODE  INTO V_OC_CODE
        FROM ENROLLMENT
        WHERE ER_CODE = P_ER_CODE;
   
        -- 개설과목코드들
        FOR R_OS_CODE IN ( SELECT OS_CODE 
                           FROM OPEN_SUB
                           WHERE OC_CODE = V_OC_CODE
                          ) LOOP
            -- 개설과목코드와 파라미터개설과목코드가 같은 게 하나라도 있으면 TRUE 
            IF R_OS_CODE.OS_CODE = P_OS_CODE    THEN
                V_FLAG := TRUE;
                EXIT;
            END IF;   
        END LOOP;
        
        -- 개설과목코드에 파라미터개설과목코드가 같은게 없다면 예외처리
        IF NOT V_FLAG THEN
            RAISE USER_DEFINE_ERROR5;
        END IF;
        
          -- 중도탈락 학생 예외처리           
                SELECT OS_EDATE INTO V_OS_EDATE
                FROM OPEN_SUB
                WHERE OS_CODE = P_OS_CODE;
                
                SELECT COUNT(*) INTO V_DO_CNT
                FROM DROP_OUT
                WHERE ER_CODE = P_ER_CODE;
                
                IF(V_DO_CNT > 0) THEN
                    SELECT DO_DATE  INTO V_DO_DATE
                    FROM DROP_OUT
                    WHERE ER_CODE = P_ER_CODE;
                    IF (V_DO_DATE <= V_OS_EDATE) THEN
                        RAISE USER_DEFINE_ERROR4;
                    ELSE
                        INSERT INTO GRADE(GR_CODE, ER_CODE, OS_CODE, ATT_SCORE, WRT_SCORE, PRC_SCORE)
                        VALUES('GR'||GR_SEQ.NEXTVAL, P_ER_CODE, P_OS_CODE, P_ATT_SCORE, P_WRT_SCORE, P_PRC_SCORE);
                    END IF;
                ELSE
                    INSERT INTO GRADE(GR_CODE, ER_CODE, OS_CODE, ATT_SCORE, WRT_SCORE, PRC_SCORE)
                    VALUES('GR'||GR_SEQ.NEXTVAL, P_ER_CODE, P_OS_CODE, P_ATT_SCORE, P_WRT_SCORE, P_PRC_SCORE);
                END IF; 
        
        
    --● 권한이 없는 계정일 때
    ELSE
        RAISE USER_DEFINE_ERROR2;
    END IF;
    
    
    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN
            RAISE_APPLICATION_ERROR(-20003, '데이터가 존재하지 않습니다.');
        WHEN USER_DEFINE_ERROR2 THEN
            RAISE_APPLICATION_ERROR(-20004, '권한이 없습니다.');
        WHEN USER_DEFINE_ERROR3 THEN
            RAISE_APPLICATION_ERROR(-20005, '유효하지 않은 파라미터입니다.');
        WHEN USER_DEFINE_ERROR4 THEN
            RAISE_APPLICATION_ERROR(-20006, '중도탈락한 학생입니다.');
        WHEN USER_DEFINE_ERROR5 THEN
            RAISE_APPLICATION_ERROR(-20007, '유효한 개설과목이 존재하지 않습니다.');
END;
*/

--================================================================================



-- 프로시저 생성
-- 프로시저명: PRC_GR_U
-- GRADE 테이블에 UPDATE - 관리자, 교수자만 가능(로그인아이디, 성적코드, 출결점수, 필기점수, 실기점수)
-- 교수자가 본인 과목에 한해서만 수정가능 (점수만 수정가능)
-- 관리자는 모든 과목을 수정할 수 있음(점수만)
CREATE OR REPLACE PROCEDURE PRC_GR_U
( P_LOGIN_ID    IN  ADMIN.AD_ID%TYPE
, P_GR_CODE     IN  GRADE.GR_CODE%TYPE
, P_ATT_SCORE   IN  GRADE.ATT_SCORE%TYPE
, P_WRT_SCORE   IN  GRADE.WRT_SCORE%TYPE
, P_PRC_SCORE   IN  GRADE.PRC_SCORE%TYPE
)
IS

    V_LOGIN_ID  CHAR(2);
    V_OS_CODE   OPEN_SUB.OS_CODE%TYPE;
    V_PF_ID     OPEN_SUB.PF_ID%TYPE;
    USER_DEFINE_ERROR1  EXCEPTION;
    USER_DEFINE_ERROR2  EXCEPTION;
    USER_DEFINE_ERROR3  EXCEPTION;
    
BEGIN
    V_LOGIN_ID := SUBSTR(P_LOGIN_ID,1,2);
    
    SELECT OS_CODE  INTO V_OS_CODE
    FROM GRADE
    WHERE GR_CODE = P_GR_CODE;
    
    --● 교수일 때
    IF(V_LOGIN_ID = 'PF') THEN
        -- 입력한 성적코드가 본인 담당인지 확인 후 업데이트
        
        SELECT PF_ID    INTO V_PF_ID
        FROM OPEN_SUB
        WHERE OS_CODE = V_OS_CODE;
        
        IF(V_PF_ID != P_LOGIN_ID) THEN
            RAISE USER_DEFINE_ERROR3;
        END IF;
  
    
        UPDATE GRADE 
        SET ATT_SCORE = NVL(P_ATT_SCORE,ATT_SCORE), WRT_SCORE = NVL(P_WRT_SCORE, WRT_SCORE), PRC_SCORE = NVL(P_PRC_SCORE, PRC_SCORE)
        WHERE GR_CODE = P_GR_CODE;
    
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('정상적으로 업데이트 되었습니다.');
        END IF;
    
    --● 관리자일 때
    ELSIF (V_LOGIN_ID = 'AD') THEN
    
    -- 그냥 업데이트
        UPDATE GRADE 
        SET ATT_SCORE = NVL(P_ATT_SCORE,ATT_SCORE), WRT_SCORE = NVL(P_WRT_SCORE, WRT_SCORE), PRC_SCORE = NVL(P_PRC_SCORE, PRC_SCORE)
        WHERE GR_CODE = P_GR_CODE;
        
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('정상적으로 업데이트 되었습니다.');
        END IF;
    
    --● 권한없는 계정일 때
    ELSE
        RAISE USER_DEFINE_ERROR1;
    END IF;
    
    
    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN
            RAISE_APPLICATION_ERROR(-20004,'권한이 없습니다.');
        WHEN USER_DEFINE_ERROR2 THEN
            RAISE_APPLICATION_ERROR(-20003,'데이터가 존재하지 않습니다.');
        WHEN USER_DEFINE_ERROR3 THEN
            RAISE_APPLICATION_ERROR(-20008,'본인의 담당 과목이 아닙니다.');
END;




--================================================================================



-- 프로시저 생성
-- 프로시저명: PRC_GR_D
-- GRADE 테이블에 DELETE - 관리자, 교수자만 가능(로그인아이디, 성적코드)
CREATE OR REPLACE PROCEDURE PRC_GR_D
( P_LOGIN_ID    IN  ADMIN.AD_ID%TYPE
, GR_CODE       IN  GRADE.GR_CODE%TYPE
)
IS
    V_LOGIN_ID  CHAR(2);
    
    USER_DEFINE_ERROR1  EXCEPTION;
    USER_DEFINE_ERROR2  EXCEPTION;
BEGIN
    V_LOGIN_ID := SUBSTR(P_LOGIN_ID,1,2);
    -- 
    
    IF (V_LOGIN_ID IN ('PF','AD')) THEN
        RAISE USER_DEFINE_ERROR2;
    ELSE
        RAISE USER_DEFINE_ERROR1;
    END IF;

    EXCEPTION
        WHEN USER_DEFINE_ERROR1 THEN
            RAISE_APPLICATION_ERROR(-20004,'권한이 없습니다.');
        WHEN USER_DEFINE_ERROR2 THEN
            RAISE_APPLICATION_ERROR(-20009,'삭제할 수 있는 성적이 없습니다.');
END;





























