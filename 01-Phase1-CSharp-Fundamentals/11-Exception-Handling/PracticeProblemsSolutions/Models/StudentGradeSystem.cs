class StudentGradeSystem
{
	private Dictionary<string, List<double>> _students = new Dictionary<string, List<double>>();

	public void AddStudent(string name)
	{
		if (_students.ContainsKey(name))
			throw new DuplicateStudentException(name);
		_students[name] = new List<double>();
	}

	public void AddGrade(string name, double grade)
	{
		if (grade < 0 || grade > 100)
			throw new InvalidGradeException(grade, name);
		if (!_students.ContainsKey(name))
			throw new KeyNotFoundException($"Student '{name}' not found.");
		_students[name].Add(grade);
	}

	public double GetAverage(string name)
	{
		if (!_students.ContainsKey(name))
			throw new KeyNotFoundException($"Student '{name}' not found.");
		var grades = _students[name];
		if (grades.Count == 0)
			throw new InvalidOperationException($"Student '{name}' has no grades.");
		return grades.Average();
	}

	public string GetLetterGrade(double avg)
	{
		if (avg >= 90) return "A";
		if (avg >= 80) return "B";
		if (avg >= 70) return "C";
		if (avg >= 60) return "D";
		return "F";
	}
}
