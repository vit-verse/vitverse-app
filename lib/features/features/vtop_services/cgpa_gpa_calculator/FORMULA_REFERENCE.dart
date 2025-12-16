/*
Reference: https://chennai.vit.ac.in/files/Academic-Regulations.pdf

This PDF was summarized with the help of Grok ;) for refrence

═══════════════════════════════════════════════════════════════════════
                    VIT GRADING SYSTEM (Official)
═══════════════════════════════════════════════════════════════════════

Grade    Points    Marks Range    Remarks              Counted in CGPA
────────────────────────────────────────────────────────────────────────
  S       10.0      90-100        Outstanding                 ✓
  A       9.0       80-89         Excellent                   ✓
  B       8.0       70-79         Very Good                   ✓
  C       7.0       60-69         Good                        ✓
  D       6.0       55-59         Average                     ✓
  E       5.0       50-54         Below Average               ✓
  F       0.0       <50           Fail                        ✓
  N       0.0       -             Non-completion              ✓
  W       -         -             Withdrawn                   ✗
  U       -         -             Audit Completed             ✗
  P       -         -             Pass (P/F course)           ✗

═══════════════════════════════════════════════════════════════════════
                        CORE FORMULAS
═══════════════════════════════════════════════════════════════════════

1. GPA (Semester Grade Point Average)
   ────────────────────────────────────
   GPA = Σ(Credits_i × GradePoint_i) / ΣCredits_i
   
   Where:
   - Credits_i = Credits of course i
   - GradePoint_i = Grade point of course i (from table above)
   - Only grades S-E, F, N are counted
   
   Example:
   Course 1: 4 credits, A grade → 4 × 9.0 = 36.0
   Course 2: 3 credits, B grade → 3 × 8.0 = 24.0
   Course 3: 3 credits, S grade → 3 × 10.0 = 30.0
   Total: 10 credits, GPA = (36 + 24 + 30) / 10 = 9.0

2. CGPA (Cumulative Grade Point Average)
   ────────────────────────────────────────
   CGPA = Σ(GPA_sem × Credits_sem) / ΣCredits_sem
   
   Alternative (for incremental update):
   NewCGPA = (PrevCGPA × PrevCredits + CurrentGPA × CurrentCredits) / (PrevCredits + CurrentCredits)
   
   Example:
   Previous: CGPA 8.48, 79 credits
   Current semester: GPA 9.0, 18 credits
   New CGPA = (8.48 × 79 + 9.0 × 18) / (79 + 18) = 8.57

3. Required GPA (Target Tracker)
   ─────────────────────────────────
   RequiredGPA = (TargetCGPA × TotalCredits - PrevCGPA × PrevCredits) / CurrentCredits
   
   Example:
   Target: 9.0 CGPA
   Current: 8.48 CGPA, 79 credits
   Current semester: 18 credits
   Required = (9.0 × 97 - 8.48 × 79) / 18 = 9.27
   
   Result: Need GPA of 9.27 this semester to reach 9.0 CGPA

4. Projected CGPA (Future Simulator)
   ──────────────────────────────────
   ProjectedCGPA = (PrevCGPA × PrevCredits + ExpectedGPA × CurrentCredits) / TotalCredits
   
   Example:
   Current: 8.48 CGPA, 79 credits
   Expected: 8.5 GPA, 18 credits
   Projected = (8.48 × 79 + 8.5 × 18) / 97 = 8.51

5. Maximum Possible CGPA
   ──────────────────────
   MaxCGPA = (PrevCGPA × PrevCredits + 10.0 × RemainingCredits) / TotalProgramCredits
   
   Example:
   Current: 8.48 CGPA, 79 credits
   Total program: 151 credits
   Remaining: 72 credits
   Max = (8.48 × 79 + 10.0 × 72) / 151 = 9.21

6. Minimum Possible CGPA
   ──────────────────────
   MinCGPA = (PrevCGPA × PrevCredits + 0.0 × RemainingCredits) / TotalProgramCredits
   MinCGPA = (PrevCGPA × PrevCredits) / TotalProgramCredits
   
   Example:
   Current: 8.48 CGPA, 79 credits
   Total program: 151 credits
   Min = (8.48 × 79) / 151 = 4.44

7. Grade Simulation (What-If Analysis)
   ────────────────────────────────────
   SimulatedCGPA = (PrevCGPA × PrevCredits + GradePoint × RemainingCredits) / TotalCredits
   
   Example (all B grades):
   Current: 8.48 CGPA, 79 credits
   Remaining: 72 credits
   B grade point: 8.0
   Simulated = (8.48 × 79 + 8.0 × 72) / 151 = 8.27

8. Grade Mix Simulation
   ──────────────────────
   MixedGPA = Σ(Percentage_g × GradePoint_g)
   ProjectedCGPA = (PrevCGPA × PrevCredits + MixedGPA × RemainingCredits) / TotalCredits
   
   Example (40% S, 30% A, 30% B):
   MixedGPA = 0.4 × 10 + 0.3 × 9 + 0.3 × 8 = 9.1
   Projected = (8.48 × 79 + 9.1 × 72) / 151 = 8.77

9. Course Impact on CGPA
   ──────────────────────
   ΔCGPA = (GradePoint_new - GradePoint_old) × CourseCredits / TotalCredits
   
   Example (changing B to S in 4-credit course):
   Change = (10.0 - 8.0) × 4 / 151 = 0.053
   Impact: CGPA increases by 0.053 points

10. CGPA to Percentage (VIT Official)
    ──────────────────────────────────
    Percentage = CGPA × 10
    
    Example:
    CGPA 8.48 → 84.8%
    CGPA 9.00 → 90.0%

═══════════════════════════════════════════════════════════════════════
                        VALIDATION RULES
═══════════════════════════════════════════════════════════════════════

1. GPA/CGPA Range: 0.00 - 10.00
2. Credits must be > 0
3. Target CGPA > Current CGPA (for estimator)
4. Required GPA > 10.0 → Target impossible
5. Required GPA < 5.0 → Target already achievable
6. Only grades S-E, F, N count in calculations
7. W, U, P grades are excluded

═══════════════════════════════════════════════════════════════════════
                        DIFFICULTY LEVELS
═══════════════════════════════════════════════════════════════════════

Required GPA    Difficulty         Description
─────────────────────────────────────────────────────────────────────
< 5.0           Achieved           Target already met
5.0 - 7.0       Very Easy          C grade average sufficient
7.0 - 8.0       Easy               B grade average needed
8.0 - 9.0       Moderate           Mix of A and B grades
9.0 - 9.5       Hard               Mix of S and A grades
9.5 - 10.0      Very Hard          Mostly S grades required
> 10.0          Impossible         Cannot achieve this semester

═══════════════════════════════════════════════════════════════════════
                        TREND INDICATORS
═══════════════════════════════════════════════════════════════════════

CGPA Change     Trend              Icon        Color
─────────────────────────────────────────────────────────────────────
≥ +0.30         Improving Fast     🔥          Green
+0.10 to +0.29  Steady Improvement 📈          Blue
-0.09 to +0.09  Maintaining Well   😊          Orange
-0.29 to -0.10  Slight Decline     ⚠️          Light Red
≤ -0.30         Needs Attention    🚨          Red


*/
