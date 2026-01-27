--======== 유현선 [1 ~ 10]======================
-- 1. 관리자 로그인
CREATE OR REPLACE PROCEDURE PRC_AD_LOGIN
(
     P_AD_ID IN ADMIN.AD_ID%TYPE
    ,P_AD_PW IN ADMIN.AD_PW%TYPE
    
    ,P_AD_NAME OUT ADMIN.AD_NAME%TYPE
    ,P_RESULT OUT VARCHAR2
)
IS
    V_ID_MATCH NUMBER;
    V_PW_MATCH NUMBER;
BEGIN
    -- 1. 아이디 존재 여부 확인
    SELECT COUNT(*) INTO V_ID_MATCH
    FROM ADMIN
    WHERE AD_ID = P_AD_ID;
    
    -- 아이디가 존재하지 않는 경우
    IF V_ID_MATCH = 0 THEN
        P_RESULT := 'ID_NOT_FOUND';
        P_AD_NAME := NULL;
        RETURN;
    END IF;
    
    -- 2. 비밀번호 일치 여부 확인
    SELECT COUNT(*) INTO V_PW_MATCH
    FROM ADMIN
    WHERE AD_ID = P_AD_ID AND AD_PW = P_AD_PW;
    
    -- 비밀번호가 틀린 경우
    IF V_PW_MATCH = 0 THEN
        P_RESULT := 'WRONG_PASSWORD';
        P_AD_NAME := NULL;
        RETURN;
    END IF;
    
    -- 3. 로그인 성공
    SELECT AD_NAME INTO P_AD_NAME
    FROM ADMIN
    WHERE AD_ID = P_AD_ID AND AD_PW = P_AD_PW;
    
    P_RESULT := P_AD_ID;  -- 성공 시 아이디 반환
    
EXCEPTION
    WHEN OTHERS THEN
        P_RESULT := 'ERROR';
        P_AD_NAME := NULL;
END;


-- 2. 교수자 로그인
CREATE OR REPLACE PROCEDURE PRC_PF_LOGIN
(
     P_PF_ID IN PROF.PF_ID%TYPE
    ,P_PF_PW IN PROF.PF_PW%TYPE
    ,P_PF_NAME OUT PROF.PF_NAME%TYPE
    ,P_RESULT OUT VARCHAR2
)
IS
    V_ID_MATCH NUMBER;
    V_PW_MATCH NUMBER;
BEGIN
    
    SELECT COUNT(*) INTO V_ID_MATCH
    FROM PROF
    WHERE PF_ID = P_PF_ID;
   
   -- 아이디가 존재하지 않는 경우
    IF V_ID_MATCH = 0 THEN
        P_RESULT := 'ID_NOT_FOUND';
        P_PF_NAME := NULL;
        RETURN;
    END IF;
    
    -- 2. 비밀번호 일치 여부 확인
    SELECT COUNT(*) INTO V_PW_MATCH
    FROM PROF
    WHERE PF_ID = P_PF_ID AND PF_PW = P_PF_PW;
    
    -- 비밀번호가 틀린 경우
    IF V_PW_MATCH = 0 THEN
        P_RESULT := 'WRONG_PASSWORD';
        P_PF_NAME := NULL;
        RETURN;
    END IF;
    
    -- 3. 로그인 성공
    SELECT PF_NAME INTO P_PF_NAME
    FROM PROF
    WHERE PF_ID = P_PF_ID AND PF_PW = P_PF_PW;
    
    P_RESULT := P_PF_ID;  -- 성공 시 아이디 반환
    
EXCEPTION
    WHEN OTHERS THEN
        P_RESULT := 'ERROR';
        P_PF_NAME := NULL;
END;

-- 3. 학생 로그인
CREATE OR REPLACE PROCEDURE PRC_ST_LOGIN
(
     P_ST_ID IN STUD.ST_ID%TYPE
    ,P_ST_PW IN STUD.ST_PW%TYPE
    ,P_ST_NAME OUT STUD.ST_NAME%TYPE
    ,P_RESULT OUT VARCHAR2
)
IS
    V_ID_MATCH NUMBER;
    V_PW_MATCH NUMBER;
