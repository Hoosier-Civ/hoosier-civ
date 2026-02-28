-- Migration: drop_representatives
-- The representatives table was designed for the Google Civic Info API,
-- which has been replaced by the Cicero integration.
-- Official data now lives in cicero_officials + zip_cicero_officials.

drop table public.representatives;
