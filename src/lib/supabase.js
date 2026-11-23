import { createClient } from '@supabase/supabase-js'

// trim: ignora espaços ou tabulações coladas sem querer no Vercel / .env
const url = import.meta.env.VITE_SUPABASE_URL?.trim()
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY?.trim()

if (!url || !anonKey) {
  throw new Error(
    'Configure VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no arquivo .env.local (veja .env.example).',
  )
}

export const supabase = createClient(url, anonKey)