BEGIN
    
    SELECT COUNT(*) INTO V_ID_MATCH
    FROM STUD
    WHERE ST_ID = P_ST_ID;
   
   -- 아이디가 존재하지 않는 경우
    IF V_ID_MATCH = 0 THEN
        P_RESULT := 'ID_NOT_FOUND';
        P_ST_NAME := NULL;
        RETURN;
    END IF;
    
    -- 2. 비밀번호 일치 여부 확인
    SELECT COUNT(*) INTO V_PW_MATCH
    FROM STUD
    WHERE ST_ID = P_ST_ID AND ST_PW = P_ST_PW;
    
    -- 비밀번호가 틀린 경우
    IF V_PW_MATCH = 0 THEN
        P_RESULT := 'WRONG_PASSWORD';
        P_ST_NAME := NULL;
        RETURN;
    END IF;
    
    -- 3. 로그인 성공
    SELECT ST_NAME INTO P_ST_NAME
    FROM STUD
    WHERE ST_ID = P_ST_ID AND ST_PW = P_ST_PW;
    
    P_RESULT := P_ST_ID;  -- 성공 시 아이디 반환
    
    EXCEPTION
        WHEN OTHERS THEN
            P_RESULT := 'ERROR';
            P_ST_NAME := NULL;
END;

-- 4. 최종관리자 (관리자 역할) CUD
CREATE OR REPLACE PROCEDURE PRC_AR_CUD
(
     P_MODE IN VARCHAR2
    ,P_AR_CODE IN ADMIN_ROLE.AR_CODE%TYPE
    ,P_AR_NAME IN ADMIN_ROLE.AR_NAME%TYPE 
)
IS
    V_AR_CNT            NUMBER;
BEGIN
    
    IF P_MODE = 'C' THEN
        SELECT COUNT(*) INTO V_AR_CNT
        FROM ADMIN_ROLE
        WHERE AR_NAME = P_AR_NAME;

        IF V_AR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, '중복이 존재합니다.');
        END IF;
        
        INSERT INTO ADMIN_ROLE (AR_CODE, AR_NAME)
        VALUES (P_AR_CODE, P_AR_NAME);

    ELSIF P_MODE = 'U' THEN
        -- 변경하려는 이름이 다른 코드에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_AR_CNT
        FROM ADMIN_ROLE
        WHERE AR_NAME = P_AR_NAME AND AR_CODE <> P_AR_CODE;

        IF V_AR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, '이미 사용 중인 이름입니다.');
        END IF;
        
        UPDATE ADMIN_ROLE
        SET AR_NAME = P_AR_NAME
        WHERE AR_CODE = P_AR_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, '수정 대상이 존재하지 않습니다.');
        END IF;

    ELSIF P_MODE = 'D' THEN
        SELECT COUNT(*) INTO V_AR_CNT
        FROM ADMIN
        WHERE AR_CODE = P_AR_CODE;

        IF V_AR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, '사용 중인 권한은 삭제할 수 없습니다.');
        END IF;

        DELETE FROM ADMIN_ROLE
        WHERE AR_CODE = P_AR_CODE;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, '삭제 대상이 존재하지 않습니다.');
        END IF;
    END IF;
    --COMMIT;
END;

-- 5. 관리자 (강의실명) CUD
CREATE OR REPLACE PROCEDURE PRC_CL_CUD
(
     P_MODE IN VARCHAR2
    ,P_CL_CODE IN CLASS.CL_CODE%TYPE
    ,P_CL_NAME IN CLASS.CL_NAME%TYPE 
)
IS
    V_CL_CNT            NUMBER;
BEGIN
    
    IF P_MODE = 'C' THEN
        SELECT COUNT(*) INTO V_CL_CNT
        FROM CLASS
        WHERE CL_NAME = P_CL_NAME;
        
        IF V_CL_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, '중복이 존재합니다.');
        END IF;
        
        INSERT INTO CLASS(CL_CODE, CL_NAME)
        VALUES (P_CL_CODE, P_CL_NAME);
    
    ELSIF P_MODE = 'U' THEN
        -- 변경하려는 이름이 다른 코드에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_CL_CNT
        FROM CLASS
        WHERE CL_NAME = P_CL_NAME AND CL_CODE <> P_CL_CODE;
        
        IF V_CL_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, '이미 사용 중인 이름입니다.');
        END IF;
        
        UPDATE CLASS
        SET CL_NAME = P_CL_NAME
        WHERE CL_CODE = P_CL_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, '수정 대상이 존재하지 않습니다.');
        END IF;
        
    ELSIF P_MODE = 'D' THEN
        -- 강의실이 개설과정에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_CL_CNT
        FROM OPEN_COURSE
        WHERE CL_CODE = P_CL_CODE;

        IF V_CL_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, '사용 중인 강의실은 삭제할 수 없습니다.');
        END IF;
        
        DELETE FROM CLASS
        WHERE CL_CODE = P_CL_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, '삭제 대상이 존재하지 않습니다.');
        END IF;
    END IF;
    --COMMIT;
