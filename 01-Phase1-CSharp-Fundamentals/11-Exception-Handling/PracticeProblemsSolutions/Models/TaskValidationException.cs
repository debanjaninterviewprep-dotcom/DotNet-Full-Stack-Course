class TaskValidationException : Exception
{
	public string FieldName { get; }
	public string InvalidValue { get; }

	public TaskValidationException(string fieldName, string invalidValue, string message)
		: base(message)
	{
		FieldName = fieldName;
		InvalidValue = invalidValue;
	}
}
