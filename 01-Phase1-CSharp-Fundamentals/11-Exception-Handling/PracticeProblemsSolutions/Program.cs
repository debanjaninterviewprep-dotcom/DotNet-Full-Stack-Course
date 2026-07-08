using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Safe Calculator
			// ===============================
			// Handle FormatException, DivideByZeroException, OverflowException with try-catch-finally blocks for each attempt.

			Console.WriteLine("Problem 1: Safe Calculator");

			try
			{
				Console.Write("Enter first number: ");
				int num1 = int.Parse(Console.ReadLine()!);

				Console.Write("Enter second number: ");
				int num2 = int.Parse(Console.ReadLine()!);

				Console.WriteLine("Enter Operator (+, -, *, /): ");
				string op = Console.ReadLine()!;

				int result = 0;
				switch (op)
				{
					case "+":
						result = checked(num1 + num2);
						break;
					case "-":
						result = checked(num1 - num2);
						break;
					case "*":
						result = checked(num1 * num2);
						break;
					case "/":
						if (num2 == 0)
							throw new DivideByZeroException("Cannot divide by zero.");
						result = num1 / num2;
						break;
					default:
						throw new FormatException("Invalid operator.");
				}
				Console.WriteLine($"Result: {result}");
			}
			catch (FormatException ex)
			{
				Console.WriteLine($"Format Error: {ex.Message}");
			}
			catch (DivideByZeroException ex)
			{
				Console.WriteLine($"Math Error: {ex.Message}");
			}
			catch (OverflowException ex)
			{
				Console.WriteLine($"Overflow Error: {ex.Message}");
			}
			finally
			{
				Console.WriteLine("Calculation attempt finished.");
			}


			// ===============================
			// Problem 2: Input Validator with Retry
			// ===============================
			// Validate name/age/email with 3 retry attempts each, throw ArgumentException on failure, guard clauses.

			GetValidatedInput();

			// ===============================
			// Problem 3: Custom Exception - Student Grade System
			// ===============================
			// Create InvalidGradeException and DuplicateStudentException, use with AddGrade and GetAverage with chaining.

			Console.WriteLine("\nProblem 3: Student Grade System");

			StudentGradeSystem gradeSystem = new StudentGradeSystem();

			// Add students
			try
			{
				gradeSystem.AddStudent("Debanjan");
				Console.WriteLine("Student 'Debanjan' added.");
			}
			catch (DuplicateStudentException ex)
			{
				Console.WriteLine($"Error: {ex.Message}");
			}

			// Add a valid grade
			try
			{
				gradeSystem.AddGrade("Debanjan", 85);
				Console.WriteLine("Grade 85 added for Debanjan.");
			}
			catch (InvalidGradeException ex)
			{
				Console.WriteLine($"Error: {ex.Message}");
			}

			// Try to add an invalid grade (> 100)
			try
			{
				gradeSystem.AddGrade("Debanjan", 150);
			}
			catch (InvalidGradeException ex)
			{
				Console.WriteLine($"Error: {ex.Message}");
			}

			// Get average
			try
			{
				double avg = gradeSystem.GetAverage("Debanjan");
				Console.WriteLine($"Debanjan's Average: {avg:F2} ({gradeSystem.GetLetterGrade(avg)})");
			}
			catch (InvalidOperationException ex)
			{
				Console.WriteLine($"Error: {ex.Message}");
			}

			// Try adding duplicate student
			try
			{
				gradeSystem.AddStudent("Debanjan");
			}
			catch (DuplicateStudentException ex)
			{
				Console.WriteLine($"Error: {ex.Message}");
			}


			// ===============================
			// Problem 4: File-Based Task Logger with IDisposable
			// ===============================
			// TaskLogger implementing IDisposable, write tasks to file, validate input, throw ObjectDisposedException after disposal.

			Console.WriteLine("\nProblem 4: File-Based Task Logger");

			string logFilePath = "task_log.txt";
			TaskLogger? loggerRef = null;

			try
			{
				using (TaskLogger logger = new TaskLogger(logFilePath))
				{
					loggerRef = logger;

					logger.LogTask("Design database schema", "High");
					Console.WriteLine("Logged: \"Design database schema\" [High]");

					logger.LogTask("Write unit tests", "Medium");
					Console.WriteLine("Logged: \"Write unit tests\" [Medium]");

					try { logger.LogTask("", "High"); }
					catch (ArgumentException ex) { Console.WriteLine($"Error: {ex.Message}"); }

					try { logger.LogTask("Some task", "Urgent"); }
					catch (ArgumentException ex) { Console.WriteLine($"Error: {ex.Message}"); }

					logger.LogError("Connection timeout on server");
					Console.WriteLine("Error logged: \"Connection timeout on server\"");

					var (tasks, errors) = logger.GetLogSummary();
					Console.WriteLine($"Summary: {tasks} tasks, {errors} error(s) logged.");
				}

				// Logger is disposed — attempt to use it
				Console.WriteLine("\nAttempting to use disposed logger...");
				try { loggerRef.LogTask("Test", "Low"); }
				catch (ObjectDisposedException ex) { Console.WriteLine($"Error: {ex.Message}"); }

				Console.WriteLine("\n=== Log File Contents ===");
				foreach (string line in File.ReadAllLines(logFilePath))
					Console.WriteLine(line);
			}
			catch (UnauthorizedAccessException ex) { Console.WriteLine($"Access Error: {ex.Message}"); }
			catch (IOException ex) { Console.WriteLine($"IO Error: {ex.Message}"); }


			// ===============================
			// Problem 5: TaskFlow Exception-Safe Task Processor
			// ===============================
			// Custom TaskValidationException, TaskProcessingException, TaskQuotaExceededException with 5-task limit and retry logic.

			Console.WriteLine("\nProblem 5: TaskFlow Exception-Safe Task Processor");
			Console.WriteLine("\nAdding tasks...");

			using (TaskProcessor processor = new TaskProcessor())
			{
				// 5 valid tasks + 2 invalid ones + 1 quota-exceeded attempt
				TryAddTask(processor, 1, "Setup project structure",    3, DateTime.Now.AddDays(2));
				TryAddTask(processor, 2, "Create database models",     3, DateTime.Now.AddDays(4));
				TryAddTask(processor, 3, "AB",                         2, DateTime.Now.AddDays(7));  // invalid title
				TryAddTask(processor, 3, "Write API endpoints",        2, DateTime.Now.AddDays(7));
				TryAddTask(processor, 4, "Build Angular frontend",     2, new DateTime(2025, 1, 1)); // past date
				TryAddTask(processor, 4, "Build Angular frontend",     2, DateTime.Now.AddDays(12));
				TryAddTask(processor, 5, "Deploy to Azure",            1, DateTime.Now.AddDays(17));
				TryAddTask(processor, 6, "Extra task",                 1, DateTime.Now.AddDays(20)); // quota exceeded

				Console.WriteLine("\nProcessing all tasks...");
				processor.ProcessAllTasks();
			}

		}

		public static void GetValidatedInput()
		{
			string? name = null;
			int age = 0;
			string? email = null;

			bool nameValid = TryGetInput(
				"Enter your name: ",
				ValidateName,
				out name);

			bool ageValid = TryGetInput(
				"Enter your age: ",
				ValidateAge,
				out age);

			bool emailValid = TryGetInput(
				"Enter your email: ",
				ValidateEmail,
				out email);

			if (nameValid && ageValid && emailValid)
			{
				Console.WriteLine("\n--- Registration Successful ---");
				Console.WriteLine($"Name  : {name}");
				Console.WriteLine($"Age   : {age}");
				Console.WriteLine($"Email : {email}");
			}
			else
			{
				Console.WriteLine("\nRegistration failed");
			}
		}

		// Generic input handler with retry logic
		private static bool TryGetInput<T>(
			string prompt,
			Func<string, T> validator,
			out T value)
		{
			int attempts = 3;

			while (attempts > 0)
			{
				Console.Write(prompt);
				string input = Console.ReadLine()!;

				try
				{
					value = validator(input);
					return true;
				}
				catch (ArgumentException ex)
				{
					attempts--;
					Console.WriteLine($"Error: {ex.Message}");

					if (attempts > 0)
					{
						Console.WriteLine($"Attempts remaining: {attempts}\n");
					}
				}
			}

			value = default!;
			return false;
		}

		// Validation Methods (throw ArgumentException)

		private static string ValidateName(string input)
		{
			if (string.IsNullOrWhiteSpace(input))
				throw new ArgumentException("Name cannot be empty.");

			foreach (char c in input)
			{
				if (char.IsDigit(c))
					throw new ArgumentException("Name cannot contain digits.");
			}

			return input;
		}

		private static int ValidateAge(string input)
		{
			if (!int.TryParse(input, out int age))
				throw new ArgumentException("Age must be a valid integer.");

			if (age < 1 || age > 120)
				throw new ArgumentException("Age must be between 1 and 120.");

			return age;
		}

		private static string ValidateEmail(string input)
		{
			if (string.IsNullOrWhiteSpace(input))
				throw new ArgumentException("Email cannot be empty.");

			if (!input.Contains("@") || !input.Contains("."))
				throw new ArgumentException("Email must contain '@' and '.'.");

			return input;
		}

		// Helper for Problem 5
		private static void TryAddTask(TaskProcessor processor, int id, string title, int priority, DateTime dueDate)
		{
			try
			{
				processor.AddTask(id, title, priority, dueDate);
				string priorityStr = priority == 3 ? "High" : priority == 2 ? "Medium" : "Low";
				Console.WriteLine($"✓ Task {id}: \"{title}\" added [{priorityStr}, Due: {dueDate:yyyy-MM-dd}]");
			}
			catch (TaskValidationException ex)
			{
				Console.WriteLine($"✗ Validation Error: Field '{ex.FieldName}' has invalid value '{ex.InvalidValue}' — {ex.Message}");
			}
			catch (TaskQuotaExceededException ex)
			{
				Console.WriteLine($"✗ Quota Error: Cannot add more tasks. Current: {ex.CurrentCount}, Maximum: {ex.MaxAllowed}.");
			}
		}

	}

}