END;


-- 6. 관리자 (과목명) CUD
CREATE OR REPLACE PROCEDURE PRC_SUB_CUD
(
     P_MODE IN VARCHAR2
    ,P_SUB_CODE IN SUB.SUB_CODE%TYPE
    ,P_SUB_NAME IN SUB.SUB_NAME%TYPE DEFAULT NULL
)
IS
    V_SUB_CNT           NUMBER;
BEGIN
    
    IF P_MODE = 'C' THEN
        SELECT COUNT(*) INTO V_SUB_CNT
        FROM SUB
        WHERE SUB_NAME = P_SUB_NAME;
        
        IF V_SUB_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, '중복이 존재합니다.');
        END IF;
        
        INSERT INTO SUB(SUB_CODE, SUB_NAME)
        VALUES (P_SUB_CODE, P_SUB_NAME);
        
    ELSIF P_MODE = 'U' THEN
        -- 변경하려는 이름이 다른 코드에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_SUB_CNT
        FROM SUB
        WHERE SUB_NAME = P_SUB_NAME AND SUB_CODE <> P_SUB_CODE;
        
        IF V_SUB_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, '이미 사용 중인 이름입니다.');
        END IF;
        
        UPDATE SUB
        SET SUB_NAME = P_SUB_NAME
        WHERE SUB_CODE = P_SUB_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, '수정 대상이 존재하지 않습니다.');
        END IF;
        
    ELSIF P_MODE = 'D' THEN
        -- 과목이 개설과목에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_SUB_CNT
        FROM OPEN_SUB
        WHERE SUB_CODE = P_SUB_CODE;

        IF V_SUB_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, '사용 중인 과목은 삭제할 수 없습니다.');
        END IF;
        
        DELETE FROM SUB
        WHERE SUB_CODE = P_SUB_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, '삭제 대상이 존재하지 않습니다.');
        END IF;
    END IF;
    --COMMIT;
END;


-- 7. 관리자 (과정명) C
CREATE OR REPLACE PROCEDURE PRC_CR_CUD
(
     P_MODE IN VARCHAR2
    ,P_CR_CODE IN COURSE.CR_CODE%TYPE
    ,P_CR_NAME IN COURSE.CR_NAME%TYPE DEFAULT NULL
)
IS
    V_CR_CNT            NUMBER;
BEGIN
    
    IF P_MODE = 'C' THEN
        SELECT COUNT(*) INTO V_CR_CNT
        FROM COURSE
        WHERE CR_NAME = P_CR_NAME;
        
        IF V_CR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, '중복이 존재합니다.');
        END IF;
        
        INSERT INTO COURSE(CR_CODE, CR_NAME)
        VALUES (P_CR_CODE, P_CR_NAME);
    END IF;
    --COMMIT;
END;


-- 8. 관리자 (과정명) UD
CREATE OR REPLACE PROCEDURE PRC_CR_CUD
(
     P_MODE IN VARCHAR2
    ,P_CR_CODE IN COURSE.CR_CODE%TYPE
    ,P_CR_NAME IN COURSE.CR_NAME%TYPE DEFAULT NULL
)
IS
    V_CR_CNT            NUMBER;
