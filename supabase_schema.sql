-- Création de la table game_records
CREATE TABLE game_records (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users NOT NULL,
  hero text NOT NULL,
  mode text NOT NULL,
  score integer NOT NULL,
  enemies_defeated integer NOT NULL,
  health_remaining integer NOT NULL,
  boss_health_remaining integer,
  duration_ms integer NOT NULL,
  is_victory boolean NOT NULL,
  played_at timestamp with time zone NOT NULL
);

-- Active RLS (Row Level Security)
ALTER TABLE game_records ENABLE ROW LEVEL SECURITY;

-- Politique de sélection : l'utilisateur ne peut lire que ses propres parties
CREATE POLICY "Users can view their own game records" 
ON game_records FOR SELECT 
USING (auth.uid() = user_id);

-- Politique d'insertion : l'utilisateur ne peut insérer que pour lui-même
CREATE POLICY "Users can insert their own game records" 
ON game_records FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Politique de suppression : l'utilisateur ne peut supprimer que ses propres parties
CREATE POLICY "Users can delete their own game records" 
ON game_records FOR DELETE 
USING (auth.uid() = user_id);
