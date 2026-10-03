-- Fix for "Security Definer View" vulnerability
-- This ensures views execute with the permissions of the querying user (invoker)
-- rather than the view owner, respecting Row Level Security (RLS) policies on underlying tables.
-- Fix workout_details view
CREATE OR REPLACE VIEW workout_details WITH (security_invoker = true) AS
SELECT 
    w.id,
    w.user_id,
    w.name,
    w.category,
    w.description,
    w.is_active,
    w.created_at,
    w.updated_at,
    COUNT(we.id) as exercise_count,
    ARRAY_AGG(
        JSON_BUILD_OBJECT(
            'exercise_id', e.id,
            'exercise_name', e.name,
            'category', e.category,
            'sets', we.sets,
            'reps', we.reps,
            'weight_kg', we.weight_kg,
            'order', we.exercise_order
        ) ORDER BY we.exercise_order
    ) as exercises
FROM workouts w
LEFT JOIN workout_exercises we ON w.id = we.workout_id
LEFT JOIN exercises e ON we.exercise_id = e.id
GROUP BY w.id, w.user_id, w.name, w.category, w.description, w.is_active, w.created_at, w.updated_at;

-- Fix workout_history view
CREATE OR REPLACE VIEW workout_history WITH (security_invoker = true) AS
SELECT 
    ws.id,
    ws.user_id,
    ws.workout_name,
    ws.start_time,
    ws.end_time,
    ws.duration_minutes,
    ws.rating,
    ws.completed,
    COUNT(wse.id) as exercises_completed,
    SUM(CASE WHEN wse.completed THEN 1 ELSE 0 END) as exercises_finished
FROM workout_sessions ws
LEFT JOIN workout_session_exercises wse ON ws.id = wse.session_id
GROUP BY ws.id, ws.user_id, ws.workout_name, ws.start_time, ws.end_time, ws.duration_minutes, ws.rating, ws.completed
ORDER BY ws.start_time DESC;