BEGIN
        
    IF P_MODE = 'U' THEN
        -- 변경하려는 이름이 다른 코드에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_CR_CNT
        FROM COURSE
        WHERE CR_NAME = P_CR_NAME AND CR_CODE <> P_CR_CODE;
        
        IF V_CR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, '이미 사용 중인 이름입니다.');
        END IF;
        
        UPDATE COURSE
        SET CR_NAME = P_CR_NAME
        WHERE CR_CODE = P_CR_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, '수정 대상이 존재하지 않습니다.');
        END IF;
        
    ELSIF P_MODE = 'D' THEN
        -- 과정이 개설과정에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_CR_CNT
        FROM OPEN_COURSE
        WHERE CR_CODE = P_CR_CODE;

        IF V_CR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, '사용 중인 과정은 삭제할 수 없습니다.');
        END IF;
        
        DELETE FROM COURSE
        WHERE CR_CODE = P_CR_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, '삭제 대상이 존재하지 않습니다.');
        END IF;
    END IF;
    --COMMIT;
END;

-- 9. 관리자 (탈락사유) CUD
CREATE OR REPLACE PROCEDURE PRC_DR_CUD
(
     P_MODE IN VARCHAR2
    ,P_DR_CODE IN DROP_REASON.DR_CODE%TYPE
    ,P_DR_REASON IN DROP_REASON.DR_REASON%TYPE DEFAULT NULL
)
IS
    V_DR_CNT            NUMBER;
BEGIN
    
    IF P_MODE = 'C' THEN
        SELECT COUNT(*) INTO V_DR_CNT
        FROM DROP_REASON
        WHERE DR_REASON = P_DR_REASON;
        
        IF V_DR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, '중복이 존재합니다.');
        END IF;
        
        INSERT INTO DROP_REASON(DR_CODE, DR_REASON)
        VALUES (P_DR_CODE, P_DR_REASON);
        
    ELSIF P_MODE = 'U' THEN
        -- 변경하려는 사유가 다른 코드에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_DR_CNT
        FROM DROP_REASON
        WHERE DR_REASON = P_DR_REASON AND DR_CODE <> P_DR_CODE;
        
        IF V_DR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, '이미 사용 중인 사유입니다.');
        END IF;
        
        UPDATE DROP_REASON
        SET DR_REASON = P_DR_REASON
        WHERE DR_CODE = P_DR_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, '수정 대상이 존재하지 않습니다.');
        END IF;
        
    ELSIF P_MODE = 'D' THEN
        -- 탈락코드가 중도탈락에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_DR_CNT
        FROM DROP_OUT
        WHERE DR_CODE = P_DR_CODE;

        IF V_DR_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, '사용 중인 탈락사유는 삭제할 수 없습니다.');
        END IF;
        
        DELETE FROM DROP_REASON
        WHERE DR_CODE = P_DR_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, '삭제 대상이 존재하지 않습니다.');
        END IF;
    END IF;
    --COMMIT;
END;


-- 10. 관리자 (교재명) CUD
CREATE OR REPLACE PROCEDURE PRC_TB_CUD
(
     P_MODE IN VARCHAR2
    ,P_TB_CODE IN TEXTBOOK.TB_CODE%TYPE
    ,P_TB_NAME IN TEXTBOOK.TB_NAME%TYPE DEFAULT NULL
)
IS
    V_TB_CNT            NUMBER;
BEGIN
    
    IF P_MODE = 'C' THEN
        SELECT COUNT(*) INTO V_TB_CNT
        FROM TEXTBOOK
        WHERE TB_NAME = P_TB_NAME;
        
        IF V_TB_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, '중복이 존재합니다.');
        END IF;
        
        INSERT INTO TEXTBOOK(TB_CODE, TB_NAME)
        VALUES (P_TB_CODE, P_TB_NAME);
        
    ELSIF P_MODE = 'U' THEN
        -- 변경하려는 이름이 다른 코드에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_TB_CNT
        FROM TEXTBOOK
        WHERE TB_NAME = P_TB_NAME AND TB_CODE <> P_TB_CODE;
        
        IF V_TB_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, '이미 사용 중인 이름입니다.');
        END IF;
        
        UPDATE TEXTBOOK
        SET TB_NAME = P_TB_NAME
        WHERE TB_CODE = P_TB_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, '수정 대상이 존재하지 않습니다.');
        END IF;
        
    ELSIF P_MODE = 'D' THEN
        -- 교재가 개설과목에서 사용 중인지 확인
        SELECT COUNT(*) INTO V_TB_CNT
        FROM OPEN_SUB
        WHERE TB_CODE = P_TB_CODE;

        IF V_TB_CNT > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, '사용 중인 교재는 삭제할 수 없습니다.');
        END IF;
        
        DELETE FROM TEXTBOOK
        WHERE TB_CODE = P_TB_CODE;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, '삭제 대상이 존재하지 않습니다.');
        END IF;
    END IF;
    --COMMIT;
