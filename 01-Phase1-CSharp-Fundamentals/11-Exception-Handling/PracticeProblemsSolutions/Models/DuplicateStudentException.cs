class DuplicateStudentException : Exception
{
	public string DuplicateName { get; }

	public DuplicateStudentException(string name)
		: base($"Student '{name}' already exists.")
	{
		DuplicateName = name;
	}
}
