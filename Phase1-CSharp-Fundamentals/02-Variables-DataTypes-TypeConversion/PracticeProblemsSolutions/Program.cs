
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

// Entry point for the console application
public class Program
{
	public static void Main(string[] args)
	{
		// Problem 1: Write a C# console program that declares one variable of each type below, assigns a value, and prints them all with labels:
		// int, double, decimal, float, long
		// char, bool, string
		// int myInt = 42;
		// double myDouble = 3.14;
		// decimal myDecimal = 19.99m;
		// float myFloat = 2.718f;
		// long myLong = 123456789L;
		// char myChar = 'A';
		// bool myBool = true;
		// string myString = "Hello, World!";
		// Console.WriteLine($"Integer: {myInt}");
		// Console.WriteLine($"Double: {myDouble}");
		// Console.WriteLine($"Decimal: {myDecimal}");
		// Console.WriteLine($"Float: {myFloat}");
		// Console.WriteLine($"Long: {myLong}");
		// Console.WriteLine($"Char: {myChar}");
		// Console.WriteLine($"Boolean: {myBool}");
		// Console.WriteLine($"String: {myString}");

		//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

		// Problem 2: Smart Type Converter
		// Write a program that:
	}
}

// Asks the user to enter a string value
// Attempts to convert it to int, double, and bool
// For each conversion, print whether it succeeded or failed, and the result

// Console.WriteLine("Enter a string value:");
// string input = Console.ReadLine();

// if (int.TryParse(input, out int intValue))
// {
//     Console.WriteLine($"Conversion to int succeeded: {intValue}");
// }
// else
// {
//     Console.WriteLine("Conversion to int failed.");
// }

// if (double.TryParse(input, out double doubleValue))
// {
//     Console.WriteLine($"Conversion to double succeeded: {doubleValue}");
// }
// else
// {
//     Console.WriteLine("Conversion to double failed.");
// }

// if (bool.TryParse(input, out bool boolValue))
// {
//     Console.WriteLine($"Conversion to bool succeeded: {boolValue}");
// }
// else
// {
//     Console.WriteLine("Conversion to bool failed.");
// }

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//Problem 3: Salary Calculator

// Write a program that:

// Asks for the employee's name, hourly rate (decimal), and hours worked this week
// Calculates:
// Gross pay = hourly rate × hours
// Tax (20% of gross)
// Net pay = gross - tax
// Displays a formatted pay slip

// Console.WriteLine("Enter employee's name:");
// string name = Console.ReadLine();

// Console.WriteLine("Enter hourly rate:");
// decimal hourlyRate = decimal.Parse(Console.ReadLine());

// Console.WriteLine("Enter hours worked this week:");
// decimal hoursWorked = decimal.Parse(Console.ReadLine());

// decimal grossPay = hourlyRate * hoursWorked;
// decimal tax = grossPay * 0.2m;
// decimal netPay = grossPay - tax;

// Console.WriteLine();
// Console.WriteLine("Pay Slip");
// Console.WriteLine("--------");
// Console.WriteLine($"Employee: {name}");
// Console.WriteLine($"Hourly Rate: {hourlyRate:C}");
// Console.WriteLine($"Hours Worked: {hoursWorked}");
// Console.WriteLine($"Gross Pay: {grossPay:C}");
// Console.WriteLine($"Tax (20%): {tax:C}");
// Console.WriteLine($"Net Pay: {netPay:C}");

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

// Problem 4: Data Type Size Reporter 

// Write a program that prints a formatted table showing:

// The name of each C# numeric data type
// Its size in bytes (use sizeof())
// Its minimum and maximum values (use int.MinValue, int.MaxValue, etc.)

// Console.WriteLine("Data Type\tSize (Bytes)\tMin Value\t\t\tMax Value");
// Console.WriteLine("---------------------------------------------------------------");
// Console.WriteLine($"int\t\t{sizeof(int)}\t\t{int.MinValue}\t\t{int.MaxValue}");
// Console.WriteLine($"double\t\t{sizeof(double)}\t\t{double.MinValue}\t{double.MaxValue}");
// Console.WriteLine($"decimal\t{sizeof(decimal)}\t\t{decimal.MinValue}\t{decimal.MaxValue}");
// Console.WriteLine($"float\t\t{sizeof(float)}\t\t{float.MinValue}\t\t{float.MaxValue}");
// Console.WriteLine($"long\t\t{sizeof(long)}\t\t{long.MinValue}\t{long.MaxValue}");
// Console.WriteLine($"short\t\t{sizeof(short)}\t\t{short.MinValue}\t\t{short.MaxValue}");
// Console.WriteLine($"byte\t\t{sizeof(byte)}\t\t{byte.MinValue}\t\t{byte.MaxValue}");

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

// Problem 5: Nullable Score Tracker

// Build a program that tracks scores for 3 subjects. The user can enter a score OR leave it blank (meaning "not yet graded").

// Ask the user for scores in Math, Science, and English
// If the user presses Enter without typing anything, store it as null (use int?)
// Display a report card showing:
// Each subject's score (or "Not Graded" if null)
// The average of only the graded subjects
// The total subjects graded vs total subjects

// Console.WriteLine("Enter score for Math (or press Enter to skip):");
// string mathInput = Console.ReadLine();
// int? mathScore = string.IsNullOrWhiteSpace(mathInput) ? (int?)null : int.Parse(mathInput);

// Console.WriteLine("Enter score for Science (or press Enter to skip):");
// string scienceInput = Console.ReadLine();
// int? scienceScore = string.IsNullOrWhiteSpace(scienceInput) ? (int?)null : int.Parse(scienceInput);

// Console.WriteLine("Enter score for English (or press Enter to skip):");
// string englishInput = Console.ReadLine();
// int? englishScore = string.IsNullOrWhiteSpace(englishInput) ? (int?)null : int.Parse(englishInput);

// int?[] scores = { mathScore, scienceScore, englishScore };
// int gradedCount = 0;
// int totalScore = 0;

// foreach (var score in scores)
// {
//     if (score.HasValue)
//     {
//         gradedCount++;
//         totalScore += score.Value;
//     }
// }

// double average = gradedCount > 0 ? (double)totalScore / gradedCount : 0;

// Console.WriteLine();
// Console.WriteLine("Report Card");
// Console.WriteLine("-----------");
// Console.WriteLine($"Math: {(mathScore.HasValue ? mathScore.Value.ToString() : "Not Graded")}");
// Console.WriteLine($"Science: {(scienceScore.HasValue ? scienceScore.Value.ToString() : "Not Graded")}");
// Console.WriteLine($"English: {(englishScore.HasValue ? englishScore.Value.ToString() : "Not Graded")}");
// Console.WriteLine($"Average: {average:F2}");
// Console.WriteLine($"Subjects Graded: {gradedCount} / {scores.Length}");