END;

--=======================================================
--===================안진모[11 ~ 13]===========================
--최종관리자
--관리자아이디, 이름, 주민번호, 등록일자, 등급코드
--관리자아이디, 비밀번호, 등급코드
--관리자아이디

--최종 관리자 생성
CREATE SEQUENCE SEQ_ADMIN
START WITH 100
NOCACHE;

-- 관리자의 등급은 화면에 한글로 표기되어 선택
CREATE OR REPLACE PROCEDURE PRC_AD_C
(
 P_NAME  ADMIN.AD_NAME%TYPE
,P_SSN   ADMIN.AD_SSN%TYPE
,P_GRADE ADMIN_ROLE.AR_CODE%TYPE   
)
IS
    V_PW ADMIN.AD_PW%TYPE;
BEGIN
    V_PW := SUBSTR(P_SSN,8);
    
    
    INSERT INTO ADMIN(AD_ID,AD_PW,AD_NAME,AD_SSN,AR_CODE)
    VALUES (TO_CHAR(SEQ_ADMIN.NEXTVAL,'AD999'),V_PW,P_NAME,P_SSN,P_GRADE);
END;

--최종 관리자 수정
CREATE OR REPLACE PROCEDURE PRC_AD_U
(
 P_ID     ADMIN.AD_ID%TYPE
,P_NAME   ADMIN.AD_NAME%TYPE
,P_SSN    ADMIN.AD_SSN%TYPE
,P_PW     ADMIN.AD_PW%TYPE
,P_GRADE  ADMIN_ROLE.AR_CODE%TYPE   
)
IS
    V_GRADE ADMIN_ROLE.AR_CODE%TYPE;
    V_NUM NUMBER;
    USER_ERROR EXCEPTION; -- 역할별 한명만 남아있는 관리자를 변경하려할때
BEGIN
    
    SELECT AR_CODE INTO V_GRADE
    FROM ADMIN
    WHERE AD_ID = P_ID;
    
    SELECT COUNT(*) INTO V_NUM
    FROM ADMIN
    WHERE AR_CODE = V_GRADE;
    
    IF V_NUM = 1 AND V_GRADE != P_GRADE
        THEN RAISE USER_ERROR;
    END IF;
    
    UPDATE ADMIN
    SET AD_NAME = P_NAME, AD_SSN = P_SSN, AD_PW = P_PW
       ,AR_CODE = P_GRADE
    WHERE AD_ID = P_ID;
    
    EXCEPTION
        WHEN USER_ERROR
            THEN RAISE_APPLICATION_ERROR(-20014,'등급별 최소 한명의 관리자가 필요합니다');
    
END;

--최종관리자 삭제
CREATE OR REPLACE PROCEDURE PRC_AD_D
(
P_ID ADMIN.AD_ID%TYPE
)
IS
    V_GRADE ADMIN_ROLE.AR_CODE%TYPE;
    V_NUM NUMBER;
    USER_ERROR EXCEPTION;   -- 역할별 한명만 남아있는 관리자를 삭제하려할때
BEGIN
    SELECT AR_CODE INTO V_GRADE
    FROM ADMIN
    WHERE AD_ID = P_ID;
    
    SELECT COUNT(*) INTO V_NUM
    FROM ADMIN
    WHERE AR_CODE = V_GRADE;
    
    IF (V_NUM = 1)
        THEN RAISE USER_ERROR;
    END IF;

    DELETE
    FROM ADMIN
    WHERE AD_ID = P_ID;
    
    EXCEPTION
        WHEN USER_ERROR
            THEN RAISE_APPLICATION_ERROR(-20014,'등급별 최소 한명의 관리자가 필요합니다');

END;



--======================================================
--============ 임유훤 [14~16]============================
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
            ROLLBACK;
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
--===========================================================================
--================= 강명철 [17 ~ 22]==========================================

--========================================================
--=========== 안진모 [23~28]===============================
-- 함수
-- 개설과목

