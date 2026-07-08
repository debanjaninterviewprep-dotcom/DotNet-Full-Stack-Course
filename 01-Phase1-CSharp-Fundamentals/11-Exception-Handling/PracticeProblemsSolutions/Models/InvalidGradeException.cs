class InvalidGradeException : Exception
{
	public double AttemptedGrade { get; }
	public string StudentName { get; }

	public InvalidGradeException(double grade, string student)
		: base($"Grade {grade} is invalid for student '{student}'. Must be 0-100.")
	{
		AttemptedGrade = grade;
		StudentName = student;
	}
}
