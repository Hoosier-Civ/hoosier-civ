-- Seed data for local development
-- Run automatically by `supabase db reset` or `supabase start`

-- ============================================================
-- Missions
-- ============================================================
insert into public.missions (id, title, description, category, xp_reward, completion_type, badge_awarded, streak_eligible, difficulty, phase) values
  ('call-legislator',       'Call Your Legislator',      'Pick from pre-written talking points and call your Indiana legislator about a bill that matters to you.',                                'Legislative', 20, 'self_report',   'First Call',    true,  'hard',   1),
  ('check-voter-reg',       'Check Voter Registration',  'Confirm your voter registration status or update your info via the Indiana Secretary of State portal.',                                  'Voting',      10, 'api_verified',  null,            true,  'easy',   1),
  ('voter-sticker',         'Mini Voter Challenge',      'Snap a photo of your "I Voted" sticker on election day to earn 25 XP and the Voter Verified badge!',                                    'Voting',      25, 'photo_upload',  'Voter Verified', true, 'hard',   1),
  ('bill-quiz',             'Bill Quiz',                 'Answer 3 questions about a current Indiana bill to earn XP and unlock the Informed Advocate badge.',                                    'Legislative', 15, 'quiz',          'Informed Advocate', true, 'medium', 1),
  ('email-legislator',      'Email Your Legislator',     'Send a one-click pre-written email to your Indiana legislator about a bill affecting your community.',                                   'Legislative', 15, 'self_report',   null,            true,  'medium', 2),
  ('social-share',          'Share a Civic Message',     'Share a pre-written message about an Indiana bill via the native share sheet. No specific platform required.',                           'Legislative', 10, 'self_report',   null,            false, 'easy',   2),
  ('voting-reminder',       'Set a Voting Reminder',     'Add an election day or absentee ballot deadline reminder to your calendar so you never miss a chance to vote.',                          'Voting',       5, 'self_report',   null,            false, 'easy',   2),
  ('attend-town-hall',      'Attend a Town Hall',        'Check in at a local city council or district meeting to earn XP and connect directly with your community leaders.',                      'Community',   25, 'gps_checkin',   null,            true,  'hard',   2),
  ('micro-lesson',          'Civic Micro-Lesson',        'Complete a short interactive lesson about Indiana government, your district, or state laws.',                                            'Education',   10, 'quiz',          null,            true,  'easy',   2),
  ('matching-game',         'Lawmaker Matching Game',    'Match Indiana lawmakers to their district, committee, or sponsored bill to level up your civic knowledge.',                              'Education',   10, 'quiz',          null,            true,  'easy',   2),
  ('volunteer-task',        'Volunteer in Your Community','Complete a 1–2 hour local volunteer opportunity and check in to earn XP and strengthen your neighborhood.',                             'Community',   30, 'self_report',   null,            true,  'hard',   3),
  ('neighborhood-challenge','Neighborhood Challenge',    'Complete a civic micro-quest in your neighborhood — like meeting a neighbor running for local office.',                                   'Community',   25, 'self_report',   null,            true,  'hard',   3),
  ('fact-check',            'Civic Fact Check',          'Test your knowledge about Indiana policies and bust some common civic myths.',                                                           'Education',   15, 'quiz',          null,            true,  'medium', 3);

-- ============================================================
-- Badges
-- ============================================================
insert into public.badges (id, name, description, icon_asset, phase) values
  ('first-call',            'First Call',             'Made your first call to an Indiana legislator.',                                    'assets/badges/first_call.png',            1),
  ('voter-verified',        'Voter Verified',         'Proved you voted by snapping your "I Voted" sticker on election day.',              'assets/badges/voter_verified.png',        1),
  ('informed-advocate',     'Informed Advocate',      'Completed a Bill Quiz after reading the latest news on a bill.',                    'assets/badges/informed_advocate.png',     1),
  ('3-day-streak',          '3-Day Streak',           'Completed at least one mission every day for 3 days in a row.',                    'assets/badges/streak_3.png',              1),
  ('civic-rookie',          'Civic Rookie',           'Reached Level 5. You''re just getting started, Hoosier!',                         'assets/badges/civic_rookie.png',          1),
  ('civic-regular',         'Civic Regular',          'Reached Level 10. You''re becoming a Hoosier civic hero.',                        'assets/badges/civic_regular.png',         2),
  ('civic-leader',          'Civic Leader',           'Reached Level 15. Indiana democracy is better because of you.',                   'assets/badges/civic_leader.png',          2),
  ('civic-champ',           'Civic Champ',            'Reached Level 20 — the max level. You are HoosierCiv.',                          'assets/badges/civic_champ.png',           2),
  ('week-warrior',          'Week Warrior',           'Completed at least one mission every day for 7 days in a row.',                   'assets/badges/week_warrior.png',          2),
  ('town-hall-hero',        'Town Hall Hero',         'Attended 3 town hall meetings. You show up when it counts.',                      'assets/badges/town_hall_hero.png',        2),
  ('neighbor-know-it-all',  'Neighbor Know-It-All',   'Completed 3 Neighborhood Challenges. Your community knows your name.',            'assets/badges/neighbor_know_it_all.png',  3);

-- ============================================================
-- Sample election date (local dev only)
-- ============================================================
insert into public.election_dates (election_date, description, is_active) values
  ('2026-05-05', 'Indiana Primary Election 2026', true);
