
using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Arithmetic Playground
			// ===============================
			Console.WriteLine("=== Arithmetic Playground ===");
			Console.Write("Enter first number: ");
			int num1;
			while (!int.TryParse(Console.ReadLine() ?? string.Empty, out num1))
			{
				Console.Write("Invalid input. Enter first number: ");
			}
			Console.Write("Enter second number: ");
			int num2;
			while (!int.TryParse(Console.ReadLine() ?? string.Empty, out num2))
			{
				Console.Write("Invalid input. Enter second number: ");
			}
			Console.WriteLine("\n=== Arithmetic Results ===");
			Console.WriteLine($"{num1} + {num2}  = {num1 + num2}");
			Console.WriteLine($"{num1} - {num2}  = {num1 - num2}");
			Console.WriteLine($"{num1} * {num2}  = {num1 * num2}");
			Console.WriteLine($"{num1} / {num2}  = {num1 / num2}       (integer division)");
			Console.WriteLine($"{num1} / {num2}  = {(num1 / (double)num2):F2}    (decimal division)");
			Console.WriteLine($"{num1} % {num2}  = {num1 % num2}       (remainder)\n");

			// ===============================
			// Problem 2: Pre/Post Increment Predictor
			// ===============================
			Console.WriteLine("=== Pre/Post Increment Predictor ===");
			int x = 10;
			Console.WriteLine($"Starting: x = {x}\n");
			int a = x++; // Post-increment: a gets 10, x becomes 11
			Console.WriteLine($"int a = x++;  → a = {a}, x = {x}");
			int b = ++x; // Pre-increment: x becomes 12, b gets 12
			Console.WriteLine($"int b = ++x;  → b = {b}, x = {x}");
			int c = x--; // Post-decrement: c gets 12, x becomes 11
			Console.WriteLine($"int c = x--;  → c = {c}, x = {x}");
			int d = --x; // Pre-decrement: x becomes 10, d gets 10
			Console.WriteLine($"int d = --x;  → d = {d}, x = {x}\n");

			// ===============================
			// Problem 3: Grade Calculator with Logical Operators
			// ===============================
			Console.WriteLine("=== Grade Calculator ===");
			int math = ReadScore("Math");
			int science = ReadScore("Science");
			int english = ReadScore("English");
			double avg = (math + science + english) / 3.0;
			char grade = avg >= 90 ? 'A' : avg >= 80 ? 'B' : avg >= 70 ? 'C' : avg >= 60 ? 'D' : 'F';
			bool passed = math >= 40 && science >= 40 && english >= 40 && avg >= 60;
			bool distinction = math >= 75 && science >= 75 && english >= 75 && avg >= 85;
			string failedSubjects = "";
			if (math < 40) failedSubjects += "Math ";
			if (science < 40) failedSubjects += "Science ";
			if (english < 40) failedSubjects += "English ";
			Console.WriteLine("\n=== REPORT CARD ===");
			Console.WriteLine($"Math:       {math}");
			Console.WriteLine($"Science:    {science}");
			Console.WriteLine($"English:    {english}");
			Console.WriteLine($"Average:    {avg:F2}");
			Console.WriteLine($"Grade:      {grade}");
			Console.WriteLine($"Status:     {(passed ? "PASSED ✅" : "FAILED ❌")}");
			Console.WriteLine($"Distinction: {(distinction ? "Yes" : "No")}");
			if (!passed)
				Console.WriteLine($"Failed subjects: {failedSubjects.Trim()}");
			Console.WriteLine();

			// ===============================
			// Problem 4: Bitwise Permission System
			// ===============================
			Console.WriteLine("=== PERMISSION MANAGER ===");
			const int Read = 1, Write = 2, Execute = 4;
			int permissions = 0;
			permissions |= AskPermission("READ") ? Read : 0;
			permissions |= AskPermission("WRITE") ? Write : 0;
			permissions |= AskPermission("EXECUTE") ? Execute : 0;
			Console.WriteLine($"\nPermission Value: {permissions}");
			Console.WriteLine($"Binary: {Convert.ToString(permissions, 2).PadLeft(3, '0')}");
			Console.Write("Permissions: ");
			if ((permissions & Read) != 0) Console.Write("Read ");
			if ((permissions & Write) != 0) Console.Write("Write ");
			if ((permissions & Execute) != 0) Console.Write("Execute ");
			if (permissions == 0) Console.Write("None");
			Console.WriteLine();
			Console.Write("\nCheck permission - Enter R/W/E: ");
			string? checkInput = Console.ReadLine();
			string check = (checkInput ?? string.Empty).Trim().ToUpper();
			int checkVal = check == "R" ? Read : check == "W" ? Write : check == "E" ? Execute : 0;
			if (checkVal == 0)
				Console.WriteLine("Invalid input.");
			else if ((permissions & checkVal) != 0)
				Console.WriteLine($"Result: ✅ {check} permission GRANTED");
			else
				Console.WriteLine($"Result: ❌ {check} permission NOT granted");
			Console.WriteLine();

			// ===============================
			// Problem 5: Null-Safe User Profile
			// ===============================
			Console.WriteLine("=== TASKFLOW PROFILE SETUP ===\n");
			string? name = AskField("name");
			string? email = AskField("email");
			string? phone = AskField("phone");
			string? city = AskField("city");
			int filled = 0;
			if (!string.IsNullOrWhiteSpace(name)) filled++;
			if (!string.IsNullOrWhiteSpace(email)) filled++;
			if (!string.IsNullOrWhiteSpace(phone)) filled++;
			if (!string.IsNullOrWhiteSpace(city)) filled++;
			double completeness = (filled / 4.0) * 100;
			string emailDomain = string.IsNullOrWhiteSpace(email) ? "N/A" : (email!.Contains("@") ? email.Split('@')[1] : "N/A");
			Console.WriteLine("╔══════════════════════════════════════╗");
			Console.WriteLine("║         USER PROFILE                 ║");
			Console.WriteLine("╠══════════════════════════════════════╣");
			Console.WriteLine($"║  Name:    {(string.IsNullOrWhiteSpace(name) ? "Not Provided" : name),-25}║");
			Console.WriteLine($"║  Email:   {(string.IsNullOrWhiteSpace(email) ? "Not Provided" : email),-25}║");
			Console.WriteLine($"║  Phone:   {(string.IsNullOrWhiteSpace(phone) ? "Not Provided" : phone),-25}║");
			Console.WriteLine($"║  City:    {(string.IsNullOrWhiteSpace(city) ? "Not Provided" : city),-25}║");
			Console.WriteLine("╠══════════════════════════════════════╣");
			Console.WriteLine($"║  Name Length:    {(string.IsNullOrEmpty(name) ? "N/A" : name.Length + " characters"),-16}║");
			Console.WriteLine($"║  Email Domain:   {emailDomain,-16}║");
			Console.WriteLine($"║  Profile:        {completeness:F0}% Complete      ║");
			Console.WriteLine("╚══════════════════════════════════════╝\n");
		}

		static int ReadScore(string subject)
		{
			int score;
			while (true)
			{
				Console.Write($"Enter {subject} score: ");
				string? input = Console.ReadLine();
				if (int.TryParse(input ?? string.Empty, out score) && score >= 0 && score <= 100)
					return score;
				Console.WriteLine("Invalid input. Please enter a number between 0 and 100.");
			}
		}

		static bool AskPermission(string perm)
		{
			Console.Write($"Grant {perm} permission? (Y/N): ");
			string? input = Console.ReadLine();
			return (input ?? string.Empty).Trim().ToUpper() == "Y";
		}

		static string? AskField(string field)
		{
			Console.Write($"Enter {field} (or press Enter to skip): ");
			string? val = Console.ReadLine();
			return string.IsNullOrWhiteSpace(val) ? null : val;
		}
	}
}