-- 포함된 개설과정내에 맞는 일시를 입력했는지 확인하는 함수
--(개설과정코드,시작일시,종료일시)
-- 1실패 0성공 함수
CREATE OR REPLACE FUNCTION FN_OS_D 
(
 P_OCCODE   OPEN_SUB.OC_CODE%TYPE
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
)
RETURN NUMBER
IS
    V_RESULT NUMBER := 0;
    V_START  OPEN_COURSE.OC_SDATE%TYPE;
    V_END    OPEN_COURSE.OC_EDATE%TYPE;
BEGIN
  
    SELECT OC_SDATE,OC_EDATE INTO V_START,V_END
    FROM OPEN_COURSE
    WHERE OC_CODE = P_OCCODE;

    IF (V_START > P_START OR V_END < P_END) OR P_START > P_END
        THEN V_RESULT := 1;
    END IF;
    RETURN V_RESULT;
END;

-----
-- 중복체크 
-- 과정별 교육일 중복 확인 함수
-- (개설과정코드,시작일시,종료일시)
-- 1실패 0성공 함수
-- 등록
CREATE OR REPLACE FUNCTION FN_OS_J1
(
 P_OCCODE   OPEN_SUB.OC_CODE%TYPE
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
)
RETURN NUMBER
IS
    CURSOR CUR_OS
    IS
    SELECT OS_SDATE,OS_EDATE
    FROM OPEN_SUB
    WHERE OC_CODE = P_OCCODE;
    V_RESULT NUMBER := 0;
BEGIN
    FOR REC IN CUR_OS LOOP
        IF (P_START <= REC.OS_EDATE AND P_END >= REC.OS_SDATE)
            THEN V_RESULT := 1;
            EXIT;
        END IF;
    END LOOP;
    RETURN V_RESULT;
END;
-- 수정
CREATE OR REPLACE FUNCTION FN_OS_J2
(
 P_OSCODE   OPEN_SUB.OC_CODE%TYPE
,P_OCCODE   OPEN_SUB.OC_CODE%TYPE
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
)
RETURN NUMBER
IS
    CURSOR CUR_OS
    IS
    SELECT OS_SDATE,OS_EDATE
    FROM OPEN_SUB
    WHERE OC_CODE = P_OCCODE
    AND NOT OS_CODE = P_OSCODE;
    V_RESULT NUMBER := 0;
BEGIN
    FOR REC IN CUR_OS LOOP
        IF (P_START <= REC.OS_EDATE AND P_END >= REC.OS_SDATE)
            THEN V_RESULT := 1;
            EXIT;
        END IF;
    END LOOP;
    RETURN V_RESULT;
END;

-----
-- 교수의 강의 일자 중복 확인 함수
-- (교수아이디,시작일시,종료일시)
-- 1실패 0성공 함수
-- 등록
CREATE OR REPLACE FUNCTION FN_OS_G1
(
 P_PFID     OPEN_SUB.PF_ID%TYPE
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
)
RETURN NUMBER
IS
    CURSOR CUR_OSS
    IS
    SELECT OS_SDATE,OS_EDATE
    FROM OPEN_SUB
    WHERE PF_ID = P_PFID;
    V_RESULT NUMBER := 0;
BEGIN
    FOR REC IN CUR_OSS LOOP
        IF (P_START <= REC.OS_EDATE AND P_END >= REC.OS_SDATE)
            THEN V_RESULT := 1;
            EXIT;
        END IF;
    END LOOP;
    RETURN V_RESULT;
END;
-- 수정
CREATE OR REPLACE FUNCTION FN_OS_G2
(
 P_OSCODE   OPEN_SUB.OC_CODE%TYPE
,P_PFID     OPEN_SUB.PF_ID%TYPE
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
)
RETURN NUMBER
IS
    CURSOR CUR_OSS
    IS
    SELECT OS_SDATE,OS_EDATE
    FROM OPEN_SUB
    WHERE PF_ID = P_PFID
    AND NOT OS_CODE = P_OSCODE;
    V_RESULT NUMBER := 0;
BEGIN
    FOR REC IN CUR_OSS LOOP
        IF (P_START <= REC.OS_EDATE AND P_END >= REC.OS_SDATE)
            THEN V_RESULT := 1;
            EXIT;
        END IF;
    END LOOP;
    RETURN V_RESULT;
END;
---------------------------------

-- 관리자 개설과목 등록
CREATE SEQUENCE SEQ_OPEN_SUB
START WITH 1
NOCACHE;

