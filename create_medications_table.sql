-- Tabla para medicamentos
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT,
    frequency TEXT,
    time TEXT, -- Hora principal del recordatorio (ej: '08:00')
    reminder_times TEXT[], -- Ejemplo: ['08:00', '20:00']
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Users can view own medications" ON public.medications
    FOR SELECT USING (auth.uid() = user_id OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Users can insert own medications" ON public.medications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own medications" ON public.medications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own medications" ON public.medications
    FOR DELETE USING (auth.uid() = user_id);
