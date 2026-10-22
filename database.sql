-- ==============================================================================
-- DDL POSTGRESQL PARA SUPABASE: GESTIÓN DE TURNOS DE LABORATORIOS DE SISTEMAS
-- ==============================================================================
-- Tabla: reservas_laboratorio
-- Descripción: Almacena las reservas de turnos estudiantiles en laboratorios de cómputo.
-- ==============================================================================

-- 1. Crear extensión para generación de identificadores UUID (por defecto en Supabase)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Creación de la tabla reservas_laboratorio
CREATE TABLE IF NOT EXISTS public.reservas_laboratorio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estudiante VARCHAR(150) NOT NULL,
    codigo VARCHAR(9) NOT NULL,
    laboratorio VARCHAR(100) NOT NULL,
    fecha_reserva DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,

    -- Restricción: el código estudiantil debe contener exactamente 9 dígitos numéricos
    CONSTRAINT check_codigo_estudiantil_9_digitos 
        CHECK (codigo ~ '^[0-9]{9}$'),

    -- Restricción: la fecha de reserva no puede ser anterior a la fecha actual del servidor
    CONSTRAINT check_fecha_reserva_valida 
        CHECK (fecha_reserva >= CURRENT_DATE),

    -- Restricción de unicidad: No permitir reservas duplicadas en el mismo laboratorio, fecha y hora
    CONSTRAINT uq_reserva_laboratorio_fecha_hora 
        UNIQUE (laboratorio, fecha_reserva, hora_inicio)
);

-- Comentarios explicativos en las columnas
COMMENT ON TABLE public.reservas_laboratorio IS 'Registro de turnos para los laboratorios de ingeniería de sistemas';
COMMENT ON COLUMN public.reservas_laboratorio.id IS 'Identificador único UUID de la reserva';
COMMENT ON COLUMN public.reservas_laboratorio.estudiante IS 'Nombre completo del estudiante';
COMMENT ON COLUMN public.reservas_laboratorio.codigo IS 'Código institucional único de 9 dígitos';
COMMENT ON COLUMN public.reservas_laboratorio.laboratorio IS 'Nombre o identificador del laboratorio de cómputo';
COMMENT ON COLUMN public.reservas_laboratorio.fecha_reserva IS 'Fecha en que se llevará a cabo el turno';
COMMENT ON COLUMN public.reservas_laboratorio.hora_inicio IS 'Hora exacta de inicio de la sesión de laboratorio';
COMMENT ON COLUMN public.reservas_laboratorio.creado_en IS 'Marca temporal UTC de registro de la transacción';

-- 3. Índices de alto rendimiento para consultas concurrentes
CREATE INDEX IF NOT EXISTS idx_reservas_lab_fecha_hora 
    ON public.reservas_laboratorio (laboratorio, fecha_reserva, hora_inicio);

CREATE INDEX IF NOT EXISTS idx_reservas_codigo_estudiante 
    ON public.reservas_laboratorio (codigo);

CREATE INDEX IF NOT EXISTS idx_reservas_fecha_reserva 
    ON public.reservas_laboratorio (fecha_reserva DESC);

-- 4. Seguridad a nivel de filas (Row Level Security - RLS)
ALTER TABLE public.reservas_laboratorio ENABLE ROW LEVEL SECURITY;

-- 4.1 Permitir lectura pública (anon y authenticated) para verificar disponibilidad y turnos
CREATE POLICY "Lectura pública de reservas de laboratorio"
    ON public.reservas_laboratorio
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- 4.2 Permitir inserción validada desde la aplicación cliente
CREATE POLICY "Inserción permitida para estudiantes anónimos o autenticados"
    ON public.reservas_laboratorio
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (
        length(trim(estudiante)) >= 3
        AND codigo ~ '^[0-9]{9}$'
        AND fecha_reserva >= CURRENT_DATE
        AND length(trim(laboratorio)) > 0
    );

-- 4.3 Opcional: Habilitar Realtime para suscripciones en vivo en Supabase
-- (Ejecutar en Supabase SQL Editor si deseas suscripciones WebSocket activas)
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservas_laboratorio;