CREATE OR REPLACE PROCEDURE PRC_OS_C -- 배점 안받는 상태
(
 P_OCCODE   OPEN_SUB.OC_CODE%TYPE
,P_PFID     OPEN_SUB.PF_ID%TYPE
,P_SUBCODE  OPEN_SUB.SUB_CODE%TYPE  
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
,P_TBCODE   OPEN_SUB.TB_CODE%TYPE 
)
IS
    USER_ERROR1 EXCEPTION; -- 과정내 포함되는 기간이아니면 에러
    USER_ERROR2 EXCEPTION; -- 과목 일시가 중복 되면 에러
    USER_ERROR3 EXCEPTION; -- 교수 일정이 중복되면에러
BEGIN
    
    -- 상의 개설강의내 포함 일자인지 확인
    IF FN_OS_D(P_OCCODE,P_START,P_END) = 1
        THEN RAISE USER_ERROR1;
    -- 과목 일정 중복 확인
    ELSIF FN_OS_J1(P_OCCODE,P_START,P_END) = 1
        THEN RAISE USER_ERROR2;
    --교수자 중복 확인
    ELSIF FN_OS_G1(P_PFID,P_START,P_END) = 1
        THEN RAISE USER_ERROR3;
    END IF;
    
    INSERT INTO OPEN_SUB(OS_CODE,OC_CODE,SUB_CODE,PF_ID,OS_SDATE
                         ,OS_EDATE,TB_CODE)
    VALUES(TO_CHAR(SEQ_OPEN_SUB.NEXTVAL,'OS999'),P_OCCODE,P_SUBCODE
          ,P_PFID,P_START,P_END,P_TBCODE);
    
    EXCEPTION
        WHEN USER_ERROR1
            THEN RAISE_APPLICATION_ERROR(-20015,'개설과정내 일시를 입력해주세요');
        WHEN USER_ERROR2
            THEN RAISE_APPLICATION_ERROR(-20016,'기존 등록된 과목과 강의 일자가 겹칠수 없습니다');
        WHEN USER_ERROR3
            THEN RAISE_APPLICATION_ERROR(-20017,'교수자는 한개의 강의만 가능합니다');
END;

-- 관리자 개설과목 수정
CREATE OR REPLACE PROCEDURE PRC_OS_U
(
 P_OSCODE   OPEN_SUB.OS_CODE%TYPE
,P_OCCODE   OPEN_SUB.OC_CODE%TYPE
,P_SUBCODE  OPEN_SUB.SUB_CODE%TYPE
,P_PFID     OPEN_SUB.PF_ID%TYPE
,P_START    OPEN_SUB.OS_SDATE%TYPE
,P_END      OPEN_SUB.OS_EDATE%TYPE
,P_TBCODE   OPEN_SUB.TB_CODE%TYPE
)
IS
    USER_ERROR1 EXCEPTION; -- 과정내 포함되는 기간이아니면 에러
    USER_ERROR2 EXCEPTION; -- 과목 일시가 중복 되면 에러
    USER_ERROR3 EXCEPTION; -- 교수 일정이 중복되면에러
BEGIN
        
    -- 상의 개설강의내 포함 일자인지 확인
    IF FN_OS_D(P_OCCODE,P_START,P_END) = 1
        THEN RAISE USER_ERROR1;
    -- 과목 일정 중복 확인
    ELSIF FN_OS_J2(P_OSCODE,P_OCCODE,P_START,P_END) = 1
        THEN RAISE USER_ERROR2;
    --교수자 중복 확인
    ELSIF FN_OS_G2(P_OSCODE,P_PFID,P_START,P_END) = 1
        THEN RAISE USER_ERROR3;
    END IF;

    UPDATE OPEN_SUB
    SET OC_CODE = P_OCCODE, SUB_CODE = P_SUBCODE, PF_ID = P_PFID
       ,OS_SDATE = P_START, OS_EDATE = P_END, TB_CODE = P_TBCODE
    WHERE OS_CODE = P_OSCODE;
    
     EXCEPTION
        WHEN USER_ERROR1
            THEN RAISE_APPLICATION_ERROR(-20015,'개설과정내 일시를 입력해주세요');
        WHEN USER_ERROR2
            THEN RAISE_APPLICATION_ERROR(-20016,'기존 등록된 과목과 강의 일자가 겹칠수 없습니다');
        WHEN USER_ERROR3
            THEN RAISE_APPLICATION_ERROR(-20017,'교수자는 한개의 강의만 가능합니다');
