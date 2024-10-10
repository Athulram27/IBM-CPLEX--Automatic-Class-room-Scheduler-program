/*********************************************
 * OPL 22.1.1.0 Model
 * Author: athul
 * Creation Date: Jun 29, 2024 at 9:24:05 AM
 *********************************************/
 
// Define sets
{string} Courses = ...;
{string} Classrooms = ...;

// Capacity
int Capacity[Classrooms] = ...;

range Timeslots = 8..21;

{string} Days = ...;

int Enrolled[Courses] = ...;
int Classes[Courses] = ...;

// Weights
float Weight[Courses] = ...;

{string} Professors = ...;

// Mapping of courses to professors
tuple ProfessorCourse {
  string course;
  string professor;
}
{ProfessorCourse} CourseProfessors = ...;

int ProfessorPreference[Professors][Days][Timeslots] = ...;
int MaxDailyClasses[Courses] = ...;

// Decision variables
dvar boolean x[Courses][Classrooms][Timeslots][Days][Professors];
dvar boolean y[Courses][Timeslots][Days];  // New variable to capture consecutive scheduling

// Objective function
maximize 
    sum(c in Courses, r in Classrooms, t in Timeslots, d in Days, p in Professors) 
        (Weight[c] * ProfessorPreference[p][d][t] * x[c][r][t][d][p]) 
    + sum(c in Courses, t in Timeslots: t < 21, d in Days) y[c][t][d];

// Constraints
subject to {
  // Capacity constraint: the number of students should not exceed the classroom capacity
  forall(r in Classrooms, t in Timeslots, d in Days)
    sum(c in Courses, p in Professors) x[c][r][t][d][p] * Enrolled[c] <= Capacity[r];

  // each course needs to be assigned exactly the number of times specified
  forall(c in Courses)
    sum(r in Classrooms, t in Timeslots, d in Days, p in Professors) x[c][r][t][d][p] == Classes[c];

  // each classroom is used at most once per timeslot
  forall(r in Classrooms, t in Timeslots, d in Days)
    sum(c in Courses, p in Professors) x[c][r][t][d][p] <= 1;

  // Each subject can be scheduled only up to its specified maximum times per day
  forall(c in Courses, d in Days)
    sum(r in Classrooms, t in Timeslots, p in Professors) x[c][r][t][d][p] <= MaxDailyClasses[c];

  // Each professor can teach only one course in one classroom at one time slot
  forall(p in Professors, d in Days, t in Timeslots)
    sum(c in Courses, r in Classrooms) x[c][r][t][d][p] <= 1;

  // Ensure a professor teaches only their assigned courses
  forall(c in Courses, r in Classrooms, t in Timeslots, d in Days, p in Professors)
    if (!(<c, p> in CourseProfessors)) {
      x[c][r][t][d][p] == 0;
    }
    
  // Define y[c][t][d] as 1 if x[c][r][t][d] and x[c][r][t+1][d] are both 1 for any classroom
  forall(c in Courses, t in Timeslots: t < 21, d in Days) {
    sum(r in Classrooms, p in Professors) 
      (x[c][r][t][d][p] + x[c][r][t+1][d][p] - 1) <= y[c][t][d];
  }
  
    /* 
  // Consecutive classes constraint
  forall(c in Courses, d in Days, t in Timeslots: t < 11)
    y[c][d][t] + y[c][d][t+1] <= 1;
   */ 
   
   /* 
    // professor teaches only their assigned courses according to their preferences
  forall(p in Professors, d in Days, t in Timeslots)
    sum(c in Courses, r in Classrooms) ProfessorPreference[p][d][t] * x[c][r][t][d][p] >= 0;
	*/
}

// Output
execute {
  writeln("Course Schedule:");
  for (var c in Courses)
    for (var r in Classrooms)
      for (var t in Timeslots)
        for (var d in Days)
          for (var p in Professors)
            if (x[c][r][t][d][p] == 1)
              writeln(c, " is scheduled in ", r, " at timeslot ", t, " on ", d, " taught by ", p);
  writeln("Objective function value: ", cplex.getObjValue());
}
