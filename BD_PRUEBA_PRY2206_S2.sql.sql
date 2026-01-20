SHOW USER;

--VARIABLE BIND PARA FECHA DE PROCESO

VARIABLE b_fecha_proceso DATE
EXEC :b_fecha_proceso := SYSDATE;


--BLOQUE PL/SQL 

DECLARE
--Variables de control 
    v_total_emp     NUMBER;
    v_contador      NUMBER := 0;

--Variables con %TYPE 
    v_id_emp        empleado.id_emp%TYPE;
    v_run           empleado.run_emp%TYPE;
    v_dv            empleado.dv_run%TYPE;
    v_nombre        empleado.nombre_emp%TYPE;
    v_apellido      empleado.apellido_emp%TYPE;
    v_estado        empleado.estado_civil%TYPE;
    v_sueldo        empleado.sueldo_base%TYPE;
    v_fec_nac       empleado.fecha_nac%TYPE;
    v_fec_ing       empleado.fecha_ingreso%TYPE;

--Variables de trabajo
    v_usuario       VARCHAR2(50);
    v_clave         VARCHAR2(100);
    v_anios         NUMBER;
    v_letras_ape    VARCHAR2(2);

BEGIN
--Limpiar tabla 
    EXECUTE IMMEDIATE 'TRUNCATE TABLE usuario_clave';

--Total de empleados a procesar
    SELECT COUNT(*)
    INTO v_total_emp
    FROM empleado
    WHERE id_emp BETWEEN 100 AND 320;

--Ciclo principal
    FOR e IN (
        SELECT *
        FROM empleado
        WHERE id_emp BETWEEN 100 AND 320
        ORDER BY id_emp
    ) LOOP

--Asignación de datos
        v_id_emp   := e.id_emp;
        v_run      := e.run_emp;
        v_dv       := e.dv_run;
        v_nombre   := e.nombre_emp;
        v_apellido := e.apellido_emp;
        v_estado   := e.estado_civil;
        v_sueldo   := e.sueldo_base;
        v_fec_nac  := e.fecha_nac;
        v_fec_ing  := e.fecha_ingreso;

--Cálculo de años trabajados
        v_anios := TRUNC(MONTHS_BETWEEN(:b_fecha_proceso, v_fec_ing) / 12);

--Construcción del usuario
        v_usuario := LOWER(SUBSTR(v_estado,1,1)) || LOWER(SUBSTR(v_nombre,1,3)) || LENGTH(v_nombre) || '*' || SUBSTR(v_sueldo,-1) || v_dv || v_anios;

        IF v_anios < 10 THEN
            v_usuario := v_usuario || 'X';
        END IF;

--Letras del apellido según estado civil
        IF v_estado IN ('CASADO','ACUERDO') THEN
            v_letras_ape := LOWER(SUBSTR(v_apellido,1,2));
        ELSIF v_estado IN ('SOLTERO','DIVORCIADO') THEN
            v_letras_ape := LOWER(SUBSTR(v_apellido,1,1) || SUBSTR(v_apellido,-1));
        ELSIF v_estado = 'VIUDO' THEN
            v_letras_ape := LOWER(SUBSTR(v_apellido,-3,2));
        ELSE
            v_letras_ape := LOWER(SUBSTR(v_apellido,-2));
        END IF;

--Construcción de la clave 
        v_clave := SUBSTR(v_run,3,1) || (EXTRACT(YEAR FROM v_fec_nac) + 2) || LPAD(SUBSTR(v_sueldo,-3) - 1, 3, '0') || v_letras_ape || v_id_emp || TO_CHAR(:b_fecha_proceso,'MMYYYY');

--Inserción en tabla USUARIO_CLAVE
        INSERT INTO usuario_clave
        VALUES (v_id_emp, v_run || '-' || v_dv, v_nombre || ' ' || v_apellido, v_usuario, v_clave);

        v_contador := v_contador + 1;

    END LOOP;

--Control de transacción
    IF v_contador = v_total_emp THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
/