END;

-- 관리자,교수 배점 등록
CREATE OR REPLACE PROCEDURE PRC_OS_UB
(
 P_OCCODE OPEN_SUB.OC_CODE%TYPE
,P_ATT  OPEN_SUB.ATT_WEIGHT%TYPE
,P_WRT  OPEN_SUB.WRT_WEIGHT%TYPE
,P_PRC  OPEN_SUB.PRC_WEIGHT%TYPE
)
IS
    USER_ERROR EXCEPTION;   -- 배점총합이 100이 아닌 경우 에러
BEGIN
    
    IF (P_ATT+P_WRT+P_PRC != 100)
        THEN RAISE USER_ERROR;
    END IF;
    
    UPDATE OPEN_SUB
    SET ATT_WEIGHT = P_ATT,WRT_WEIGHT = P_WRT
       ,PRC_WEIGHT = P_PRC
    WHERE OC_CODE = P_OCCODE;
    
    EXCEPTION
        WHEN USER_ERROR
            THEN RAISE_APPLICATION_ERROR(-20018,'배점의 배율이 100이 되지않아 입력할 수 없습니다');
                 
       
END;

-- 개설 과목 삭제
CREATE OR REPLACE PROCEDURE PRC_OS_D
(
P_OSCODE OPEN_SUB.OS_CODE%TYPE
)
IS
    USER_ERROR EXCEPTION;   -- 삭제하려는 개설과목이 이미 시작됐으면 에러
    V_DATE OPEN_SUB.OS_SDATE%TYPE;
BEGIN
    SELECT OS_SDATE INTO V_DATE
    FROM OPEN_SUB
    WHERE OS_CODE = P_OSCODE;
    
    -- 개설과목일 확인
    IF (SYSDATE > V_DATE)
        THEN RAISE USER_ERROR;
    END IF;
    
    DELETE 
    FROM OPEN_SUB
    WHERE OS_CODE = P_OSCODE;
    
    EXCEPTION
        WHEN USER_ERROR
            THEN RAISE_APPLICATION_ERROR(-20019,'과목 개설 시작일이 지나 삭제할 수 없습니다');
                 --ROLLBACK;
END;

-- 중도탈락 생성
CREATE SEQUENCE SEQ_DROPOUT
START WITH 1
NOCACHE;

CREATE OR REPLACE PROCEDURE PRC_DO_C
(
 P_ERCODE    DROP_OUT.ER_CODE%TYPE
,P_DODATE    DROP_OUT.DO_DATE%TYPE
,P_DRCODE    DROP_OUT.DR_CODE%TYPE
)
IS
BEGIN
    INSERT INTO DROP_OUT(DO_CODE,ER_CODE,DO_DATE,DR_CODE)
    VALUES(TO_CHAR(SEQ_DROPOUT.NEXTVAL,'DO999'),P_ERCODE
          ,P_DODATE,P_DRCODE);
END;

-- 중도탈락 수정
CREATE OR REPLACE PROCEDURE PRC_DO_U
(
 P_DOCODE   DROP_OUT.DO_CODE%TYPE
,P_ERCODE   DROP_OUT.ER_CODE%TYPE
,P_DODATE   DROP_OUT.DO_DATE%TYPE
,P_DRCODE   DROP_OUT.DR_CODE%TYPE
)
IS
BEGIN
    UPDATE DROP_OUT
    SET ER_CODE = P_ERCODE, DO_DATE = P_DODATE, DR_CODE = P_DRCODE
    WHERE DO_CODE = P_DOCODE;
END;


-- 중도탈락 삭제
CREATE OR REPLACE PROCEDURE PRC_DO_D
(
P_DOCODE   DROP_OUT.DO_CODE%TYPE
)
IS
BEGIN
    DELETE
    FROM DROP_OUT
    WHERE DO_CODE = P_DOCODE;
END;


--=========================================================================================
--======================유훤[29 ~ 31]===================================
CREATE SEQUENCE GR_SEQ
INCREMENT BY 1
START WITH 003
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

--=====================================================================================================
--======================명철[32~34]========================================


